import 'dart:async';

import 'package:flutter/material.dart';

import '../../../Color/Colorclass.dart';
import '../../../services/JBL_apis/jbl_api_bailing_reports.dart';
import 'PackingEntryScreen.dart';
import 'PackingReportModel.dart';

class PackingBagReportScreen extends StatefulWidget {
  const PackingBagReportScreen({super.key});

  @override
  State<PackingBagReportScreen> createState() => _PackingBagReportScreenState();
}

class _PackingBagReportScreenState extends State<PackingBagReportScreen> {
  List<PackingBagReportModel> reportList = [];
  List<PackingBagReportModel> filteredList = [];

  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchData();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final data = await JblApiService.getPackingBagReport();

      if (!mounted) return;

      setState(() {
        reportList = data;
        _applyFilter(searchController.text);
        loading = false;
      });
    } catch (e) {
      debugPrint('Packing Bag Report Error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load packing report')),
      );
    }
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();

    filteredList = reportList.where((item) {
      final party = item.partyname?.toString().toLowerCase() ?? '';
      final wo = item.workOrderNo?.toString().toLowerCase() ?? '';

      return party.contains(q) || wo.contains(q);
    }).toList();
  }

  num _number(dynamic value) {
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _openEntry(PackingBagReportModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PackingEntryBag(data: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.pageBg,
      appBar: AppBar(
        backgroundColor: C.appBar1,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Packing Bag Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  _applyFilter(value);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Party Name or WO No',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            _applyFilter('');
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchData,
                    child: filteredList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 150),
                              Center(
                                child: Text(
                                  reportList.isEmpty
                                      ? 'No Data Found'
                                      : 'No matching records found',
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width,
                              ),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    C.appBar1.withOpacity(0.12),
                                  ),
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  dataTextStyle: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  columnSpacing: 20,
                                  horizontalMargin: 12,
                                  dataRowMinHeight: 46,
                                  dataRowMaxHeight: 60,
                                  columns: const [
                                    DataColumn(label: Text('Party Name')),
                                    DataColumn(label: Text('WO No')),
                                    DataColumn(label: Text('Article')),
                                    DataColumn(label: Text('Bag Type')),
                                    DataColumn(label: Text('Size')),
                                    DataColumn(label: Text('Order')),
                                    DataColumn(label: Text('Manufactured')),
                                    DataColumn(label: Text('Packed')),
                                    DataColumn(label: Text('Balance')),
                                    DataColumn(label: Text('Status')),
                                  ],
                                  rows: filteredList.map((e) {
                                    final balance = _number(e.balanceBag);
                                    final completed = balance <= 0;

                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith((
                                        states,
                                      ) {
                                        if (states.contains(
                                          WidgetState.hovered,
                                        )) {
                                          return C.appBar1.withOpacity(0.08);
                                        }
                                        return null;
                                      }),
                                      onSelectChanged: (selected) {
                                        if (selected == true) {
                                          _openEntry(e);
                                        }
                                      },
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: 150,
                                            child: Text(
                                              e.partyname?.toString() ?? '-',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            e.workOrderNo?.toString() ?? '-',
                                          ),
                                        ),
                                        DataCell(
                                          Text(e.articleNo?.toString() ?? '-'),
                                        ),
                                        DataCell(
                                          Text(e.bagtype?.toString() ?? '-'),
                                        ),
                                        DataCell(
                                          Text(e.bagsize?.toString() ?? '-'),
                                        ),
                                        DataCell(
                                          Text(e.orderQty?.toString() ?? '0'),
                                        ),
                                        DataCell(
                                          Text(e.totalManf?.toString() ?? '0'),
                                        ),
                                        DataCell(
                                          Text(e.packedBags?.toString() ?? '0'),
                                        ),
                                        DataCell(
                                          Text(e.balanceBag?.toString() ?? '0'),
                                        ),
                                        DataCell(
                                          Text(
                                            completed ? 'Completed' : 'Pending',
                                            style: TextStyle(
                                              color: completed
                                                  ? Colors.green
                                                  : Colors.orange.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
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
        ],
      ),
    );
  }
}
