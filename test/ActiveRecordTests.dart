import 'package:unittest/unittest.dart';
import 'package:ActiveRecord/activerecord.dart';
import 'dart:mirrors';

class MyModel extends Object with Persistable {
  int arg1;
  String arg2;
  
  MyModel();
  MyModel._empty();
  
  Schema getDefaultSchema() => 
      new Schema("le_table", [
        new Variable("arg1", VariableType.NUMBER),
        new Variable("arg2", VariableType.STRING)
      ]);
}

class MyModel2 extends Object with Persistable {
  double number;
}

main() {
  test('Test Persistable field getter', () {
    var inst = new MyModel();
    expect(inst.fields.length, equals(2), reason: "Two fields are named");
    expect(MirrorSystem.getName(inst.fields[0].simpleName), equals("arg1"));
    expect(inst.fields[0].type, equals(reflectClass(int)), reason: "First field is int");
    expect(MirrorSystem.getName(inst.fields[1].simpleName), equals("arg2"));
    expect(inst.fields[1].type, equals(reflectClass(String)), reason: "Second field is String");
  });
  
  test('Test Config field', () {
    var inst1 = new MyModel();
    inst1.config.tableName = "1";
    var inst2 = new MyModel();
    inst2.config.tableName = "2";
    expect(inst1.config.tableName, "2");
    expect(inst2.config.tableName, "2");
    var inst3 = new MyModel2();
    inst3.config.tableName = "3";
    expect(inst1.config.tableName, "2");
    expect(inst3.config.tableName, "3");
  });
  
  test('Test schema generation', () {
    var inst1 = new MyModel();
    expect(inst1.config.schema.variables.length, equals(2));
    expect(inst1.config.schema.tableName, equals("le_table"));
    var inst2 = new MyModel2();
    expect(inst2.config.schema.tableName, equals("MyModel2"));
  });
  
  test('Test object saving and retrieving', () {
    var inst1 = new MyModel();
    inst1.arg1 = 1;
    inst1.arg2 = "Two";
    inst1.save().then((_) {
      var inst2 = Persistable.find(MyModel, 1);
      expect(inst2.arg1, equals(1));
      expect(inst2.arg2, equals("Two"));
      expect(inst2, equals(inst1));
    });
  });
}