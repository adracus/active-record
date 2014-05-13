part of activerecord;

class MemoryAdapter extends DatabaseAdapter {
  Map<String, Table> _tables = {};
  int _incr = 1;
  
  reset() => _tables.clear();
  
  Future<bool> saveModel(Schema schema, Model m) {
    var name = schema.tableName;
    _tables.putIfAbsent(name, () => new Table());
    var r = new _Row();
    
    schema.variables.forEach((v) => saveVariable(r, v, m));
    _tables[name].addRow(r);
    return new Future.value(true);
  }
  
  void saveVariable(Row target, Variable v, Model m) {
    if (v.constraints.length == 0) {
      target[v.name] = m[v.name]; return;
    }
    if (v.constraints.contains(Constraint.AUTO_INCREMENT) && m[v.name] == null) {
      target[v.name] = _incr; // TODO: Improve auto increment function
      _incr++; // This simulates auto increment (in a bad way)
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
        print(r["id"].toString());
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