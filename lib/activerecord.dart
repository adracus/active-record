library activerecord;

import 'dart:mirrors';
import 'dart:async';
import 'dart:io';
import 'dart:convert' show JSON;

import 'package:activemigration/activemigration.dart';
import 'package:logging/logging.dart';
import 'package:json_object/json_object.dart';

part 'database_abstraction.dart';
part 'relation.dart';
part 'model.dart';
part 'collection.dart';
part 'validations.dart';

DatabaseAdapter defaultAdapter = null;  //Inject own defaultAdapter here
var environment = "development";
var log = Logger.root;      //Inject own Logger here, see dart logging

var _tried = false;

retrieveDefaultAdapter() {
  if(defaultAdapter != null || _tried) return defaultAdapter;
  File f = new File(Platform.script.path);
  defaultAdapter = _getDatabaseFile(f);
  _tried = true;
  return defaultAdapter;
}

DatabaseAdapter _getDatabaseFile(File root) {
  var possibility = _findDatabaseFile(root.parent);
  if (possibility != null) return possibility;
  possibility = _findDatabaseFile(root.parent.parent);
  return possibility; // Can also return null here
}

DatabaseAdapter _findDatabaseFile(Directory dir) {
  var candidates = dir.listSync(followLinks: true)
      .where((ent) => ent.path.endsWith("database.yaml"));
  if(candidates.length == 0) return null;
  if(candidates.length > 1) throw "Too many database.yml files";
  return parseDatabaseFile(candidates.first as File)[environment].adapter;
}

@proxy
abstract class Row {
  void forEach(void f(String columNames, columnValues));
}