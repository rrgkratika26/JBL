import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Color/Colorclass.dart';
import '../../../screen/inStock/inStockController.dart';
import '../../../services/JBL_apis/jbl_api_bailing_reports.dart';
import '../RecievedScannedItems.dart';
import 'JblRecieveDetailsCreen.dart';

import 'Jbl_ScanBarcode.dart'; // ScanJBLType

import 'scanBarcoddeRecieve.dart';

class JBLRmdReceive extends StatefulWidget {
  const JBLRmdReceive({Key? key}) : super(key: key);

  @override
  State<JBLRmdReceive> createState() => _JBLRmdReceiveState();
}

class _JBLRmdReceiveState extends State<JBLRmdReceive> {
  final controller = InStockController();

  static const String department = 'RMD';

  String? unit; // login unit (plant)
  String? location; // abhi login unit hi hai
  String _unitTitle = '';

  Future<List<ReceiveScannedItem>> _itemsFuture = Future.value(const []);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await controller.load_JBl_InitialData();

    final prefs = await SharedPreferences.getInstance();
    final loginUnit = prefs.getString('unit');

    if (!mounted) return;

    setState(() {
      unit = loginUnit;
      location = loginUnit;
      _unitTitle = loginUnit ?? 'UNIT';
    });

    _refreshItems();
  }

  void _refreshItems() {
    if (unit == null) return;

    setState(() {
      _itemsFuture = JblApiService().fetchReceiveScannedItems(
        plant: unit!,
        date: DateTime.now(),
      );
    });
  }

  String getApiDate() => DateFormat('dd-MMM-yyyy').format(DateTime.now());
  String getCurrentDate() => DateFormat('dd-MM-yyyy').format(DateTime.now());

  // ================= VALIDATION =================

  bool _isFormValid() {
    return controller.selectedOperator != null &&
        controller.selectedSupervisor != null &&
        location != null &&
        unit != null;
  }

  void _showValidationSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill all required fields before scanning QR'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ================= SCAN =================

  Future<void> _openScanner() async {
    if (!_isFormValid()) {
      _showValidationSnackBar();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Jbl_ScanRecieveBarcode(
          operatorName: controller.selectedOperator!,
          supervisor: controller.selectedSupervisor!,
          storage: location!,
          department: department,
          scanType: ScanJBLType.inRmd,
          unit: unit!,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) _refreshItems(); // count + list refresh
  }

  // ================= MANUAL ENTRY =================

  void _showManualDialog() {
    if (!_isFormValid()) {
      _showValidationSnackBar();
      return;
    }

    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manual Entry'),
        content: TextField(
          controller: barcodeController,
          decoration: const InputDecoration(labelText: 'Enter Barcode'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Submit'),
            onPressed: () async {
              final barcode = barcodeController.text.trim();

              if (barcode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid barcode'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              try {
                debugPrint('========== RMD RECEIVE MANUAL ==========');
                debugPrint('Barcode: $barcode | Plant: $unit | IssueTo: $location');

                final result = await JblApiService().processBarcodeRecieveJbl(
                  barcode: barcode,
                  plant: unit!,
                  department: department,
                  issueTo: location!,
                  operatorName: controller.selectedOperator!,
                  supervisor: controller.selectedSupervisor!,
                );

                debugPrint('Manual Entry API Response: $result');

                if (!mounted) return;

                if (result == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server not responding'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final success = result['success'] == true;
                final message =
                    result['message']?.toString() ?? 'Unknown response';

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: success ? Colors.green : Colors.redAccent,
                  ),
                );

                if (success) _refreshItems();
              } catch (e, st) {
                debugPrint('Manual Entry Error: $e\n$st');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.appBar1,
        elevation: 2,
        iconTheme: IconThemeData(color: C.primaryLight),
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: C.primaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'RMD Receive',
              style: TextStyle(
                color: C.primaryLight,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _unitTitle.isNotEmpty ? _unitTitle : 'Unit Name',
              style: TextStyle(
                color: C.primaryDark,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24 : (isSmallScreen ? 12 : 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(
                label: 'Choose an Operator',
                value: controller.selectedOperator,
                items: controller.jbloperators,
                icon: Icons.person,
                isTablet: isTablet,
                isSmallScreen: isSmallScreen,
                onChanged: (v) =>
                    setState(() => controller.selectedOperator = v),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Choose a Supervisor',
                value: controller.selectedSupervisor,
                items: controller.jblsupervisors,
                icon: Icons.supervisor_account,
                isTablet: isTablet,
                isSmallScreen: isSmallScreen,
                onChanged: (v) =>
                    setState(() => controller.selectedSupervisor = v),
              ),
              const SizedBox(height: 16),
              _buildInfoField(
                label: 'LOCATION',
                value: location ?? 'Loading...',
                icon: Icons.place,
                isTablet: isTablet,
                isSmallScreen: isSmallScreen,
              ),
             
              const SizedBox(height: 15),
              _buildInfoField(
                label: 'DEPARTMENT',
                value: department,
                icon: Icons.business,
                isTablet: isTablet,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 15),
              _buildScanningCard(),
              const SizedBox(height: 15),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required bool isTablet,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: _boxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _iconBox(icon),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _labelStyle(isTablet, isSmallScreen)),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: items.contains(value) ? value : null,
                      hint: Text(
                        'Select an option',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      isExpanded: true,
                      items: items
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ))
                          .toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required bool isTablet,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      decoration: _boxDecoration(),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 12 : 16,
      ),
      child: Row(
        children: [
          _iconBox(icon),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _labelStyle(isTablet, isSmallScreen)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 15),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanningCard() {
    return FutureBuilder<List<ReceiveScannedItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        final loading =
            snapshot.connectionState == ConnectionState.waiting;

        final items = snapshot.data ?? const <ReceiveScannedItem>[];

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: loading || snapshot.hasError
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JblReceiveDetailScreen(
                  title: '$department Receive',
                  date: getCurrentDate(),
                  items: items,
                ),
              ),
            );
          },
          child: Center(
            child: Container(

              decoration: _boxDecoration(borderRadius: 20),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Total Items Received',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (loading)
                    const SizedBox(
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    )
                  else if (snapshot.hasError)
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    )
                  else
                    Text(
                      '${items.length}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 4),

                  Text(
                    getCurrentDate(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    loading
                        ? 'Loading received items...'
                        : snapshot.hasError
                        ? 'Unable to load items'
                        : items.isEmpty
                        ? 'No items received today'
                        : 'Tap to view details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  if (snapshot.hasError) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _refreshItems,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.qr_code_scanner,
            label: 'Scan QR',
            color: Colors.blue,
            onTap: _openScanner,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit_note,
            label: 'Manual Entry',
            color: Colors.green,
            onTap: _showManualDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: _boxDecoration(borderRadius: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  TextStyle _labelStyle(bool isTablet, bool isSmallScreen) {
    return TextStyle(
      fontSize: isTablet ? 12 : (isSmallScreen ? 10 : 11),
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );
  }

  BoxDecoration _boxDecoration({double borderRadius = 12}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.blue),
    );
  }
}