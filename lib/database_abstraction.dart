part of activerecord;

class Config {
  DatabaseAdapter _adapter;
  Schema _schema;
  
  Config() {
    _adapter = null;
    _schema = null;
  }
  
  DatabaseAdapter get adapter => _adapter;
  Schema get schema => _schema;
}

class Schema {
  String _tableName;
  Map<String, Variable> _variables = {};
  
  Schema(this._tableName, List<Variable> vars) {
    vars.forEach((v) => _variables[v.name] = v);
  }
  Variable getProperty(String name) {
    return _variables[name];
  }
  bool hasProperty(String name) {
    return _variables.keys.contains(name);
  }
  void addVariable(Variable v) {
    _variables[v.name] = v;
  }
  void addVariables(List<Variable> vars) {
    vars.forEach((v) => addVariable(v));
  }
  toString() {
    var result = "{\n";
    _variables.forEach((_, val) => result += "\t$val\n");
    return result += "}";
  }
  
  List<Variable> get variables => new List.from(this._variables.values);
  String get tableName => _tableName;
}

class Variable {
  static const ID_FIELD = const Variable._("id", type: VariableType.INT,
      constrs: const[Constraint.PRIMARY_KEY, Constraint.AUTO_INCREMENT]);
  static const CREATED_AT = const Variable._("created_at", type: VariableType.DATETIME,
      constrs: const[Constraint.NOT_NULL]);
  static const UPDATED_AT = const Variable._("updated_at", type: VariableType.DATETIME,
      constrs: const[Constraint.NOT_NULL]);
  static const MODEL_STUBS = const[ID_FIELD, CREATED_AT, UPDATED_AT];
  final String name;
  final VariableType type;
  final List<Constraint> constrs;
  final List<Validation> validations;
  
  Variable(this.name, {this.type: VariableType.STRING, 
     this.constrs: const[], this.validations: const[]});
  
  const Variable._(this.name, {this.type: VariableType.STRING, 
    this.constrs: const[], this.validations: const[]});
  
  toString() => "$name: $type";
  List<Constraint> get constraints => this.constrs.toSet().toList();
}

class VariableType {
  static const STRING = const VariableType._(0, "String");
  static const INT = const VariableType._(1, "Integer", numerical: true);
  static const DOUBLE = const VariableType._(2, "Double", numerical: true);
  static const BOOL = const VariableType._(3, "Bool");
  static const TEXT = const VariableType._(4, "Text");
  static const DATETIME = const VariableType._(5, "Datetime");
  static const List<Variable> TYPES = const [STRING, INT, DOUBLE, BOOL, TEXT, DATETIME];
  
  final int value;
  final bool numerical;
  final String name;
  
  const VariableType._(this.value, this.name, {this.numerical : false});
  factory VariableType.fromString(String arg) {
    for (var type in TYPES) {
      if (type.name == arg) return type;
    }
    throw("Type not found");
  }
  toString() => name;
}

class Constraint {
  static const NOT_NULL = const Constraint._("NOT NULL");
  static const UNIQUE = const Constraint._("UNIQUE");
  static const PRIMARY_KEY = const Constraint._("PRIMARY KEY");
  static const AUTO_INCREMENT = const Constraint._("AUTO INCREMENT");
  final String name;
  Constraint(this.name);
  const Constraint._(this.name);
  toString() => name;
}