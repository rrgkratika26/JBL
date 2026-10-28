import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Color/Colorclass.dart';
import '../../services/JBL_apis/jbl_api_bailing_reports.dart';
import '../../services/getSupervisors/getSupervisors.dart';
import 'ModelClass/WorkOrderModel.dart';
import 'ModelClass/cuttingOutStockJbl.dart';
import 'SearchableDropdown.dart';

class CuttingOutStockFormJbl extends StatefulWidget {
  final CuttingOutstockJbl production;

  /// Optional: WO change hone par parent ko notify
  final ValueChanged<String>? onWorkOrderChanged;

  const CuttingOutStockFormJbl({
    super.key,
    required this.production,
    this.onWorkOrderChanged,
  });

  @override
  State<CuttingOutStockFormJbl> createState() => _CuttingOutStockFormJblState();
}

class _CuttingOutStockFormJblState extends State<CuttingOutStockFormJbl> {
  static const _gap = SizedBox(height: 14);
  static const _red = Color(0xFFD32F2F);

  /// Bottom sheet ki fields ke error keys
  static const _sheetKeys = {'net', 'qty', 'wastage', 'cutW', 'cutL'};

  // ── Toggles (bottom sheet me) ──
  bool _withWorkOrder = true;
  bool _rollFinish = false;
  bool _loadingCutSize = false;
  bool _isCutLengthEnabled = true;

  // ── Sheet state ──
  bool _sheetOpen = false;
  StateSetter? _sheetSetState;

  // ── Validation ──
  final Set<String> _touched = {};
  Map<String, String> _errors = {};
  bool _isSaving = false;

  // ── Code / Batch ──
  bool _codeGenerated = false;

  // ── WO / Inquiry / Component ──
  WorkOrderOption? _selectedWo;
  List<String> _inquiryList = [];
  String? _selectedInquiry;
  String? _selectedComponent;
  bool _loadingInquiry = false;
  String? _inquiryError;

  // ── Operator / Supervisor ──
  List<String> _operators = [];
  List<String> _supervisors = [];
  final JblApiService _apiService = JblApiService();
  String? _selectedOperator;
  String? _selectedSupervisor;
  bool _loadingOperators = false;
  bool _loadingSupervisors = false;

  // ── Machine ──
  final List<String> _machineNumbers = ['1', '2', '3', '4'];
  String? _selectedMachineNo;

  // ── Lamination ──
  final List<String> _extraLaminationTypes = [
    'H',
    'L',
    'LL',
    'Sl',
    'Ul',
    'LAMINATEED',
    'LAMI-1',
  ];
  List<String> _laminationTypes = [];
  String? _selectedLaminationType;
  // ── Required Quantity from previous screen ──
  final TextEditingController _reqQtyKgCtrl = TextEditingController();
  final TextEditingController _reqQtyMtrCtrl = TextEditingController();
  // ── Till Remaining Weight ──
  final TextEditingController _tillRemainingCtrl = TextEditingController();
  bool _loadingTillRemaining = false;
  String? _tillRemainingError;

  // ── Fabric spec controllers ──
  final _fabricTypeUseCtrl = TextEditingController();
  final _fabricConstCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _fabricGsmCtrl = TextEditingController();
  final _fabricWidthCtrl = TextEditingController();
  final _cutTypeCtrl = TextEditingController();
  final _baffleCtrl = TextEditingController();

  // ── Generated ──
  final _generateCodeCtrl = TextEditingController();
  final _batchNoCtrl = TextEditingController();

  // ── Weights ──
  final _operatorNameCtrl = TextEditingController();
  final _grossWeightCtrl = TextEditingController();
  final _tareWeightCtrl = TextEditingController();
  final _rollLengthCtrl = TextEditingController();
  final _rollWeightCtrl = TextEditingController();
  final _avgWeightMtrCtrl = TextEditingController();

  // ── Cut piece details ──
  final _qntyCtrl = TextEditingController();
  final _useCtrl = TextEditingController();
  final _finalRemCtrl = TextEditingController();
  final _netWtCtrl = TextEditingController();
  final _wastageCtrl = TextEditingController();
  final _pcsCtrl = TextEditingController();
  final _cutWidthCtrl = TextEditingController();
  final _cutLengthCtrl = TextEditingController();
  final _perPcWtCtrl = TextEditingController();

  // ── Remark ──
  final _remarkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = widget.production;

    _fabricTypeUseCtrl.text = r.fabricTypeFabricUse;
    _fabricConstCtrl.text = r.fabricConstruction;
    _colorCtrl.text = r.color;
    _fabricGsmCtrl.text = r.fabricGsm;
    _fabricWidthCtrl.text = r.fabricWidth;
    _cutTypeCtrl.text = r.specialIdentification;
    _baffleCtrl.text = r.cutSlipType;
    _remarkCtrl.text = r.remark;
    _reqQtyKgCtrl.text = widget.production.requiredQuantityKg.toString();
    _reqQtyMtrCtrl.text = widget.production.requiredQuantityMtr.toString();
    _selectedLaminationType = r.laminationType.trim().isEmpty
        ? null
        : r.laminationType.trim();
    _laminationTypes = {
      ..._extraLaminationTypes,
      if (_selectedLaminationType != null) _selectedLaminationType!,
    }.toList();

