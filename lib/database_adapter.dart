part of activerecord;

abstract class DatabaseAdapter {
  Future<bool> saveModel(Schema schema, Persistable p);
  Persistable findModel(String tableName, int id);
}