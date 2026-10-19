import 'download_stub.dart' if (dart.library.html) 'download_web.dart' as impl;

void downloadCsv(String filename, String content) => impl.downloadCsv(filename, content);
