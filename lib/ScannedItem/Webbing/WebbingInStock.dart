
import 'package:IMS/services/GlobalLoader/GloabalUnit.dart';
import 'package:IMS/util/sharedpreference/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Color/Colorclass.dart';
import '../../QRScan/QrScanScreen.dart';
import '../../screen/inStock/ReportScreen.dart';
import '../../screen/inStock/inStockController.dart';
import '../../services/getSupervisors/getSupervisors.dart';
import 'ReportmodelClass/ReportModelClass.dart';
import 'StockDetailsScreen.dart';
import 'WebbingBarcode.dart';
import 'WebbingController.dart';

class WebbingInStock extends StatefulWidget {
  const WebbingInStock({Key? key}) : super(key: key);

  @override
  State<WebbingInStock> createState() => _WebbingInStockState();
}

class _WebbingInStockState extends State<WebbingInStock> {
  late InStockWebController controller;
  late Future<void> _dropdownFuture;

  String _unitTitle = '';
  final String department = 'WEBBING';

  int totalScanned = 0;
  Future<WebbingReportModel?>? _reportFuture;

  bool _isSubmitting = false;

  String getApiDate() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String getCurrentDate() {
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  @override
  void initState() {
    super.initState();

    controller = InStockWebController();
    _dropdownFuture = controller.loadWebInitialData();
    _reportFuture = InStockService.fetchWebbingScannedItems();

    _loadUnit();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _unitTitle = prefs.getString('unit') ?? 'UNIT';
      });
    } catch (e) {
      debugPrint('LOAD UNIT ERROR: $e');
    }
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? Colors.red : C.success,
          content: Text(message),
        ),
      );
  }

  Future<void> _refreshReport() async {
    if (!mounted) return;

    setState(() {
      _reportFuture = InStockService.fetchWebbingScannedItems();
    });

    try {
      await _reportFuture;
    } catch (e) {
      debugPrint('WEBBING REPORT REFRESH ERROR: $e');
    }
  }

  Future<void> _checkBarcodeApi(String barcode) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      _showMessage('Please enter a barcode', isError: true);
      return;
    }

    if (_isSubmitting) {
      debugPrint('Barcode submission already in progress.');
      return;
    }

    // Validate before using nullable dropdown selections.
    if (!controller.isFormValid()) {
      _showMessage(
        'Please select operator, supervisor and storage location.',
        isError: true,
      );
      return;
    }

    final operator = controller.selectedOperator;
    final supervisor = controller.selectedSupervisor;
    final location = controller.selectedLocation;
    final plant = AppGlobals.unit;

    if (operator == null ||
        supervisor == null ||
        location == null ||
        operator.trim().isEmpty ||
        supervisor.trim().isEmpty ||
        location.trim().isEmpty) {
      _showMessage(
        'Please select operator, supervisor and storage location.',
        isError: true,
      );
      return;
    }

    if (plant.trim().isEmpty) {
      _showMessage(
        'Unit is not available. Please login again.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool loaderShown = false;

    try {
      debugPrint('======= CHECK WEBBING BARCODE API =======');
      debugPrint('Barcode: $cleanBarcode');
      debugPrint('Plant: $plant');
      debugPrint('App Unit: ${AppGlobals.unit}');
      debugPrint('Session Unit: ${AppSession.unit}');
      debugPrint('Department: $department');
      debugPrint('Supervisor: $supervisor');
      debugPrint('Operator: $operator');
      debugPrint('Roll Entry: ROLL_ENTRY_1');
      debugPrint('Location: $location');
      debugPrint('=========================================');

      // Show a non-dismissible loader while saving.
      if (!mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      loaderShown = true;

      final response = await InStockService().checkWebbBarcode(
        barcode: cleanBarcode,
        plant: plant,
        department: department,
        supervisor: supervisor,
        operator: operator,
        rollEntry: 'ROLL_ENTRY_1',
        location: location,
      );

      debugPrint('CHECK WEBBING BARCODE RESPONSE: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        _showMessage(
          response['message']?.toString() ??
              'Barcode saved successfully',
        );

        setState(() {
          totalScanned++;
          _reportFuture = InStockService.fetchWebbingScannedItems();
        });
      } else {
        _showMessage(
          response['message']?.toString() ??
              'Barcode could not be saved',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('CHECK WEBBING BARCODE ERROR: $e');
      debugPrint('$stackTrace');

      _showMessage('Unable to save barcode: $e', isError: true);
    } finally {
      if (loaderShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _retryDropdowns() async {
    setState(() {
      _dropdownFuture = controller.loadWebInitialData();
    });

    try {
      await _dropdownFuture;
    } catch (e) {
      debugPrint('WEBBING DROPDOWN RETRY ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: C.primary,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: C.bg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'WEBBING In Stock',
          style: TextStyle(
            color: C.bg,
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: _dropdownFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load dropdown data:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retryDropdowns,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(11),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDropdown(
                      label: 'Choose Operator',
                      value: controller.selectedOperator,
                      items: controller.operators,
                      icon: Icons.person,
                      onChanged: (val) {
                        setState(() {
                          controller.selectedOperator = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Choose Supervisor',
                      value: controller.selectedSupervisor,
                      items: controller.supervisors,
                      icon: Icons.supervisor_account,
                      onChanged: (val) {
                        setState(() {
                          controller.selectedSupervisor = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Choose Storage Location',
                      value: controller.selectedLocation,
                      items: controller.locations,
                      icon: Icons.location_on,
                      onChanged: (val) {
                        setState(() {
                          controller.selectedLocation = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDepartmentCard(),
                    const SizedBox(height: 24),
                    _buildTotalCard(),
                    const SizedBox(height: 20),
                    _buildButtons(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueItems = items.toSet().toList();

    final safeValue =
    value != null && uniqueItems.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _labelStyle()),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeValue,
                    hint: Text(
                      'Select an option',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    isExpanded: true,
                    items: uniqueItems.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDepartmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _iconBox(Icons.business),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEPARTMENT',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  department,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebbingInStockDetailScreen(
              date: getApiDate(),
            ),
          ),
        );
      },
      child: Center(
        child: Container(

          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FutureBuilder<WebbingReportModel?>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  children: [
                    Text(
                      'Total Webbing Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(),
                    ),
                  ],
                );
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return Column(
                  children: [
                    const Text(
                      'Total Webbing Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (snapshot.hasError)
                      Text(
                        'Unable to load report',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _refreshReport,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                );
              }

              final count = snapshot.data!.data.length;

              return Column(
                children: [
                  const Text(
                    'Total Webbing Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    getCurrentDate(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _refreshReport,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.qr_code_scanner,
            label: 'Scan QR',
            color: Colors.blue,
            onTap: _openScanner,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.edit,
            label: 'Manual Entry',
            color: Colors.green,
            onTap: _manualEntry,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _isSubmitting ? null : onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ACTIONS =================

  Future<void> _openScanner() async {
    debugPrint('Operator: ${controller.selectedOperator}');
    debugPrint('Supervisor: ${controller.selectedSupervisor}');
    debugPrint('Location: ${controller.selectedLocation}');

    if (_isSubmitting) return;

    if (!controller.isFormValid()) {
      _showMessage('Please fill all fields', isError: true);
      return;
    }

    final operator = controller.selectedOperator;
    final supervisor = controller.selectedSupervisor;
    final location = controller.selectedLocation;

    if (operator == null || supervisor == null || location == null) {
      _showMessage('Please select all required fields', isError: true);
      return;
    }

    try {
      final scannedBarcode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => WebbingScanScreen(
            operatorName: operator,
            supervisor: supervisor,
            location: location,
            department: department,
            scanType: ScanType.inStock,
          ),
        ),
      );

      if (!mounted || scannedBarcode == null) return;

      await _checkBarcodeApi(scannedBarcode);
    } catch (e, stackTrace) {
      debugPrint('WEBBING SCANNER ERROR: $e');
      debugPrint('$stackTrace');

      _showMessage('Unable to open scanner: $e', isError: true);
    }
  }

  Future<void> _manualEntry() async {
    if (!controller.isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    final barcodeController = TextEditingController();

    String? barcode;

    try {
      barcode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Enter Barcode'),
            content: TextField(
              controller: barcodeController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Enter Barcode'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final enteredBarcode =
                  barcodeController.text.trim();

                  if (enteredBarcode.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a barcode'),
                      ),
                    );
                    return;
                  }

                  // Return the barcode; do not dispose the controller here.
                  Navigator.of(dialogContext).pop(enteredBarcode);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    } finally {
      // Dispose only after the dialog has finished closing.
      barcodeController.dispose();
    }

    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }

    await _checkBarcodeApi(barcode.trim());
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: C.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: C.bg,
      ),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(
      fontSize: 10,
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );
  }
}
