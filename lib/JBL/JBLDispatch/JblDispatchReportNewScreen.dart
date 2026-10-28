import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../Color/Colorclass.dart';
import '../../services/JBL_apis/jbl_api_bailing_reports.dart';
import '../app_colors.dart';

// ── Model (chahe to alag file mein move kar lo: DispatchReportNewModel.dart) ──
class DispatchReportNewModel {
  final String woNumber;
  final String partyName;
  final num woQty;
  final num tillDispatch;
  final num balanceQty;

  DispatchReportNewModel({
    required this.woNumber,
    required this.partyName,
    required this.woQty,
    required this.tillDispatch,
    required this.balanceQty,
  });

  factory DispatchReportNewModel.fromJson(Map<String, dynamic> json) {
    return DispatchReportNewModel(
      woNumber: (json['woNumber'] ?? '').toString().trim(),
      partyName: (json['partyName'] ?? '').toString().trim(),
      woQty: num.tryParse('${json['woQty']}') ?? 0,
      tillDispatch: num.tryParse('${json['tillDispatch']}') ?? 0,
      balanceQty: num.tryParse('${json['balanceQty']}') ?? 0,
    );
  }

  /// Pending / Completed / Excess
  String get status {
    if (balanceQty < 0) return 'Excess';
    if (balanceQty == 0) return 'Completed';
    return 'Pending';
  }

  double get dispatchPercent =>
      woQty <= 0 ? 0 : (tillDispatch / woQty * 100).toDouble();
}

class _Col {
  final String title;
  final double w;
  final bool right;
  const _Col(this.title, this.w, {this.right = false});
}

class DispatchReportNewScreen extends StatefulWidget {
  const DispatchReportNewScreen({super.key});

  @override
  State<DispatchReportNewScreen> createState() =>
      _DispatchReportNewScreenState();
}

class _DispatchReportNewScreenState extends State<DispatchReportNewScreen> {
  bool isLoading = true;
  String? errorMsg;

  List<DispatchReportNewModel> reportList = [];
  List<DispatchReportNewModel> filteredList = [];

  final TextEditingController searchController = TextEditingController();
  final ScrollController _hScroll = ScrollController();

  int currentPage = 1;
  int rowsPerPage = 10;

  // All / Pending / Completed / Excess
  String _statusFilter = 'All';
  static const _filters = ['All', 'Pending', 'Completed', 'Excess'];

  static const _cols = <_Col>[
    _Col('#', 50),
    _Col('WO Number', 110),
    _Col('Party Name', 260),
    _Col('WO Qty', 80, right: true),
    _Col('Till Dispatch', 100, right: true),
    _Col('Balance Qty', 110, right: true),

  ];

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  @override
  void dispose() {
    _hScroll.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────
  Future<void> loadReport() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final data = await JblApiService().getDispatchReportNew();
      if (!mounted) return;
      setState(() {
        reportList = data;
        isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint("❌ Dispatch report new error: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMsg = "Data load nahi hua. Retry karo.";
      });
    }
  }

  void _applyFilters() {
    final q = searchController.text.toLowerCase().trim();

    setState(() {
      filteredList = reportList.where((item) {
        final matchSearch = q.isEmpty ||
            item.woNumber.toLowerCase().contains(q) ||
            item.partyName.toLowerCase().contains(q);
        final matchStatus =
            _statusFilter == 'All' || item.status == _statusFilter;
        return matchSearch && matchStatus;
      }).toList();
      currentPage = 1;
    });
  }

