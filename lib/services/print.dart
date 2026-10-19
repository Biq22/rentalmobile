import 'print_stub.dart' if (dart.library.html) 'print_web.dart' as impl;

/// Buka dialog cetak browser (hanya berguna di web).
void printPage() => impl.printPage();
