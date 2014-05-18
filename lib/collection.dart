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
  
  Future<Model> save(Model m) {
    if (m._needsToBePersisted) {
      m["updated_at"] = new DateTime.now();
      Future<Model> f;
      var completer = new Completer<Model>();
      var wasPersistedBefore = m.isPersisted;
      if (m.isPersisted) {
        this.beforeUpdate(m);
        f = _adapter.updateModel(schema, m);
      } else {
        m["created_at"] = new DateTime.now();
        this.beforeCreate(m);
        f = _adapter.saveModel(schema, m);
      }
      f.then((saved) {
        saved._setClean();
        wasPersistedBefore ? 
            this.afterUpdate(saved) : this.afterCreate(saved);
        completer.complete(saved);
      }).catchError((err) {
        completer.completeError(err);
      });
      return completer.future;
    }
    return new Future.value(m);
  }
  Future<Model> find(int id) {
    var completer = new Completer<Model>();
    _adapter.findModel(this, id).then((m) {
      m._setClean();
      completer.complete(m);
    }).catchError((err) {
      completer.completeError(err);
    });
    return completer.future;
  }
  
  Future<List<Model>> where(String sql, List params) {
    var completer = new Completer<List<Model>>();
    _adapter.modelsWhere(this, sql, params).then((ms) {
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