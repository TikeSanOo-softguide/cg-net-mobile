import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme/app_theme.dart';

/// Full-screen camera scanner. Pops the first barcode or QR value.
class AppBarcodeScannerPage extends StatefulWidget {
  const AppBarcodeScannerPage({
    super.key,
    this.scanValueParser,
    this.scanInvalidMessage,
  });

  final String? Function(String raw)? scanValueParser;
  final String? scanInvalidMessage;

  @override
  State<AppBarcodeScannerPage> createState() => _AppBarcodeScannerPageState();
}

class _AppBarcodeScannerPageState extends State<AppBarcodeScannerPage> {
  bool _popped = false;
  bool _showInvalidMessage = false;
  Timer? _invalidMessageTimer;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_popped || !mounted) return;
    String? raw;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        raw = value;
        break;
      }
    }
    if (raw == null) return;
    final scanValue =
        widget.scanValueParser == null ? raw : widget.scanValueParser!(raw);
    if (scanValue == null || scanValue.trim().isEmpty) {
      if (!_showInvalidMessage) {
        setState(() => _showInvalidMessage = true);
        _invalidMessageTimer?.cancel();
        _invalidMessageTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _showInvalidMessage = false);
          }
        });
      }
      return;
    }
    _popped = true;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    Navigator.of(context).pop(scanValue);
  }

  @override
  void dispose() {
    _invalidMessageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final frameSize = (constraints.maxWidth * 0.68).clamp(190.0, 250.0);
          final scanWindow = Rect.fromCenter(
            center: Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            ),
            width: frameSize - 4,
            height: frameSize - 4,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                scanWindow: scanWindow,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'topup.scan_unavailable'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTheme.english(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
              _ScanOverlay(frameSize: frameSize),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'topup.scan_title'.tr(),
                          style: AppTheme.english(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showInvalidMessage && widget.scanInvalidMessage != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.paddingOf(context).bottom + 28,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        widget.scanInvalidMessage!,
                        textAlign: TextAlign.center,
                        style: AppTheme.english(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScanOverlay extends StatefulWidget {
  const _ScanOverlay({required this.frameSize});

  final double frameSize;

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _scanAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            CustomPaint(
              painter: _ScanOverlayPainter(widget.frameSize),
              child: const SizedBox.expand(),
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox.square(
                  dimension: widget.frameSize,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.square(widget.frameSize),
                        painter: const _ScanCornersPainter(),
                      ),
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          const inset = 16.0;
                          final travel = widget.frameSize - inset * 2;
                          return Positioned(
                            left: 14,
                            right: 14,
                            top: inset + travel * _scanAnimation.value,
                            child: child!,
                          );
                        },
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF80DEEA),
                                Colors.white,
                                Color(0xFF80DEEA),
                                Colors.transparent,
                              ],
                              stops: [0, 0.22, 0.5, 0.78, 1],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF80DEEA)
                                    .withValues(alpha: 0.75),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  const _ScanOverlayPainter(this.frameSize);

  final double frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final scanWindow = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: frameSize - 4,
        height: frameSize - 4,
      ),
      const Radius.circular(4),
    );
    final overlay = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(scanWindow);
    canvas.drawPath(overlay, Paint()..color = const Color(0xB5001458));
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      oldDelegate.frameSize != frameSize;
}

class _ScanCornersPainter extends CustomPainter {
  const _ScanCornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const cornerLength = 42.0;
    const inset = 2.0;
    final right = size.width - inset;
    final bottom = size.height - inset;
    final path = Path()
      ..moveTo(inset + cornerLength, inset)
      ..lineTo(inset + 12, inset)
      ..quadraticBezierTo(inset, inset, inset, inset + 12)
      ..lineTo(inset, inset + cornerLength)
      ..moveTo(right - cornerLength, inset)
      ..lineTo(right - 12, inset)
      ..quadraticBezierTo(right, inset, right, inset + 12)
      ..lineTo(right, inset + cornerLength)
      ..moveTo(inset, bottom - cornerLength)
      ..lineTo(inset, bottom - 12)
      ..quadraticBezierTo(inset, bottom, inset + 12, bottom)
      ..lineTo(inset + cornerLength, bottom)
      ..moveTo(right - cornerLength, bottom)
      ..lineTo(right - 12, bottom)
      ..quadraticBezierTo(right, bottom, right, bottom - 12)
      ..lineTo(right, bottom - cornerLength);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanCornersPainter oldDelegate) => false;
}
