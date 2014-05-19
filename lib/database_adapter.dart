part of activerecord;

abstract class DatabaseAdapter {
  Future<Model> saveModel(Schema schema, Model m);
  Future<Model> updateModel(Schema schema, Model m);
  Future<bool> destroyModel(Model m);
  Future<List<Model>> modelsWhere(Collection c, String sql, List args, int limit, int offset);
  Future<bool> createTable(Schema schema);
}