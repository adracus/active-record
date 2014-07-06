part of activerecord;

typedef LifecycleMethod(Model m);

abstract class Collection {
  DatabaseAdapter _adapter;
  Schema _schema;
  
  /**
   * Instantiates a new [Collection] instance.
   * 
   * Instantiates a new [Collection] instance with the variables specified by
   * variables and the relations specified by the different relations.
   * The created_at, updated_at and id attribute are set by default.
   */
  Collection() {
    var vars = []..addAll(Variable.MODEL_STUBS)
      ..addAll(parseVariables(variables));
    this.parseRelations(belongsTo).forEach((r) 
      => vars.add(r.variableOnHolder));
    _schema = new Schema(this._tableName, vars);
    _adapter = this.adapter;
  }
  
  
  /**
   * Instantiates a model of the underlying collection.
   * 
   * Instantiates a model with all model methods specified in the
   * Collection class (methods with first parameter [Model])
   */
  Model create(Map <String, dynamic> args) {
    var m = this.nu;
    args.forEach((String k, v) => m[k] = v);
    return m;
  }
  
  /**
   * Initializes this collection (creates the table of the collection).
   * 
   * This makes the underlying adapter create a table or something equivalent.
   * Returns a future, which is true, if it worked and false if not.
   * Attention: If you use ActiveMigration, you don't have to use this method.
   * This Method is more suitable for quick testing.
   */
  Future<bool> init() {
    log.info("Creating table ${_schema.tableName} if not exists.");
    return _adapter.createTable(_schema);
  }
  
  
  /**
   * Returns all [Model] methods of this collection.
   * 
   * Returns all [Model] methods of this collection. [Model] methods are
   * methods, whose first parameter is [Model], for example
   * 
   *     String say(Model m, String msg)
   * ...
   */
  List<MethodMirror> getModelMethods() {
    var lst = [];
    reflect(this).type.instanceMembers.forEach((Symbol k, MethodMirror m) {
        if(m.isRegularMethod && isModelMethod(m)) lst.add(m);
    });
    return lst;
  }
  
  /**
   * Checks, if the given [MethodMirror] is a [Model] method.
   * 
   * Checks, if the given [MethodMirror] is a [Model] methods
   * are methods, whose first parameter is [Model]. Returns
   * true, if it is a [Model] method and false otherwise.
   */
  bool isModelMethod(MethodMirror m) {
    return (m.parameters.length > 0 && m.parameters[0].type == reflectClass(Model));
  }
  
  
  /**
   * Destroys the [Model] persistence.
   * 
   * Destroys the [Model] persistence. For example, on a relational database,
   * the row of the [Model] deleted.
   */
  Future<bool> destroy(Model m) {
    if (m.isPersisted) {
      log.info("Destroying model with id ${m["id"]}");
      this.beforeDestroy(m);
      return _adapter.destroyModel(m).then((bool val) {
        log.info("Destroyed model with id ${m["id"]}");
        this.afterDestroy(m);
        return val;
      });
    }
    log.severe("Non persisted model $m cannot be destroyed");
    throw("Model was not persisted --> cannot destroy model");
  }
  
  
  /**
   * Executes the needed operations to create the model on its database.
   * 
   * Executes the needed operations to create the model on its database.
   * Sets created_at and updated_at fields and returns the model after
   * creation.
   */
  Future<Model> dbCreate(Model m) {
    return validate(m, Validation.ON_CREATE_FLAG).then((bool valRes) {
      if (valRes) {
        log.info("Creating model $m");
        this.beforeCreate(m);
        m["updated_at"] = new DateTime.now().toIso8601String();
        m["created_at"] = new DateTime.now().toIso8601String();
        return _adapter.saveModel(schema, m).then((created) {
          created.setClean();
          m = created;
          log.info("Created new model $m");
          this.afterCreate(created);
          return created;
        });
      }
      throw("Validation failed");
    });
  }
  
  
  /**
   * Executes the needed operations to update the model on its database.
   * 
   * Executes the needed operations to update the model on its database.
   * Updates the updated_at field and sets the model "clean".
   */
  Future<Model> dbUpdate(Model m) {
    return validate(m, Validation.ON_CREATE_FLAG).then((bool valRes) {
      if (valRes) {
        this.beforeUpdate(m);
        m["updated_at"] = new DateTime.now().toIso8601String();
        return _adapter.updateModel(schema, m).then((updated) {
          updated.setClean();
          m = updated;
          this.afterUpdate(updated);
          return updated;
        });
      }
      throw("Validation failed");
    });
  }
  
  
  /**
   * Saves the specified [Model].
   * 
   * Saves the specified [Model]. If it is not persisted yet,
   * it will be saved. If it is existing, it will be updated.
   */
  Future<Model> save(Model m) {
    if (m.needsToBePersisted) {
      if(m.isPersisted) return dbUpdate(m);
      else return dbCreate(m);
    }
    return new Future.value(m);
  }
  
  
  /**
   * Validates the given [Model] with the given flag.
   * 
   * Validates the given [Model] with the given flag.
   * The flags can be found in the [Validation] class.
   * Returns a future with true if all [Validation]s succeeded
   * and false otherwise.
   */
  Future<bool> validate(Model m, int flag) {
    if (m.parent != this) throw("Not same parent");
    var validationResults = new List<Future<bool>>();
    schema.variables.forEach((v) {
      v.validations.forEach((Validation validation) {
        validationResults.add(validation.validate(v, m, m[v.name], flag));
      });
    });
    return Future.wait(validationResults).then((List<bool> results) {
      bool result = true;
      for (bool res in results) {
        result = result && res;
      }
      return result;
    });
  }
  
