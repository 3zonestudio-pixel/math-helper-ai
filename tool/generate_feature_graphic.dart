// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

/// Generates Play Store feature graphic (1024x500).
/// Matches the app icon's dark navy + purple/cyan style.
/// Run: dart run tool/generate_feature_graphic.dart
void main() async {
  const w = 1024;
  const h = 500;
  final pixels = Uint8List(w * h * 4);

  // 1. Dark navy gradient background
  _drawBackground(pixels, w, h);

  // 2. Decorative scan corners (same style as icon)
  _drawScanCorners(pixels, w, h);

  // 3. x² symbol on the left side
  _drawX2Symbol(pixels, w, h);

  // 4. "Math Helper AI" text on the right
  _drawTitle(pixels, w, h);

  // 5. Subtitle line
  _drawSubtitle(pixels, w, h);

  // 6. Subtle floating math symbols in background
  _drawFloatingMath(pixels, w, h);

  final png = _encodePng(pixels, w, h);

  final dir = Directory('assets/icons');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final file = File('assets/icons/feature_graphic.png');
  await file.writeAsBytes(png);
  print('Generated feature_graphic.png (${png.length} bytes) — 1024x500');
}

// ─── Background ───────────────────────────────────────────────

void _drawBackground(Uint8List pixels, int w, int h) {
  final cx = w / 2;
  final cy = h / 2;
  final maxDist = math.sqrt(cx * cx + cy * cy);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final idx = (y * w + x) * 4;
      final dx = x - cx;
      final dy = y - cy;
      final t = (math.sqrt(dx * dx + dy * dy) / maxDist).clamp(0.0, 1.0);

      // Center #0E1428 → Edge #080B16 (same as icon)
      pixels[idx + 0] = (14 - 6 * t).round().clamp(0, 255);
      pixels[idx + 1] = (20 - 9 * t).round().clamp(0, 255);
      pixels[idx + 2] = (40 - 18 * t).round().clamp(0, 255);
      pixels[idx + 3] = 255;
    }
  }
}

// ─── Scan corners ─────────────────────────────────────────────

void _drawScanCorners(Uint8List pixels, int w, int h) {
  const margin = 40;
  const armLen = 80;
  const thick = 8;

  // Purple (#7B61FF) TL/BR, Cyan (#00B4D8) TR/BL
  const pR = 123, pG = 97, pB = 255;
  const cR = 0, cG = 180, cB = 216;

  // Top-left (purple)
  _drawL(pixels, w, h, margin, margin, armLen, thick, pR, pG, pB, true, true);
  // Top-right (cyan)
  _drawL(pixels, w, h, w - margin, margin, armLen, thick, cR, cG, cB, false, true);
  // Bottom-left (cyan)
  _drawL(pixels, w, h, margin, h - margin, armLen, thick, cR, cG, cB, true, false);
  // Bottom-right (purple)
  _drawL(pixels, w, h, w - margin, h - margin, armLen, thick, pR, pG, pB, false, false);
}

void _drawL(Uint8List pixels, int w, int h, int cx, int cy, int armLen, int thick, int r, int g, int b, bool left, bool top) {
  // Horizontal arm
  final hStart = left ? cx : cx - armLen;
  final hEnd = left ? cx + armLen : cx;
  final vStart = top ? cy : cy - armLen;
  final vEnd = top ? cy + armLen : cy;

  // Horizontal bar
  for (int y = (top ? cy : cy - thick); y < (top ? cy + thick : cy); y++) {
    for (int x = hStart; x < hEnd; x++) {
      _setPixel(pixels, w, h, x, y, r, g, b, 255);
    }
  }
  // Vertical bar
  for (int y = vStart; y < vEnd; y++) {
    for (int x = (left ? cx : cx - thick); x < (left ? cx + thick : cx); x++) {
      _setPixel(pixels, w, h, x, y, r, g, b, 255);
    }
  }

  // Glow
  const glowR = 10;
  for (int dy = -glowR; dy <= armLen + glowR; dy++) {
    for (int dx = -glowR; dx <= armLen + glowR; dx++) {
      final px = left ? cx + dx : cx - dx;
      final py = top ? cy + dy : cy - dy;
      // Check distance to the L shape
      final dH = _distToBox(px, py, hStart, top ? cy : cy - thick, hEnd, top ? cy + thick : cy);
      final dV = _distToBox(px, py, left ? cx : cx - thick, vStart, left ? cx + thick : cx, vEnd);
      final d = math.min(dH, dV);
      if (d > 0 && d <= glowR) {
        final alpha = (25 * (1.0 - d / glowR)).round().clamp(0, 255);
        _blendPixel(pixels, w, h, px, py, r, g, b, alpha);
      }
    }
  }
}

