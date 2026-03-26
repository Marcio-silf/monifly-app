import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void saveBytesWeb(Uint8List bytes, String fileName) {
  final blobParts = <JSAny>[bytes.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: 'application/octet-stream'));
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  
  web.URL.revokeObjectURL(url);
}
