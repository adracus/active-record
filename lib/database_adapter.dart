part of activerecord;

abstract class DatabaseAdapter {
  Future<Model> saveModel(Schema schema, Model m);
  Future<Model> updateModel(Schema schema, Model m);
  Future<bool> destroyModel(Model m);
  Future<List<Model>> modelsWhere(Collection c, String sql, List args,
      {int limit, int offset});
  Future<bool> createTable(Schema schema);
  Future<List<Model>> findModelsByVariables(Collection c,
      Map<Variable, dynamic> variables, {int limit, int offset});
  Future<bool> addColumnToTable(String tableName, Variable variable);
  Future<bool> removeColumnFromTable(String tableName, String variableName);
  Future<bool> dropTable(String tableName);
  DatabaseAdapter(Configuration config);
}