  List<DispatchReportNewModel> get paginatedList {
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= filteredList.length) return [];
    final end = math.min(start + rowsPerPage, filteredList.length);
    return filteredList.sublist(start, end);
  }

  int get totalPages =>
      math.max(1, (filteredList.length / rowsPerPage).ceil());

  String _fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Color _statusColor(String s) {
    switch (s) {
      case 'Completed':
        return const Color(0xFF2E7D32);
      case 'Excess':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFEF6C00);
    }
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: C.primary,
        title: const Text(
          "Dispatch Report",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Text(
            "${filteredList.length} records",
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          IconButton(
            onPressed: loadReport,
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: C.appBar3))
          : errorMsg != null
          ? _buildError()
          : Column(
        children: [
          _buildSearchBar(),


          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text("No Data Found"))
                : _buildTable(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(errorMsg!, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: loadReport,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: (_) => _applyFilters(),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search WO Number or Party Name",
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                searchController.clear();
                _applyFilters();
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }



  Widget _buildInfoRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [


        ],
      ),
    );
  }

  Widget _buildPagination() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed:
              currentPage > 1 ? () => setState(() => currentPage--) : null,
              icon: const Icon(Icons.arrow_back),
            ),
            Text(
              "Page $currentPage of $totalPages",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: currentPage < totalPages
                  ? () => setState(() => currentPage++)
                  : null,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }

  // ── Table ───────────────────────────────────────────────────
  List<double> _widths(double available) {
    final base = _cols.map((c) => c.w).toList();
    final total = base.fold<double>(0, (a, b) => a + b);
    // Extra screen space Party Name column ko
    if (available > total) base[2] += available - total;
    return base;
  }

  Widget _buildTable() {
    final available = (MediaQuery.sizeOf(context).width - 24)
        .clamp(0.0, double.infinity)
        .toDouble();
    final widths = _widths(available);
    final tableW = widths.fold<double>(0, (a, b) => a + b);
    final startIndex = (currentPage - 1) * rowsPerPage;
    final rows = paginatedList;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _hScroll,
        thumbVisibility: true,
        notificationPredicate: (n) => n.depth == 0,
        child: SingleChildScrollView(
          controller: _hScroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableW,
            child: Column(
              children: [
                _headerRow(widths),
                Expanded(
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) =>
                        _dataRow(rows[i], startIndex + i + 1, i, widths),
                  ),
                ),
                _totalRow(widths, rows),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(double width, Widget child, bool right) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }

  Widget _headerRow(List<double> w) {
    return Container(
      color: C.primary,
      height: 44,
      child: Row(
        children: List.generate(_cols.length, (i) {
          return _cell(
            w[i],
            Text(
              _cols[i].title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            _cols[i].right,
          );
        }),
      ),
    );
  }

  Widget _dataRow(DispatchReportNewModel item, int sno, int i, List<double> w) {
    final balColor = item.balanceQty < 0
        ? const Color(0xFFC62828)
        : (item.balanceQty == 0 ? const Color(0xFF2E7D32) : Colors.black87);

    TextStyle base({FontWeight fw = FontWeight.w500, Color? color}) =>
        TextStyle(
          fontSize: 12.5,
          fontWeight: fw,
          color: color ?? Colors.black87,
        );

    Widget txt(String s, {TextStyle? style}) => Text(
      s,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ?? base(),
    );

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: i.isEven ? Colors.white : const Color(0xFFF6F8FA),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _cell(w[0], txt('$sno'), false),
          _cell(
            w[1],
            txt(item.woNumber,
                style: base(fw: FontWeight.w700, color: AppColors.primaryColor)),
            false,
          ),
          _cell(w[2], txt(item.partyName.isEmpty ? '-' : item.partyName), false),
          _cell(w[3], txt(_fmt(item.woQty)), true),
          _cell(w[4], txt(_fmt(item.tillDispatch)), true),
          _cell(
            w[5],
            txt(_fmt(item.balanceQty),
                style: base(fw: FontWeight.w700, color: balColor)),
            true,
          ),
        ],
      ),
    );
  }
  Widget _totalRow(List<double> w, List<DispatchReportNewModel> rows) {
    final woQty = rows.fold<num>(0, (s, e) => s + e.woQty);
    final dispatched = rows.fold<num>(0, (s, e) => s + e.tillDispatch);
    final balance = rows.fold<num>(0, (s, e) => s + e.balanceQty);

    final cells = <int, String>{
      2: 'Page Total',
      3: _fmt(woQty),
      4: _fmt(dispatched),
      5: _fmt(balance),
    };

    return Container(
      height: 42,
      color: C.brand50,
      child: Row(
        children: List.generate(_cols.length, (i) {
          return _cell(
            w[i],
            Text(
              cells[i] ?? '',
              style:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
            _cols[i].right,
          );
        }),
      ),
    );
  }
}