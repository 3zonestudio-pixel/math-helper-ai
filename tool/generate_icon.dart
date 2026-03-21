// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

/// Generates app icon PNGs — dark bg + scan corners + white x².
/// Run: dart run tool/generate_icon.dart
void main() async {
  const size = 1024;
  final pixels = Uint8List(size * size * 4); // RGBA

  // 1. Dark navy background
  _drawBackground(pixels, size);

  // 2. White scan-style corner brackets with neon glow
  _drawScanCorners(pixels, size);

  // 3. White x² centered — x big, ² small superscript, with neon glow
  _drawX2Symbol(pixels, size);

  // Encode as PNG
  final png = _encodePng(pixels, size, size);

  // Save
  final iconFile = File('assets/icons/app_icon.png');
  await iconFile.writeAsBytes(png);
  print('Generated app_icon.png (${png.length} bytes)');

  final fgFile = File('assets/icons/app_icon_foreground.png');
  await fgFile.writeAsBytes(png);
  print('Generated app_icon_foreground.png');
}

// ─── Background ───────────────────────────────────────────────

void _drawBackground(Uint8List pixels, int size) {
  final cx = size / 2;
  final cy = size / 2;
  final maxDist = math.sqrt(cx * cx + cy * cy);

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final idx = (y * size + x) * 4;
      final dx = x - cx;
      final dy = y - cy;
      final t = (math.sqrt(dx * dx + dy * dy) / maxDist).clamp(0.0, 1.0);

      // Center #10162C → Edge #080C18
      pixels[idx + 0] = (16 - 8 * t).round().clamp(0, 255);
      pixels[idx + 1] = (22 - 10 * t).round().clamp(0, 255);
      pixels[idx + 2] = (44 - 20 * t).round().clamp(0, 255);
      pixels[idx + 3] = 255;
    }
  }
}

// ─── Scan-style corner brackets ────────────────────────────────

void _drawScanCorners(Uint8List pixels, int size) {
  const margin = 150;
  const armLen = 175;
  const thick = 18;
  const cR = 255, cG = 255, cB = 255; // White corners

  // 8 rectangles: 2 per corner (horizontal arm + vertical arm)
  final rects = <List<int>>[
    // Top-left
    [margin, margin, margin + armLen, margin + thick],
    [margin, margin, margin + thick, margin + armLen],
    // Top-right
    [size - margin - armLen, margin, size - margin, margin + thick],
    [size - margin - thick, margin, size - margin, margin + armLen],
    // Bottom-left
    [margin, size - margin - thick, margin + armLen, size - margin],
    [margin, size - margin - armLen, margin + thick, size - margin],
    // Bottom-right
    [size - margin - armLen, size - margin - thick, size - margin, size - margin],
    [size - margin - thick, size - margin - armLen, size - margin, size - margin],
  ];

  // Process only the 4 corner regions for performance
  const pad = 2;
  final cornerRegions = <List<int>>[
    [margin - pad, margin - pad, margin + armLen + pad, margin + armLen + pad],
    [size - margin - armLen - pad, margin - pad, size - margin + pad, margin + armLen + pad],
    [margin - pad, size - margin - armLen - pad, margin + armLen + pad, size - margin + pad],
    [size - margin - armLen - pad, size - margin - armLen - pad, size - margin + pad, size - margin + pad],
  ];

  for (final region in cornerRegions) {
    final y1 = region[1].clamp(0, size - 1);
    final y2 = region[3].clamp(0, size - 1);
    final x1 = region[0].clamp(0, size - 1);
    final x2 = region[2].clamp(0, size - 1);

    for (int y = y1; y <= y2; y++) {
      for (int x = x1; x <= x2; x++) {
        double minDist = double.infinity;
        for (final r in rects) {
          final dx = math.max(r[0] - x, math.max(0, x - r[2])).toDouble();
          final dy = math.max(r[1] - y, math.max(0, y - r[3])).toDouble();
          final d = math.sqrt(dx * dx + dy * dy);
          if (d < minDist) minDist = d;
        }

        if (minDist <= 0) {
          _setPixel(pixels, size, x, y, cR, cG, cB, 255);
        }
      }
    }
  }
}

// ─── x² symbol ─────────────────────────────────────────────────

