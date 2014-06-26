library activerecord;

import 'dart:mirrors';
import 'dart:async';
import 'dart:convert' show JSON;

import 'package:activemigration/activemigration.dart';
import 'package:logging/logging.dart';
import 'package:json_object/json_object.dart';

part 'database_adapter.dart';
part 'database_abstraction.dart';
part 'relation.dart';
part 'model.dart';
part 'collection.dart';
part 'validations.dart';

var defaultAdapter = null;  //Inject own defaultAdapter here
var log = Logger.root;      //Inject own Logger here, see dart logging


@proxy
abstract class Row {
  void forEach(void f(String columNames, columnValues));
}