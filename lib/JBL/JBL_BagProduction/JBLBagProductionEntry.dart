import 'package:IMS/services/JBL_apis/jbl_api_bailing_reports.dart';
import 'package:flutter/material.dart';

import '../../Color/Colorclass.dart';
import 'JblFormENtryScreen.dart';

// ───────────────── MODEL ─────────────────

class JBLBagEntryModel {
  final String customerName;
  final String woNumber;
  final String articleNo;
  final int quantity;
  final int remainingToProduce;
  final int canProduction;

  JBLBagEntryModel({
    required this.customerName,
    required this.woNumber,
    required this.articleNo,
    required this.quantity,
    required this.remainingToProduce,
    required this.canProduction,
  });

  factory JBLBagEntryModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return JBLBagEntryModel(
      customerName: json['customeR_NAME']?.toString() ?? '',
      woNumber: json['wO_NUMBER']?.toString() ?? '',
      articleNo: json['articlE_NO']?.toString() ?? '',
      quantity: toInt(json['quantity']),
      remainingToProduce: toInt(json['remaininG_TO_PRODUCE']),
      canProduction: toInt(json['caN_PRODUCTION']),
    );
  }
}

// ───────────────── SCREEN ─────────────────

class JBLBagEntryScreen extends StatefulWidget {
  const JBLBagEntryScreen({super.key});

  @override
  State<JBLBagEntryScreen> createState() => _JBLBagEntryScreenState();
}

class _JBLBagEntryScreenState extends State<JBLBagEntryScreen> {
  final JblApiService _service = JblApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  List<JBLBagEntryModel> _allData = [];
  List<JBLBagEntryModel> _filteredData = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  int _pageSize = 10;
  int _currentPage = 1;

  int get _totalPages =>
      _filteredData.isEmpty ? 1 : (_filteredData.length / _pageSize).ceil();

  int get _startIndex =>
      _filteredData.isEmpty ? 0 : (_currentPage - 1) * _pageSize;

  int get _endIndex => (_startIndex + _pageSize).clamp(0, _filteredData.length);

  List<JBLBagEntryModel> get _visibleData {
    if (_filteredData.isEmpty) return [];
    return _filteredData.sublist(_startIndex, _endIndex);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  // ───────────────── LOAD DATA ─────────────────

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('========== JBL BAG ENTRY API ==========');

      final data = await JblApiService.getjblBagEntryData();

      debugPrint('Bag entry records received: ${data.length}');

      if (!mounted) return;

      setState(() {
        _allData = data;
        _applyFilters(resetPage: true);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Bag entry loading error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load bag entries.\n$e';
      });
    }
  }

  Future<void> _refreshData() async {
    _searchController.clear();
    await _loadInitialData();
  }

  // ───────────────── SEARCH / FILTER ─────────────────

  void _onSearchChanged(String query) {
    setState(() {
      _applyFilters(resetPage: true);
    });
  }

  void _applyFilters({bool resetPage = false}) {
    final query = _searchController.text.trim().toLowerCase();

    _filteredData = _allData.where((item) {
      return item.customerName.toLowerCase().contains(query) ||
          item.woNumber.toLowerCase().contains(query) ||
          item.articleNo.toLowerCase().contains(query);
    }).toList();

    if (resetPage) {
      _currentPage = 1;
    } else if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
  }

  // ───────────────── PAGINATION ─────────────────

  void _changePage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;

    setState(() {
      _currentPage = page;
    });
  }

  void _changePageSize(int? size) {
    if (size == null) return;

    setState(() {
      _pageSize = size;
      _currentPage = 1;
    });
  }

  // ───────────────── NAVIGATION ─────────────────

  void _navigateToDetails(JBLBagEntryModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JBLFormScreen(
          partyName: item.customerName,
          woNumber: item.woNumber,
          articleNo: item.articleNo,
          quantity: item.quantity,
          remainingToProduce: item.remainingToProduce,
          canProduction: item.canProduction,
        ),
      ),
    );
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.primary,
        iconTheme: const IconThemeData(color: C.bgColor),
        title: const Text(
          'Bag Entries',
          style: TextStyle(color: C.bgColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${_filteredData.length} entries',
                style: const TextStyle(
                  color: C.bgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _refreshData,
            icon: const Icon(Icons.refresh, color: C.bgColor),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: C.appBar3),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadInitialData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_filteredData.isEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 140),
                      Icon(Icons.inbox_outlined, size: 58),
                      SizedBox(height: 12),
                      Center(child: Text('No bag entries found')),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    _buildResultSummary(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  C.primary,
                                ),
                                headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                dataRowMinHeight: 44,
                                dataRowMaxHeight: 52,
                                columnSpacing: 20,
                                horizontalMargin: 12,
                                border: TableBorder.all(
                                  color: Colors.blue.shade100,
                                ),
                                columns: const [
                                  DataColumn(label: Text('#')),
                                  DataColumn(label: Text('Customer Name')),
                                  DataColumn(label: Text('WO Number')),
                                  DataColumn(label: Text('Article No')),
                                  DataColumn(
                                    label: Text('Quantity'),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('Remaining'),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('Can Prod.'),
                                    numeric: true,
                                  ),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: _visibleData.asMap().entries.map((entry) {
                                  final item = entry.value;
                                  final rowNumber = _startIndex + entry.key + 1;

                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith(
                                      (states) => rowNumber.isEven
                                          ? Colors.blue.shade50
                                          : Colors.white,
                                    ),
                                    cells: [
                                      DataCell(Text('$rowNumber')),
                                      DataCell(
                                        SizedBox(
                                          width: 160,
                                          child: Text(
                                            item.customerName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(item.woNumber)),
                                      DataCell(Text(item.articleNo)),
                                      DataCell(Text('${item.quantity}')),
                                      DataCell(
                                        Text(
                                          '${item.remainingToProduce}',
                                          style: TextStyle(
                                            color: item.remainingToProduce > 0
                                                ? Colors.orange.shade800
                                                : Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text('${item.canProduction}')),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed: () =>
                                              _navigateToDetails(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF42A5F6,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text('Open'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildPaginationBar(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search customer, WO number, article...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _filteredData.isEmpty
                  ? 'Showing 0 entries'
                  : 'Showing ${_startIndex + 1}–$_endIndex '
                        'of ${_filteredData.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Text('Rows: ', style: TextStyle(fontSize: 12)),
          DropdownButton<int>(
            value: _pageSize,
            isDense: true,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 20, child: Text('20')),
              DropdownMenuItem(value: 50, child: Text('50')),
            ],
            onChanged: _changePageSize,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'First page',
            onPressed: _currentPage > 1 ? () => _changePage(1) : null,
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: _currentPage > 1
                ? () => _changePage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: _currentPage < _totalPages
                ? () => _changePage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Last page',
            onPressed: _currentPage < _totalPages
                ? () => _changePage(_totalPages)
                : null,
            icon: const Icon(Icons.last_page),
          ),
        ],
      ),
    );
  }
}
