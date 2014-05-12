part of activerecord;

class MemoryAdapter extends DatabaseAdapter {
  Map<String, Table> _tables = {};
  
  Future<bool> saveModel(Schema schema, Persistable m) {
    var name = schema.tableName;
    _tables.putIfAbsent(name, () => new Table());
    _tables[name].addModel(m);
    return new Future.value(true);
  }
  
  Persistable findModel(String tableName, int id) {
    if (_tables[tableName] == null) return null;
    return _tables[tableName].getModel(id);
  }
}

class Table {
  int idCount;
  Map<int, Persistable> _rows;
  
  Table() {
    idCount = 1;
    _rows = {};
  }
  
  addModel(Persistable m) {
    this._rows[idCount] = m;
    idCount++;
  }
  
  getModel(int id) {
    return _rows[id];
  }
  
  removeModel(int id) {
    this._rows.remove(id);
  }
}