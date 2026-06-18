import 'dart:io';

import 'package:flutter/material.dart';

/// Full-screen, zoomable view of a receipt photo.
class ReceiptViewerPage extends StatelessWidget {
  const ReceiptViewerPage({required this.absolutePath, super.key});

  final String absolutePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Receipt'),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.file(
            File(absolutePath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Receipt image is unavailable.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
