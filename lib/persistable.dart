part of activerecord;

abstract class Persistable {
  static Map<ClassMirror, Config> _config = {};
  
  Config get config =>
      (_config[reflect(this).type] == null) ?
          _config[reflect(this).type] = this.configure() : _config[reflect(this).type];
          
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
  
  DatabaseAdapter getDefaultAdapter() {
    return defaultAdapter;
  }
  
  List<VariableMirror> get fields {
    var result = [];
    var classMirror = reflect(this).type;
    classMirror.declarations.values.forEach((dec) 
        => (dec is VariableMirror) ? result.add(dec) : null);
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
    return _config[clazz].adatper.findModel(_config[clazz].schema.tableName, id);
  }
  
  Future<bool> save() {
    if (config.adatper == null) {
      return new Future.error(new ArgumentError("Database adapter was not specified"));
    }
    return config.adatper.saveModel(config.schema, this);
  }
  
  static VariableType convertTypeMirrorToVariableType(TypeMirror tm) {
    if (tm == reflectClass(String)) return VariableType.STRING;
    if (tm == reflectClass(int) || tm == reflectClass(num) 
        || tm == reflectClass(double))
      return VariableType.NUMBER;
    if (tm == reflectClass(bool)) return VariableType.BOOL;
    throw new UnsupportedError("Type ${tm.simpleName} is not supported.");
  }
}

class Config {
  DatabaseAdapter _adapter;
  String _tableName;
  Schema _schema;
  
  Config() {
    _adapter = null;
    _tableName = null;
    _schema = null;
  }
  
  
  DatabaseAdapter get adatper => _adapter;
  String get tableName => _tableName;
         set tableName(String name) => _tableName = name;
  Schema get schema => _schema;
}

class Schema {
  String _tableName;
  List<Variable> _variables;
  
  Schema(this._tableName, this._variables);
  
  List<Variable> get variables => _variables;
  String get tableName => _tableName;
}

class Variable {
  final String name;
  final VariableType type;
  
  Variable(this.name, [this.type = VariableType.STRING]);
}

class VariableType {
  static const STRING = const VariableType._(0);
  static const NUMBER = const VariableType._(1);
  static const BOOL = const VariableType._(2);
  
  final int value;
  const VariableType._(this.value);
}