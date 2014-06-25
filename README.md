ActiveRecord
============
[Build Status](https://drone.io/github.com/Adracus/ActiveRecord/latest)

Implementation of the [Active Record pattern](http://en.wikipedia.org/wiki/Active_record_pattern) with some specialties from the Dart language.

### Things you should know
This implementation of the Active Record pattern differs from other implementations. For example, in the Active Record implementation in
Ruby, to define an Active Record class, one had to subclass the ActiveRecord::Base class. After doing that, the subclass had methods
like `find` or other, dynamic methods. In this implementation, to get a kind of Active Record class, you have to subclass the `Collection`
class. In contrast to the Ruby Active Record implementation, you now have to instantiate an instance of this class:

```dart
var person = new Person();
```
    
This new instance has now the methods you are used to use in the Active Record implementation of Ruby.
You may ask yourself now: _"What if I don't want to instantiate a Collection but a Model?"_ - For this, there is a solution: To instantiate
a model, which belongs to the collection you created, use the `nu`-"constructor". This "constructor" is actually a getter, but it produces
a model which knows the parent collection:

```dart
var mark = person.nu;
```

### Create your own collection
If you've seen ActiveRecord in Ruby or Waterline in Node, you might want to add attributes to the future model of your collection. To do so,
you have to subclass the Collection class and override some methods. **The id field, the created\_at and the updated\_at field will be inserted
automatically and also updated automatically**.
If you subclass, you also may specify the Database Adapter you want to use.
The current database adapters are:

* [Postgres adapter](https://github.com/Adracus/PostgresAdapter)

Feel free to contribute further adapters! Also other contribution is very appreciated!

#### Subclassing Example

```dart
class Person extends Collection {
  get variables => [
    "name",
    ["age", "Integer"],
    "haircolor"
  ];
  get adapter => new PostgresAdapter(/* your uri here*/);
  void say(Model m, String msg) => print("${m["name"]} says: '$msg'");
}
```
Lifecycle methods are also available:
* beforeCreate(Model m)
* afterCreate(Model m)
* beforeUpdate(Model m)
* afterUpdate(Model m)
* beforeDestroy(Model m)
* afterDestroy()

##### Define instance methods of Models
To define an instance method of a Model, you don't need to modify the Model class (since every instance of every Collection will be a Model).
A model instance method is "defined" in its collection: Simply define an instance function for the collection and add the Model, on which
the method shall be executed as first parameter. So, for example, such a method would look like this:

```dart
void say(Model m, String msg) => print("${m["name"]} says: '$msg'");
```
If you now want to call this method on a model instance, call it as if the model argument wouldn't be there, for example:
```dart
var myPerson = person.nu;
myPerson.name = "Duffman";
myPerson.say("hello");
```
The method call will be redirected from the Model to its parent collection, adding itself as the first parameter.

### Saving, finding and querying models
#### Saving models
To save models, simply call the `save()` method on a model instance. This will return a Future containing the Model (if it worked). If you
did not specify an id, the id will automatically be incremented by the adapter. The returned model will have an id attribute. Example code:

```dart
myPerson.save().then((Model savedMyPerson) // Do something with the saved person
```
##### Validations
Validations have been built in since version 0.2.0. Validations happen in Active record itself.
Validations have to be defined when defining the variables of a Model, like so:

```dart
get variables => [
  new Variable("name", validations: [new Length(max: 50, min: 2)]),
  new Variable("age", type: VariableType.INT)
];
```
Here, the validation `Length` is used. Other available validations are:
* Presence
* Absence
* Unique
* Custom (implement an own method validating the model here)

Validations have three possibilities of triggering: On save, on create and on update. To specify
this, fill in the optional named parameter triggers with constants from the Validations class.
Expect the syntax of defining variables, their type and their constraints to change
soon, in a more effective and less time consuming way.

#### Finding models by id
To find models, call the `find(int id)` method on a collection instance. This returns a Future containing the Model and will throw an error
if the specified Model does not exist:

```dart
person.find(1).then((Model foundModel) // Do something with the found person
```
#### Querying models by specific criteria
In order to find Models where several conditions apply, use the `where(sql, args)`-method. This method will give you a list of Models which
fit to the given criteria. The where syntax is the same as in the ruby implementation of ActiveRecord. So, if you want to query for a person
with name "mark" and an age greater than 30, the code would look like this:

```dart
person.where("name = ? AND age >= ?", ["mark", 30]).then(List<Model> models) // Do something with the found models
```

The question marks will be replaced by the parameters given in the args list. It is also
possible to limit and to offset the amount of `collection.where` and `collection.all` by adding the
optional named parameter limit and/or offset:

```dart
person.all(limit: 100, offset: 100).then(List<Model> models) // Do something with the found models
```

**!!!CAUTION!!!**: Only parameters given in the args list will be escaped. If you concatenate strings and put those into the sql parameter,
you are vulnerable to SQL-Injection!

#### Relations
Since v.1.1.0, Relations have been implemented in an early stage. Currently available relations are
1..n-relations (in both sides). To define two related collections, proceed as follows:

```dart
class Person extends Collection {
  get belongsTo => [PostgresModel];
}

class PostgresModel extends Collection {
  get hasMany => [Person];
}
```
The Relation constructor first takes the target Collection, then the holder collection.

You can now use the relations on a model of a related instance, like following example:

```dart
postgresmodel.find(1).then((Model postgresModel) {
  var relatedPerson = postgresModel.persons.nu;
  relatedPerson.name = "A new name";
  relatedPerson.save().then((Model savedPerson) {
    savedPerson.postgresmodel.get().then((Model foundPModel) {
      print(foundPModel);
    });
  });
});
```
