import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<void> downloadImage(String src, {required String filename}) async {
  Uint8List? bytes;
  if (src.startsWith('data:image/')) {
    final b64 = src.split(',').last;
    bytes = Uint8List.fromList(const Base64Decoder().convert(b64));
  } else {
    final r = await http.get(Uri.parse(src));
    if (r.statusCode == 200) bytes = r.bodyBytes;
  }
  if (bytes == null) return;
  await downloadBytes(bytes, filename: filename);
}

Future<void> downloadBytes(Uint8List bytes, {required String filename}) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$filename');
  await f.writeAsBytes(bytes);
}
