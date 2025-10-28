import 'dart:html' as html;

class PlatformDownloader {
  Future<void> download(String url, String filename) async {
    final a = html.AnchorElement(href: url)..download = filename;
    html.document.body!.append(a);
    a.click();
    a.remove();
  }
}
