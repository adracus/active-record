part of activerecord;

abstract class DatabaseAdapter {
  Future<Model> saveModel(Schema schema, Model m);
  Future<Model> updateModel(Schema schema, Model m);
  Future<Model> findModel(Collection c, int id);
  Future<List<Model>> modelsWhere(Collection c, String sql, List args);
  Future<bool> createTable(Schema schema);
}