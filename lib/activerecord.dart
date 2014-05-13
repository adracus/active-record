library activerecord;

import 'dart:mirrors';
import 'dart:async';
import 'dart:collection' show HashSet;

part 'database_adapter.dart';
part 'memory_adapter.dart';
part 'persistable.dart';
part 'database_abstraction.dart';
part 'model.dart';
part 'collection.dart';

var defaultAdapter = new MemoryAdapter();

@proxy
abstract class Row {
  void forEach(void f(String columNames, columnValues));
}