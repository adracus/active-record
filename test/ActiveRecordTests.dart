import 'package:unittest/unittest.dart';
import 'package:ActiveRecord/activerecord.dart';

class Person extends Collection {
  get variables => [
    new Variable("name"),
    new Variable("age", VariableType.NUMBER)
  ];
  get adapter => new MemoryAdapter();
}

main() {
  var person = new Person();
  
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
      expect(arg, equals(true));
      if (arg) {
        person.find(1).then((mark) {
          expect(mark["id"], equals(1));
          expect(mark["name"], equals("Mark"));
          expect(mark["age"], equals(16));
          empty.parent.adapter.reset();
        });
      }
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
        one.parent.adapter.reset();
      });
    });
  });
}