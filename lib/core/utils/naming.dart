String buildDownloadName({String prefix = 'PoliAI', String ext = 'png'}) {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final stamp =
      '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  return '${prefix}_$stamp.$ext';
}
