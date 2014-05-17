part of activerecord;

class MemoryAdapter implements DatabaseAdapter {
  Map<String, Table> _tables = {};
  int _incr = 1;
  
  reset() => _tables.clear();
  
  Future<Model> saveModel(Schema schema, Model m) {
    var name = schema.tableName;
    var r = new _Row();
    
    schema.variables.forEach((v) => saveVariable(r, v, m));
    _tables[name].addRow(r);
    return new Future.value(m);
  }
  
  Future<List<Model>> findModelsWhere(Collection c, List params) {
    return new Future.error("Not yet implemented");
  }
  
  Future<bool> createTable(Schema schema) {
    _tables.putIfAbsent(schema.tableName, () => new Table());
    return new Future.value(true);
  }
  
  int _getNextId(String tname) {
    while(_isContainedInTable(tname, "id", _incr)) {
      _incr ++;
    }
    return _incr;
  }
  
  bool _isContainedInTable(String tname, String key, attr) {
    for (Row r in _tables[tname].rows) {
      if(r[key] == attr) return true;
    }
    return false;
  }
  
  void saveVariable(Row target, Variable v, Model m) {
    if (v.constraints.length == 0) {
      target[v.name] = m[v.name]; return;
    }
    if (v.constraints.contains(Constraint.AUTO_INCREMENT) && m[v.name] == null) {
      target[v.name] = _getNextId(m.parent.schema.tableName);
      m[v.name] = _getNextId(m.parent.schema.tableName);
      _incr++;
    } else {
      target[v.name] = m[v.name]; return; 
    }
  }
  
  Future<Model> findModel(Model empty, int id) {
    var schema = empty.parent.schema;
    var tName = schema.tableName;
    if (_tables[tName] == null) return null;
    else {
      var row = null;
      for(Row r in _tables[tName].rows) {
        if(id == int.parse(r["id"].toString())) {
          row = r; break;
        }
      }
      
      if (row == null) return new Future.error("Not found");
      var vars = schema.variables;
      vars.forEach((v) => empty[v.name] = row[v.name]);
      return new Future.value(empty);
    }
  }
}

class Table {
  List<Row> _rows;
  
  Table() {
    _rows = [];
  }
  
  addRow(Row r) {
    this._rows.add(r);
  }
  
  List<Row> get rows => _rows;
  forEach(f(Row r)) => _rows.forEach(f);
}



class _Row extends Object with DynObject implements Row{
}