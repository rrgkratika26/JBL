import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../../services/JBL_apis/jbl_api_bailing_reports.dart';
import 'Jbl_ScanBarcode.dart'; // ScanJBLType

class Jbl_ScanRecieveBarcode extends StatefulWidget {
  final String operatorName;
  final String supervisor;
  final String storage; // issueTo
  final String department;
  final ScanJBLType scanType;
  final String unit; // plant

  const Jbl_ScanRecieveBarcode({
    Key? key,
    required this.operatorName,
    required this.supervisor,
    required this.storage,
    required this.department,
    required this.scanType,
    required this.unit,
  }) : super(key: key);

  @override
  State<Jbl_ScanRecieveBarcode> createState() => _Jbl_ScanRecieveBarcodeState();
}

class _Jbl_ScanRecieveBarcodeState extends State<Jbl_ScanRecieveBarcode> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR_RECEIVE');
  QRViewController? controller;

  bool isFlashOn = false;
  bool isScanned = false;
  Timer? timeoutTimer;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void dispose() {
    timeoutTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  /// Auto timeout
  void _startTimeout() {
    timeoutTimer?.cancel();
    timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!isScanned && mounted) {
        controller?.pauseCamera();
        _showSnackBar('Scan timed out. Try again.', isSuccess: false);
        Navigator.pop(context);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  void _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      setState(() => isFlashOn = !isFlashOn);
    }
  }

  // =====================================================
  // MAIN LOGIC -> POST /Rmd/ProcessBarcodeJbl
  // =====================================================

  Future<void> _processBarcode(String barcode) async {
    Map<String, dynamic>? result;

    try {
      result = await JblApiService().processBarcodeRecieveJbl(
        barcode: barcode,
        plant: widget.unit,
        department: widget.department,
        issueTo: widget.storage,
        operatorName: widget.operatorName,
        supervisor: widget.supervisor,
      );
    } catch (e) {
      debugPrint('Receive scan error: $e');
      _retry('Something went wrong');
      return;
    }

    if (!mounted) return;

    if (result == null) {
      _retry('Server not responding');
      return;
    }

    final success = result['success'] == true;
    final message = result['message']?.toString() ?? 'Unknown response';

    _showSnackBar(message, isSuccess: success);

    if (success) {
      // Success -> thodi der baad close, Receive screen count refresh karega
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context, barcode);
    } else {
      // Fail -> dobara scan allow
      await Future.delayed(const Duration(milliseconds: 1200));
      _retry(null);
    }
  }

  /// Camera resume + timeout restart
  void _retry(String? errorMessage) {
    if (!mounted) return;
    if (errorMessage != null) _showSnackBar(errorMessage, isSuccess: false);
    isScanned = false;
    controller?.resumeCamera();
    _startTimeout();
  }

  // =====================================================
  // UI HELPERS
  // =====================================================

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.department} Receive Scan'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: isFlashOn ? Colors.amber : null,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            overlay: QrScannerOverlayShape(
              borderRadius: 12,
              borderColor: Colors.blue,
              borderWidth: 8,
              borderLength: 24,
            ),
            onQRViewCreated: (ctrl) {
              controller = ctrl;

              controller!.scannedDataStream.listen((scanData) async {
                if (isScanned) return;

                isScanned = true;
                timeoutTimer?.cancel();
                controller!.pauseCamera();

                final barcode = scanData.code?.trim();

                if (barcode != null && barcode.isNotEmpty) {
                  await _processBarcode(barcode);
                } else {
                  _retry('Invalid QR Code');
                }
              });
            },
          ),

          // Info card (plant / issue to / operator / supervisor)


          // Flash button
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              onPressed: _toggleFlash,
              backgroundColor: isFlashOn ? Colors.amber : Colors.blue,
              child: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}