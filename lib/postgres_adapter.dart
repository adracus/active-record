part of activerecord;

class PostgresAdapter implements DatabaseAdapter {
  String _uri;
  
  PostgresAdapter(this._uri);
  
  Future<bool> createTable(Schema schema) {
    return connect(_uri).then((conn) {
      return conn.execute(buildCreateTableStatement(schema)).then((_) {
        return true;
      }).catchError((e) {
        return false;
      }).whenComplete(() {
        conn.close();
      });
    });
  }
  
  Future<bool> destroyModel(Model m) {
    return connect(_uri).then((conn) {
      var s = buildDestroyModelStatement(m);
      return conn.execute(s.sql, s.values).then((_)
        => true).whenComplete(()
        => conn.close());
    });
  }
  
  Future<Model> saveModel(Schema schema, Model m) {
    return connect(_uri).then((conn) {
      var s = buildSaveModelStatement(m);
      return conn.query(s.sql, s.values).toList().then((rows) {
        rows.forEach((row) => updateModelWithRow(row, m));
        return m;
      }).whenComplete(() => conn.close());
    });
  }
  
  Future<Model> updateModel(Schema schema, Model m) {
    return connect(_uri).then((conn) {
      var s = buildUpdateModelStatement(m);
      return conn.execute(s.sql, s.values).then((_) {
        return m;
      }).whenComplete(() => conn.close());
    });
  }
  
  Future<List<Model>> modelsWhere(Collection c, String sql, List params, int limit, int offset) {
    return connect(_uri).then((conn) {
      Statement s = buildSelectModelStatement(c.schema, sql, params, limit, offset);
      return conn.query(s.sql, s.values).toList()
      .then((rows) {
        var models = [];
        rows.forEach((row) => models.add(updateModelWithRow(row, c.nu)));
        return models;
      })
      .whenComplete(() => conn.close());
    });
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
      case VariableType.DATETIME:
        return "date";
      default:
        return "varchar(255)";
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
    var st = "CREATE TABLE IF NOT EXISTS ${schema.tableName} (${lst.join(',')});";
    return st;
  }
  
  Statement buildUpdateModelStatement(Model m) {
    var schema = m.parent.schema;
    var upd = [];
    var s = new Statement();
    for (Variable v in schema.variables) {
      if (v != Variable.ID_FIELD && m[v.name] != null) {
        upd.add("${v.name}=@${v.name}");
        s.addValue(v.name, m[v.name]);
      }
    }
    s.addValue("id", m["id"]);
    s.sql = "UPDATE ${schema.tableName} SET ${upd.join(',')} WHERE id=@id;";
    return s;
  }
  
  Statement buildSelectModelStatement(Schema schema, String sql, List args, int limit, int offset) {
    var s = new Statement();
    var stmnt = "SELECT * FROM ${schema.tableName} ";
    if (sql!= null && sql.length > 0) {
      stmnt += "WHERE ";
      var clauses = [];
      for (int i = 0; i < args.length; i++) {
        s.addValue("param${i+1}", args[i]);
      }
    }
    stmnt += replacePlaceholders(sql) + " ";
    if (limit != null) stmnt += "LIMIT $limit ";
    if (offset != null) stmnt += "OFFSET $offset";
    s.sql = stmnt + ";";
    return s;
  }
  
  String replacePlaceholders(String sql) {
    var num = 1;
    return sql.replaceAllMapped(new RegExp(r'\?'), (Match m) {
      var res = "@param$num";
      num++;
      return res;
    });
  }
  
  Statement buildDestroyModelStatement(Model m) {
    var s = new Statement();
    s.sql = "DELETE FROM ${m.parent.schema.tableName} WHERE id = @id";
    s.addValue("id", m["id"]);
    return s;
  }
  
  Statement buildSaveModelStatement(Model m) {
    var schema = m.parent.schema;
    var insertNames = [];
    var values = [];
    var s = new Statement();
    schema.variables.forEach((v) {
      if(m[v.name] != null) {
        insertNames.add(v.name);
        values.add("@${v.name}");
        s.addValue(v.name, m[v.name]);
      }
    });
    s.sql = "INSERT INTO ${schema.tableName} (${insertNames.join(',')}) "
      + "values (${values.join(',')}) RETURNING id;";
    return s;
  }
}

class Statement {
  Map<String, dynamic> _values = {};
  String _sql = "";
  
  addValue(String key, value) => _values[key] = value;
  forEachValue(f(String k, v)) => _values.forEach(f);
  set sql(String sql) => this._sql = sql;
  String get sql => this._sql;
  Map<String, dynamic> get values => this._values;
}