// ─── x² symbol (left side) ───────────────────────────────────

void _drawX2Symbol(Uint8List pixels, int w, int h) {
  // Place x² on the left third, vertically centered
  final cx = (w * 0.22).toInt();
  final cy = (h * 0.48).toInt();
  const xHalf = 70;
  const xThick = 18.0;

  // Curved x strokes
  final s1 = _cubicBezier(
    cx - xHalf + 0.0, cy - xHalf + 0.0,
    cx - xHalf * 0.15, cy - xHalf * 0.4,
    cx + xHalf * 0.15, cy + xHalf * 0.4,
    cx + xHalf + 0.0, cy + xHalf + 0.0, 60,
  );
  final s2 = _cubicBezier(
    cx + xHalf + 0.0, cy - xHalf + 0.0,
    cx + xHalf * 0.15, cy - xHalf * 0.4,
    cx - xHalf * 0.15, cy + xHalf * 0.4,
    cx - xHalf + 0.0, cy + xHalf + 0.0, 60,
  );

  // ² superscript
  final twoX = cx + xHalf + 20;
  final twoY = cy - xHalf - 50;
  const twoW = 55;
  const twoH = 70;
  const twoT = 14;

  final twoRects = <List<int>>[
    [twoX, twoY, twoX + twoW, twoY + twoT],
    [twoX + twoW - twoT, twoY, twoX + twoW, twoY + twoH ~/ 2 + twoT ~/ 2],
    [twoX, twoY + twoH ~/ 2 - twoT ~/ 2, twoX + twoW, twoY + twoH ~/ 2 + twoT ~/ 2],
    [twoX, twoY + twoH ~/ 2 - twoT ~/ 2, twoX + twoT, twoY + twoH],
    [twoX, twoY + twoH - twoT, twoX + twoW, twoY + twoH],
  ];

  const pad = 14;
  final rxMin = (cx - xHalf - pad).clamp(0, w - 1);
  final ryMin = (twoY - pad).clamp(0, h - 1);
  final rxMax = (twoX + twoW + pad).clamp(0, w - 1);
  final ryMax = (cy + xHalf + pad).clamp(0, h - 1);

  for (int y = ryMin; y <= ryMax; y++) {
    for (int x = rxMin; x <= rxMax; x++) {
      double d1 = double.infinity, d2 = double.infinity;
      for (int i = 0; i < s1.length - 1; i++) {
        final d = _distToSeg(x.toDouble(), y.toDouble(), s1[i][0], s1[i][1], s1[i + 1][0], s1[i + 1][1], xThick / 2);
        if (d < d1) d1 = d;
      }
      for (int i = 0; i < s2.length - 1; i++) {
        final d = _distToSeg(x.toDouble(), y.toDouble(), s2[i][0], s2[i][1], s2[i + 1][0], s2[i + 1][1], xThick / 2);
        if (d < d2) d2 = d;
      }
      final xDist = math.min(d1, d2);

      double twoDist = double.infinity;
      for (final r in twoRects) {
        final d = _distToBox(x, y, r[0], r[1], r[2], r[3]).toDouble();
        if (d < twoDist) twoDist = d;
      }

      if (twoDist <= 0) {
        _setPixel(pixels, w, h, x, y, 0, 180, 216, 255); // cyan ²
      } else if (twoDist <= 6) {
        final a = (35 * (1.0 - twoDist / 6)).round().clamp(0, 255);
        _blendPixel(pixels, w, h, x, y, 0, 180, 216, a);
      } else if (xDist <= 0) {
        _setPixel(pixels, w, h, x, y, 255, 255, 255, 255); // white x
      } else if (xDist <= 8) {
        final a = (30 * (1.0 - xDist / 8)).round().clamp(0, 255);
        _blendPixel(pixels, w, h, x, y, 255, 255, 255, a);
      }
    }
  }
}

