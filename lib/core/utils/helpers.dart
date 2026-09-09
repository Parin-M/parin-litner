import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_models.dart';

String uid() => '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';

int dueCount(Deck d) => d.cards.where((c) => !c.dueAt.isAfter(DateTime.now())).length;

Color boxColor(LeitnerBox b) => Color(b.colorValue);

Uint8List? tryDecodeBase64Image(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    final bytes = base64Decode(value.trim());
    if (bytes.isEmpty) return null;
    return Uint8List.fromList(bytes);
  } catch (_) {
    return null;
  }
}

class SafeMemoryImage extends StatelessWidget {
  final String? base64;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget? error;

  const SafeMemoryImage({
    super.key,
    required this.base64,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.borderRadius = BorderRadius.zero,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeBase64Image(base64);
    if (bytes == null) {
      return error ?? const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.memory(
        bytes,
        height: height,
        width: width,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => error ?? const SizedBox.shrink(),
      ),
    );
  }
}