    _tareWeightCtrl.text = r.weekNo.toString();
    _grossWeightCtrl.text = r.orderType.toString();
    _rollLengthCtrl.text = r.rollLengthMtr.toString();
    _rollWeightCtrl.text = r.rollWeightKg.toString();

    final wo = r.workOrderNo;
    _selectedWo = wo.trim().isEmpty ? null : WorkOrderOption(work_order: wo);
    _selectedComponent = r.component.trim().isEmpty ? null : r.component;
    _selectedSupervisor = r.supervisorName.trim().isEmpty
        ? null
        : r.supervisorName;
    _selectedOperator = r.operatorName.trim().isEmpty ? null : r.operatorName;

    _fetchTillRemainingWeight();
    _calculateAvgWeight();
    _loadSchedulingDropdowns();
    if (wo.trim().isNotEmpty) _fetchInquiryNumber(wo);
  }

  /// Parent + (agar khula ho to) bottom sheet dono rebuild
  void _update(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
    _sheetSetState?.call(() {});
  }

  // ── Cut size API ──

  Future<void> _fetchCutSizeWidth() async {
    final wo = _selectedWo?.work_order.trim() ?? '';
    final component = _selectedComponent?.trim() ?? '';
    final inquiry = _selectedInquiry?.trim() ?? '';

    if (wo.isEmpty || component.isEmpty || inquiry.isEmpty) {
      _update(() {
        _cutWidthCtrl.clear();
        _cutLengthCtrl.clear();
        _isCutLengthEnabled = true;
        _loadingCutSize = false;
      });
      return;
    }

    _update(() => _loadingCutSize = true);

    try {
      final url = Uri.parse('${InStockService.baseUrl}/Cutting/GetCutsizeWidth')
          .replace(
            queryParameters: {
              'partyOrWoNumber': wo,
              'componentOrWoNo': component,
              'inquiryNo': inquiry,
            },
          );

      final response = await http
          .get(url, headers: await InStockService.authHeaders())
          .timeout(const Duration(seconds: 20));

      debugPrint('CUT SIZE URL: $url');
      debugPrint('CUT SIZE STATUS: ${response.statusCode}');
      debugPrint('CUT SIZE BODY: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch cut size (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Unable to fetch cut size',
        );
      }

      final data = decoded['data'];
      if (data == null || data is! Map) {
        throw Exception('Cut size data not found');
      }

      final cutWidth = data['cutWidth']?.toString() ?? '';
      final cutLength = data['cutLength']?.toString() ?? '';
      final isCutLengthEnabled = data['isCutLengthEnabled'] == true;

      // Selection badal gayi ho to response ignore
      if (!mounted ||
          _selectedWo?.work_order.trim() != wo ||
          _selectedComponent?.trim() != component ||
          _selectedInquiry?.trim() != inquiry) {
        return;
      }

      _update(() {
        _cutWidthCtrl.text = cutWidth;
        _cutLengthCtrl.text = cutLength;
        _isCutLengthEnabled = isCutLengthEnabled;
        _loadingCutSize = false;
      });
    } catch (e) {
      debugPrint('CUT SIZE API ERROR: $e');

      if (!mounted ||
          _selectedWo?.work_order.trim() != wo ||
          _selectedComponent?.trim() != component ||
          _selectedInquiry?.trim() != inquiry) {
        return;
      }

      _update(() {
        _loadingCutSize = false;
        _cutWidthCtrl.clear();
        _cutLengthCtrl.clear();
        _isCutLengthEnabled = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to fetch cut width and length: $e'),
          backgroundColor: _red,
        ),
      );
    }
  }

  Future<void> _loadSchedulingDropdowns() async {
    setState(() {
      _loadingOperators = true;
      _loadingSupervisors = true;
    });

    try {
      final results = await Future.wait([
        _apiService.getJblCuttingOperators(),
        _apiService.getJblCuttingSupervisors(),
      ]);
      if (!mounted) return;

      setState(() {
        _operators = results[0];
        _supervisors = results[1];

        if (_selectedOperator != null &&
            !_operators.contains(_selectedOperator)) {
          _selectedOperator = null;
        }
        if (_selectedSupervisor != null &&
            !_supervisors.contains(_selectedSupervisor)) {
          _selectedSupervisor = null;
        }
        _loadingOperators = false;
        _loadingSupervisors = false;
      });
    } catch (e) {
      debugPrint('CUTTING OPERATOR/SUPERVISOR ERROR: $e');
      if (!mounted) return;
      setState(() {
        _loadingOperators = false;
        _loadingSupervisors = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _fabricTypeUseCtrl,
      _fabricConstCtrl,
      _colorCtrl,
      _fabricGsmCtrl,
      _fabricWidthCtrl,
      _cutTypeCtrl,
      _baffleCtrl,
      _generateCodeCtrl,
      _batchNoCtrl,
      _operatorNameCtrl,
      _grossWeightCtrl,
      _tareWeightCtrl,
      _rollLengthCtrl,
      _rollWeightCtrl,
      _avgWeightMtrCtrl,
      _netWtCtrl,
      _qntyCtrl,
      _wastageCtrl,

      _cutWidthCtrl,
      _cutLengthCtrl,
      _perPcWtCtrl,
      _remarkCtrl,
      _useCtrl,
      _finalRemCtrl,
      _tillRemainingCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Calculations ──

  void _calculateAvgWeight() {
    final weight = double.tryParse(_rollWeightCtrl.text.trim()) ?? 0;
    final length = double.tryParse(_rollLengthCtrl.text.trim()) ?? 0;
    final avg = length > 0 ? (weight / length) * 1000 : 0.0;
    _avgWeightMtrCtrl.text = avg.toStringAsFixed(2);
  }

  // Per Pc Wt (GM) = Net Wt (Kg) * 1000 / PCS  -> unit apne hisaab se badal lena
  void _calculatePerPcWt() {
    final net = double.tryParse(_netWtCtrl.text.trim()) ?? 0;
    final pcs = double.tryParse(_pcsCtrl.text.trim()) ?? 0;
    final v = pcs > 0 ? (net * 1000) / pcs : 0.0;
    _perPcWtCtrl.text = v.toStringAsFixed(2);
  }

  void _calculateUseAndFinalRem() {
    final net = double.tryParse(_netWtCtrl.text.trim()) ?? 0;
    final wastage = double.tryParse(_wastageCtrl.text.trim()) ?? 0;
    final tillRem = double.tryParse(_tillRemainingCtrl.text.trim()) ?? 0;

    final use = net + wastage;
    final finalRem = tillRem - use;

    _useCtrl.text = use.toStringAsFixed(2);
    _finalRemCtrl.text = finalRem.toStringAsFixed(2);
  }

  /// Net Wt badalne par Per Pc Wt + Use/Final Remaining dono update
  void _onNetChanged() {
    _calculatePerPcWt();
    _calculateUseAndFinalRem();
  }

  // ── Fabric code + Batch no ──

  void _generateFabricCode() {
    _generateCodeCtrl.text = [
      _fabricWidthCtrl.text.trim(),
      _baffleCtrl.text.trim(),
      _fabricTypeUseCtrl.text.trim(),
      _fabricGsmCtrl.text.trim(),
      _selectedLaminationType ?? '',
      _colorCtrl.text.trim(),
      _cutTypeCtrl.text.trim(),
      _fabricConstCtrl.text.trim(),
    ].join('-');
  }

  void _setBatchNumber() {
    _batchNoCtrl.text = 'CUT-${DateFormat('yyMMdd').format(DateTime.now())}';
  }

  void _onGeneratePressed() {
    _update(() {
      _generateFabricCode();
      _setBatchNumber();
      _codeGenerated = true;
      _touched.add('code');
    });

    final pending = _computeErrors().keys
        .where((k) => !_sheetKeys.contains(k))
        .toList();
    if (pending.isEmpty) {
      _openSheet();
    } else {
      _update(() => _touched.addAll(pending));
    }
  }

  void _onSpecChanged() {
    if (_codeGenerated) _generateFabricCode();
  }

  // ── Validation ──

  Map<String, String> _computeErrors() {
    final e = <String, String>{};

    void req(String k, String? v) {
      if (v == null || v.trim().isEmpty) e[k] = 'Required';
    }

    void num_(String k, TextEditingController c, {bool allowZero = false}) {
      final t = c.text.trim();
      if (t.isEmpty) {
        e[k] = 'Required';
        return;
      }
      final n = double.tryParse(t);
      if (n == null) {
        e[k] = 'Enter valid number';
      } else if (n < 0) {
        e[k] = 'Cannot be negative';
      }
    }

    req('supervisor', _selectedSupervisor);
    req('operator', _selectedOperator);
    req('machine', _selectedMachineNo);

    if (_withWorkOrder) {
      req('wo', _selectedWo?.work_order);
      req('inquiry', _selectedInquiry);
      req('component', _selectedComponent);
    }

    req('type', _fabricTypeUseCtrl.text);
    req('color', _colorCtrl.text);
    req('lam', _selectedLaminationType);
    num_('width', _fabricWidthCtrl);
    num_('gsm', _fabricGsmCtrl);
    num_('gross', _grossWeightCtrl);

    if (!_codeGenerated) e['code'] = 'Generate Fabric Code';

    // bottom sheet fields
    num_('qty', _qntyCtrl);
    num_('net', _netWtCtrl);
    num_('wastage', _wastageCtrl, allowZero: true);

    num_('cutW', _cutWidthCtrl);
    num_('cutL', _cutLengthCtrl);
    if (_rollFinish) {
      num_('rollLen', _rollLengthCtrl);
      num_('rollWt', _rollWeightCtrl);
    }

    return e;
  }

  String? _err(String key) => _touched.contains(key) ? _errors[key] : null;

  // ── Save ──

  Future<void> _saveForm() async {
    final errors = _computeErrors();

    if (errors.isNotEmpty) {
      _update(() => _touched.addAll(errors.keys));

      // Show all pending fields in debug console.
      debugPrint('PENDING FIELDS: ${errors.keys.join(', ')}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete: ${errors.keys.join(', ')}'),
          backgroundColor: _red,
        ),
      );
      return;
    }

    if (_isSaving) return;
    final r = widget.production;
    setState(() => _isSaving = true);
    try {
      // Read the current unit/plant from saved login preferences.
      final prefs = await SharedPreferences.getInstance();
      final plant = prefs.getString('unit') ?? '';
      final payload = <String, dynamic>{
        // Save mode based on the Roll Finish switch
        'saveMode': _rollFinish ? 'ROLLFINISH' : 'NOTFINISH',

        'barcode': r.barcode,
        'stR_NO_S': r.srNo.toString(),
        'plant': plant,

        'machine': widget.production.loomNo,
        'operatorName': _selectedOperator ?? '',

        // 'operatorName': _operatorNameCtrl.text.trim(),
        'machineNo': widget.production.workOrderNo ?? '',
        'supervisor': _selectedSupervisor ?? '',
        'loomOperator1': _selectedOperator ?? '',
        'cuttingMachineNo': _selectedMachineNo ?? '',

        'fabricCode': _generateCodeCtrl.text.trim(),
        'fabric_construction': _fabricConstCtrl.text.trim(),
        'fabricType': _fabricTypeUseCtrl.text.trim(),
        'fabricWidth': _fabricWidthCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'lamination_type': _selectedLaminationType ?? '',
        'gsm': _fabricGsmCtrl.text.trim(),
        'cut_type': _cutTypeCtrl.text.trim(),
        'fabric_baffle_type': _baffleCtrl.text.trim(),

        'rollWeight': _rollWeightCtrl.text.trim(),
        'rollLength': _rollLengthCtrl.text.trim(),
        'tare_wt': _tareWeightCtrl.text.trim(),
        'grossWeight': _grossWeightCtrl.text.trim(),
        'avgwt': _avgWeightMtrCtrl.text.trim(),

        'remark': _remarkCtrl.text.trim(),
        'department': 'CUTTING',
        'productionType': r.productionType,

        'work_order_no': _withWorkOrder ? (_selectedWo?.work_order ?? '') : '',
        'componentName': _withWorkOrder ? (_selectedComponent ?? '') : '',
        // 'orderNoNew': _withWorkOrder ? (_selectedWo?.work_order ?? '') : '',
        'orderNoNew': widget.production.partyName,

        'reqQtyKg': _reqQtyKgCtrl.text.trim(),
        'reqQtyMtr': _reqQtyMtrCtrl.text.trim(),
        'loomtype': widget.production.loomType,

        // 'planningWeek': widget.production.workOrderNo,
        'planningWeek': _operatorNameCtrl.text.trim(),

        'cutLength': _cutLengthCtrl.text.trim(),
        'cutSizeQty': _qntyCtrl.text.trim(),
        'wastage': _wastageCtrl.text.trim(),
        'netWeight': _netWtCtrl.text.trim(),
        'cutWidth': _cutWidthCtrl.text.trim(),

        'lengthNew': _cutLengthCtrl.text.trim(),
        'kgNew': _netWtCtrl.text.trim(),
        'mtrNew': _tillRemainingCtrl.text.trim(),
        'barcode1': r.barcode,

        'gridRows': [
          {
            'isChecked': _rollFinish, // false = NOTFINISH, true = ROLLFINISH
            'oldId': widget.production.rollCode.toString(),
            'oldBarcode': widget.production.barcode.toString(),
          },
        ],
      };

      debugPrint('ROLL FINISH SELECTED: $_rollFinish');
      debugPrint('SAVE MODE: ${payload['saveMode']}');
      debugPrint('SAVE CUTTING PAYLOAD: ${jsonEncode(payload)}');

      // Debug logs
      final url = Uri.parse(
        '${InStockService.baseUrl}/Cutting/SaveCuttingEntry',
      );

      debugPrint('SAVE CUTTING URL: $url');
      debugPrint('SAVE CUTTING PAYLOAD: ${jsonEncode(payload)}');

      final response = await http
          .post(
            url,
            headers: {
              ...await InStockService.authHeaders(),
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('SAVE CUTTING STATUS: ${response.statusCode}');
      debugPrint('SAVE CUTTING RESPONSE: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Save failed with status ${response.statusCode}: '
          '${response.body}',
        );
      }

      if (response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['success'] == false) {
          throw Exception(
            decoded['message']?.toString() ?? 'Unable to save cutting entry',
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cutting entry saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('SAVE CUTTING ERROR: $e');
      debugPrint('SAVE CUTTING STACK TRACE: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: _red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ── Bottom sheet ──

  Future<void> _openSheet() async {
    if (_sheetOpen || !mounted) return;
    FocusScope.of(context).unfocus();
    _sheetOpen = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          _sheetSetState = ss;
          return _sheetBody(ctx);
        },
      ),
    );

    _sheetOpen = false;
    _sheetSetState = null;
    if (mounted) setState(() {});
  }

  Widget _sheetBody(BuildContext ctx) {
    _errors = _computeErrors();
    final canSave = _errors.isEmpty && !_isSaving;
    final woPending =
        _withWorkOrder &&
        _errors.keys.any(
          (k) => const {'wo', 'inquiry', 'component'}.contains(k),
        );

    final media = MediaQuery.of(ctx);
    final kb = media.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: kb),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: (media.size.height - kb) * 0.92),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            kb == 0 ? media.padding.bottom + 16 : 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cut Piece Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              _switchTile('With Work Order', _withWorkOrder, (v) {
                _update(() {
                  _withWorkOrder = v;
                  if (!v) {
                    _selectedWo = null;
                    _selectedInquiry = null;
                    _selectedComponent = null;
                    _inquiryList = [];
                    _inquiryError = null;
                    _touched.removeAll(['wo', 'inquiry', 'component']);
                  }
                });
                if (!v) widget.onWorkOrderChanged?.call('');
              }),
              const SizedBox(height: 8),
              _switchTile('Roll Finish', _rollFinish, (v) {
                _update(() {
                  _rollFinish = v;
                  if (!v) _touched.removeAll(['rollLen', 'rollWt']);
                });
              }),
              const SizedBox(height: 12),

              if (woPending)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Work Order, Select in Form.',
                    style: TextStyle(fontSize: 11, color: _red),
                  ),
                ),

              _row([
                _tf('qty', 'Cut Size Qty', _qntyCtrl, numeric: true),
                _tf(
                  'net',
                  'Net Wt (Kg)',
                  _netWtCtrl,
                  numeric: true,
                  after: _onNetChanged,
                ),
                _tf(
                  'wastage',
                  'Wastage (Kg)',
                  _wastageCtrl,
                  numeric: true,
                  after: _calculateUseAndFinalRem,
                ),
              ]),
              const SizedBox(height: 10),

              if (_loadingCutSize)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Fetching cut width and length...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

              _row([
                _tf(
                  'cutL',
                  'Cut Length',
                  _cutLengthCtrl,
                  numeric: true,
                  readOnly: !_isCutLengthEnabled,
                ),
                _tf(
                  'cutW',
                  'Cut Width (cm)',
                  _cutWidthCtrl,
                  numeric: true,
                  readOnly: true,
                ),
              ]),
              const SizedBox(height: 10),

              _row([
                _inputField(
                  'Till Remaining (Kg)',
                  _tillRemainingCtrl,
                  readOnly: true,
                ),
                _inputField('Use (Kg)', _useCtrl, readOnly: true),
                _inputField(
                  'Final Remaining (Kg)',
                  _finalRemCtrl,
                  readOnly: true,
                ),
              ]),

              if (_loadingTillRemaining)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Fetching till remaining weight...',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),

              if (_tillRemainingError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _tillRemainingError!,
                    style: const TextStyle(color: _red, fontSize: 11),
                  ),
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: canSave
                      ? () async {
                          Navigator.pop(ctx);
                          await _saveForm();
                        }
                      : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text(
                    'Save',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (!canSave && !_isSaving && _errors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Pending fields: ${_errors.keys.join(', ')}',
                    style: const TextStyle(fontSize: 11, color: _red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Main form ke end me tile jo sheet kholta hai
  Widget _sheetTile() {
    final pending = _errors.keys.where((k) => _sheetKeys.contains(k)).length;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _openSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: C.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.brand300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cut Piece Details & Options',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'WO: ${_withWorkOrder ? "Yes" : "No"}  |  '
                    'Roll Finish: ${_rollFinish ? "Yes" : "No"}  |  '
                    '${pending == 0 ? "Complete" : "$pending pending"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: pending == 0 ? Colors.green : _red,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_up_rounded),
          ],
        ),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final r = widget.production;
    _errors = _computeErrors();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildAppBar(context, r),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pad = constraints.maxWidth > 600 ? 20.0 : 14.0;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Scheduling ──
                _sectionLabel('Scheduling'),
                _card([
                  _row([
                    _dd(
                      'supervisor',
                      SearchableDropdown<String>(
                        key: const ValueKey('cutting_supervisor'),
                        label: 'Supervisor',
                        hint: _loadingSupervisors
                            ? 'Loading supervisors...'
                            : _supervisors.isEmpty
                            ? 'No supervisors available'
                            : 'Select Supervisor',
                        value: _selectedSupervisor,
                        items: _supervisors,
                        itemLabel: (e) => e,
                        enabled:
                            !_loadingSupervisors && _supervisors.isNotEmpty,
                        onChanged: (v) => _update(() {
                          _touched.add('supervisor');
                          _selectedSupervisor = v;
                        }),
                      ),
                    ),
                    _dd(
                      'operator',
                      SearchableDropdown<String>(
                        key: const ValueKey('cutting_operator'),
                        label: 'Operator',
                        hint: _loadingOperators
                            ? 'Loading operators...'
                            : _operators.isEmpty
                            ? 'No operators available'
                            : 'Select Operator',
                        value: _selectedOperator,
                        items: _operators,
                        itemLabel: (e) => e,
                        enabled: !_loadingOperators && _operators.isNotEmpty,
                        onChanged: (v) => _update(() {
                          _touched.add('operator');
                          _selectedOperator = v;
                        }),
                      ),
                    ),
                  ]),
                  _row([_inputField('Operator Name', _operatorNameCtrl)]),
                ]),
                _gap,

                // ── Job Info ──
                _sectionLabel('Job Info'),
                _card([
                  if (_withWorkOrder)
                    _row([
                      _dd(
                        'wo',
                        SearchableDropdown<WorkOrderOption>(
                          key: ValueKey(r.productionType),
                          label: 'WO No',
                          hint: 'Select Work Order',
                          value: _selectedWo,
                          fetchItems: () => JblApiService.fetchJblWorkOrders(
                            productionType: r.productionType,
                          ),
                          itemLabel: (o) => o.work_order,
                          onChanged: (o) {
                            _update(() {
                              _touched.add('wo');
                              _selectedWo = o;
                              _selectedInquiry = null;
                              _selectedComponent = null;
                              _cutWidthCtrl.clear();
                              _cutLengthCtrl.clear();
                            });
                            widget.onWorkOrderChanged?.call(o.work_order);
                            _fetchInquiryNumber(o.work_order);
                          },
                        ),
                      ),
                      _dd(
                        'inquiry',
                        _disableIf(
                          _inquiryList.isEmpty,
                          SearchableDropdown<String>(
                            key: ValueKey('inquiry_${_selectedWo?.work_order}'),
                            label: 'Inq. No',
                            hint: _loadingInquiry
                                ? 'Loading...'
                                : (_inquiryError ?? 'Select Inquiry'),
                            value: _selectedInquiry,
                            items: _inquiryList,
                            itemLabel: (e) => e,
                            enabled: _inquiryList.isNotEmpty,
                            onChanged: (v) {
                              _update(() {
                                _touched.add('inquiry');
                                _selectedInquiry = v;
                                _selectedComponent = null;
                                _cutWidthCtrl.clear();
                                _cutLengthCtrl.clear();
                              });
                            },
                          ),
                        ),
                      ),
                    ]),
                  _row([
                    if (_withWorkOrder)
                      _dd(
                        'component',
                        _disableIf(
                          !_canLoadComponent,
                          SearchableDropdown<String>(
                            key: ValueKey(
                              '${_selectedWo?.work_order}_$_selectedInquiry',
                            ),
                            label: 'Component',
                            hint: _canLoadComponent
                                ? 'Select Component'
                                : 'Select WO & Inquiry',
                            value: _selectedComponent,
                            fetchItems: _fetchComponents,
                            itemLabel: (e) => e,
                            enabled: _canLoadComponent,
                            onChanged: (v) {
                              _update(() {
                                _touched.add('component');
                                _selectedComponent = v;

                                // Purane component ki values clear
                                _cutWidthCtrl.clear();
                                _cutLengthCtrl.clear();
                              });

                              _fetchCutSizeWidth();
                            },
                          ),
                        ),
                      ),
                    _dd(
                      'machine',
                      SearchableDropdown<String>(
                        key: const ValueKey('machine_no'),
                        label: 'Machine No',
                        hint: 'Select Machine No',
                        value: _selectedMachineNo,
                        items: _machineNumbers,
                        itemLabel: (v) => v,
                        onChanged: (v) => _update(() {
                          _touched.add('machine');
                          _selectedMachineNo = v;
                        }),
                      ),
                    ),
                  ]),
                ]),
                _gap,
                // ── Required Quantity ──
                _sectionLabel('Required Quantity'),
                _card([
                  _row([
                    _inputField(
                      'Required Quantity (Kg)',
                      _reqQtyKgCtrl,
                      readOnly: true,
                    ),
                    _inputField(
                      'Required Quantity (Mtr)',
                      _reqQtyMtrCtrl,
                      readOnly: true,
                    ),
                  ]),
                ]),
                _gap,
                // ── Fabric Specs ──
                _sectionLabel('Fabric Specs'),
                _card([
                  _row([
                    _tf(
                      'type',
                      'Fabric Type / Use',
                      _fabricTypeUseCtrl,
                      after: _onSpecChanged,
                    ),
                    _tf(
                      'const',
                      'Fabric Construction',
                      _fabricConstCtrl,
                      after: _onSpecChanged,
                    ),
                  ]),
                  _row([
                    _tf('color', 'Color', _colorCtrl, after: _onSpecChanged),
                    _dd(
                      'lam',
                      SearchableDropdown<String>(
                        key: const ValueKey('lamination_type'),
                        label: 'Lamination Type',
                        hint: 'Select Lamination Type',
                        value: _selectedLaminationType,
                        items: _laminationTypes,
                        itemLabel: (v) => v,
                        onChanged: (v) {
                          _update(() {
                            _touched.add('lam');
                            _selectedLaminationType = v;
                          });
                          _onSpecChanged();
                        },
                      ),
                    ),
                  ]),
                  _row([
                    _tf(
                      'gsm',
                      'Fabric GSM',
                      _fabricGsmCtrl,
                      numeric: true,
                      after: _onSpecChanged,
                    ),
                    _tf(
                      'width',
                      'Fabric Width (cm)',
                      _fabricWidthCtrl,
                      numeric: true,
                      after: _onSpecChanged,
                    ),
                  ]),
                  _row([
                    _tf(
                      'baffle',
                      'Fabric Baffle Type',
                      _baffleCtrl,
                      after: _onSpecChanged,
                    ),
                    _tf(
                      'cutType',
                      'Cut Type',
                      _cutTypeCtrl,
                      after: _onSpecChanged,
                    ),
                  ]),
                ]),
                _gap,

                // ── Weight ──
                _sectionLabel('Weight'),
                _card([
                  _row([
                    _tf(
                      'rollLen',
                      'Roll Length (Mtr) *',
                      _rollLengthCtrl,
                      numeric: true,
                      after: _calculateAvgWeight,
                    ),
                    _tf(
                      'rollWt',
                      'Roll Wt (Kg) *',
                      _rollWeightCtrl,
                      numeric: true,
                      after: _calculateAvgWeight,
                    ),
                  ]),

                  _tf('avg', 'Avg Wt (GM)', _avgWeightMtrCtrl, readOnly: true),

                  _row([
                    _tf(
                      'gross',
                      'Gross Wt (Kg)',
                      _grossWeightCtrl,
                      numeric: true,
                    ),
                    _tf(
                      'tare',
                      'Tare Wt (Kg)',
                      _tareWeightCtrl,
                      readOnly: true,
                    ),
                  ]),
                  _tf('avg', 'Avg Wt (GM)', _avgWeightMtrCtrl, readOnly: true),
                ]),
                _gap,

                // ── Remark & Code ──
                _sectionLabel('Remarks & Code'),
                _card([
                  _field(
                    'Remark',
                    '',
                    readOnly: false,
                    controller: _remarkCtrl,
                    maxLines: 2,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _onGeneratePressed,
                      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                      label: Text(
                        _codeGenerated
                            ? 'Regenerate Fabric Code'
                            : 'Generate Fabric Code',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.primary,
                        side: BorderSide(
                          color: _err('code') != null ? _red : C.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_err('code') != null)
                    Text(
                      _err('code')!,
                      style: const TextStyle(fontSize: 11, color: _red),
                    ),
                  if (_codeGenerated)
                    _inputField(
                      'Generated Fabric Code',
                      _generateCodeCtrl,
                      readOnly: true,
                    ),
                ]),
                _gap,

                // ── Cut Piece (last, dropdown tile → bottom sheet) ──
                _sectionLabel('Cut Piece'),
                _card([_sheetTile()]),
                _gap,
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CuttingOutstockJbl r) {
    return AppBar(
      backgroundColor: C.appBar1,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 23),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cutting Out ${r.barcode}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            r.date.split('T').first,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ── Layout helpers ──

  Widget _row(List<Widget> children) {
    final expanded =
        children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
            .toList()
          ..removeLast();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: expanded,
    );
  }

  Widget _sectionLabel(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 2),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: C.textHigh,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: C.brand300),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.expand((w) => [w, const SizedBox(height: 10)]).toList()
        ..removeLast(),
    ),
  );

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.brand300),
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        activeColor: C.primary,
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          value ? 'Yes' : 'No',
          style: const TextStyle(fontSize: 11),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Dropdown pe red border + niche error text
  Widget _dd(String key, Widget child) {
    final err = _err(key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: err == null
              ? null
              : BoxDecoration(
                  border: Border.all(color: _red),
                  borderRadius: BorderRadius.circular(8),
                ),
          child: child,
        ),
        if (err != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(err, style: const TextStyle(fontSize: 10, color: _red)),
          ),
      ],
    );
  }

  /// TextField + validation hook
  Widget _tf(
    String key,
    String label,
    TextEditingController c, {
    bool numeric = false,
    bool readOnly = false,
    VoidCallback? after,
  }) {
    return _inputField(
      label,
      c,
      readOnly: readOnly,
      numeric: numeric,
      errorText: _err(key),
      onChanged: (_) => _update(() {
        _touched.add(key);
        after?.call();
      }),
    );
  }

  // ── Label + boxed value (read-only ya editable remark) ──
  Widget _field(
    String label,
    String value, {
    int maxLines = 1,
    bool readOnly = true,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: C.textHigh,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: C.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.brand300),
          ),
          child: readOnly
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    value.trim().isEmpty ? '-' : value,
                    maxLines: maxLines,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A2340),
                    ),
                  ),
                )
              : TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A2340),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Editable field with red error support ──
  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool numeric = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: errorText != null ? _red : C.textHigh,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A2340),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: readOnly ? C.bg : Colors.white,
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 10, color: _red),
            border: border(C.brand300),
            enabledBorder: border(C.brand300),
            focusedBorder: border(C.primary),
            errorBorder: border(_red),
            focusedErrorBorder: border(_red),
          ),
        ),
      ],
    );
  }

  // ── Inquiry API ──

  Future<void> _fetchInquiryNumber(String woNumber) async {
    final wo = woNumber.trim();

    if (wo.isEmpty) {
      if (!mounted) return;
      setState(() {
        _inquiryList = [];
        _selectedInquiry = null;
        _selectedComponent = null;
        _inquiryError = null;
        _loadingInquiry = false;
      });
      return;
    }

    setState(() {
      _loadingInquiry = true;
      _inquiryList = [];
      _selectedInquiry = null;
      _selectedComponent = null;
      _inquiryError = null;
    });

    try {
      final url = Uri.parse(
        '${InStockService.baseUrl}/Cutting/GetInquiryNumbers',
      ).replace(queryParameters: {'woNumber': wo});

      final response = await http
          .get(url, headers: await InStockService.authHeaders())
          .timeout(const Duration(seconds: 20));

      debugPrint('INQUIRY URL: $url');
      debugPrint('INQUIRY STATUS: ${response.statusCode}');
      debugPrint('INQUIRY BODY: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch inquiry number (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Unable to fetch inquiry number',
        );
      }

      final List<dynamic> data = (decoded['data'] as List?) ?? [];
      final list = data
          .map((item) => item['inquiryNo']?.toString().trim() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      // Stale response guard
      if (!mounted || _selectedWo?.work_order.trim() != wo) return;

      _update(() {
        _inquiryList = list;
        _selectedInquiry = list.length == 1 ? list.first : null;
        _inquiryError = list.isEmpty ? 'No inquiry found' : null;
        _loadingInquiry = false;
      });
    } catch (e) {
      debugPrint('INQUIRY API ERROR: $e');
      if (!mounted || _selectedWo?.work_order.trim() != wo) return;

      _update(() {
        _inquiryList = [];
        _selectedInquiry = null;
        _inquiryError = 'Unable to fetch inquiry';
        _loadingInquiry = false;
      });
    }
  }

  bool get _canLoadComponent =>
      (_selectedWo?.work_order.trim().isNotEmpty ?? false) &&
      (_selectedInquiry?.trim().isNotEmpty ?? false);

  // Disabled look: halka + tap band
  Widget _disableIf(bool disabled, Widget child) => Opacity(
    opacity: disabled ? 0.5 : 1,
    child: IgnorePointer(ignoring: disabled, child: child),
  );

  Future<List<String>> _fetchComponents() async {
    if (!_canLoadComponent) return [];

    final url =
        Uri.parse(
          '${InStockService.baseUrl}/Cutting/GetComponentDropdown',
        ).replace(
          queryParameters: {
            'partyNameOrWoNumber': _selectedWo!.work_order.trim(),
            'inquiryNo': _selectedInquiry!.trim(),
          },
        );

    final response = await http
        .get(url, headers: await InStockService.authHeaders())
        .timeout(const Duration(seconds: 20));

    debugPrint('COMPONENT URL: $url');
    debugPrint('COMPONENT STATUS: ${response.statusCode}');
    debugPrint('COMPONENT BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to load components: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? 'API error');
    }

    final List<dynamic> data = (decoded['data'] as List?) ?? [];
    final seen = <String>{};
    return data
        .map((e) => e['component']?.toString().trim() ?? '')
        .where((c) => c.isNotEmpty && seen.add(c))
        .toList();
  }

  // ── Till Remaining API ──

  Future<void> _fetchTillRemainingWeight() async {
    final r = widget.production;

    final srNo = r.srNo.toString().trim();
    final barcode = r.barcode.trim();
    final rollWeight = _rollWeightCtrl.text.trim();

    if (srNo.isEmpty || barcode.isEmpty || rollWeight.isEmpty) {
      _update(() {
        _tillRemainingCtrl.clear();
        _tillRemainingError = null;
        _loadingTillRemaining = false;
      });
      return;
    }

    final weight = double.tryParse(rollWeight);
    if (weight == null || weight <= 0) {
      _update(() {
        _tillRemainingCtrl.clear();
        _tillRemainingError = 'Enter a valid roll weight';
        _loadingTillRemaining = false;
      });
      return;
    }

    _update(() {
      _loadingTillRemaining = true;
      _tillRemainingError = null;
    });

    try {
      final url =
          Uri.parse(
            '${InStockService.baseUrl}/Cutting/GetTillRemainingWeight',
          ).replace(
            queryParameters: {
              'srno': srNo,
              'barcode': barcode,
              'rollWeight': weight.toStringAsFixed(2),
            },
          );

      final response = await http
          .get(url, headers: await InStockService.authHeaders())
          .timeout(const Duration(seconds: 20));

      debugPrint('TILL REMAINING URL: $url');
      debugPrint('TILL REMAINING STATUS: ${response.statusCode}');
      debugPrint('TILL REMAINING BODY: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch till remaining (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Unable to fetch till remaining weight',
        );
      }

      final data = decoded['data'];

      if (data is! Map || data['tillRemaining'] == null) {
        throw Exception('Till remaining weight not found');
      }

      // Roll weight badal gaya ho to stale response ignore
      if (!mounted ||
          widget.production.barcode.trim() != barcode ||
          _rollWeightCtrl.text.trim() != rollWeight) {
        return;
      }

      final tillRemaining = double.tryParse(data['tillRemaining'].toString());

      if (tillRemaining == null) {
        throw Exception('Invalid till remaining weight returned by API');
      }

      _update(() {
        _tillRemainingCtrl.text = tillRemaining.toStringAsFixed(2);
        _calculateUseAndFinalRem(); // ✅ Till Remaining aate hi Use/Final update
        _loadingTillRemaining = false;
        _tillRemainingError = null;
      });

      debugPrint('TILL REMAINING: ${_tillRemainingCtrl.text}');
      debugPrint('TOTAL CONSUMED: ${data['totalConsumed']}');
      debugPrint('HAS PREVIOUS CUTS: ${data['hasPreviousCuts']}');
    } catch (e) {
      debugPrint('TILL REMAINING API ERROR: $e');
      if (!mounted) return;

      _update(() {
        _loadingTillRemaining = false;
        _tillRemainingError = 'Unable to fetch till remaining';
      });
    }
  }
}