// ─── Title: "Math Helper AI" ──────────────────────────────────
// Using a simple block-pixel font approach for clean text rendering.

void _drawTitle(Uint8List pixels, int w, int h) {
  // Each character is defined as a 5x7 grid of booleans
  final chars = _getBlockChars('MATH HELPER AI');
  const charW = 5;
  const charH = 7;
  const scale = 5; // pixels per block unit
  const spacing = 2; // spacing between characters in block units

  final totalW = chars.length * (charW + spacing) * scale;
  final startX = (w * 0.44).toInt();
  final startY = (h * 0.30).toInt();

  for (int ci = 0; ci < chars.length; ci++) {
    final grid = chars[ci];
    final ox = startX + ci * (charW + spacing) * scale;
    for (int gy = 0; gy < charH; gy++) {
      for (int gx = 0; gx < charW; gx++) {
        if (grid[gy][gx]) {
          // Fill scaled block
          for (int sy = 0; sy < scale; sy++) {
            for (int sx = 0; sx < scale; sx++) {
              final px = ox + gx * scale + sx;
              final py = startY + gy * scale + sy;
              _setPixel(pixels, w, h, px, py, 255, 255, 255, 255);
            }
          }
          // Subtle glow
          for (int sy = -2; sy < scale + 2; sy++) {
            for (int sx = -2; sx < scale + 2; sx++) {
              final px = ox + gx * scale + sx;
              final py = startY + gy * scale + sy;
              if (sx >= 0 && sx < scale && sy >= 0 && sy < scale) continue;
              _blendPixel(pixels, w, h, px, py, 255, 255, 255, 15);
            }
          }
        }
      }
    }
  }
}

// ─── Subtitle ─────────────────────────────────────────────────

void _drawSubtitle(Uint8List pixels, int w, int h) {
  final chars = _getBlockChars('SOLVE STEP BY STEP');
  const charW = 5;
  const charH = 7;
  const scale = 3;
  const spacing = 2;

  final startX = (w * 0.45).toInt();
  final startY = (h * 0.65).toInt();

  for (int ci = 0; ci < chars.length; ci++) {
    final grid = chars[ci];
    final ox = startX + ci * (charW + spacing) * scale;
    for (int gy = 0; gy < charH; gy++) {
      for (int gx = 0; gx < charW; gx++) {
        if (grid[gy][gx]) {
          for (int sy = 0; sy < scale; sy++) {
            for (int sx = 0; sx < scale; sx++) {
              final px = ox + gx * scale + sx;
              final py = startY + gy * scale + sy;
              // Cyan color for subtitle
              _setPixel(pixels, w, h, px, py, 0, 180, 216, 220);
            }
          }
        }
      }
    }
  }
}

// ─── Floating math symbols in background ──────────────────────

void _drawFloatingMath(Uint8List pixels, int w, int h) {
  // Subtle math symbols scattered in background
  final symbols = [
    _getBlockChars('+')[0],
    _getBlockChars('-')[0],
    _getBlockChars('=')[0],
  ];

  final positions = [
    [80, 80, 20], // x, y, alpha
    [w - 120, 120, 15],
    [200, h - 90, 15],
    [w - 200, h - 80, 18],
    [w ~/ 2 - 50, h - 70, 12],
    [w ~/ 2 + 200, 70, 14],
  ];

  const charW = 5;
  const charH = 7;
  const scale = 5;

  for (int pi = 0; pi < positions.length; pi++) {
    final pos = positions[pi];
    final grid = symbols[pi % symbols.length];
    final ox = pos[0];
    final oy = pos[1];
    final alpha = pos[2];
    // Purple or cyan alternating
    final isP = pi % 2 == 0;
    final cr = isP ? 123 : 0;
    final cg = isP ? 97 : 180;
    final cb = isP ? 255 : 216;

    for (int gy = 0; gy < charH; gy++) {
      for (int gx = 0; gx < charW; gx++) {
        if (grid[gy][gx]) {
          for (int sy = 0; sy < scale; sy++) {
            for (int sx = 0; sx < scale; sx++) {
              _blendPixel(pixels, w, h, ox + gx * scale + sx, oy + gy * scale + sy, cr, cg, cb, alpha);
            }
          }
        }
      }
    }
  }
}

