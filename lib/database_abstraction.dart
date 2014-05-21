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
  static var ID_FIELD = new Variable("id", type: VariableType.INT,
      constrs: [Constraint.PRIMARY_KEY, Constraint.AUTO_INCREMENT]);
  static var CREATED_AT = new Variable("created_at", type: VariableType.DATETIME,
      constrs: [Constraint.NOT_NULL]);
  static var UPDATED_AT = new Variable("updated_at", type: VariableType.DATETIME,
      constrs: [Constraint.NOT_NULL]);
  static var MODEL_STUBS = [ID_FIELD, CREATED_AT, UPDATED_AT];
  final String name;
  final VariableType type;
  final LinkedHashSet<Constraint> _constraints;
  final List<Validation> validations;
  
  Variable(this.name, {this.type: VariableType.STRING, 
     List<Constraint> constrs: const[],  this.validations: const[]}) 
      : _constraints = _constraintListToSet(constrs);
  
  static LinkedHashSet<Constraint> _constraintListToSet(List<Constraint> constrs)
    => constrs == null? new LinkedHashSet() : new LinkedHashSet.from(constrs);
  
  toString() => "$name: $type";
  List<Constraint> get constraints => new List.from(_constraints);
}

class Relation extends Variable{
  final Type t;
  Relation(Type t, {List<Constraint> constrs : const[],
    List<Validation> validations : const[]}) : this.t = t,
      super(getName(t) + "_id", type:VariableType.INT, 
          constrs: getConstraints(t, constrs), validations: validations);
  
  static List<Constraint> getConstraints(Type t, List<Constraint> cs) {
    var schema = getRelatedCollection(t).schema;
    var result = new List<Constraint>();
    return result..add(new ForeignKey("id", schema.tableName))..addAll(cs);
  }
  
  static Collection getRelatedCollection(Type t)
    => reflectClass(t).newInstance(new Symbol(''), []).reflectee;
  static String getName(Type t)
    => getRelatedCollection(t).schema.tableName;
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
  Constraint(this.name);
  const Constraint._(this.name);
  toString() => name;
}

class ForeignKey extends Constraint{
  final String keyName;
  final String tableName;
  ForeignKey(this.keyName, this.tableName) : super("FOREIGN KEY");
}