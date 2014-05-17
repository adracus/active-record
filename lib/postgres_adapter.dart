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
        completer.complete(false);
      }).whenComplete(() {
        conn.close();
      });
    }).catchError((e) {
      completer.complete(false);
    });
    return completer.future;
  }
  
  Future<Model> saveModel(Schema schema, Model m) =>
    m.isPersisted? executeUpdate(schema, m) : executeSave(schema, m);
  
  Future<Model> executeSave(Schema schema, Model m) {
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
  
  Future<Model> executeUpdate(Schema schema, Model m) {
    var completer = new Completer();
    connect(_uri).then((conn) {
      conn.execute(buildUpdateModelStatement(m)).then((_) {
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
  
  Future<List<Model>> findModelsWhere(Collection c, List params) {
    var completer = new Completer();
    var models = [];
    connect(_uri).then((conn) {
      conn.query(buildSelectModelStatement(c.schema, params)).toList()
      .then((rows) => 
          rows.forEach((row) => models.add(updateModelWithRow(row, c.nu))))
      .then((_) => completer.complete(models))
      .catchError((e) => completer.completeError(e))
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
  
  String buildUpdateModelStatement(Model m) {
    var schema = m.parent.schema;
    var upd = [];
    for (Variable v in schema.variables) {
      if (v != Variable.ID_FIELD && m[v.name] != null) {
        if (v.type.numerical) {
          upd.add("${v.name}=${m[v.name]}");
        } else {
          upd.add("${v.name}='${m[v.name]}'");
        }
      }
    }
    return "UPDATE ${schema.tableName} SET ${upd.join(',')} WHERE id=${m['id']};";
  }
  
  String buildSelectModelStatement(Schema schema, List args) {
    var tname = schema.tableName;
    var stmnt = "SELECT * FROM $tname";
    var clauses = [];
    if (args.length > 1 && args.length % 2 == 0) {
      for (int i = 0; i < args.length; i+=2) {
        clauses.add(replaceInsert(args[i], args[i+1]));
      }
      stmnt += " WHERE ";
      stmnt += clauses.join(" AND ");
    }
    return stmnt += ";";
  }
  
  String replaceInsert(String src, var ins)
    => src.replaceAll(new RegExp("@"), "'$ins'"); // TODO: Escaping in all cases
  
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