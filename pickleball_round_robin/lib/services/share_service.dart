import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Flattens a captured widget (the current matchups or live standings) into a
/// high-contrast PNG and hands it to the native platform share sheet for
/// one-tap distribution into messaging threads.
class ShareService {
  /// Rasterizes the [RepaintBoundary] behind [key] and shares it.
  static Future<void> shareBoundary(
    GlobalKey key, {
    required String text,
    String fileName = 'round_robin.png',
  }) async {
    final bytes = await capture(key);
    if (bytes == null) return;

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: fileName,
        ),
      ],
      text: text,
    );
  }

  /// Captures the boundary as PNG bytes. Returns null if the boundary is not
  /// yet laid out.
  static Future<Uint8List?> capture(GlobalKey key, {double pixelRatio = 3.0}) async {
    final context = key.currentContext;
    if (context == null) return null;
    final object = context.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;

    final image = await object.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
