part of activerecord;

abstract class DatabaseAdapter {
  Future<bool> saveModel(Schema schema, Model m);
  Future<Model> findModel(Model empty, int id);
}