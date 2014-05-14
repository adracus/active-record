part of activerecord;

@proxy
abstract class DynObject<T> {
  Map<String, T> _vars = {};
  operator[](String key) => _vars[key];
  operator[]=(String key, T v) => _vars[key] = v;
  forEach(f(String key, T v)) => _vars.forEach(f);
}

class Model extends Object with DynObject<dynamic> {
  Collection _parent;
  
  Model(this._parent);
  
  Future<Model> save() => _parent.saveModel(this);
  toString() => "Instance of 'Model' of table ${_parent.schema.tableName}";
  
  operator[]=(String key, v)
      => parent.schema.hasProperty(key) ? super[key] = v : 
        throw new ArgumentError("${_parent.schema.tableName} does not have property $key");
  Collection get parent => _parent;
}