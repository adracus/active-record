part of activerecord;

@proxy
abstract class DynObject<T> {
  Map<String, T> _vars = {};
  operator[](String key) => _vars[key];
  operator[]=(String key, T v) => _vars[key] = v;
  forEach(f(String key, T v)) => _vars.forEach(f);
}

@proxy
class Model extends Object with DynObject<dynamic> {
  final Collection _parent;
  
  bool _isDirty = false;
  bool _isPersisted = false;
  
  Model(this._parent);
  
  Future<Model> save() => _parent.save(this);
  Future<bool> destroy() => _parent.destroy(this);
  bool get isDirty => _isDirty;
  bool get isPersisted => _isPersisted;
  bool get _needsToBePersisted => (_isDirty || !_isPersisted);
  
  void _setClean() {
    this._isDirty = false;
    this._isPersisted = true;
  }
  
  noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) return routeToParentMethod(invocation);
    if (invocation.isGetter) {
      return _vars[MirrorSystem.getName(invocation.memberName)];
    }
    if (invocation.isSetter) {
      var key = MirrorSystem.getName(invocation.memberName);
      key = key.substring(0, key.length -1);
      _setVariable(key, invocation.positionalArguments[0]);
    }
  }
  
  routeToParentMethod(Invocation invocation) {
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
  
  _setVariable(String key, v) {
    if (this._parent.schema.hasProperty(key)) {
      super[key] = v;
      this._isDirty = true;
    } else {
      throw new ArgumentError("${_parent.schema.tableName} does not have property $key");
    }
  }
  
  operator[]=(String key, v) => _setVariable(key, v);
  Collection get parent => _parent;
}