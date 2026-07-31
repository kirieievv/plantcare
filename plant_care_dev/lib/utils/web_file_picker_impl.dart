import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Opens a file picker anchored at the center of the screen.
/// On iOS Safari this makes the native sheet appear consistently in the center
/// rather than wherever the triggering button happened to be on the page.
Future<Uint8List?> pickCenteredImageFromWeb() async {
  final completer = Completer<Uint8List?>();

  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = 'image/*';

  // Fix the element at the center of the viewport so the browser-native
  // picker popup is anchored there, not near the button that was tapped.
  input.style.position = 'fixed';
  input.style.left = '50%';
  input.style.top = '50%';
  input.style.transform = 'translate(-50%, -50%)';
  input.style.width = '1px';
  input.style.height = '1px';
  input.style.opacity = '0';
  input.style.overflow = 'hidden';
  input.style.zIndex = '-1';

  web.document.body?.append(input);

  input.addEventListener(
    'change',
    (web.Event event) {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        input.remove();
        return;
      }

      final file = files.item(0)!;
      final reader = web.FileReader();

      reader.addEventListener(
        'load',
        (web.Event e) {
          try {
            final buffer = (reader.result as JSArrayBuffer).toDart;
            if (!completer.isCompleted) {
              completer.complete(Uint8List.view(buffer));
            }
          } catch (_) {
            if (!completer.isCompleted) completer.complete(null);
          }
          input.remove();
        }.toJS,
      );

      reader.addEventListener(
        'error',
        (web.Event e) {
          if (!completer.isCompleted) completer.complete(null);
          input.remove();
        }.toJS,
      );

      reader.readAsArrayBuffer(file);
    }.toJS,
  );

  // Detect cancel: window regains focus without a 'change' event.
  late JSFunction onWindowFocus;
  onWindowFocus = ((web.Event _) {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!completer.isCompleted) completer.complete(null);
      input.remove();
    });
    web.window.removeEventListener('focus', onWindowFocus);
  }).toJS;
  web.window.addEventListener('focus', onWindowFocus);

  input.click();

  return completer.future;
}
