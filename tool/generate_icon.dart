// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

/// Generates app icon PNGs — dark bg + rounded scan corners + x² with glow.
/// Run: dart run tool/generate_icon.dart
void main() async {
  const size = 1024;
  final pixels = Uint8List(size * size * 4); // RGBA

  // 1. Dark navy background with subtle radial gradient
  _drawBackground(pixels, size);

  // 2. Scan-style corner brackets (purple TL/BR, cyan TR/BL) with rounded ends + glow
  _drawScanCorners(pixels, size);

  // 3. White "x" + cyan "²" centered with subtle glow
  _drawX2Symbol(pixels, size);

  // Encode as PNG
  final png = _encodePng(pixels, size, size);

  // Save
  final dir = Directory('assets/icons');
  if (!dir.existsSync()) dir.createSync(recursive: true);

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

      // Center #0E1428 → Edge #080B16
      pixels[idx + 0] = (14 - 6 * t).round().clamp(0, 255);
      pixels[idx + 1] = (20 - 9 * t).round().clamp(0, 255);
      pixels[idx + 2] = (40 - 18 * t).round().clamp(0, 255);
      pixels[idx + 3] = 255;
    }
  }
}

// ─── Scan-style corner brackets with rounded ends ──────────────

void _drawScanCorners(Uint8List pixels, int size) {
  const margin = 160;
  const armLen = 180;
  const thick = 16;
  const roundR = 20; // rounded corner radius

  // Purple (#7B61FF) for TL and BR
  const pR = 123, pG = 97, pB = 255;
  // Cyan (#00B4D8) for TR and BL
  const cR = 0, cG = 180, cB = 216;

  // Draw rounded L-shaped corners
  // Top-left (purple)
  _drawCornerL(pixels, size, margin, margin, armLen, thick, roundR, pR, pG, pB, _Corner.topLeft);
  // Top-right (cyan)
  _drawCornerL(pixels, size, size - margin, margin, armLen, thick, roundR, cR, cG, cB, _Corner.topRight);
  // Bottom-left (cyan)
  _drawCornerL(pixels, size, margin, size - margin, armLen, thick, roundR, cR, cG, cB, _Corner.bottomLeft);
  // Bottom-right (purple)
  _drawCornerL(pixels, size, size - margin, size - margin, armLen, thick, roundR, pR, pG, pB, _Corner.bottomRight);

  // Add glow around corners
  _drawCornerGlow(pixels, size, margin, margin, armLen, thick, pR, pG, pB, _Corner.topLeft);
  _drawCornerGlow(pixels, size, size - margin, margin, armLen, thick, cR, cG, cB, _Corner.topRight);
  _drawCornerGlow(pixels, size, margin, size - margin, armLen, thick, cR, cG, cB, _Corner.bottomLeft);
  _drawCornerGlow(pixels, size, size - margin, size - margin, armLen, thick, pR, pG, pB, _Corner.bottomRight);
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

void _drawCornerL(Uint8List pixels, int size, int cx, int cy, int armLen, int thick, int roundR, int r, int g, int b, _Corner corner) {
  // Draw two arms as thick lines meeting at a rounded corner
  // Arms extend outward from the corner point
  int hx1, hy1, hx2, hy2; // horizontal arm rect
  int vx1, vy1, vx2, vy2; // vertical arm rect
  int arcCx, arcCy; // arc center

  switch (corner) {
    case _Corner.topLeft:
      hx1 = cx + roundR; hy1 = cy; hx2 = cx + armLen; hy2 = cy + thick;
      vx1 = cx; vy1 = cy + roundR; vx2 = cx + thick; vy2 = cy + armLen;
      arcCx = cx + roundR; arcCy = cy + roundR;
      break;
    case _Corner.topRight:
      hx1 = cx - armLen; hy1 = cy; hx2 = cx - roundR; hy2 = cy + thick;
      vx1 = cx - thick; vy1 = cy + roundR; vx2 = cx; vy2 = cy + armLen;
      arcCx = cx - roundR; arcCy = cy + roundR;
      break;
    case _Corner.bottomLeft:
      hx1 = cx + roundR; hy1 = cy - thick; hx2 = cx + armLen; hy2 = cy;
      vx1 = cx; vy1 = cy - armLen; vx2 = cx + thick; vy2 = cy - roundR;
      arcCx = cx + roundR; arcCy = cy - roundR;
      break;
    case _Corner.bottomRight:
      hx1 = cx - armLen; hy1 = cy - thick; hx2 = cx - roundR; hy2 = cy;
      vx1 = cx - thick; vy1 = cy - armLen; vx2 = cx; vy2 = cy - roundR;
      arcCx = cx - roundR; arcCy = cy - roundR;
      break;
  }

  // Draw horizontal arm
  for (int y = math.min(hy1, hy2); y <= math.max(hy1, hy2); y++) {
    for (int x = math.min(hx1, hx2); x <= math.max(hx1, hx2); x++) {
      _setPixel(pixels, size, x, y, r, g, b, 255);
    }
  }

  // Draw vertical arm
  for (int y = math.min(vy1, vy2); y <= math.max(vy1, vy2); y++) {
    for (int x = math.min(vx1, vx2); x <= math.max(vx1, vx2); x++) {
      _setPixel(pixels, size, x, y, r, g, b, 255);
    }
  }

  // Draw rounded corner arc (fill the quarter circle area between the arms)
  for (int y = arcCy - roundR; y <= arcCy + roundR; y++) {
    for (int x = arcCx - roundR; x <= arcCx + roundR; x++) {
      final dx = (x - arcCx).toDouble();
      final dy = (y - arcCy).toDouble();
      final dist = math.sqrt(dx * dx + dy * dy);
      // Only draw in the correct quadrant and within the annulus
      bool inQuadrant = false;
      switch (corner) {
        case _Corner.topLeft: inQuadrant = x <= arcCx && y <= arcCy; break;
        case _Corner.topRight: inQuadrant = x >= arcCx && y <= arcCy; break;
        case _Corner.bottomLeft: inQuadrant = x <= arcCx && y >= arcCy; break;
        case _Corner.bottomRight: inQuadrant = x >= arcCx && y >= arcCy; break;
      }
      if (inQuadrant && dist <= roundR && dist >= roundR - thick) {
        _setPixel(pixels, size, x, y, r, g, b, 255);
      }
    }
  }
}

void _drawCornerGlow(Uint8List pixels, int size, int cx, int cy, int armLen, int thick, int r, int g, int b, _Corner corner) {
  const glowRadius = 12;
  const glowAlpha = 30;
  int hx1, hy1, hx2, hy2;
  int vx1, vy1, vx2, vy2;

  switch (corner) {
    case _Corner.topLeft:
      hx1 = cx; hy1 = cy; hx2 = cx + armLen; hy2 = cy + thick;
      vx1 = cx; vy1 = cy; vx2 = cx + thick; vy2 = cy + armLen;
      break;
    case _Corner.topRight:
      hx1 = cx - armLen; hy1 = cy; hx2 = cx; hy2 = cy + thick;
      vx1 = cx - thick; vy1 = cy; vx2 = cx; vy2 = cy + armLen;
      break;
    case _Corner.bottomLeft:
      hx1 = cx; hy1 = cy - thick; hx2 = cx + armLen; hy2 = cy;
      vx1 = cx; vy1 = cy - armLen; vx2 = cx + thick; vy2 = cy;
      break;
    case _Corner.bottomRight:
      hx1 = cx - armLen; hy1 = cy - thick; hx2 = cx; hy2 = cy;
      vx1 = cx - thick; vy1 = cy - armLen; vx2 = cx; vy2 = cy;
      break;
  }

  final minX = math.min(math.min(hx1, hx2), math.min(vx1, vx2)) - glowRadius;
  final maxX = math.max(math.max(hx1, hx2), math.max(vx1, vx2)) + glowRadius;
  final minY = math.min(math.min(hy1, hy2), math.min(vy1, vy2)) - glowRadius;
  final maxY = math.max(math.max(hy1, hy2), math.max(vy1, vy2)) + glowRadius;

  for (int y = minY.clamp(0, size - 1); y <= maxY.clamp(0, size - 1); y++) {
    for (int x = minX.clamp(0, size - 1); x <= maxX.clamp(0, size - 1); x++) {
      // Distance to nearest arm rectangle
      final dh = _distToRect(x, y, math.min(hx1, hx2), math.min(hy1, hy2), math.max(hx1, hx2), math.max(hy1, hy2));
      final dv = _distToRect(x, y, math.min(vx1, vx2), math.min(vy1, vy2), math.max(vx1, vx2), math.max(vy1, vy2));
      final d = math.min(dh, dv);
      if (d > 0 && d <= glowRadius) {
        final alpha = (glowAlpha * (1.0 - d / glowRadius)).round().clamp(0, 255);
        _blendPixel(pixels, size, x, y, r, g, b, alpha);
      }
    }
  }
}

double _distToRect(int px, int py, int x1, int y1, int x2, int y2) {
  final dx = math.max(x1 - px, math.max(0, px - x2)).toDouble();
  final dy = math.max(y1 - py, math.max(0, py - y2)).toDouble();
  return math.sqrt(dx * dx + dy * dy);
}

// ─── x² symbol ─────────────────────────────────────────────────

void _drawX2Symbol(Uint8List pixels, int size) {
  final cx = size ~/ 2;
  final cy = size ~/ 2;

  // "x" — curved strokes with rounded ends for a cute/stylish look
  final xCx = cx - 40;
  final xCy = cy + 15;
  const xHalf = 105;
  const xThick = 24.0;

  // Generate curved x strokes using cubic bezier (S-curve)
  // Stroke 1: top-left → bottom-right
  final s1Points = _cubicBezierPoints(
    xCx - xHalf + 0.0, xCy - xHalf + 0.0,       // start
    xCx - xHalf * 0.15, xCy - xHalf * 0.4,       // control 1
    xCx + xHalf * 0.15, xCy + xHalf * 0.4,       // control 2
    xCx + xHalf + 0.0, xCy + xHalf + 0.0,         // end
    80,
  );
  // Stroke 2: top-right → bottom-left
  final s2Points = _cubicBezierPoints(
    xCx + xHalf + 0.0, xCy - xHalf + 0.0,
    xCx + xHalf * 0.15, xCy - xHalf * 0.4,
    xCx - xHalf * 0.15, xCy + xHalf * 0.4,
    xCx - xHalf + 0.0, xCy + xHalf + 0.0,
    80,
  );

  // "²" — BIGGER superscript (5-segment digital style)
  final twoX = xCx + xHalf + 25;
  final twoY = xCy - xHalf - 55;
  const twoW = 85;
  const twoH = 110;
  const twoT = 18;

  final twoRects = <List<int>>[
    [twoX, twoY, twoX + twoW, twoY + twoT],                            // top bar
    [twoX + twoW - twoT, twoY, twoX + twoW, twoY + twoH ~/ 2 + twoT ~/ 2], // right upper
    [twoX, twoY + twoH ~/ 2 - twoT ~/ 2, twoX + twoW, twoY + twoH ~/ 2 + twoT ~/ 2], // middle
    [twoX, twoY + twoH ~/ 2 - twoT ~/ 2, twoX + twoT, twoY + twoH],   // left lower
    [twoX, twoY + twoH - twoT, twoX + twoW, twoY + twoH],              // bottom bar
  ];

  // Render bounding box
  const pad = 18; // extra for glow
  final rxMin = (xCx - xHalf - pad).clamp(0, size - 1);
  final ryMin = (twoY - pad).clamp(0, size - 1);
  final rxMax = (twoX + twoW + pad).clamp(0, size - 1);
  final ryMax = (xCy + xHalf + pad).clamp(0, size - 1);

  for (int y = ryMin; y <= ryMax; y++) {
    for (int x = rxMin; x <= rxMax; x++) {
      // Distance to curved x strokes (minimum distance to any segment of each curve)
      double d1 = double.infinity;
      for (int i = 0; i < s1Points.length - 1; i++) {
        final d = _distToThickSeg(
          x.toDouble(), y.toDouble(),
          s1Points[i][0], s1Points[i][1],
          s1Points[i + 1][0], s1Points[i + 1][1],
          xThick / 2,
        );
        if (d < d1) d1 = d;
      }
      double d2 = double.infinity;
      for (int i = 0; i < s2Points.length - 1; i++) {
        final d = _distToThickSeg(
          x.toDouble(), y.toDouble(),
          s2Points[i][0], s2Points[i][1],
          s2Points[i + 1][0], s2Points[i + 1][1],
          xThick / 2,
        );
        if (d < d2) d2 = d;
      }
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
        // ² in cyan (#00B4D8)
        _setPixel(pixels, size, x, y, 0, 180, 216, 255);
      } else if (twoDist <= 8) {
        // Cyan glow around ²
        final alpha = (40 * (1.0 - twoDist / 8)).round().clamp(0, 255);
        _blendPixel(pixels, size, x, y, 0, 180, 216, alpha);
      } else if (xDist <= 0) {
        // x in white
        _setPixel(pixels, size, x, y, 255, 255, 255, 255);
      } else if (xDist <= 10) {
        // White glow around x
        final alpha = (35 * (1.0 - xDist / 10)).round().clamp(0, 255);
        _blendPixel(pixels, size, x, y, 255, 255, 255, alpha);
      }
    }
  }
}

/// Generate points along a cubic bezier curve
List<List<double>> _cubicBezierPoints(
  double x0, double y0, double x1, double y1,
  double x2, double y2, double x3, double y3,
  int segments,
) {
  final points = <List<double>>[];
  for (int i = 0; i <= segments; i++) {
    final t = i / segments;
    final u = 1.0 - t;
    final px = u * u * u * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x3;
    final py = u * u * u * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y3;
    points.add([px, py]);
  }
  return points;
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
