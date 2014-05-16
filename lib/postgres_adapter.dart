part of activerecord;

class PostgresAdapter implements DatabaseAdapter {
  String _uri;
  
  PostgresAdapter(this._uri) {
    
  }
  
  Future<List<Model>> findModelWhere(Collection c, List<String> args, int limit) {
    var completer = new Completer();
    var models = [];
    connect(_uri).then((conn) {
      conn.query(buildSelectModelStatement(c.schema, args, limit)).toList()
      .then((rows) => 
          rows.forEach((row) => models.add(updateModelWithRow(row, c.nu))))
      .then((_) => completer.complete(models))
      .whenComplete(() => conn.close());
    });
    return completer.future;
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
  
  Model updateModelWithRow(r, Model empty) {
    r.forEach((String name, val) => empty[name] = val);
    return empty;
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
  
  String buildSelectModelStatement(Schema schema, List<String> args, int limit) {
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
    if (limit != null) {
      stmnt += " LIMIT $limit";
    }
    return stmnt += ";";
  }
  
  String replaceInsert(String src, var ins)
    => src.replaceAll(new RegExp("@"), "'$ins'"); // TODO: Escaping in all cases
  
  String buildCreateTableStatement(Schema schema) {
    var lst = [];
    schema.variables.forEach((v) => lst.add(getVariableForCreate(v)));
    return "CREATE TABLE IF NOT EXISTS ${schema.tableName} (${lst.join(',')});";
  }
  
  String buildUpdateModelStatement(Model m) {
    var params = {};
    var schema = m.parent.schema;
    var upd = [];
    for (Variable v in schema.variables) {
      if (v != Variable.ID_FIELD && m[v.name] != null) {
        upd.add("${v.name}=@${v.name}");
        params[v.name] = m[v.name];
      }
    }
    params["id"] = m["id"];
    return substitute("UPDATE ${schema.tableName} "
      +"SET ${upd.join(',')} WHERE id=@id;", params);
  }
  
  String buildSaveModelStatement(Model m) {
    var schema = m.parent.schema;
    var insertNames = [];
    var values = [];
    var params = {};
    schema.variables.forEach((v) {
      if(m[v.name] != null) {
        insertNames.add(v.name);
        values.add("@${m[v.name]}");
        params[v.name] = m[v.name];
      }
    });
    return substitute("INSERT INTO ${schema.tableName} (${insertNames.join(',')}) "
      + "values (${values.join(',')}) RETURNING id;", params);
  }
}

class Statement {
  final String text;
  final Map<String, dynamic> params;
  
  Statement(this.text, this.params);
  toString() => substitute(text, params);
}