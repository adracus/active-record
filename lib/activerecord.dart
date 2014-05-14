library activerecord;

import 'dart:mirrors';
import 'dart:async';
import 'dart:collection' show LinkedHashSet;

import 'package:postgresql/postgresql.dart';

part 'database_adapter.dart';
part 'memory_adapter.dart';
part 'postgres_adapter.dart';
part 'database_abstraction.dart';
part 'model.dart';
part 'collection.dart';

var defaultAdapter = new MemoryAdapter();

@proxy
abstract class Row {
  void forEach(void f(String columNames, columnValues));
}