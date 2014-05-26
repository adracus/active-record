part of activerecord;

class Relation {
  static final Symbol _EMPTY = new Symbol('');
  final Type target;
  final Type holder;
  final String name;
  final List<Constraint> constrs;
  final List<Validation> validations;
  Relation(Type target, this.holder, 
      {String relationName, List<Constraint> constraints: const[],
       List<Validation> this.validations: const[]}):
      this.name = _getRelationName(relationName, target),
      this.target = target,
      this.constrs = []..addAll(constraints);
      
  static String _getRelationName(String relationName, Type target)
    => relationName == null ? _getName(target) : relationName; 
  
  static String _getName(Type t)
    => MirrorSystem.getName(reflectClass(t).simpleName).toLowerCase();
  
  Collection get targetCollection
    => reflectClass(target).newInstance(_EMPTY, []).reflectee;
  
  Collection get holderCollection
    => reflectClass(holder).newInstance(_EMPTY, []).reflectee;
  
  Variable get variableOnHolder
    => new Variable(this.name + "_id", type: VariableType.INT,
        constrs: constrs, validations: validations);
  
  Variable get variableOnTarget
    => new Variable(_getName(holder) + "_id", type: VariableType.INT,
        constrs: constrs, validations: validations);
}

abstract class RelationManager {
  Future get();
}

class HasManyManager implements RelationManager {
  Model caller;
  Relation relation;
  Collection sourceCollection;
  Collection targetCollection;
  HasManyManager(this.caller, this.relation, this.sourceCollection, this.targetCollection);
  
  Future get() =>
    targetCollection.where(relation.variableOnTarget.name + "=?", [caller["id"]]);
  
  Model create(Map<String, dynamic> args)
    => targetCollection.create(args)..[relation.variableOnTarget.name] = caller.id;
  
  Model get nu => targetCollection.nu..[relation.variableOnTarget.name] = caller.id;
}

class BelongsToManager implements RelationManager {
  Model caller;
  Relation relation;
  Collection sourceCollection;
  Collection targetCollection;
  BelongsToManager(this.caller, this.relation, this.sourceCollection, this.targetCollection);
  
  Future get() =>
      targetCollection.find(caller[relation.variableOnHolder.name]);
}

/*
class HasOneManager extends HasManyManager {
  HasOneManager(Model caller, Relation relation,
      Collection sourceCollection, Collection targetCollection)
      : super (caller, relation, sourceCollection, targetCollection);
  
  Future get() => super.get().then((ms) => ms.first);
} */