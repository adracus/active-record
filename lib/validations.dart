part of activerecord;

typedef Future<bool> Validator(Variable v, Model m, arg);

abstract class Validation {
  static const int ON_UPDATE_FLAG = 3;
  static const int ON_CREATE_FLAG = 4;
  static const List<int> ON_SAVE = const [ON_UPDATE_FLAG, ON_CREATE_FLAG];
  static const List<int> ON_UPDATE = const[ON_UPDATE_FLAG];
  static const List<int> ON_CREATE = const[ON_CREATE_FLAG];
  List<int> _triggers;
  
  Validation({List<int> triggers}) {
    if (triggers == null) this._triggers = ON_SAVE;
    else this._triggers = triggers;
  }
  
  Future<bool> validate(Variable v, Model m, arg, int flag) {
    if (triggersOn(flag)) return checkCondition(v, m, arg);
    return new Future.value(true);
  }
  Future<bool> checkCondition(Variable v, Model m, arg);
  bool xor(bool arg, bool negationFlag) {
    if (negationFlag) return !arg;
    else return arg;
  }
  bool triggersOn(int flag) => this._triggers.contains(flag);
}

class Presence extends Validation {
  Presence({List<int> triggers}) : super(triggers: triggers);
  Future<bool> checkCondition(Variable v, Model m, arg)
    => new Future.value(arg != null);
}

class Absence extends Validation {
  Absence({List<int> triggers}) : super(triggers: triggers);
  Future<bool> checkCondition(v, Model m, arg) => new Future.value(arg == null);
}

class Length extends Validation {
  final int max;
  final int min;
  Length({List<int> triggers, this.max, this.min}) : super(triggers: triggers);
  Future<bool> checkCondition(Variable v, Model m, arg) => 
      arg is String || arg is Iterable ? 
          new Future.value(checkMax(arg.length) && checkMin(arg.length))
          : new Future.error(new ArgumentError("Argument cannot be length-checked"));
  bool checkMax(int len) => max != null ? len <= max : true;
  bool checkMin(int len) => min != null ? len >= min : true;
}

class Unique extends Validation {
  Unique({List<int> triggers}) : super(triggers: triggers);
  Future<bool> checkCondition(Variable v, Model m, arg) {
    var completer = new Completer<bool>();
    m.parent.where("${v.name} = ?", [m[v.name]]).then((List<Model> ms) {
      completer.complete(ms.length == 0);
    }).catchError((e) => completer.completeError(e));
    return completer.future;
  }
}

class Custom extends Validation {
  final Validator f;
  Custom(this.f, {List<int> triggers}) : super(triggers: triggers);
  checkCondition(Variable v, Model m, arg) => f(v, m, arg);
}