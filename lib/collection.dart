part of activerecord;

abstract class Collection {
  DatabaseAdapter _adapter;
  Schema _schema;
  
  Collection() {
    var vars = [Variable.ID_FIELD]..addAll(variables);
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
      var completer = new Completer<Model>();
      _adapter.saveModel(_schema, m).then((saved) {
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
    _adapter.findModel(this.nu, id).then((m) {
      m._setClean();
      completer.complete(m);
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