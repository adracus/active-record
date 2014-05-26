part of activerecord;

@proxy
abstract class DynObject<T> {
  Map<String, T> _vars = {};
  operator[](String key) => _vars[key];
  operator[]=(String key, T v) => _vars[key] = v;
  forEach(f(String key, T v)) => _vars.forEach(f);
}

@proxy
abstract class Model {
  bool get isDirty;
  bool get isPersisted;
  bool get needsToBePersisted;
  void setClean();
  noSuchMethod(Invocation invocation);
  Future<Model> save();
  Future<bool> destroy();
  Collection get parent;
  operator[](String key);
  operator[]=(String key, v);
  forEach(f(String key, v));
}

@proxy
class _Model extends Object with DynObject<dynamic> implements Model{
  final Collection _parent;
  
  bool _isDirty = false;
  bool _isPersisted = false;
  
  _Model(this._parent);
  
  Future<Model> save() => _parent.save(this);
  Future<bool> destroy() => _parent.destroy(this);
  bool get isDirty => _isDirty;
  bool get isPersisted => _isPersisted;
  bool get needsToBePersisted => (_isDirty || !_isPersisted);
  
  void setClean() {
    this._isDirty = false;
    this._isPersisted = true;
  }
  
  bool _isBelongsToRelationGetter(String name)
    => this.parent.pBelongsTo.map((e) => e.name.toLowerCase()).contains(name);
  
  bool _isHasManyRelationGetter(String name)
    => this.parent.pHasMany.map((Relation e) => e.name.toLowerCase()+"s").contains(name);
  
  Relation _getHasManyRelation(String name) {
    return this.parent.pHasMany.firstWhere((r) => r.name + "s" == name);
  }
  
  Relation _getBelongsToRelation(String name) {
    return this.parent.pBelongsTo.firstWhere((r) => r.name == name);
  }
  
  bool _isRelationGetter(String name)
    => _isHasManyRelationGetter(name) || _isBelongsToRelationGetter(name);
  
  _doRelationReturn(Invocation invocation) {
    var name = MirrorSystem.getName(invocation.memberName);
    if (_isHasManyRelationGetter(name)) {
      var r = _getHasManyRelation(name);
      var col = r.targetCollection;
      return new HasManyManager(this, r, this.parent, col);
    }
    if (_isBelongsToRelationGetter(name)) {
      var r = _getBelongsToRelation(name);
      var col = r.targetCollection;
      return new BelongsToManager(this, r, this.parent, col);
    }
    return new Future.error("Relation method not supported");
  }
  
  noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) return _routeToParentMethod(invocation);
    if (invocation.isGetter) {
      if (_isRelationGetter(MirrorSystem.getName(invocation.memberName))) {
        return _doRelationReturn(invocation);
      }
      return _vars[MirrorSystem.getName(invocation.memberName)];
    }
    if (invocation.isSetter) {
      var key = MirrorSystem.getName(invocation.memberName);
      key = key.substring(0, key.length -1);
      setVariable(key, invocation.positionalArguments[0]);
    }
  }
  
  _routeToParentMethod(Invocation invocation) {
    var s = null;
    var posArgs;
    var namedArgs;
    for (MethodMirror m in _parent.getModelMethods()) {
      if(invocation.memberName == m.simpleName) {
        posArgs = [this]..addAll(invocation.positionalArguments);
        namedArgs = invocation.namedArguments;
        s = invocation.memberName;
        break;
      }
    }
    if (s != null) {
      return reflect(this._parent)
      .invoke(s, posArgs, namedArgs).reflectee;
    }
  }
  
  String toString() => "Instance of 'Model' of table ${_parent.schema.tableName}";
  
  setVariable(String key, v) {
    if (this._parent.schema.hasProperty(key)) {
        super[key] = v;
      this._isDirty = true;
    } else {
      throw new ArgumentError("${_parent.schema.tableName} does not have property $key");
    }
  }
  
  operator[]=(String key, v) => setVariable(key, v);
  Collection get parent => _parent;
}