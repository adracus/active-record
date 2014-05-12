library activerecord;

import 'dart:mirrors';
import 'dart:async';

part 'database_adapter.dart';
part 'memory_adapter.dart';
part 'persistable.dart';

var defaultAdapter = new MemoryAdapter();

@proxy
abstract class Row {
  void forEach(void f(String columNames, columnValues));
}