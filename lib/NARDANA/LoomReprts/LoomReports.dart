import 'dart:convert';

import 'package:IMS/services/getSupervisors/getSupervisors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Color/Colorclass.dart';
import '../../services/NardanaApis/NardanaApi.dart';
import '../../util/widget/CountRecords/CountRecords.dart';
import 'LoomReportModelClass.dart';



class LoomReportjBLScreen extends StatefulWidget {
  const LoomReportjBLScreen({super.key});

  @override
  State<LoomReportjBLScreen> createState() => _LoomReportjBLScreenState();
}

class _LoomReportjBLScreenState extends State<LoomReportjBLScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  DateTime? _from;
  DateTime? _to;
  List<LoomReportjBL> _allReports = [];
  bool _isLoading = false;

  List<LoomReportjBL> get _filtered => _allReports.where((r) {
    final q = _query.toLowerCase();
    final matchQ =
        q.isEmpty ||
        r.barcode.toLowerCase().contains(q) ||
        r.operatorName.toLowerCase().contains(q) ||
        r.fabricCode.toLowerCase().contains(q);
    final fromDate = _from != null
        ? DateTime(_from!.year, _from!.month, _from!.day)
        : null;

    final toDate = _to != null
        ? DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59)
        : null;

    final matchFrom = fromDate == null || !r.date.isBefore(fromDate);
    final matchTo = toDate == null || !r.date.isAfter(toDate);
    return matchQ && matchFrom && matchTo;
  }).toList();

  int get _totalRecords =>
      ReportTotalHelper.totalRecords(_filtered);

  double get _totalNetWeight =>
      ReportTotalHelper.totalNetWeight(_filtered, (e) => e.netWeight);

  // double get _totalLength =>
  //     ReportTotalHelper.totalRollLength(_filtered, (e) => e.rollLength);

  // double get _totalNetWeight {
  //   return _filtered.fold(0.0, (sum, item) => sum + (item.netWeight ?? 0));
  // }

  double get _totalRollLength {
    return _filtered.fold(0.0, (sum, item) => sum + (item.rollLength ?? 0));
  }
  @override
  void initState() {
    super.initState();



    _to = DateTime.now();
    _from = _to!.subtract(const Duration(days: 6)); // Last 7 days (today included)

    _fetchData();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,

      // ✅ Allow wide range (almost any date)
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),

      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });

      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await NaradanaApiService().fetchLoomDataJbl(

      );

      if (!mounted) return;

      setState(() {
        _allReports = data;
      });
    } catch (e) {
      debugPrint('UI ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  // Future<void> _fetchData() async {
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final data = await NaradanaApiService().fetchLoomData(
  //       from: _from,
  //       to: _to,
  //     );
  //
  //     setState(() {
  //       _allReports = data;
  //     });
  //   } catch (e) {
  //     debugPrint("UI ERROR: $e");
  //
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Failed to load data")));
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  void _clear() {
    final now = DateTime.now();

    setState(() {
      _query = '';
      _searchCtrl.clear();

      _from = DateTime(now.year, now.month, now.day);
      _to   = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });

    _fetchData(); // 🔥 IMPORTANT
  }

  String _fmt(DateTime d) => DateFormat('dd MMM yy').format(d);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
       backgroundColor: C.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Loom Report',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.calendar_today, color: Colors.white),
        //     onPressed: _pickDateRange,
        //   ),
        //   if (_from != null || _to != null || _query.isNotEmpty)
        //     IconButton(
        //       icon: const Icon(Icons.close, size: 20),
        //       onPressed: _clear,
        //       tooltip: 'Clear',
        //     ),
        //   const SizedBox(width: 4),
        // ],
        actions: [

          /// SIMPLE TEXT COUNT
          // CountText(count: _filtered.length),

          IconButton(
            icon: const Icon(Icons.calendar_today, color: C.primaryDark,size: 18,),
            onPressed: _pickDateRange,
          ),


        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search barcode, operator, fabric…',
                hintStyle: const TextStyle(color: C.bg, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search,
                  color: C.bg,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => setState(() {
                          _query = '';
                          _searchCtrl.clear();
                        }),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white12,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body:  (!_isLoading && _filtered.isEmpty)
          ? _emptyState()
          : Column(children: [

            _summaryBar(),

            Expanded(child: _table(_filtered))]),
    );
  }

  // ── Paginated Table ────────────────────────────────────────────────────────

  Widget _table(List<LoomReportjBL> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Theme(
        data: Theme.of(context).copyWith(
          dataTableTheme: DataTableThemeData(
            headingRowColor: WidgetStateProperty.all(C.cardOrange),
            headingTextStyle: const TextStyle(
              color: C.textHigh,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF333333),
            ),
          ),
        ),
        child: PaginatedDataTable(
          rowsPerPage: 10,
          availableRowsPerPage: const [6, 10, 20],
          columnSpacing: 16,
          horizontalMargin: 14,

          columns: const [
            DataColumn(label: Text('Sr')),
            DataColumn(label: Text('Roll Code')),
            DataColumn(label: Text('Barcode')),
            DataColumn(label: Text('Loom Type')),
            DataColumn(label: Text('Loom No')),
            DataColumn(label: Text('Fabric Code')),
            DataColumn(label: Text('Gross Wt(kg)'), numeric: true),
            DataColumn(label: Text('Net Wt(kg)'), numeric: true),
            DataColumn(label: Text('Roll Length(m)'), numeric: true),
            DataColumn(label: Text('Avg Wt(gm)'), numeric: true),
            DataColumn(label: Text('Operator')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Loom OP1')),
            DataColumn(label: Text('GSM(mtr/gm)')),
            DataColumn(label: Text('Sup Name')),
            DataColumn(label: Text('Party Name')),
            DataColumn(label: Text('WO No')),
            DataColumn(label: Text('Cont No')),
            DataColumn(label: Text('Req.Qty(Kg)')),
            DataColumn(label: Text('Req.Qty(mtr)')),
            DataColumn(label: Text('Tare(Kg)')),
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('Issue To Dept')),
            DataColumn(label: Text('Status')),
          ],

          source: _LoomDataSource(data),
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        TextButton.icon(
          onPressed: _clear,
          icon: const Icon(Icons.tab_unselected_sharp, color: C.textHigh),
          label: const Text('Select First Date range ', style: TextStyle(color: C.textHigh)),
        ),
      ],
    ),
  );


  Widget _summaryBar() {
    return Container(
      color: C.bg,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          _box("Records", '$_totalRecords', C.bg),
          _box("Roll Weight(Kg)", _totalNetWeight.toStringAsFixed(2), C.bg),
          _box("Roll Length(mtr)", _totalRollLength.toStringAsFixed(2), C.bg),
        ],
      ),
    );
  }

  Widget _box(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.primaryDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Data Source ───────────────────────────────────────────────────────────────

class _LoomDataSource extends DataTableSource {
  final List<LoomReportjBL> _data;
  _LoomDataSource(this._data);

  @override
  DataRow getRow(int i) {
    final r = _data[i];
    final isLohia = r.loomType.startsWith('LOHIA');

    return DataRow(
      color: WidgetStateProperty.all(
        i.isEven ? Colors.white : const Color(0xFFF8FAFF),
      ),

      cells: [
        DataCell(Text('${r.srNo}')),
        DataCell(Text('${r.rollCode}')),
        DataCell(Text(r.barcode)),
        DataCell(_badge(r.loomType, r.loomType.startsWith('LOHIA'))),
        DataCell(Text(r.loomNo)),
        DataCell(
          SizedBox(
            width: 190,
            child: Text(
              r.fabricCode,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(r.grossWeight.toStringAsFixed(2))),
        DataCell(Text(r.netWeight.toStringAsFixed(2))),
        DataCell(Text(r.rollLength.toStringAsFixed(2))),
        DataCell(Text(r.avgWeight.toStringAsFixed(2))),
        DataCell(Text(r.operatorName)),
        DataCell(Text(DateFormat('dd MMM yy').format(r.date))),
        DataCell(Text(r.time)),
        DataCell(Text(r.loomOperator1)),
        DataCell(Text(r.fabricGsm)),
        DataCell(Text(r.supervisorName)),
        DataCell(Text(r.partyName)),
        DataCell(Text(r.workOrderNo)),
        DataCell(Text(r.contNo)),
        DataCell(Text(r.requiredQty.toStringAsFixed(2))),
        DataCell(Text(r.requiredQtyMtr.toStringAsFixed(2))),
        DataCell(Text(r.tareWeight.toStringAsFixed(2))),
        DataCell(Text(r.department)),
        DataCell(Text(r.issueToDept)),
        DataCell(Text(r.status)),
      ],

    );
  }

  Widget _badge(String type, bool isLohia) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: isLohia ? const Color(0xFFF3E5F5) : const Color(0xFFE3F2FD),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      type,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: isLohia ? Colors.purple.shade700 : Colors.blue.shade700,
      ),
    ),
  );

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _data.length;
  @override
  int get selectedRowCount => 0;
}
