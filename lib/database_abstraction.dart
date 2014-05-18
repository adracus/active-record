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
  static var ID_FIELD = new Variable("id", VariableType.INT,
      [Constraint.PRIMARY_KEY, Constraint.AUTO_INCREMENT]);
  static var CREATED_AT = new Variable("created_at", VariableType.DATETIME,
      [Constraint.NOT_NULL]);
  static var UPDATED_AT = new Variable("updated_at", VariableType.DATETIME,
      [Constraint.NOT_NULL]);
  static var MODEL_STUBS = [ID_FIELD, CREATED_AT, UPDATED_AT];
  final String name;
  final VariableType type;
  final LinkedHashSet<Constraint> _constraints;
  
  
  Variable(this.name, [this.type = VariableType.STRING, List<Constraint> constrs]) 
      : _constraints = _constraintListToSet(constrs);
  
  static LinkedHashSet<Constraint> _constraintListToSet(List<Constraint> constrs)
    => constrs == null? new LinkedHashSet() : new LinkedHashSet.from(constrs);
  
  toString() => "$name: $type";
  List<Constraint> get constraints => new List.from(_constraints);
}

class VariableType {
  static const STRING = const VariableType._(0, "String");
  static const INT = const VariableType._(1, "Integer", numerical: true);
  static const DOUBLE = const VariableType._(2, "Double", numerical: true);
  static const BOOL = const VariableType._(3, "Bool");
  static const TEXT = const VariableType._(4, "Text");
  static const DATETIME = const VariableType._(5, "Datetime");
  
  final int value;
  final bool numerical;
  final String name;
  
  const VariableType._(this.value, this.name, {this.numerical : false});
  toString() => name;
}

class Constraint {
  static const NOT_NULL = const Constraint._("NOT NULL");
  static const UNIQUE = const Constraint._("UNIQUE");
  static const PRIMARY_KEY = const Constraint._("PRIMARY KEY");
  static const AUTO_INCREMENT = const Constraint._("AUTO INCREMENT");
  final String name;
  
  const Constraint._(this.name);
  toString() => name;
}