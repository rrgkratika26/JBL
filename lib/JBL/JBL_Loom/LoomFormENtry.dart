import 'dart:convert';
import 'dart:math' as math;

import 'package:IMS/JBL/JBL_Loom/modelClass/FIBCmodel.dart';
import 'package:IMS/services/getSupervisors/getSupervisors.dart';
import 'package:IMS/util/sharedpreference/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Color/Colorclass.dart';
import 'SavedListScreenLomm.dart';

/// Marks a grid child that should take the full row.
class _Full extends StatelessWidget {
  final Widget child;
  const _Full(this.child);
  @override
  Widget build(BuildContext context) => child;
}

class LoomForm extends StatefulWidget {
  final ProductionModel production;
  const LoomForm({super.key, required this.production});

  @override
  State<LoomForm> createState() => _LoomFormState();
}

class _LoomFormState extends State<LoomForm> {
  final _formKey = GlobalKey<FormState>();

  // supervisors -> Computer Operator list, operators -> Loom Operator 1 & 2
  List<String> supervisors = [];
  List<String> operators = [];
  List<String> machines = [];
  List<String> machineTypes = []; // Loom No list
  List<String> loomTypes = []; // Loom Type dropdown values
  String? selectedWastageType; // SETTING / WASTAGE
  late TextEditingController wastageCtrl;
  String? selectedSupervisor;
  String? selectedMachine; // Loom Type
  String? selectedBom;
  String? selectedOperator1;
  String? selectedShift;
  String? selectedOperator2;
  String? selectedMachineType; // selected Loom No
  bool isLoading = false;
  bool isSaving = false;
  int? cId;
  String? barcode;

  String unit = "";
  late TextEditingController supervisorNameCtrl;
  late TextEditingController _batchController;
  late TextEditingController _generatedCodeController;
  late TextEditingController articleNoCtrl;
  late TextEditingController partyController;
  late TextEditingController loomOrderController;
  late TextEditingController bomNoController;
  late TextEditingController reqQntyKgController;
  late TextEditingController reqQntyMtrController;
  late TextEditingController loomTypeCtrl;
  late TextEditingController poNoController;
  late TextEditingController loomNoController;
  late TextEditingController fabricController;
  late TextEditingController qtyKgController;
  late TextEditingController qtyMtrController;
  late TextEditingController fabricWidthCtrl;
  late TextEditingController cutTypeCtrl;
  late TextEditingController fabricTypeCtrl;
  late TextEditingController gsmCtrl;
  late TextEditingController laminationCtrl;
  late TextEditingController colorCtrl;
  late TextEditingController sidCtrl;
  late TextEditingController baffleCtrl;
  late TextEditingController meshCtrl;
  late TextEditingController loomStartCtrl;
  late TextEditingController loomEndCtrl;
  late TextEditingController remarkCtrl;
  late TextEditingController grossWeightCtrl;
  late TextEditingController tareWeightCtrl;
  late TextEditingController netWeightCtrl;
  late TextEditingController rollLengthCtrl;
  late TextEditingController avgWeightMtrCtrl;
  late TextEditingController avgWeightMtrGmCtrl;

  // ── Responsive helpers (MediaQuery) ─────────────────────────
  static const double _maxContentW = 1000;
  static const double _gap = 12;
  static const double _sectionPad = 14;

  double get _screenW => MediaQuery.sizeOf(context).width;
  bool get _isMobile => _screenW < 600;
  bool get _isTablet => _screenW >= 600 && _screenW < 1024;
  double get _hPad => _isMobile ? 12 : (_isTablet ? 20 : 32);
  double get _contentW => math.min(_screenW, _maxContentW);

