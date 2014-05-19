part of activerecord;

typedef void BeforeCreateFunc(Model toBePersisted);
typedef void AfterCreateFunc(Model wasPersisted);
typedef void BeforeUpdateFunc(Model toBeUpdated);
typedef void AfterUpdateFunc(Model wasUpdated);
typedef void BeforeDestroyFunc(Model toBeDestroyed);
typedef void AfterDestroyFunc();

abstract class Collection {
  DatabaseAdapter _adapter;
  Schema _schema;
  
  Collection() {
    var vars = Variable.MODEL_STUBS..addAll(variables);
    _schema = new Schema(this._tableName, vars);
    _adapter = this.adapter;
    _adapter.createTable(_schema);
  }
  
  List<MethodMirror> getModelMethods() {
    var lst = [];
    reflect(this).type.instanceMembers.forEach((Symbol k, MethodMirror m) {
        if(m.isRegularMethod && isModelMethod(m)) lst.add(m);
    });
    return lst;
  }
  
  bool isModelMethod(MethodMirror m) {
    return (m.parameters.length > 0 && m.parameters[0].type == reflectClass(Model));
  }
  
  Future<bool> destroy(Model m) {
    if (m.isPersisted) {
      var completer = new Completer();
      this.beforeDestroy(m);
      _adapter.destroyModel(m).then((bool val) {
        this.afterDestroy();
        completer.complete(val);
      }).catchError((e) => completer.completeError(e));
      return completer.future;
    }
    return new Future.error("Model was not persisted --> cannot destroy model");
  }
  
  Future<Model> create(Model m) {
    var completer = new Completer<Model>();
    validate(m, Validation.ON_CREATE_FLAG).then((bool valRes) {
      if (valRes) {
        this.beforeCreate(m);
        m["updated_at"] = new DateTime.now();
        m["created_at"] = new DateTime.now();
        _adapter.saveModel(schema, m).then((created) {
          created._setClean();
          this.afterCreate(created);
          completer.complete(created);
        }).catchError((e) => completer.completeError(e));
      } else {
        completer.completeError("Model validation failed");
      }
    }).catchError((e) => completer.completeError(e));
    return completer.future;
  }
  
  Future<Model> update(Model m) {
    var completer = new Completer<Model>();
    validate(m, Validation.ON_CREATE_FLAG).then((bool valRes) {
      if (valRes) {
        this.beforeUpdate(m);
        m["updated_at"] = new DateTime.now();
        _adapter.saveModel(schema, m).then((updated) {
          updated._setClean();
          this.afterUpdate(updated);
          completer.complete(updated);
        }).catchError((e) => completer.completeError(e));
      } else {
        completer.completeError("Model Validation failed");
      }
    }).catchError((e) => completer.completeError(e));
    return completer.future;
  }
  
  Future<Model> save(Model m) {
    if (m._needsToBePersisted) {
      if(m.isPersisted) return update(m);
      else return create(m);
    }
    return new Future.value(m);
  }
  
  Future<bool> validate(Model m, int flag) {
    var completer = new Completer<bool>();
    if (m.parent != this) return new Future.error("Not same parent");
    var validationResults = new List<Future<bool>>();
    schema.variables.forEach((v) {
      v.validations.forEach((Validation validation) {
        validationResults.add(validation.validate(v, m, m[v.name], flag));
      });
    });
    Future.wait(validationResults).then((List<bool> results) {
      bool result = true;
      for (bool res in results) {
        result = result && res;
      }
      return completer.complete(result);
    }).catchError((e) => completer.completeError(e));
    return completer.future;
  }
  
  Future<Model> find(int id) {
    var completer = new Completer<Model>();
    where("id = ?", [id], limit: 1).then((List<Model> models) {
      if (models.length != 1) {
        completer.completeError("Invalid result: ${models.length} found");
      } else {
        completer.complete(models[0]);
      }
    }).catchError((e) => completer.completeError(e));
    return completer.future;
  }
  
  Future<List<Model>> all({int limit, int offset}) {
    return where("", [], limit: limit, offset: offset);
  }
  
  Future<List<Model>> where(String sql, List params, {int limit, int offset}) {
    var completer = new Completer<List<Model>>();
    _adapter.modelsWhere(this, sql, params, limit, offset).then((ms) {
      ms.forEach((m) => m._setClean());
      completer.complete(ms);
    }).catchError((err) {
      completer.completeError(err);
    });
    return completer.future;
  }
  
  BeforeCreateFunc get beforeCreate => (Model m){};
  AfterCreateFunc get afterCreate => (Model m){};
  BeforeUpdateFunc get beforeUpdate => (Model m){};
  AfterUpdateFunc get afterUpdate => (Model m){};
  BeforeDestroyFunc get beforeDestroy => (Model m){};
  AfterDestroyFunc get afterDestroy => (){};
  DatabaseAdapter get adapter => defaultAdapter; // Override if needed
  List<Variable> get variables => []; // Override to set Variables in Schema
  String get _tableName => MirrorSystem.getName(reflect(this).type.simpleName);
  Schema get schema => _schema;
  Model get nu => new Model(this);
}