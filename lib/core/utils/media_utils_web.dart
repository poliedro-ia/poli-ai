import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadImage(String src, {required String filename}) async {
  final a = html.AnchorElement(href: src)..download = filename;
  html.document.body?.append(a);
  a.click();
  a.remove();
}

Future<void> downloadBytes(Uint8List bytes, {required String filename}) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)..download = filename;
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
}