void _drawX2Symbol(Uint8List pixels, int size) {
  final cx = size ~/ 2;
  final cy = size ~/ 2;

  // "x" — shifted left to make room for superscript ²
  final xCx = cx - 30;
  final xCy = cy + 18;
  const xHalf = 158; // big x
  const xThick = 30.0; // bold stroke

  // Two diagonal strokes of x:  \ and /
  final s1ax = (xCx - xHalf).toDouble(), s1ay = (xCy - xHalf).toDouble();
  final s1bx = (xCx + xHalf).toDouble(), s1by = (xCy + xHalf).toDouble();
  final s2ax = (xCx + xHalf).toDouble(), s2ay = (xCy - xHalf).toDouble();
  final s2bx = (xCx - xHalf).toDouble(), s2by = (xCy + xHalf).toDouble();

  // "²" — smaller superscript (5-segment digital style)
  final twoX = xCx + xHalf + 38;
  final twoY = xCy - xHalf - 25;
  const twoW = 62;
  const twoH = 80;
  const twoT = 14;

  final twoRects = <List<int>>[
    [twoX, twoY, twoX + twoW, twoY + twoT],                            // top bar
    [twoX + twoW - twoT, twoY, twoX + twoW, twoY + twoH ~/ 2 + twoT ~/ 2], // right (upper)
    [twoX, twoY + twoH ~/ 2 - twoT ~/ 2, twoX + twoW, twoY + twoH ~/ 2 + twoT ~/ 2], // middle
    [twoX, twoY + twoH ~/ 2 - twoT ~/ 2, twoX + twoT, twoY + twoH],   // left (lower)
    [twoX, twoY + twoH - twoT, twoX + twoW, twoY + twoH],              // bottom bar
  ];

  // Render bounding box
  const pad = 2;
  final rxMin = (xCx - xHalf - pad).clamp(0, size - 1);
  final ryMin = (twoY - pad).clamp(0, size - 1);
  final rxMax = (twoX + twoW + pad).clamp(0, size - 1);
  final ryMax = (xCy + xHalf + pad).clamp(0, size - 1);

  for (int y = rxMin; y <= ryMax; y++) {
    for (int x = rxMin; x <= rxMax; x++) {
      // Distance to x strokes
      final d1 = _distToThickSeg(x.toDouble(), y.toDouble(), s1ax, s1ay, s1bx, s1by, xThick / 2);
      final d2 = _distToThickSeg(x.toDouble(), y.toDouble(), s2ax, s2ay, s2bx, s2by, xThick / 2);
      final xDist = math.min(d1, d2);

      // Distance to ² rects
      double twoDist = double.infinity;
      for (final r in twoRects) {
        final dx = math.max(r[0] - x, math.max(0, x - r[2])).toDouble();
        final dy = math.max(r[1] - y, math.max(0, y - r[3])).toDouble();
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < twoDist) twoDist = d;
      }

      if (twoDist <= 0) {
        // ² in cyan accent color
        _setPixel(pixels, size, x, y, 0, 200, 255, 255);
      } else if (xDist <= 0) {
        // x in white
        _setPixel(pixels, size, x, y, 255, 255, 255, 255);
      }
    }
  }
}

/// Distance from point to a thick line segment (stroke with half-width).
double _distToThickSeg(double px, double py, double ax, double ay, double bx, double by, double halfW) {
  final abx = bx - ax, aby = by - ay;
  final apx = px - ax, apy = py - ay;
  final ab2 = abx * abx + aby * aby;
  final t = ((apx * abx + apy * aby) / ab2).clamp(0.0, 1.0);
  final dx = px - (ax + t * abx);
  final dy = py - (ay + t * aby);
  return math.max(0.0, math.sqrt(dx * dx + dy * dy) - halfW);
}

// ─── Pixel helpers ─────────────────────────────────────────────

void _setPixel(Uint8List pixels, int size, int x, int y, int r, int g, int b, int a) {
  if (x < 0 || x >= size || y < 0 || y >= size) return;
  final idx = (y * size + x) * 4;
  pixels[idx + 0] = r;
  pixels[idx + 1] = g;
  pixels[idx + 2] = b;
  pixels[idx + 3] = a;
}

void _blendPixel(Uint8List pixels, int size, int x, int y, int r, int g, int b, int a) {
  if (x < 0 || x >= size || y < 0 || y >= size) return;
  final idx = (y * size + x) * 4;
  final srcA = a / 255.0;
  final dstA = 1.0 - srcA;
  pixels[idx + 0] = (pixels[idx + 0] * dstA + r * srcA).round().clamp(0, 255);
  pixels[idx + 1] = (pixels[idx + 1] * dstA + g * srcA).round().clamp(0, 255);
  pixels[idx + 2] = (pixels[idx + 2] * dstA + b * srcA).round().clamp(0, 255);
  pixels[idx + 3] = 255;
}

/// Minimal PNG encoder for RGBA pixel data
Uint8List _encodePng(Uint8List rgba, int width, int height) {
  // Build raw image data with filter byte (0 = None) per row
  final rawLen = height * (1 + width * 4);
  final raw = Uint8List(rawLen);
  int pos = 0;
  for (int y = 0; y < height; y++) {
    raw[pos++] = 0; // filter: None
    final rowStart = y * width * 4;
    for (int x = 0; x < width * 4; x++) {
      raw[pos++] = rgba[rowStart + x];
    }
  }
  
  // Compress with zlib (deflate)
  final compressed = ZLibCodec().encode(raw);
  
  // Build PNG
  final out = BytesBuilder();
  
  // PNG signature
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);
  
  // IHDR chunk
  _writePngChunk(out, 'IHDR', _buildIhdr(width, height));
  
  // IDAT chunk
  _writePngChunk(out, 'IDAT', Uint8List.fromList(compressed));
  
  // IEND chunk
  _writePngChunk(out, 'IEND', Uint8List(0));
  
  return out.toBytes();
}

Uint8List _buildIhdr(int width, int height) {
  final data = ByteData(13);
  data.setUint32(0, width);
  data.setUint32(4, height);
  data.setUint8(8, 8); // bit depth
  data.setUint8(9, 6); // color type: RGBA
  data.setUint8(10, 0); // compression
  data.setUint8(11, 0); // filter
  data.setUint8(12, 0); // interlace
  return data.buffer.asUint8List();
}

void _writePngChunk(BytesBuilder out, String type, Uint8List data) {
  final lenBytes = ByteData(4)..setUint32(0, data.length);
  out.add(lenBytes.buffer.asUint8List());
  
  final typeBytes = type.codeUnits;
  out.add(typeBytes);
  
  out.add(data);
  
  // CRC32 over type + data
  final crcInput = Uint8List(typeBytes.length + data.length);
  crcInput.setAll(0, typeBytes);
  crcInput.setAll(typeBytes.length, data);
  final crc = _crc32(crcInput);
  final crcBytes = ByteData(4)..setUint32(0, crc);
  out.add(crcBytes.buffer.asUint8List());
}

int _crc32(Uint8List data) {
  int crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (int j = 0; j < 8; j++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
