ActiveRecord
============
[![Build Status](https://drone.io/github.com/Adracus/ActiveRecord/status.png)](https://drone.io/github.com/Adracus/ActiveRecord/latest)
Implementation of the [Active Record pattern](http://en.wikipedia.org/wiki/Active_record_pattern) with some specialties from the Dart language.

## How to use
### Preparation
In order to use ActiveRecord, you have to subclass the `Collection` class.
Variables of the Collection are defined by overriding the `get variables` method.
You can override this method in a variety of styles: For instance, if you simply want
to define a String variable (like e.g. name), the result of `get variables` should
be `["name"]. If you want to specify type of the variable as well as constraints or
validations, you've got two options: You can either hand over a list, with
the name as first, the type as second, constraints and validations as fourth and fifth
argument, or hand over a Variable object.

Example of List approach:

```dart
get variables => [["name", "Integer"]];
```

Currently supported types are String, Integer, Double, Bool, Text and Datetime.

Another important point is overriding the `get adapter` method. If you don't
override this method, the collection will use the `defaultAdapter` as adapter,
which is by default null (you should also change this). Adapters are available
via the [ActiveMigration library](https://github.com/Adracus/ActiveMigration),
which also features generation and execution of Migration files. Contribution
of further adapters as well as contribution to this repository are appreciated.

### Creating, saving, finding and destroying Records
#### Creating
Creation of Collection instances can be done via the `get nu` method of the
Collection class. This immediatly returns a Model instance. You can then
Manipulate this Model until you want to save it.

#### Saving
To save it, call the `save` method on the Model instance. This returns a
future containing the saved Model.

#### Finding
For finding, there are four methods of each Collection instance:
##### find(int id)
This returns a Future containing the Model with the specified id. Only a
single Model instance is returned.
##### all({int limit, int offset})
Returns all Models of the Collection. You may specify limit and/or offset,
if you don't want all or just models after a specific number of models.
##### where(String sql, List params, {int limit, int offset})
This executes the given sql command on the underlying adapter (doesn't have
to be sql, but in the initial versithreeon this was the name). Be sure to
put the search parameters into the params List because then the adapter
can do prepared statements.
##### findByVariable(Map<String, dynamic> input, {int limit, int offset})
This is the adapter independent way of finding variables. Simply specify
a map of variable names and the corresponding values, which will then be
returned.

#### Destroying
Destroying is very simple: Get a Model which has been persisted via the
various find methods and call the `destroy` method on it. This returns
a Future with a boolean indicating the success of the destroy operation.

### Consistency of the persistence
In order to provide a consistent persistence, there are two ways of
providing checks to the given variables: _Validations_ and _Constraints_.
Constraints are checks which run on the adapters, Validations are checks
which run inside ActiveRecord. This results in Validations being always
available and Constraints being available only on some Adapters.

### Further subclassing of Collections
#### Model methods
Methods, which are available on Model instances can be specified inside
the collection. A Model method has a Model as the first parameter. So,
a Model method could look like this:

```dart
void say(Model m, String text) {
  print(m["name"] + " wants to say $text");
}
```

#### Relations
Relations can be specified by overriding the appropriate methods.
Those methods are:
+ hasMany
+ belongsTo

Relations can be specified in two ways:
One way is to directly specify the type of the other collection and the
other way is to specify a Relation object.

Example:

```dart
List get belongsTo => [AnotherCollection];
```

To get related Models of a Model instance, simply call a method with
the lowercase name of the related collection. If it is a "hasMany" relation,
add an "s". Also, if it is a "hasMany" relation, you can create Model instances
of the related Collection by calling `nu` on the result of this method.

Example:

```dart
// Receiving models
mymodel.anothercollections.get.then((anotherCollectionModels) => ...);
// Creating models
var newRelatedModel = mymodel.anothercollections.nu;
```

### Lifecycle management
Some methods on models should be triggered in specific states of the
Lifecycle of a Model. For this, there are Lifecycle methods. Current
Lifecycle methods are:
+ beforeCreate(Model m)
+ afterCreate(Model m)
+ beforeUpdate(Model m)
+ afterUpdate(Model m)
+ beforeDestroy(Model m)
+ afterDestroy(Model m)
