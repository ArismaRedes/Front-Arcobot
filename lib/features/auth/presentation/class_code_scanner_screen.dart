import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ClassCodeScannerScreen extends StatefulWidget {
  const ClassCodeScannerScreen({super.key});

  @override
  State<ClassCodeScannerScreen> createState() => _ClassCodeScannerScreenState();
}

class _ClassCodeScannerScreenState extends State<ClassCodeScannerScreen> {
  // PIN de clase: 6 dígitos (mismo formato que genera el backend).
  static final _codePattern = RegExp(r'^\d{6}$');

  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _torchOn = false;
  bool _showInvalidHint = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }

    final rawValue = capture.barcodes.first.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    if (!_codePattern.hasMatch(rawValue)) {
      if (!_showInvalidHint) {
        setState(() => _showInvalidHint = true);
      }
      return;
    }

    _handled = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(rawValue);
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xAA0F172A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Escanea el código de la clase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleTorch,
                          tooltip: 'Linterna',
                          icon: Icon(
                            _torchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: _torchOn
                                ? ArcobotColors.sunYellow
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ArcobotColors.guideTurquoise,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x6619BFB7),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(_showInvalidHint),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _showInvalidHint
                            ? const Color(0xCC7A2E14)
                            : const Color(0xAA0F172A),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _showInvalidHint
                            ? 'Ese código no es de una clase. Pide ayuda a tu profe.'
                            : 'Alinea el código dentro del recuadro',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
