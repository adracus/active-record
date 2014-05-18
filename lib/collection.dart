part of activerecord;

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
  
  Future<Model> save(Model m) {
    if (m._needsToBePersisted) {
      m["updated_at"] = new DateTime.now();
      Future<Model> f;
      var completer = new Completer<Model>();
      if (m.isPersisted) { 
          f = _adapter.updateModel(schema, m);
      } else {
        m["created_at"] = new DateTime.now();
        f = _adapter.saveModel(schema, m);
      }
      f.then((saved) {
        saved._setClean();
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
  
  Future<List<Model>> findWhere(List params) {
    var completer = new Completer<List<Model>>();
    _adapter.findModelsWhere(this, params).then((ms) {
      ms.forEach((m) => m._setClean());
      completer.complete(ms);
    }).catchError((err) {
      completer.completeError(err);
    });
    return completer.future;
  }
  DatabaseAdapter get adapter => defaultAdapter; // Override if needed
  List<Variable> get variables => []; // Override to set Variables in Schema
  String get _tableName => MirrorSystem.getName(reflect(this).type.simpleName);
  Schema get schema => _schema;
  Model get nu => new Model(this);
}