// ─── Block font (5x7) ────────────────────────────────────────

List<List<List<bool>>> _getBlockChars(String text) {
  return text.split('').map((c) => _charGrid(c)).toList();
}

List<List<bool>> _charGrid(String c) {
  // 5 wide x 7 tall bitmap font
  const fonts = <String, List<String>>{
    'A': ['01110','10001','10001','11111','10001','10001','10001'],
    'B': ['11110','10001','10001','11110','10001','10001','11110'],
    'C': ['01110','10001','10000','10000','10000','10001','01110'],
    'D': ['11100','10010','10001','10001','10001','10010','11100'],
    'E': ['11111','10000','10000','11110','10000','10000','11111'],
    'F': ['11111','10000','10000','11110','10000','10000','10000'],
    'G': ['01110','10001','10000','10111','10001','10001','01110'],
    'H': ['10001','10001','10001','11111','10001','10001','10001'],
    'I': ['01110','00100','00100','00100','00100','00100','01110'],
    'J': ['00111','00010','00010','00010','00010','10010','01100'],
    'K': ['10001','10010','10100','11000','10100','10010','10001'],
    'L': ['10000','10000','10000','10000','10000','10000','11111'],
    'M': ['10001','11011','10101','10101','10001','10001','10001'],
    'N': ['10001','11001','10101','10011','10001','10001','10001'],
    'O': ['01110','10001','10001','10001','10001','10001','01110'],
    'P': ['11110','10001','10001','11110','10000','10000','10000'],
    'Q': ['01110','10001','10001','10001','10101','10010','01101'],
    'R': ['11110','10001','10001','11110','10100','10010','10001'],
    'S': ['01111','10000','10000','01110','00001','00001','11110'],
    'T': ['11111','00100','00100','00100','00100','00100','00100'],
    'U': ['10001','10001','10001','10001','10001','10001','01110'],
    'V': ['10001','10001','10001','10001','01010','01010','00100'],
    'W': ['10001','10001','10001','10101','10101','10101','01010'],
    'X': ['10001','10001','01010','00100','01010','10001','10001'],
    'Y': ['10001','10001','01010','00100','00100','00100','00100'],
    'Z': ['11111','00001','00010','00100','01000','10000','11111'],
    '0': ['01110','10001','10011','10101','11001','10001','01110'],
    '1': ['00100','01100','00100','00100','00100','00100','01110'],
    '2': ['01110','10001','00001','00010','00100','01000','11111'],
    '3': ['01110','10001','00001','00110','00001','10001','01110'],
    '4': ['00010','00110','01010','10010','11111','00010','00010'],
    '5': ['11111','10000','11110','00001','00001','10001','01110'],
    '6': ['01110','10000','11110','10001','10001','10001','01110'],
    '7': ['11111','00001','00010','00100','01000','01000','01000'],
    '8': ['01110','10001','10001','01110','10001','10001','01110'],
    '9': ['01110','10001','10001','01111','00001','00001','01110'],
    '+': ['00000','00100','00100','11111','00100','00100','00000'],
    '-': ['00000','00000','00000','11111','00000','00000','00000'],
    '*': ['00000','10101','01110','11111','01110','10101','00000'],
    '/': ['00001','00010','00010','00100','01000','01000','10000'],
    '=': ['00000','00000','11111','00000','11111','00000','00000'],
    ' ': ['00000','00000','00000','00000','00000','00000','00000'],
  };

  final rows = fonts[c.toUpperCase()] ?? fonts[' ']!;
  return rows.map((row) => row.split('').map((ch) => ch == '1').toList()).toList();
}