  @override
  void initState() {
    super.initState();
    final data = widget.production;
    wastageCtrl = TextEditingController();
    supervisorNameCtrl = TextEditingController(text: "ADMIN");
    _batchController = TextEditingController();
    _generatedCodeController = TextEditingController();
    partyController = TextEditingController(text: data.partyName);
    loomOrderController = TextEditingController(text: data.orderNo.toString());
    bomNoController = TextEditingController(text: data.bomNo);
    reqQntyKgController = TextEditingController(
      text: data.balanceKgInt.toString(),
    );
    reqQntyMtrController = TextEditingController(
      text: data.balanceMtrInt.toString(),
    );
    loomTypeCtrl = TextEditingController();
    poNoController = TextEditingController(text: data.poNumber.toString());
    fabricController = TextEditingController(text: data.fabricCode);
    loomNoController = TextEditingController();
    articleNoCtrl = TextEditingController(text: data.articleNo.toString());
    qtyKgController = TextEditingController(
      text: data.actualRequiredKg.toString(),
    );
    qtyMtrController = TextEditingController(
      text: data.actualRequiredMtr.toString(),
    );
    fabricWidthCtrl = TextEditingController();
    cutTypeCtrl = TextEditingController();
    fabricTypeCtrl = TextEditingController();
    gsmCtrl = TextEditingController();
    laminationCtrl = TextEditingController();
    colorCtrl = TextEditingController();
    sidCtrl = TextEditingController();
    baffleCtrl = TextEditingController();
    meshCtrl = TextEditingController();
    remarkCtrl = TextEditingController();
    loomStartCtrl = TextEditingController();
    loomEndCtrl = TextEditingController();
    grossWeightCtrl = TextEditingController();
    tareWeightCtrl = TextEditingController();
    netWeightCtrl = TextEditingController();
    rollLengthCtrl = TextEditingController();
    avgWeightMtrCtrl = TextEditingController();
    avgWeightMtrGmCtrl = TextEditingController();

    grossWeightCtrl.addListener(_calculateValues);
    tareWeightCtrl.addListener(_calculateValues);
    rollLengthCtrl.addListener(_calculateValues);
    fabricWidthCtrl.addListener(_calculateValues);

    _parseFabricCode(data.fabricCode);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    await _loadUnit();
    await Future.wait([
      _loadPersonDropdowns(),
      _loadLoomNos(),
      _fetchNextCid(),
    ]);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  // ── APIs (unchanged) ────────────────────────────────────────
  Future<List<String>> _fetchDropdown(String type) async {
    final url = Uri.parse(
      "${InStockService.baseUrl}/Loom/GetDropdown?type=$type",
    );
    try {
      final res = await http.get(
        url,
        headers: await InStockService.authHeaders(),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == true) {
          return (json['data'] as List)
              .map((e) => e['value'].toString())
              .toList();
        }
      } else {
        debugPrint("❌ Dropdown ($type) status: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("❌ Dropdown ($type) error: $e");
    }
    return [];
  }

  Future<void> _loadPersonDropdowns() async {
    final results = await Future.wait([
      _fetchDropdown('supervisor'),
      _fetchDropdown('operator'),
    ]);
    if (!mounted) return;
    setState(() {
      supervisors = results[0];
      operators = results[1];
    });
  }

  Future<void> _fetchNextCid() async {
    final url = Uri.parse("${InStockService.baseUrl}/LoomForward/next-cid");
    try {
      final res = await http.get(
        url,
        headers: await InStockService.authHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          cId = data['cId'];
          barcode = data['barcode'];
        });
      }
    } catch (e) {
      debugPrint("❌ CID API ERROR: $e");
    }
  }

  Future<void> _fetchLoomReading() async {
    if (selectedMachineType == null || selectedMachine == null) {
      debugPrint("⚠️ Select Loom No and Loom Type first");
      return;
    }

    final url = Uri.parse(
      "${InStockService.baseUrl}/Loom/GetReading"
      "?machine=${Uri.encodeComponent(selectedMachineType!.trim())}"
      "&loomType=${Uri.encodeComponent(selectedMachine!.trim())}",
    );

    try {
      debugPrint("👉 GET READING URL: $url");

      final res = await http.get(
        url,
        headers: await InStockService.authHeaders(),
      );

      debugPrint("👉 GET READING STATUS: ${res.statusCode}");
      debugPrint("👉 GET READING RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (!mounted) return;

        setState(() {
          final reading = data['startReading'];

          loomStartCtrl.text = reading != null ? reading.toString() : "";

          debugPrint("✅ Loom Starting Reading: ${loomStartCtrl.text}");
          debugPrint("✅ Loom Capacity: ${data['capacity']}");
          debugPrint("✅ Loom Rate: ${data['rate']}");
        });
      } else {
        debugPrint("❌ GetReading API Error: ${res.statusCode} - ${res.body}");

        if (mounted) {
          _toast(
            "Failed to fetch Loom Starting: ${res.statusCode}",
            error: true,
          );
        }
      }
    } catch (e, stack) {
      debugPrint("❌ GetReading Exception: $e\n$stack");
    }
  }