  /**
   * Searches this collection for the given input
   * 
   * Searches this collection for the given input. The input can be either
   * a single String containing the variable name or a list of strings
   * containing variable names.
   */
  Future<List<Model>> findByVariable(Map<String, dynamic> input,
      {int limit, int offset}) =>
      _adapter.findModelsByVariables(this,
          _generateFindVariableMap(input));
  
  Map<Variable, dynamic> _generateFindVariableMap(Map<String, dynamic> input) {
    var result = new Map<Variable, dynamic>();
    input.forEach((k, v) {
      result[_findVariableByName(k)] = input[k];
    });
    return result;
  }
  
  static List _dynToList(input) =>
      input is List ? input : [input];
  
  Variable _findVariableByName(String name) =>
      _schema.variables.where((v) => v.name == name).first;
  
  
  /** 
   * Returns the [Model] specified by the given id.
   * 
   * Returns the [Model] specified by the given id.
   * Throws an error, if no or more than one models were found.
   */
  Future<Model> find(int id) {
    return adapter.findModelsByVariables(this, {Variable.ID_FIELD: id})
        .then((List<Model> models) {
      if (models.length != 1) {
        throw("Invalid result: ${models.length} found");
      } else {
        return (models[0]);
      }
    });
  }
  
  
  /**
   * Returns all [Model]s of the underlying adapter.
   * 
   * Returns all [Model]s of the underlying adapter.
   */
  Future<List<Model>> all({int limit, int offset}) {
    return adapter.findModelsByVariables(this, {}, limit: limit, offset: offset);
  }
  
  
  /**
   * Returns all [Model]s, where the sql matches. Attention: Adapter-specific!
   * 
   * Returns all [Model]s, where the sql matches. Attention: Adapter-specific!
   * Also attention: Beware of sql injection here, the parameters should be handed
   * over the parameter list and escaped by the adapter. Read your adapter's
   * implementation for this.
   */
  Future<List<Model>> where(String sql, List params, {int limit, int offset}) {
    return _adapter
        .modelsWhere(this, sql, params, limit: limit, offset: offset)
        .then((ms) {
      ms.forEach((m) => m.setClean());
      return ms;
    });
  }
  
  
  /**
   * Parses all internal variables.
   * 
   * Parses all internal variables. Makes it possible to specify
   * a variable via a string or a [Variable] or a list of those.
   */
  List<Variable> parseVariables(List args) {
    var result = [];
    args.forEach((arg) 
      => (arg is Variable) ? result.add(arg) : 
         (arg is String) ? result.add(new Variable(arg)) :
         (arg is List) ? result.add(variableFromList((arg as List))):
         throw new UnsupportedError("Unsupported Variable"));
    return result;
  }
  
  
  /**
   * Parses the given List to [Variable] instances.
   * 
   * Parses the given List to [Variable] instances. The name is the first
   * element, from then on it is optional. Second possible argument is the
   * type, then the constraints and finally the validations.
   */
  Variable variableFromList(List args) {
    var name = args[0];
    var type = args.length > 1 ? new VariableType.fromString(args[1]) : VariableType.STRING;
    var constraints = args.length > 2 ? args[2] : [];
    var validations = args.length > 3 ? args[3] : [];
    return new Variable(name, type: type, constrs: constraints, validations: validations);
  }
  
  
  /**
   * Parses Relations from a given List.
   * 
   * Parses Relations from a given List. Makes it possible to specify
   * a Relation to another class by simply entering the Type of the
   * related class.
   */
  List<Relation> parseRelations(List args) {
    var result = [];
    args.forEach((arg) 
      => (arg is Relation) ? result.add(arg) : 
         (arg is Type) ? result.add(new Relation(arg, this.runtimeType)) :
         throw new UnsupportedError("Unsupported Relation"));
    return result;
  }
  
  
  /**
   * Specifies the Relations to which this Collection belongs.
   * 
   * Specifies the Relations to which this Collection belongs.
   * If it belongs to a another Collection, this Collection will
   * get a foreign key to mirror the key of the other Collection.
   */
  List get belongsTo => [];
  
  
  /**
   * Specifies the Relations, of which this Collection has many.
   * 
   * Specifies Relations which this Collection has.
   */
  List get hasMany => [];
  List<Relation> get pBelongsTo => parseRelations(belongsTo);
  List<Relation> get pHasMany => parseRelations(hasMany);
  List<Relation> get _relations => []..addAll(pBelongsTo)..addAll(pHasMany);
  LifecycleMethod get beforeCreate => (Model m){};
  LifecycleMethod get afterCreate => (Model m){};
  LifecycleMethod get beforeUpdate => (Model m){};
  LifecycleMethod get afterUpdate => (Model m){};
  LifecycleMethod get beforeDestroy => (Model m){};
  LifecycleMethod get afterDestroy => (Model m){};
  
  
  /**
   * Override this method to specify an adapter.
   * 
   * Override this method to specify an adapter.
   * If it is not overridden, the [defaultAdapter] will
   * be used.
   */
  DatabaseAdapter get adapter => defaultAdapter;
  
  
  /**
   * Override this method to specify variables for this Collection.
   * 
   * Override this method to specify variables for this Collection.
   * Variables can be specified as String, or as Variable instances.
   */
  List get variables => []; // Override to set Variables in Schema
  String get _tableName => MirrorSystem.getName(reflect(this).type.simpleName);
  Schema get schema => _schema;
  
  /**
   * Instantiates a new [Model] of this collection.
   */
  Model get nu => new _Model(this);
}