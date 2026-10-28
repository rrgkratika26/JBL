import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Color/Colorclass.dart';
import '../../routes/app_routes.dart';
import '../../services/JBL_apis/jbl_api_bailing_reports.dart';
import '../app_colors.dart';
import 'JblDispatchModel.dart';

class _Col {
  final String title;
  final double w;
  final bool right;
  const _Col(this.title, this.w, {this.right = false});
}

class JblPackingReportScreen extends StatefulWidget {
  const JblPackingReportScreen({super.key});

  @override
  State<JblPackingReportScreen> createState() => _JblPackingReportScreenState();
}

class _JblPackingReportScreenState extends State<JblPackingReportScreen> {
  bool isLoading = true;
  List<DispatchModel> dispatchList = [];
  List<DispatchModel> filteredList = [];

  final TextEditingController searchController = TextEditingController();
  final ScrollController _hScroll = ScrollController();

  int currentPage = 1;
  int rowsPerPage = 10;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  static const _cols = <_Col>[
    _Col('#', 50),
    _Col('Dis No', 80),
    _Col('Date', 105),
    _Col('Party Name', 200),
    _Col('PO No', 110),
    _Col('Invoice', 110),
    _Col('Transport', 160),
    _Col('Vehicle', 110),
    _Col('PCS', 70, right: true),
    _Col('Count', 70, right: true),
    _Col('GWT', 90, right: true),
    _Col('Net Wt', 90, right: true),
    _Col('Total TWt', 80, right: true),

    _Col('', 20),
  ];

  @override
  void initState() {
    super.initState();
    loadDispatchData();
  }

  @override
  void dispose() {
    _hScroll.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────
  Future<void> loadDispatchData() async {
    try {
      // TODO: API service mein from/to params add karke yahan pass karo:
      // JblApiService().getDispatchReport(from: _fromDate, to: _toDate)
      final data = await JblApiService().getDispatchReport();

      if (!mounted) return;
      setState(() {
        dispatchList = data;
        isLoading = false;
      });
      filterDispatch(searchController.text);
    } catch (e) {
      debugPrint("❌ Dispatch report error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void filterDispatch(String query) {
    final q = query.toLowerCase().trim();

    setState(() {
      filteredList = q.isEmpty
          ? List.of(dispatchList)
          : dispatchList.where((item) {
        return item.dispatchNo.toString().toLowerCase().contains(q) ||
            item.partyName.toLowerCase().contains(q);
      }).toList();
      currentPage = 1;
    });
  }

  List<DispatchModel> get paginatedList {
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= filteredList.length) return [];
    final end = math.min(start + rowsPerPage, filteredList.length);
    return filteredList.sublist(start, end);
  }

  int get totalPages =>
      math.max(1, (filteredList.length / rowsPerPage).ceil());

  String formatDate(String apiDate) {
    try {
      return DateFormat("dd-MMM-yyyy").format(DateTime.parse(apiDate));
    } catch (_) {
      return apiDate;
    }
  }

  num _n(dynamic v) => num.tryParse(v.toString()) ?? 0;

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
        isLoading = true;
      });
      await loadDispatchData();
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
          "Packing Reports",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            tooltip: "Date range",
            icon: const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: C.appBar3))
          : Column(
        children: [
          _buildSearchBar(),
          _buildRangeChip(),
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
          onChanged: filterDispatch,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search Dispatch No or Party Name",
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                searchController.clear();
                filterDispatch("");
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 10,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRangeChip() {
    final f = DateFormat('dd MMM yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(
            "${f.format(_fromDate)}  →  ${f.format(_toDate)}",
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            "${filteredList.length} records",
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
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
              onPressed: currentPage > 1
                  ? () => setState(() => currentPage--)
                  : null,
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
  /// Screen chhoti ho to fixed widths + horizontal scroll,
  /// badi ho to extra space Party Name le leta hai.
  List<double> _widths(double available) {
    final base = _cols.map((c) => c.w).toList();

    final total = base.fold<double>(0, (a, b) => a + b);

    // Available screen width zyada ho to extra width Party Name ko dein.
    if (available > total) {
      base[3] += available - total;
    }

    // Har column width same rahegi; horizontal scrolling table ko
    // screen se wider hone par scroll karne degi.
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

  Widget _headerRow(List<double> w) {
    return Container(
      color: C.primary,
      height: 44,
      child: Row(
        children: List.generate(_cols.length, (i) {
          return SizedBox(
            width: w[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: _cols[i].right
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  _cols[i].title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _dataRow(DispatchModel item, int sno, int i, List<double> w) {
    final cells = <String>[
      '$sno',
      '${item.dispatchNo}',
      formatDate(item.date),
      item.partyName,
      '${item.poNo}',
      '${item.invoiceNo}',
      '${item.transportName}',
      '${item.vehicleNo}',
      '${item.totalPcs}',
      '${item.totalCount}',
      '${item.totalGwt}',
      '${item.totalNetWt}',
      '${item.totalTwt}',
    ];

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: i.isEven ? Colors.white : const Color(0xFFF6F8FA),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          ...List.generate(cells.length, (c) {
            return SizedBox(
              width: w[c],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: _cols[c].right
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    cells[c],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                      c == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: c == 1
                          ? AppColors.primaryColor
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Last column blank — no arrow and no navigation
          SizedBox(width: w.last),
        ],
      ),
    );
  }

  Widget _totalRow(List<double> w, List<DispatchModel> rows) {
    final pcs = rows.fold<num>(0, (s, e) => s + _n(e.totalPcs));
    final cnt = rows.fold<num>(0, (s, e) => s + _n(e.totalCount));
    final gwt = rows.fold<num>(0, (s, e) => s + _n(e.totalGwt));
    final net = rows.fold<num>(0, (s, e) => s + _n(e.totalNetWt));

    final cells = <int, String>{
      3: 'Page Total',
      8: pcs.toStringAsFixed(0),
      9: cnt.toStringAsFixed(0),
      10: gwt.toStringAsFixed(2),
      11: net.toStringAsFixed(2),
    };

    return Container(
      height: 42,
      color: C.brand50,
      child: Row(
        children: List.generate(_cols.length, (i) {
          return SizedBox(
            width: w[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: _cols[i].right
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  cells[i] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}