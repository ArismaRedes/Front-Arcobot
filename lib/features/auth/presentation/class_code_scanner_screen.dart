import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ClassCodeScannerScreen extends StatefulWidget {
  const ClassCodeScannerScreen({super.key});

  @override
  State<ClassCodeScannerScreen> createState() => _ClassCodeScannerScreenState();
}

class _ClassCodeScannerScreenState extends State<ClassCodeScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) {
                return;
              }

              final rawValue = capture.barcodes.first.rawValue?.trim();
              if (rawValue == null || rawValue.isEmpty) {
                return;
              }

              _handled = true;
              Navigator.of(context).pop(rawValue);
            },
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
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Escanea el codigo de la clase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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
                        color: const Color(0xFF0B6E5E),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x660B6E5E),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xAA0F172A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Alinea el codigo dentro del recuadro',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
