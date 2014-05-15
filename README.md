ActiveRecord
============
[![Build Status](https://drone.io/github.com/Adracus/ActiveRecord/status.png)](https://drone.io/github.com/Adracus/ActiveRecord/latest)

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
a model, which belongs to the collection you created, use the `nu`-"constructor". This "constructor is actually a getter, but it produces
a model which knows the parent collection:

```dart
var mark = person.nu;
```

### Create your own collection
If you've seen ActiveRecord in Ruby or Waterline in Node, you might want to add attributes to the future model of your collection. To do so,
you have to subclass the Collection class and override some methods (**The id attribute is always there and will always be the primary key**).
If you subclass, you also may specify the Database Adapter you want to use. Currently, there are two adapters: The MemoryAdapter (which does
all of its operations in-memory) and the PostgresAdapter (which operates on a Postgres database with a given connection uri). The uri has to be
in the following format:

    postgres://<username>:<password>@<host>:<port>/<database>
#### Subclassing Example

```dart
class Person extends Collection {
  get variables => [
    new Variable("name"),
    new Variable("age", VariableType.NUMBER)
  ];
  get adapter => new MemoryAdapter();
  void say(Model m, String msg) => print("${m["name"]} says: '$msg'");
}
```
##### Saving and finding models
To save models, simply call the `save()` method on a model instance. This will return a Future containing the Model (if it worked). If you
did not specify an id, the id will automatically be incremented by the adapter. The returned model will have an id attribute.
To find models, call the `find(int id)` method on a collection instance. This returns a Future containing the Model and will throw an error
if the specified Model does not exist.
