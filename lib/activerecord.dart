library activerecord;

import 'dart:mirrors';
import 'dart:async';

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