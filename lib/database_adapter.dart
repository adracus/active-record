part of activerecord;

abstract class DatabaseAdapter {
  Future<Model> saveModel(Schema schema, Model m);
  Future<Model> findModel(Model empty, int id);
  Future<bool> createTable(Schema schema);
}