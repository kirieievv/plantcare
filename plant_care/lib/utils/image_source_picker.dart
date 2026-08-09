/// One way to ask the user for a photo, wherever the app is running.
///
/// Four screens needed the same thing — camera or gallery on a phone, a file
/// dialog everywhere else — and each had grown its own copy of the action
/// sheet, its own platform check and its own idea of what to call the buttons.
/// One of those copies was still in English.
///
/// The web branch deliberately shows no sheet of our own: the hidden
/// `<input type="file" accept="image/*">` behind [pickCenteredImageFromWeb]
/// makes a mobile browser offer "Take Photo / Photo Library" itself, in the
/// system's language and with the system's permission prompt. Drawing our own
/// on top of that would be a second, worse chooser.
library;

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/utils/web_file_picker.dart';

/// True where `image_picker` can reach a real camera and the Cupertino sheet
/// belongs. Web is excluded first: on the web build `defaultTargetPlatform`
/// reports iOS for Safari, which would otherwise take us down the native path.
bool get isNativeMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Picks one image and returns its bytes, or null if the user backed out.
///
/// Bytes rather than a file because every consumer wants bytes: uploads go
/// through `putData` and the analyzer takes base64.
///
/// Errors are thrown, not swallowed — each screen already has its own place to
/// show `errorPickingImage`, and a null here means "cancelled", which must stay
/// distinguishable from "failed".
Future<Uint8List?> pickImageBytes(
  BuildContext context, {
  double maxWidth = 1200,
  double maxHeight = 1600,
  int imageQuality = 90,
}) async {
  if (!isNativeMobile) return pickCenteredImageFromWeb();

  final source = await _askSource(context);
  if (source == null) return null;

  final image = await ImagePicker().pickImage(
    source: source,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: imageQuality,
  );
  if (image == null) return null;
  return image.readAsBytes();
}

/// The native sheet. Returns null on cancel, including a swipe-down.
Future<ImageSource?> _askSource(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showCupertinoModalPopup<ImageSource>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
          child: Text(l10n.camera),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
          child: Text(l10n.gallery),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(l10n.cancel),
      ),
    ),
  );
}
