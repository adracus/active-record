part of activerecord;

class PostgresAdapter implements DatabaseAdapter {
  String _uri;
  
  PostgresAdapter(this._uri) {
    
  }
  
  Future<bool> createTable(Schema schema) {
    var completer = new Completer();
    connect(_uri).then((conn) {
      conn.execute(buildCreateTableStatement(schema)).then((_) {
        completer.complete(true);
      }).catchError((e) {
        print(e);
        completer.complete(false);
      }).whenComplete(() {
        conn.close();
      });
    }).catchError((e) {
      print(e);
      completer.complete(false);
    });
    return completer.future;
  }
  
  Future<Model> saveModel(Schema schema, Model m) {
    var completer = new Completer();
    connect(_uri).then((conn) {
      conn.query(buildSaveModelStatement(m)).toList().then((rows) {
        rows.forEach((row) => updateModelWithRow(row, m));
        completer.complete(m);
      }).catchError((e) => completer.completeError(e))
        .whenComplete(() => conn.close());
    });
    return completer.future;
  }
  
  Future<Model> findModel(Model empty, int id) {
    var completer = new Completer();
    var tName = empty.parent.schema.tableName;
    connect(_uri).then((conn) {
      conn.query("SELECT * FROM $tName where id=$id LIMIT 1").toList()
      .then((rows) => rows.forEach((row) => updateModelWithRow(row, empty)))
      .then((_) => completer.complete(empty))
      .whenComplete(() => conn.close());
    });
    return completer.future;
  }
  
  void updateModelWithRow(r, Model empty) {
    r.forEach((String name, val) => empty[name] = val);
  }
  
  String getPostgresType(VariableType v) {
    switch(v) {
      case VariableType.BOOL:
        return "boolean";
      case VariableType.INT:
        return "int8";
      case VariableType.DOUBLE:
        return "float8";
      case VariableType.STRING:
        return "varchar(255)";
      default:
        throw new ArgumentError("Not supported");
    }
  }
  
  String getPgConstraint(Constraint c) {
    switch (c.name) {
      case "AUTO INCREMENT": return "SERIAL";
      default: return c.name;
    }
  }
  
  String getVariableForCreate(Variable v) {
    if (v == Variable.ID_FIELD) return "id serial PRIMARY KEY";
    var stmnt = "${v.name} ${getPostgresType(v.type)}";
    v.constraints.forEach((c) => stmnt += " ${getPgConstraint(c)}");
    return stmnt;
  }
  
  String buildCreateTableStatement(Schema schema) {
    var lst = [];
    schema.variables.forEach((v) => lst.add(getVariableForCreate(v)));
    return "CREATE TABLE IF NOT EXISTS ${schema.tableName} (${lst.join(',')});";
  }
  
  String buildSaveModelStatement(Model m) {
    var schema = m.parent.schema;
    var insertNames = [];
    var values = [];
    schema.variables.forEach((v) {
      if(m[v.name] != null) {
        insertNames.add(v.name);
        if (v.type.numerical) values.add(m[v.name]);
        else values.add("'${m[v.name]}'");
      }
    });
    return "INSERT INTO ${schema.tableName} (${insertNames.join(',')}) "
      + "values (${values.join(',')}) RETURNING id;";
  }
}