  Future<void> _loadLoomNos() async {
    final url = Uri.parse(
      "${InStockService.baseUrl}/Loom/GetLoomNo?unit=${Uri.encodeComponent(unit)}",
    );
    try {
      final res = await http.get(
        url,
        headers: await InStockService.authHeaders(),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == true) {
          final list = (json['data'] as List)
              .map((e) => e['loomNo'])
              .where((e) => e != null && e.toString().isNotEmpty)
              .map((e) => e.toString())
              .toList();
          if (!mounted) return;
          setState(() => machineTypes = list);
        }
      } else {
        debugPrint("❌ GetLoomNo ${res.statusCode}: ${res.body}");
      }
    } catch (e) {
      debugPrint("❌ GetLoomNo error: $e");
    }
  }

  Future<void> _fetchLoomType(String loomNo) async {
    final url = Uri.parse(
      "${InStockService.baseUrl}/Loom/GetLoomType"
      "?loomNo=${Uri.encodeComponent(loomNo)}"
      "&unit=${Uri.encodeComponent(unit)}",
    );

    try {
      debugPrint("👉 GET LOOM TYPE URL: $url");

      final res = await http.get(
        url,
        headers: await InStockService.authHeaders(),
      );

      debugPrint("👉 GET LOOM TYPE STATUS: ${res.statusCode}");
      debugPrint("👉 GET LOOM TYPE RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        if (json['status'] == true) {
          final types = (json['data'] as List)
              .map((e) => e['loomType'])
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .map((e) => e.toString().trim())
              .toSet()
              .toList();

          if (!mounted) return;

          setState(() {
            loomTypes = types;
            selectedMachine = null;
            loomTypeCtrl.clear();
            loomStartCtrl.clear();
          });

          debugPrint("✅ Available Loom Types: $loomTypes");
        } else {
          if (!mounted) return;

          setState(() {
            loomTypes = [];
            selectedMachine = null;
            loomTypeCtrl.clear();
          });

          debugPrint("⚠️ GetLoomType API returned status false");
        }
      } else {
        debugPrint("❌ GetLoomType Error: ${res.statusCode} ${res.body}");
      }
    } catch (e, stack) {
      debugPrint("❌ GetLoomType Exception: $e\n$stack");
    }
  }

  Future<void> _loadUnit() async {
    final savedUnit = await AppSession.getUnit();
    if (!mounted) return;
    setState(() => unit = savedUnit ?? "");
  }

  // ── Logic ───────────────────────────────────────────────────
  void _parseFabricCode(String code) {
    final parts = code.split('-');
    if (parts.length >= 8) {
      fabricWidthCtrl.text = parts[0];
      cutTypeCtrl.text = parts[1];
      fabricTypeCtrl.text = parts[2];
      gsmCtrl.text = parts[3];
      laminationCtrl.text = 'UL';
      colorCtrl.text = parts[5];
      sidCtrl.text = parts[6];
      baffleCtrl.text = parts[7];
    }
  }

  String _generateBatchNumber() {
    final party = partyController.text.trim();
    final shift = selectedShift ?? '';
    final now = DateTime.now();
    final date = now.day.toString();
    final month = now.month.toString().padLeft(2, '0');
    final partyCode = party.length >= 3
        ? party.substring(0, 3).toUpperCase()
        : party.toUpperCase();
    return "$partyCode$date$month${shift}LO";
  }

  void _generateCodes({bool silent = false}) {
    if (selectedMachine == null || selectedMachineType == null) {
      if (!silent) _toast("select Loom No first", error: true);
      return;
    }
    final batch = _generateBatchNumber();
    final code =
        "${fabricWidthCtrl.text}"
        "-${cutTypeCtrl.text}"
"-${fabricTypeCtrl.text}"
        "-${gsmCtrl.text}"
        "-${laminationCtrl.text}"
        "-${colorCtrl.text}"
        "-${sidCtrl.text}"
        "-${baffleCtrl.text}";
    setState(() {
      _batchController.text = batch;
      _generatedCodeController.text = code;
    });
  }

  void _calculateValues() {
    final gross = double.tryParse(grossWeightCtrl.text) ?? 0;
    final tare = double.tryParse(tareWeightCtrl.text) ?? 0;
    final roll = double.tryParse(rollLengthCtrl.text) ?? 0;
    final width = (double.tryParse(fabricWidthCtrl.text)) ?? 0;

    // Net Weight = Gross Weight - Tare Weight
    final net = gross - tare;
    netWeightCtrl.text = net.toStringAsFixed(2);

    final avgMtr = roll > 0 ? (net / roll) * 1000 : 0.0;
    avgWeightMtrCtrl.text = avgMtr.toStringAsFixed(2);

    final type = cutTypeCtrl.text.trim().toUpperCase();

    double result = 0.0;

    if (width > 0) {
      if (type.startsWith('F')) {
        // F ya koi bhi doosra type
        result = (avgMtr / width)*100;
      } else {
        // Type ka first letter C ya koi or
        result = ((avgMtr / width) / 2) * 100;
      }
    }

    avgWeightMtrGmCtrl.text = result.toStringAsFixed(2);
  }


  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: error ? Colors.red.shade700 : C.success,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(_hPad, 0, _hPad, 90),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  Future<void> _saveForm() async {
    if (isSaving) return;

    FocusScope.of(context).unfocus();

    // Validate required fields
    if (!(_formKey.currentState?.validate() ?? false)) {
      _toast("Please fill all required fields.", error: true);
      return;
    }

    if (_batchController.text.isEmpty) {
      _generateCodes(silent: true);
    }

    final url = Uri.parse(
      "${InStockService.baseUrl}/Loom/SaveLoomEntry",
    );

    final body = {
      "machine": selectedMachineType,
      "operator1": selectedOperator1,
      "operator2": selectedOperator2 ?? selectedOperator1,
      "orderNo": partyController.text,
      "generateCode": _generatedCodeController.text,
      "supervisor": supervisorNameCtrl.text,
      "specialId": sidCtrl.text,
      "fabricType": fabricTypeCtrl.text,
      "fabricWidth": fabricWidthCtrl.text,
      "color": colorCtrl.text,
      "lamination": laminationCtrl.text,
      "gsm": gsmCtrl.text,
      "cutType": cutTypeCtrl.text,
      "buffle": baffleCtrl.text,
      "netWeight": netWeightCtrl.text,
      "rollLength": rollLengthCtrl.text,
      "remark": remarkCtrl.text,
      "workOrder": partyController.text,
      "reqQtyKg": reqQntyKgController.text,
      "reqQtyMtr": qtyMtrController.text,
      "loomNo": selectedMachine,
      "grossWeight": grossWeightCtrl.text,
      "mesh": meshCtrl.text,
      "avgWeight": avgWeightMtrCtrl.text,
      "production_type": "FIBC",
      "partyName": loomOrderController.text,
      "tareWeight": tareWeightCtrl.text,
      "avgWeightGM": avgWeightMtrGmCtrl.text,
      "requiredFabric": fabricController.text,
      "loomStartReading": loomStartCtrl.text,
      "loomEndReading": loomEndCtrl.text,
      "setting": selectedWastageType,
      "wastage": wastageCtrl.text,
      "planningWeek": tareWeightCtrl.text,
      "requiredKg": double.tryParse(reqQntyKgController.text) ?? 0,
      "requiredMtr": double.tryParse(qtyMtrController.text) ?? 0,
      "unit": unit,
    };

    setState(() => isSaving = true);

    try {
      debugPrint("SAVE LOOM URL: $url");
      debugPrint("SAVE LOOM BODY: ${jsonEncode(body)}");

      final res = await http.post(
        url,
        headers: {
          ...await InStockService.authHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint("SAVE LOOM STATUS: ${res.statusCode}");
      debugPrint("SAVE LOOM RESPONSE: ${res.body}");

      if (!mounted) return;

      // Handle HTTP errors
      if (res.statusCode < 200 || res.statusCode >= 300) {
        String message = "Failed to save. HTTP ${res.statusCode}";

        try {
          final errorData = jsonDecode(res.body);
          if (errorData is Map) {
            message = errorData['message']?.toString() ??
                errorData['error']?.toString() ??
                message;
          }
        } catch (_) {
          if (res.body.trim().isNotEmpty) {
            message = "$message: ${res.body}";
          }
        }

        _toast(message, error: true);
        return;
      }

      // Handle empty or invalid JSON response
      dynamic responseData;

      try {
        if (res.body.trim().isEmpty) {
          _toast("Save failed: Server returned an empty response.",
              error: true);
          return;
        }

        responseData = jsonDecode(res.body);
      } catch (e) {
        _toast("Save failed: Invalid server response.", error: true);
        debugPrint("LOOM RESPONSE JSON ERROR: $e");
        return;
      }

      if (responseData is! Map) {
        _toast("Save failed: Unexpected server response.", error: true);
        return;
      }

      final bool status = responseData['status'] == true;

      final String message =
          responseData['message']?.toString() ??
              (status ? "Data saved successfully." : "Failed to save data.");

      // API may return HTTP 200 but status false
      if (!status) {
        _toast(message, error: true);
        return;
      }

      final responseDetails = responseData['data'];
      final savedBarcode = responseDetails is Map
          ? responseDetails['barcode']?.toString() ?? ''
          : '';

      _toast(
        savedBarcode.isNotEmpty
            ? "$message\nBarcode: $savedBarcode"
            : message,
      );

      // Navigate only after successful save
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SavedListScreen(),
        ),
      );
    } catch (e, stack) {
      debugPrint("LOOM SAVE EXCEPTION: $e\n$stack");

      if (mounted) {
        _toast("Save failed: $e", error: true);
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }


  // Future<void> _saveForm() async {
  //   if (isSaving) return;
  //   FocusScope.of(context).unfocus();
  //
  //   if (!(_formKey.currentState?.validate() ?? false)) {
  //     _toast("fill the fields", error: true);
  //     return;
  //   }
  //   if (_batchController.text.isEmpty) _generateCodes(silent: true);
  //
  //   final url = Uri.parse("${InStockService.baseUrl}/Loom/SaveLoomEntry");
  //
  //   final body = {
  //     "machine": selectedMachineType,
  //     "operator1": selectedOperator1,
  //     "operator2": selectedOperator2 ?? selectedOperator1,
  //
  //     // Old boM_NO -> new orderNo (confirm whether BOM/order number is expected)
  //     "orderNo": partyController.text,
  //
  //     // TODO: map generateCode to the correct generated-code variable
  //     "generateCode": _generatedCodeController.text,
  //
  //     "supervisor": supervisorNameCtrl.text,
  //
  //     // Old sid -> specialId
  //     "specialId": sidCtrl.text,
  //
  //     // Old typeUse -> fabricType
  //     "fabricType": fabricTypeCtrl.text,
  //
  //     "fabricWidth": fabricWidthCtrl.text,
  //     "color": colorCtrl.text,
  //     "lamination": laminationCtrl.text,
  //     "gsm": gsmCtrl.text,
  //     "cutType": cutTypeCtrl.text,
  //
  //     // Old buffie -> buffle (API spelling)
  //     "buffle": baffleCtrl.text,
  //
  //     // New API expects strings
  //     "netWeight": netWeightCtrl.text,
  //
  //     // Old quantity -> rollLength
  //     "rollLength": rollLengthCtrl.text,
  //
  //     "remark": remarkCtrl.text,
  //
  //     // Old workOrderNo -> workOrder
  //     "workOrder": partyController.text,
  //
  //     // Old requiredNetWt -> reqQtyKg
  //     "reqQtyKg": reqQntyKgController.text,
  //
  //     // Old requiredQtyMtr -> reqQtyMtr
  //     "reqQtyMtr": qtyMtrController.text,
  //
  //     // Old machineNo -> loomNo (confirm this mapping)
  //     "loomNo": selectedMachine,
  //
  //     // TODO: map grossWeight to its correct controller
  //     "grossWeight": grossWeightCtrl.text,
  //
  //     // Old rmdSupervisor -> mesh
  //     "mesh": meshCtrl.text,
  //
  //     // TODO: map avgWeight to its correct controller
  //     "avgWeight": avgWeightMtrCtrl.text,
  //
  //     // TODO: map production_type to the correct production type value
  //     "production_type": "FIBC",
  //
  //     "partyName": loomOrderController.text,
  //
  //     // Old weekNo -> tareWeight (confirm this mapping)
  //     "tareWeight": tareWeightCtrl.text,
  //
  //     // Old stateName -> avgWeightGM (confirm this mapping)
  //     "avgWeightGM": avgWeightMtrGmCtrl.text,
  //
  //     // TODO: map requiredFabric to the correct controller/value
  //     "requiredFabric": fabricController.text,
  //
  //     // TODO: map loomStartReading to the correct controller
  //     "loomStartReading": loomStartCtrl.text,
  //
  //     // TODO: map loomEndReading to the correct controller
  //     "loomEndReading": loomEndCtrl.text,
  //
  //     // TODO: map setting to the correct controller/value
  //     "setting": selectedWastageType,
  //
  //     // TODO: map wastage to the correct controller/value
  //     "wastage": wastageCtrl.text,
  //
  //     "planningWeek": tareWeightCtrl.text,
  //
  //     // New API expects numeric values here
  //     "requiredKg": double.tryParse(reqQntyKgController.text) ?? 0,
  //     "requiredMtr": double.tryParse(qtyMtrController.text) ?? 0,
  //
  //     // Old plant1/plant2 -> unit
  //     "unit": unit,
  //   };
  //
  //   setState(() => isSaving = true);
  //   try {
  //     debugPrint("👉 URL: $url");
  //     debugPrint("👉 BODY: ${jsonEncode(body)}");
  //
  //     final res = await http.post(
  //       url,
  //       headers: await InStockService.authHeaders(),
  //       body: jsonEncode(body),
  //     );
  //
  //     debugPrint("👉 STATUS: ${res.statusCode} | ${res.body}");
  //
  //     if (!mounted) return;
  //
  //     if (res.statusCode == 200) {
  //       final responseData = jsonDecode(res.body);
  //
  //       final status = responseData['status'] == true;
  //       final message =
  //           responseData['message']?.toString() ?? 'Data Saved Successfully';
  //
  //       final responseDetails = responseData['data'];
  //       final savedBarcode = responseDetails is Map
  //           ? responseDetails['barcode']?.toString() ?? ''
  //           : '';
  //
  //       if (status) {
  //         // Show success message with barcode
  //         _toast(
  //           savedBarcode.isNotEmpty
  //               ? '$message\nBarcode: $savedBarcode'
  //               : message,
  //         );
  //
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => SavedListScreen()),
  //         );
  //       } else {
  //         _toast(message, error: true);
  //       }
  //     } else {
  //       _toast(
  //         "Error ${res.statusCode}: ${res.body}",
  //         error: true,
  //       );
  //     }
  //   } catch (e, stack) {
  //     debugPrint("❌ EXCEPTION: $e\n$stack");
  //     if (mounted) _toast("Exception: $e", error: true);
  //   } finally {
  //     if (mounted) setState(() => isSaving = false);
  //   }
  // }

  @override
  void dispose() {
    for (final c in [
      supervisorNameCtrl,
      _batchController,
      _generatedCodeController,
      loomTypeCtrl,
      articleNoCtrl,
      partyController,
      loomOrderController,
      bomNoController,
      reqQntyKgController,
      reqQntyMtrController,
      poNoController,
      loomNoController,
      fabricController,
      qtyKgController,
      qtyMtrController,
      fabricWidthCtrl,
      cutTypeCtrl,
      fabricTypeCtrl,
      gsmCtrl,
      laminationCtrl,
      colorCtrl,
      sidCtrl,
      baffleCtrl,
      meshCtrl,
      loomStartCtrl,
      loomEndCtrl,
      remarkCtrl,
      grossWeightCtrl,
      tareWeightCtrl,
      netWeightCtrl,
      rollLengthCtrl,
      avgWeightMtrCtrl,
      avgWeightMtrGmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // tap outside = keyboard hide
      child: Scaffold(
        backgroundColor: C.pageBg,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _buildHeader(context),
            if (isLoading)
              LinearProgressIndicator(minHeight: 3, color: C.brand600),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentW),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: _hPad,
                        vertical: 14,
                      ),
                      children: [
                        _buildSection(
                          icon: Icons.person_outline_rounded,
                          title: "General Info",
                          children: [
                            _grid([
                              _Full(
                                _dropdown(
                                  label: "Computer Operator *",
                                  value: selectedSupervisor,
                                  items: supervisors,
                                  required: true,
                                  onChanged: (v) =>
                                      setState(() => selectedSupervisor = v),
                                ),
                              ),

                              // Fixed Supervisor Name
                              _Full(
                                _field(
                                  "Supervisor Name",
                                  controller: supervisorNameCtrl,
                                  readOnly: true,
                                ),
                              ),

                              _Full(
                                _field(
                                  "Party Name",
                                  controller: loomOrderController,
                                  readOnly: true,
                                ),
                              ),

                              _field(
                                "BOM No",
                                controller: partyController,
                                readOnly: true,
                              ),

                              _field(
                                "WO No",
                                controller: partyController,
                                readOnly: true,
                              ),

                              // _dropdown(
                              //   label: "Shift *",
                              //   value: selectedShift,
                              //   items: const ['A', 'B', 'C'],
                              //   required: true,
                              //   onChanged: (v) {
                              //     setState(() => selectedShift = v);
                              //     _generateCodes(silent: true);
                              //   },
                              // ),
                            ], mobileCols: 2),
                          ],
                        ),
                        _buildSection(
                          icon: Icons.precision_manufacturing_outlined,
                          title: "Loom & Operators",
                          children: [
                            _grid([
                              _dropdown(
                                label: "Loom Type *",
                                value: selectedMachineType,
                                items: machineTypes,
                                required: true,
                                onChanged: (val) async {
                                  setState(() {
                                    selectedMachineType = val;
                                    selectedMachine = null;
                                    loomTypes = [];
                                    loomTypeCtrl.clear();
                                    loomStartCtrl.clear();
                                  });

                                  if (val == null) return;

                                  // Fetch available Loom Types for the selected Loom No.
                                  await _fetchLoomType(val);

                                  _generateCodes(silent: true);
                                },
                              ),

                              _dropdown(
                                label: "Loom No *",
                                value: selectedMachine,
                                items: loomTypes,
                                required: true,
                                onChanged: (val) async {
                                  setState(() {
                                    selectedMachine = val;
                                    loomTypeCtrl.text = val ?? "";
                                    loomStartCtrl.clear();
                                  });

                                  if (val == null) return;

                                  // Fetch the start reading for the selected Loom No + Loom Type.
                                  await _fetchLoomReading();

                                  _generateCodes(silent: true);
                                },
                              ),
                              _dropdown(
                                label: "Loom Operator 1 *",
                                value: selectedOperator1,
                                items: operators,
                                required: true,
                                onChanged: (v) =>
                                    setState(() => selectedOperator1 = v),
                              ),
                              _dropdown(
                                label: "Loom Operator 2",
                                value: selectedOperator2,
                                items: operators,
                                onChanged: (v) =>
                                    setState(() => selectedOperator2 = v),
                              ),
                            ]),
                          ],
                        ),
                        _buildSection(
                          icon: Icons.layers_outlined,
                          title: "Fabric Details",
                          children: [
                            _grid([
                              _Full(
                                _field(
                                  "Required Fabric",
                                  controller: fabricController,
                                  readOnly: true,
                                ),
                              ),
                              _field(
                                "Fabric Width",
                                controller: fabricWidthCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "Fabric Baffle/Type",
                                controller: cutTypeCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "Fabric Type/Use",
                                controller: fabricTypeCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "Fabric GSM",
                                controller: gsmCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "Fabric Width(cm)",
                                controller: gsmCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "Lamination",
                                controller: laminationCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "Color(WARP/WEFT)",
                                controller: colorCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "CUT TYPE",
                                controller: sidCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "SID",
                                controller: baffleCtrl,
                                readOnly: true,
                              ),
                              _field("Mesh", controller: meshCtrl),
                            ], mobileCols: 2),
                          ],
                        ),
                        _buildSection(
                          icon: Icons.monitor_weight_outlined,
                          title: "Weights & Measures",
                          children: [
                            _grid([
                              _field(
                                "Required Quantity (Kg)",
                                controller: reqQntyKgController,
                                readOnly: true,
                                suffix: "kg",
                              ),
                              _field(
                                "Required Quantity (Mtr)",
                                controller: reqQntyMtrController,
                                readOnly: true,
                                suffix: "mtr",
                              ),
                              _field(
                                "Gross Weight",
                                controller: grossWeightCtrl,
                                numeric: true,
                                suffix: "kg",
                              ),
                              _field(
                                "Tare Weight",
                                controller: tareWeightCtrl,
                                numeric: true,
                                suffix: "kg",
                              ),
                              _field(
                                "Net Weight",
                                controller: netWeightCtrl,
                                readOnly: true,
                                suffix: "kg",
                              ),
                              _field(
                                "Roll Length",
                                controller: rollLengthCtrl,
                                numeric: true,
                                suffix: "mtr",
                              ),
                              _field(
                                "Avg Wt (Mtr)",
                                controller: avgWeightMtrCtrl,
                                readOnly: true,
                              ),
                              _field(
                                "Avg Wt (GSM)",
                                controller: avgWeightMtrGmCtrl,
                                readOnly: true,
                              ),
                            ], mobileCols: 2),
                          ],
                        ),

                        _buildSection(
                          icon: Icons.qr_code_2_rounded,
                          title: "Batch & Code",
                          children: [
                            _grid([
                              _dropdown(
                                label: "Wastage Type",
                                value: selectedWastageType,
                                items: const ['SETTING', 'WASTAGE'],
                                onChanged: (v) =>
                                    setState(() => selectedWastageType = v),
                              ),
                              _field(
                                "Wastage",
                                controller: wastageCtrl,
                                numeric: true,
                                suffix: "kg",
                              ),
                              _field(
                                "Generated Code",
                                controller: _generatedCodeController,
                                readOnly: true,
                              ),
                              _Full(
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _generateCodes,
                                    icon: Icon(
                                      Icons.auto_fix_high,
                                      size: 18,
                                      color: C.brand700,
                                    ),
                                    label: Text(
                                      "Generate Code",
                                      style: TextStyle(
                                        color: C.brand700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: C.brand600,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                        _buildSection(
                          icon: Icons.more_horiz_rounded,
                          title: "Other Details",
                          children: [
                            _grid([
                              _field(
                                "Loom Starting",
                                controller: loomStartCtrl,
                                numeric: true,
                              ),
                              _field(
                                "Loom Ending",
                                controller: loomEndCtrl,
                                numeric: true,
                              ),
                              _Full(
                                _field(
                                  "Remark",
                                  controller: remarkCtrl,
                                  maxLines: 3,
                                ),
                              ),
                            ], mobileCols: 2),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  // ── Responsive grid: 1/2 cols mobile, 2 cols tablet, 3 cols desktop ──
  Widget _grid(List<Widget> children, {int mobileCols = 1}) {
    final cols = _isMobile ? mobileCols : (_isTablet ? 2 : 3);
    final available = _contentW - (_hPad * 2) - (_sectionPad * 2) - 2;
    final itemW = ((available - _gap * (cols - 1)) / cols).floorToDouble();

    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: children.map((c) {
        final full = c is _Full;
        return SizedBox(width: full ? available : itemW, child: c);
      }).toList(),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Container(
      color: C.appBar1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(_hPad - 4, 8, _hPad, 14),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: "Back",
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Loom Entry Form",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isMobile ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.factory_outlined,
                            color: Colors.white70,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              unit,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _isMobile
                  ? IconButton.filledTonal(
                      onPressed: _openSavedList,
                      icon: const Icon(Icons.list_alt_rounded),
                      tooltip: "Saved List",
                    )
                  : ElevatedButton.icon(
                      onPressed: _openSavedList,
                      icon: Icon(
                        Icons.list_alt_rounded,
                        size: 16,
                        color: C.primaryDark,
                      ),
                      label: Text(
                        "Saved List",
                        style: TextStyle(
                          color: C.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.border,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSavedList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SavedListScreen()),
    );
  }

  // ── Section Card ────────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: C.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.borderLight),
        boxShadow: [
          BoxShadow(
            color: C.brand500.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: C.brand50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: C.borderLight)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: C.brand700.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: C.brand700),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: C.textHigh,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(_sectionPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ── Field ───────────────────────────────────────────────────
  InputDecoration _decoration(
    String label, {
    bool readOnly = false,
    String? suffix,
  }) {
    final radius = BorderRadius.circular(10);
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      isDense: true,
      filled: true,
      fillColor: readOnly ? const Color(0xFFF1F3F5) : C.brand50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: C.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: C.brand600, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.6),
      ),
    );
  }

  Widget _field(
    String label, {
    TextEditingController? controller,
    int maxLines = 1,
    bool readOnly = false,
    bool numeric = false,
    String? suffix,
  }) {
    final isMultiline = maxLines > 1;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,

      // Multiline field ke liye multiline keyboard
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : isMultiline
          ? TextInputType.multiline
          : TextInputType.text,

      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,

      // Remark mein Enter se new line; normal fields mein Next
      textInputAction: isMultiline
          ? TextInputAction.newline
          : TextInputAction.next,

      style: TextStyle(
        fontSize: 14,
        color: readOnly ? Colors.black54 : C.textHigh,
        fontWeight: FontWeight.w500,
      ),

      decoration: _decoration(label, readOnly: readOnly, suffix: suffix),
    );
  }

  static const String _clearToken = '__CLEAR__';

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    final cleanLabel = label.replaceAll('*', '').trim();

    return FormField<String>(
      // key change hone par field value ke saath sync ho jata hai
      key: ValueKey('$label|$value|${items.length}'),
      initialValue: value,
      validator: required ? (v) => v == null ? "Required" : null : null,
      builder: (state) {
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            FocusScope.of(context).unfocus();
            final picked = await _showPicker(
              title: cleanLabel,
              items: items,
              selected: value,
              allowClear: !required,
            );
            if (picked == null) return;
            final newVal = picked == _clearToken ? null : picked;
            state.didChange(newVal);
            onChanged(newVal);
          },
          child: InputDecorator(
            isEmpty: value == null,
            decoration: _decoration(label).copyWith(
              errorText: state.errorText,
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: C.brand700,
              ),
            ),
            child: value == null
                ? const SizedBox.shrink()
                : Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: C.textHigh,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<String?> _showPicker({
    required String title,
    required List<String> items,
    required String? selected,
    bool allowClear = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: C.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final filtered = items
                .where((e) => e.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Select $title",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: C.textHigh,
                              ),
                            ),
                          ),
                          if (allowClear && selected != null)
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, _clearToken),
                              child: const Text("Clear"),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    if (items.length > 6)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: TextField(
                          autofocus: false,
                          onChanged: (v) => setSheet(() => query = v),
                          decoration: _decoration("Search").copyWith(
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                items.isEmpty
                                    ? "No options available"
                                    : "No match found",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: C.borderLight),
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                final isSel = item == selected;
                                return ListTile(
                                  minTileHeight: 52,
                                  tileColor: isSel
                                      ? C.brand50
                                      : Colors.transparent,
                                  title: Text(
                                    item,
                                    style: TextStyle(
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSel ? C.brand700 : C.textHigh,
                                    ),
                                  ),
                                  trailing: isSel
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: C.brand700,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(ctx, item),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Sticky bottom action bar ────────────────────────────────
  Widget _buildActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: C.cardBg,
        border: Border(top: BorderSide(color: C.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentW),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _hPad, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: _isMobile ? 3 : 2,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveForm,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                      label: Text(
                        isSaving ? "Saving..." : "Save Form",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.brand700,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
