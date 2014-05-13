part of activerecord;

abstract class Persistable {
  static Map<Type, Config> _config = {};
  
  Config get config {
    if(_config[this.runtimeType] == null) {
      _config[this.runtimeType] = this.configure();
    }
    return _config[this.runtimeType];
  }
          
  Config configure() {
    var result = new Config();
    result._schema = getDefaultSchema();
    result._adapter = getDefaultAdapter();
    return result;
  }
  
  Schema getDefaultSchema() {
    var tableName = MirrorSystem.getName(reflect(this).type.simpleName);
    Schema schema = new Schema(tableName, this.variables);
    return schema;
  }
  
  getProperty (String key) {
    var mirr = reflect(this);
    return mirr.getField(new Symbol(key)).reflectee;
  }
  
  setProperty (String key, val) {
    var mirr =reflect(this);
    mirr.setField(new Symbol(key), val);
  }
  
  DatabaseAdapter getDefaultAdapter() {
    return defaultAdapter;
  }
  
  List<VariableMirror> get fields {
    var result = [];
    var classMirror = reflect(this).type;
    do {
    classMirror.declarations.values.forEach((dec) 
        => (dec is VariableMirror) ? result.add(dec) : null);
    classMirror = classMirror.superclass;
    } while(classMirror != null && classMirror != reflectClass(Object) &&
        classMirror.isAssignableTo(reflectClass(Persistable)));
    return result;
  }
  
  List<Variable> get variables {
    var result = [];
    fields.forEach((field) => 
        result.add(
            new Variable(MirrorSystem.getName(field.simpleName),
                convertTypeMirrorToVariableType(field.type))));
    return result;
  }
  
  static find(Type type, int id) {
    var clazz = reflectClass(type);
    var empty = (clazz.newInstance(new Symbol(''), []).reflectee as Persistable);
    return empty.config.adapter.findModel(empty, id);
  }
  
  Future<bool> save() {
    if (config.adapter == null) {
      return new Future.error(new ArgumentError("Database adapter was not specified"));
    }
    return config.adapter.saveModel(this.config.schema, this);
  }
  
  static VariableType convertTypeMirrorToVariableType(TypeMirror tm) {
    if (tm == reflectClass(String)) return VariableType.STRING;
    if (tm == reflectClass(int) || tm == reflectClass(num) 
        || tm == reflectClass(double))
      return VariableType.NUMBER;
    if (tm == reflectClass(bool)) return VariableType.BOOL;
    throw new UnsupportedError("Type ${tm.simpleName} is not supported.");
  }
  
  static void reset() {
    _config = {};
  }
}