library activerecord;

import 'dart:mirrors';
import 'dart:async';
import 'dart:math';
import 'dart:collection' show LinkedHashSet;
import 'dart:convert' show JSON;

import 'package:postgresql/postgresql.dart';

part 'database_adapter.dart';
part 'postgres_adapter.dart';
part 'database_abstraction.dart';
part 'relation.dart';
part 'model.dart';
part 'collection.dart';
part 'validations.dart';

var defaultAdapter = null;

@proxy
abstract class Row {
  void forEach(void f(String columNames, columnValues));
}