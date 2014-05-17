import 'package:activerecord/activerecord.dart';
import 'package:unittest/unittest.dart';
import 'dart:io';

class Person extends Collection {
  get variables => [
    new Variable("name"),
    new Variable("age", VariableType.INT)
  ];
  void say(Model m, String msg) {
    print(getSayText(m, msg));
  }
  
  String getSayText(Model m, String msg, {String mood: "normal"}) {
    return "${m["name"]} wants to say '$msg' in a $mood mood";
  }
}

class PostgresModel extends Collection {
  get variables => [
    new Variable("name")
  ];
}

main(List<String> arguments) {
  var dbUri = Platform.environment["DATABASE_URL"];
  if (dbUri!= null) defaultAdapter = new PostgresAdapter(dbUri);
  var person = new Person();
  var postgresModel = new PostgresModel();
  
  test("Test model generation", () {
    var empty = person.nu;
    empty["id"] = 1;
    empty["name"] = "Mark";
    empty["age"] = 16;
    expect(empty.parent, equals(person));
    expect(empty.parent.schema.tableName, equals("Person"));
    expect(empty["id"], equals(1));
    expect(empty["name"], equals("Mark"));
    expect(empty["age"], equals(16));
  });
  
  test("Test model persistance", () {
    var empty = person.nu;
    empty["id"] = 1;
    empty["name"] = "Mark";
    empty["age"] = 16;
    empty.save().then((arg) {
      expect(arg, isNotNull);
      person.find(1).then((mark) {
        expect(mark["id"], equals(1));
        expect(mark["name"], equals("Mark"));
        expect(mark["age"], equals(16));
      });
    });
  });
  
  test("Auto increment function", () {
    var one = person.nu;
    var two = person.nu;
    one["name"] = "One";
    two["name"] = "Two";
    one["age"] = "111";
    two["age"] = "222";
    one.save().then((_) => two.save())
    .then((_) {
      person.find(1).then((res) {
        expect(res["id"], equals(1));
      });
    });
  });
  
  test("Test sql statement generation", () {
    var adapter = new PostgresAdapter(dbUri);
    var variable = new Variable("mynum", VariableType.STRING, [Constraint.NOT_NULL]);
    var schema = new Schema("MyTable", [Variable.ID_FIELD, variable]);
    expect(adapter.getPostgresType(variable.type),
        equals("varchar(255)"));
    expect(adapter.getVariableForCreate(variable),
        equals("mynum varchar(255) NOT NULL"));
    expect(adapter.getVariableForCreate(Variable.ID_FIELD),
        equals("id serial PRIMARY KEY"));
    expect(adapter.buildCreateTableStatement(schema),
        equals("CREATE TABLE IF NOT EXISTS MyTable ("
            + "id serial PRIMARY KEY,"
            + "mynum varchar(255) NOT NULL);"));
    if (dbUri != null) {
      adapter.createTable(schema).then((val) {
        expect(val, equals(true));
      });
    }
  });
  
  test("Test model persistance on postgres", () {
    if (dbUri != null) {
      var m = postgresModel.nu;
      m["name"] = "A new user";
      m.save().then((mo) {
        expect(mo, isNotNull);
        expect(mo["name"], "User");
      });
    }
  });
  
  test("Test collection reflection", () {
    var p = person.nu;
    p.save().then((res) {
      expect(res, isNotNull);
    });
    p["name"] = "Fred";
    expect(p.getSayText("Hello"),
        equals("Fred wants to say 'Hello' in a normal mood"));
    expect(p.getSayText("Hello", mood: "angry"), 
        equals("Fred wants to say 'Hello' in a angry mood"));
  });
  
  test("Test dirty and need to persisted management", () {
    var p = person.nu;
    expect(p.isDirty, isFalse);
    expect(p.isPersisted, isFalse);
    p["name"] = "NewName";
    expect(p.isDirty, isTrue);
    p.save().then((pThen) {
      expect(pThen.isDirty, isFalse);
      expect(pThen.isPersisted, isTrue);
      pThen["name"] = "IhatedMyOldName";
      expect(pThen.isDirty, isTrue);
      pThen.save().then((pThenThen) {
        expect(pThenThen.isPersisted, isTrue);
        expect(pThenThen.isDirty, isFalse);
      });
    });
  });
}