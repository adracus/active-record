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
part 'database_adapter.dart';

/**
 * This is the defaultAdapter used by each Collection instance.
 * You can set this one by hand, otherwise, the adapter is initally
 * set by the retrieveDefaultAdapter method, which searches for a
 * database.yaml file and extracts the correct adapter for your
 * specified environment.
 */
DatabaseAdapter defaultAdapter = null;  //Inject own defaultAdapter here

/**
 * This is the default environment for your ActiveRecord instance.
 * 
 * The default environment is development. You can set this variable as
 * you like, it will affect finding the correct adapter in your
 * database.yaml file.
 */
var environment = "development";

/**
 * This is the logger used by the ActiveRecord library.
 * 
 * If you want to use an own logger, set this variable with a correct logger.
 * See dart logging for further information about correct logging.
 */
var log = Logger.root;      //Inject own Logger here, see dart logging

/**
 * Contains information, whether a lookup for a database file happened.
 * 
 * Is true if a lookup happened, false otherwise.
 */
var _tried = false;


/**
 * Looks up your default adapter.
 * 
 * This method returns the default adapter. If you set the defaultAdapter
 * variable by hand, it will return the variable without doing anything
 * further. If you didn't, this method will search (only once) for a .yaml
 * file containing information which can be used by ActiveMigration for
 * getting a database adapter. 
 */
retrieveDefaultAdapter() {
  if(defaultAdapter != null || _tried) return defaultAdapter;
  File f = new File(Platform.script.path);
  defaultAdapter = _getDatabaseFile(f);
  _tried = true;
  return defaultAdapter;
}

/*
 * Searches for a database.yaml file from the path of the given file.
 * 
 * This will search in the directory of the given file and in the parent
 * directory of the given file. Files found in the directory of the file
 * itself have higher priority than files in the parent direcory.
 */
DatabaseAdapter _getDatabaseFile(File root) {
  var possibility = _findDatabaseFile(root.parent);
  if (possibility != null) return possibility;
  possibility = _findDatabaseFile(root.parent.parent);
  return possibility; // Can also return null here
}

/*
 * Searches for a file called database.yaml and returns it if found.
 * 
 * This searches the given directory for a file called database.yaml.
 * If it found one, it will parse it and return the database adapter
 * with the current environment
 */
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