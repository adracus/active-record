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

class HasManyManager implements Model {
  Model model;
  Model caller;
  Relation relation;
  Collection parent;
  HasManyManager(this.caller, this.model, this.relation, this.parent);
  Future<bool> destroy() => model.destroy();
  Future<Model> save() => model.save();
  noSuchMethod(Invocation invocation) => model.noSuchMethod(invocation);
  void setClean() => model.setClean();
  void forEach(f(String key, v)) => model.forEach(f);
  bool get needsToBePersisted => model.needsToBePersisted;
  bool get isPersisted => model.isPersisted;
  bool get isDirty => model.isDirty;
  operator[](String key) => model[key];
  operator[]=(String key, v) => model[key] = v;
}

class BelongsToManager implements List<Model> {
  List<Model> models;
  Model caller;
  Relation relation;
  Collection parent;
  BelongsToManager(this.caller, this.models, this.relation, this.parent);
  
  Model get nu => this.relation.targetCollection.nu
  ..[this.relation.variableOnTarget.name] = caller.id;
  
  Iterable<Model> takeWhile(bool test(Model value)) => models.takeWhile(test);
  dynamic fold(var initialValue, dynamic combine(var previousValue, Model element))
    => models.fold(initialValue, combine);
  Model elementAt(int index) => models.elementAt(index);
  Model firstWhere(bool test(Model value), { Model orElse() })
    => models.firstWhere(test, orElse:orElse);
  Model lastWhere(bool test(Model element), {Model orElse()})
    => models.lastWhere(test, orElse:orElse);
  Iterable<Model> skip(int n) => models.skip(n);
  bool any(bool test(Model element)) => models.any(test);
  Model get single => models.single;
  List<Model> toList({bool growable}) => models.toList(growable: growable);
  String join([String separator = ""]) => models.join(separator);
  Iterator<Model> get iterator => models.iterator;
  Model reduce(Model combine(Model value, Model element)) => models.reduce(combine);
  Iterable expand(Iterable f(Model element)) => models.expand(f);
  void forEach(void f(Model element)) => models.forEach(f);
  bool get isNotEmpty => models.isNotEmpty;
  bool get isEmpty => models.isEmpty;
  Model singleWhere(bool test(Model element)) => models.singleWhere(test);
  Model get first => models.first;
  Model get last => models.last;
  Set<Model> toSet() => models.toSet();
  Iterable map(f(Model element)) => models.map(f);
  bool every(bool test(Model element)) => models.every(test);
  Iterable<Model> take(int n) => models.take(n);
  Iterable<Model> where(bool test(Model element)) => models.where(test);
  int get length => models.length;
  bool contains(Model element) => models.contains(element);
  Iterable<Model> skipWhile(bool test(Model value)) => models.skipWhile(test);
  int lastIndexOf(Model element, [int start]) => models.lastIndexOf(element, start);
  Iterable<Model> getRange(int start, int end) => models.getRange(start, end);
  void shuffle([Random random]) => models.shuffle(random);
  void replaceRange(int start, int end, Iterable<Model> replacement)
    => models.replaceRange(start, end, replacement);
  void setAll(int index, Iterable<Model> iterable) => models.setAll(index, iterable);
  void retainWhere(bool test(Model element)) => models.retainWhere(test);
  Model removeAt(int index) => models.removeAt(index);
  Model removeLast() => models.removeLast();
  void insertAll(int index, Iterable<Model> iterable) => models.insertAll(index, iterable);
  Iterable<Model> get reversed => models.reversed;
  void addAll(Iterable<Model> iterable) => models.addAll(iterable);
  void removeWhere(bool test(Model element)) => models.removeWhere(test);
  void sort([int compare(Model a, Model b)]) => models.sort(compare);
  void fillRange(int start, int end, [Model fillValue]) => models.fillRange(start, end, fillValue);
  List<Model> sublist(int start, [int end]) => models.sublist(start, end);
  void removeRange(int start, int end) => models.removeRange(start, end);
  void insert(int index, Model element) => models.insert(index, element);
  void setRange(int start, int end, Iterable<Model> iterable, [int skipCount = 0])
    => models.setRange(start, end, iterable, skipCount);
  Map<int, Model> asMap() => models.asMap();
  void clear() => models.clear();
  void set length(int newLength) => null;
  bool remove(Model value) => models.remove(value);
  operator[]=(int index, Model value) => models[index] = value;
  operator[](int index) => models[index];
  indexOf(Model element, [int start]) => models.indexOf(element, start);
  void add(Model value) => models.add(value);
  toString() => models.toString();
}