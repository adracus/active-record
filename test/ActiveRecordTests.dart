import 'package:activerecord/activerecord.dart';
import 'package:unittest/unittest.dart';
import 'package:logging/logging.dart';
import 'package:postgres_adapter/postgres_adapter.dart';
import 'dart:async';
import 'dart:io';

class Person extends Collection {
  get variables => [
    ["name", "String", [], [new Length(max: 50, min: 2)]],
    ["age", "Integer"],
    "password"
  ];
  
  get beforeCreate => (Model m) => (m.password = "Test Lifecycle");
  
  get belongsTo => [PostgresModel];
  
  void say(Model m, String msg) {
    print(getSayText(m, msg));
  }
  
  String getSayText(Model m, String msg, {String mood: "normal"}) {
    return "${m["name"]} wants to say '$msg' in a $mood mood";
  }
}

class PostgresModel extends Collection {
  get variables => [
    "name"
  ];
  
  get hasMany => [Person];
  get belongsTo => [];
}

main(List<String> arguments) {
  log.level = Level.ALL;
  log.onRecord.listen((LogRecord rec)
    => print('${rec.level.name}: ${rec.time}: ${rec.message}'));
  var dbUri = Platform.environment["DATABASE_URL"];
  if (dbUri!= null) defaultAdapter = new PostgresAdapter.fromUri(dbUri);
  var person = new Person();
  var postgresModel = new PostgresModel();
  Future.wait([person.init(), postgresModel.init()]).then((res) {
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
      
      test("Auto increment function", () {
        var one = person.nu;
        var two = person.nu;
        one["name"] = "One";
        two["name"] = "Two";
        one["age"] = "111";
        two["age"] = "222";
        one.save().then((_) => two.save())
        .then((_) {
          person.find(1).then(expectAsync((res) {
            expect(res["id"], isNotNull);
          }));
        });
      });
      
      test("Test model persistance on postgres", () {
        if (dbUri != null) {
          var m = postgresModel.nu;
          m["name"] = "A new user";
          m.save().then(expectAsync((Model mo) {
            expect(mo, isNotNull);
            expect(mo.id, isNotNull);
            expect(mo["name"], "A new user");
            expect(mo.isPersisted, isTrue);
          }));
        }
      });
      
      test("Test collection reflection", () {
        var p = person.nu;
        p["name"] = "Fred";
        expect(p.getSayText("Hello"),
            equals("Fred wants to say 'Hello' in a normal mood"));
        expect(p.getSayText("Hello", mood: "angry"), 
            equals("Fred wants to say 'Hello' in a angry mood"));
        p.name = "NewName";
        expect(p["name"], equals("NewName"));
        expect(p.name, equals("NewName"));
      });
      
      test("Test dirty and need to persisted management", () {
        var p = person.nu;
        expect(p.isDirty, isFalse);
        expect(p.isPersisted, isFalse);
        p["name"] = "NewName";
        expect(p.isDirty, isTrue);
        p.save().then(expectAsync((pThen) {
          expect(pThen.isDirty, isFalse);
          expect(pThen.isPersisted, isTrue);
          pThen["name"] = "IhatedMyOldName";
          expect(pThen.isDirty, isTrue);
          pThen.save().then(expectAsync((pThenThen) {
            expect(pThenThen.isPersisted, isTrue);
            expect(pThenThen.isDirty, isFalse);
          }));
        }));
      });
      
      test("Test findModelWhere", () {
        var test = person.nu;
        test["name"] = "IhatedMyOldName";
        test["age"] = 300;
        test.save().then(expectAsync((saved) {
          expect(saved, isNotNull);
          person.where("name = ? AND age >= ?", ["IhatedMyOldName", 30]).
          then(expectAsync((List<Model> models) {
            var model = models[0];
            expect(model["age"], greaterThanOrEqualTo(30));
            expect(model["name"], equals("IhatedMyOldName"));
          }));
        }));
      });
      
      test("Test model destroy", () {
        person.where("name = ? AND age >= ?", ["IhatedMyOldName", 30]).
        then(expectAsync((List<Model> models) {
          var model = models[0];
          expect(model["age"], greaterThanOrEqualTo(30));
          expect(model["name"], equals("IhatedMyOldName"));
          model.destroy().then(expectAsync((val) {
            expect(val, isTrue);
          }));
        }));
      });
      
      test("Test limit, model all", () {
        var psaves = [];
        for (int i = 0; i < 12; i++) {
          psaves.add(person.nu..name = "person$i");
        }
        var futures = [];
        psaves.forEach((p) => futures.add(p.save()));
        Future.wait(futures).then(expectAsync((vals) {
          person.all(limit: 10).then(expectAsync((List<Model> models) {
            expect(models.length, equals(10));
            models.forEach((ml) => expect(ml, isNotNull));
          }));
        }));
      });
      
      test("Test validations", () {
        var p = person.nu;
        p["name"] = "w";
        p.save().catchError(expectAsync((e) {
          expect(e, isNotNull);
        }));
      });
      
      test("Test relation generation", () {
        var r = new Relation(PostgresModel, Person);
        expect(r.variableOnHolder.name, equals("postgresmodel_id"));
        expect(r.variableOnTarget.name, equals("person_id"));
        var p = person.nu;
        var pm = postgresModel.nu;
        pm.save().then(expectAsync((Model pmSaved) {
          var p1Rel = pmSaved.persons.nu;
          var p2Rel = pmSaved.persons.nu;
          p1Rel.name = "Person1Rel";
          p2Rel.name = "Person2Rel";
          var fs = [];
          fs..add(p1Rel.save())..add(p2Rel.save());
          Future.wait(fs).then(expectAsync((saveds) {
            pmSaved.persons.get().then(expectAsync((List<Model> ms) {
              expect(ms.length, equals(2));
            }));
          }));
        }));
      });
      
      test("Test JsonObject generation", () {
        var p = person.nu;
        p.age = 20;
        p.name = "Steve";
        expect(p.jsonObject.name, equals("Steve"));
        expect(p.jsonObject.age, equals(20));
        expect(p.password, isNull);
      });
  });
}