// ─── Helpers ──────────────────────────────────────────────────

List<List<double>> _cubicBezier(double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3, int n) {
  final pts = <List<double>>[];
  for (int i = 0; i <= n; i++) {
    final t = i / n;
    final u = 1 - t;
    pts.add([
      u * u * u * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x3,
      u * u * u * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y3,
    ]);
  }
  return pts;
}

double _distToSeg(double px, double py, double ax, double ay, double bx, double by, double halfW) {
  final abx = bx - ax, aby = by - ay;
  final apx = px - ax, apy = py - ay;
  final ab2 = abx * abx + aby * aby;
  final t = ab2 == 0 ? 0.0 : ((apx * abx + apy * aby) / ab2).clamp(0.0, 1.0);
  final dx = px - (ax + t * abx);
  final dy = py - (ay + t * aby);
  return math.max(0.0, math.sqrt(dx * dx + dy * dy) - halfW);
}

double _distToBox(int px, int py, int x1, int y1, int x2, int y2) {
  final dx = math.max(x1 - px, math.max(0, px - x2)).toDouble();
  final dy = math.max(y1 - py, math.max(0, py - y2)).toDouble();
  return math.sqrt(dx * dx + dy * dy);
}

void _setPixel(Uint8List pixels, int w, int h, int x, int y, int r, int g, int b, int a) {
  if (x < 0 || x >= w || y < 0 || y >= h) return;
  final idx = (y * w + x) * 4;
  pixels[idx] = r; pixels[idx + 1] = g; pixels[idx + 2] = b; pixels[idx + 3] = a;
}

void _blendPixel(Uint8List pixels, int w, int h, int x, int y, int r, int g, int b, int a) {
  if (x < 0 || x >= w || y < 0 || y >= h) return;
  final idx = (y * w + x) * 4;
  final s = a / 255.0;
  final d = 1.0 - s;
  pixels[idx] = (pixels[idx] * d + r * s).round().clamp(0, 255);
  pixels[idx + 1] = (pixels[idx + 1] * d + g * s).round().clamp(0, 255);
  pixels[idx + 2] = (pixels[idx + 2] * d + b * s).round().clamp(0, 255);
  pixels[idx + 3] = 255;
}

// ─── PNG encoder ──────────────────────────────────────────────

Uint8List _encodePng(Uint8List rgba, int w, int h) {
  final rawLen = h * (1 + w * 4);
  final raw = Uint8List(rawLen);
  int pos = 0;
  for (int y = 0; y < h; y++) {
    raw[pos++] = 0;
    final rowStart = y * w * 4;
    for (int x = 0; x < w * 4; x++) {
      raw[pos++] = rgba[rowStart + x];
    }
  }
  final compressed = ZLibCodec().encode(raw);
  final out = BytesBuilder();
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);
  _writePngChunk(out, 'IHDR', _buildIhdr(w, h));
  _writePngChunk(out, 'IDAT', Uint8List.fromList(compressed));
  _writePngChunk(out, 'IEND', Uint8List(0));
  return out.toBytes();
}

Uint8List _buildIhdr(int w, int h) {
  final d = ByteData(13);
  d.setUint32(0, w); d.setUint32(4, h);
  d.setUint8(8, 8); d.setUint8(9, 6);
  d.setUint8(10, 0); d.setUint8(11, 0); d.setUint8(12, 0);
  return d.buffer.asUint8List();
}

void _writePngChunk(BytesBuilder out, String type, Uint8List data) {
  out.add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List());
  out.add(type.codeUnits);
  out.add(data);
  final ci = Uint8List(type.length + data.length);
  ci.setAll(0, type.codeUnits);
  ci.setAll(type.length, data);
  out.add((ByteData(4)..setUint32(0, _crc32(ci))).buffer.asUint8List());
}

int _crc32(Uint8List data) {
  int crc = 0xFFFFFFFF;
  for (final b in data) {
    crc ^= b;
    for (int j = 0; j < 8; j++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
