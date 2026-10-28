import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Color/Colorclass.dart';
import '../RecievedScannedItems.dart';

class JblReceiveDetailScreen extends StatelessWidget {
  final String title;
  final String date;
  final List<ReceiveScannedItem> items;

  const JblReceiveDetailScreen({
    Key? key,
    required this.title,
    required this.date,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.appBar1,
        iconTheme: IconThemeData(color: C.primaryLight),
        title: Text(
          title,
          style: TextStyle(
            color: C.primaryLight,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Text(
            '${items.length} records',
            style: TextStyle(color: C.bg, fontSize: 15),
          ),
        ],
      ),

      body: items.isEmpty
          ? const Center(child: Text('No Data Found'))
          : Column(
              children: [
                // ============== TABLE ==============
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(C.appBar1),
                            headingTextStyle: TextStyle(
                              color: C.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            dataTextStyle: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                            columnSpacing: 22,
                            horizontalMargin: 12,
                            headingRowHeight: 45,
                            dataRowMinHeight: 45,
                            dataRowMaxHeight: 60,

                            columns: const [
                              DataColumn(label: Text('Sr No')),
                              DataColumn(label: Text('Barcode')),
                              DataColumn(label: Text('Roll Code')),
                              DataColumn(label: Text('Party')),
                              DataColumn(label: Text('Work Order')),
                              DataColumn(label: Text('Net Kg')),
                              DataColumn(label: Text('Length Mtr')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Location')),
                              DataColumn(label: Text('Supervisor')),
                              DataColumn(label: Text('Date')),
                            ],

                            rows: items.map((e) {
                              return DataRow(
                                cells: [
                                  DataCell(Text('${e.srNo}')),
                                  DataCell(Text(e.barcode)),
                                  DataCell(Text('${e.rollCode}')),
                                  DataCell(Text(e.partyName)),
                                  DataCell(Text(e.workOrderNo)),
                                  DataCell(
                                    Text(e.netWeightKg.toStringAsFixed(2)),
                                  ),
                                  DataCell(
                                    Text(e.rollLengthMtr.toStringAsFixed(2)),
                                  ),
                                  DataCell(_statusCell(e.status)),
                                  DataCell(Text(e.location)),
                                  DataCell(Text(e.supervisorName)),
                                  DataCell(
                                    Text(
                                      e.date == null
                                          ? '-'
                                          : DateFormat(
                                              'dd-MM-yyyy',
                                            ).format(e.date!),
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

  // ============== STATUS ==============

  Widget _statusCell(String status) {
    final received = status.toLowerCase() == 'receive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: received
            ? Colors.green.withOpacity(0.12)
            : Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: TextStyle(
          color: received ? Colors.green.shade700 : Colors.orange.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
