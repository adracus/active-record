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
    var vars = []..addAll(Variable.MODEL_STUBS)
      ..addAll(parseVariables(variables));
    this.parseRelations(belongsTo).forEach((r) 
      => vars.add(r.variableOnHolder));
    _schema = new Schema(this._tableName, vars);
    _adapter = this.adapter;
  }
  
  Model create(Map <String, dynamic> args) {
    var m = this.nu;
    args.forEach((String k, v) => m[k] = v);
    return m;
  }
  
  Future<bool> init() {
    return _adapter.createTable(_schema);
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
      this.beforeDestroy(m);
      return _adapter.destroyModel(m).then((bool val) {
        this.afterDestroy();
        return val;
      });
    }
    throw("Model was not persisted --> cannot destroy model");
  }
  
  Future<Model> dbCreate(Model m) {
    return validate(m, Validation.ON_CREATE_FLAG).then((bool valRes) {
      if (valRes) {
        this.beforeCreate(m);
        m["updated_at"] = new DateTime.now();
        m["created_at"] = new DateTime.now();
        return _adapter.saveModel(schema, m).then((created) {
          created.setClean();
          this.afterCreate(created);
          return created;
        });
      }
      throw("Validation failed");
    });
  }
  
  Future<Model> dbUpdate(Model m) {
    return validate(m, Validation.ON_CREATE_FLAG).then((bool valRes) {
      if (valRes) {
        this.beforeUpdate(m);
        m["updated_at"] = new DateTime.now();
        return _adapter.updateModel(schema, m).then((updated) {
          updated.setClean();
          this.afterUpdate(updated);
          return updated;
        });
      }
      throw("Validation failed");
    });
  }
  
  Future<Model> save(Model m) {
    if (m.needsToBePersisted) {
      if(m.isPersisted) return dbUpdate(m);
      else return dbCreate(m);
    }
    return new Future.value(m);
  }
  
  Future<bool> validate(Model m, int flag) {
    if (m.parent != this) throw("Not same parent");
    var validationResults = new List<Future<bool>>();
    schema.variables.forEach((v) {
      v.validations.forEach((Validation validation) {
        validationResults.add(validation.validate(v, m, m[v.name], flag));
      });
    });
    return Future.wait(validationResults).then((List<bool> results) {
      bool result = true;
      for (bool res in results) {
        result = result && res;
      }
      return result;
    });
  }
  
  Future<Model> find(int id) {
    return where("id = ?", [id], limit: 1).then((List<Model> models) {
      if (models.length != 1) {
        throw("Invalid result: ${models.length} found");
      } else {
        return (models[0]);
      }
    });
  }
  
  Future<List<Model>> all({int limit, int offset}) {
    return where("", [], limit: limit, offset: offset);
  }
  
  Future<List<Model>> where(String sql, List params, {int limit, int offset}) {
    return _adapter.modelsWhere(this, sql, params, limit, offset).then((ms) {
      ms.forEach((m) => m.setClean());
      return ms;
    });
  }
  
  List<Variable> parseVariables(List args) {
    var result = [];
    args.forEach((arg) 
      => (arg is Variable) ? result.add(arg) : 
         (arg is String) ? result.add(new Variable(arg)) :
         throw new UnsupportedError("Unsupported Variable"));
    return result;
  }
  
  List<Relation> parseRelations(List args) {
    var result = [];
    args.forEach((arg) 
      => (arg is Relation) ? result.add(arg) : 
         (arg is Type) ? result.add(new Relation(arg, this.runtimeType)) :
         throw new UnsupportedError("Unsupported Relation"));
    return result;
  }
  
  List get belongsTo => [];
  List get hasMany => [];
  List<Relation> get pBelongsTo => parseRelations(belongsTo);
  List<Relation> get pHasMany => parseRelations(hasMany);
  List<Relation> get _relations => []..addAll(pBelongsTo)..addAll(pHasMany);
  BeforeCreateFunc get beforeCreate => (Model m){};
  AfterCreateFunc get afterCreate => (Model m){};
  BeforeUpdateFunc get beforeUpdate => (Model m){};
  AfterUpdateFunc get afterUpdate => (Model m){};
  BeforeDestroyFunc get beforeDestroy => (Model m){};
  AfterDestroyFunc get afterDestroy => (){};
  DatabaseAdapter get adapter => defaultAdapter; // Override if needed
  List get variables => []; // Override to set Variables in Schema
  String get _tableName => MirrorSystem.getName(reflect(this).type.simpleName);
  Schema get schema => _schema;
  Model get nu => new _Model(this);
}