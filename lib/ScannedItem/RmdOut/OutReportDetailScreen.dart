import 'package:flutter/material.dart';
import '../../Color/Colorclass.dart';
import '../../services/getSupervisors/getSupervisors.dart';

class OutReportDetailsScreen extends StatelessWidget {
  final String date;
  OutReportDetailsScreen({Key? key, required this.date}) : super(key: key);

  final InStockService _service = InStockService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: C.bg),
        title: const Text('RMD OUT Report', style: TextStyle(color: C.bg)),
        centerTitle: true,
        backgroundColor: C.appBar1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.getOutScannedItems(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          // return ListView.builder(
          //   padding: const EdgeInsets.all(12),
          //   itemCount: items.length,
          //   itemBuilder: (context, index) {
          //     final item = items[index];
          //
          //     return Card(
          //       elevation: 4,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       margin: const EdgeInsets.only(bottom: 12),
          //       child: Padding(
          //         padding: const EdgeInsets.all(12),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //               children: [
          //                 Text(
          //                   'Barcode: ${item['BARCODE'] ?? 'N/A'}',
          //                   style: const TextStyle(
          //                     fontSize: 16,
          //                     fontWeight: FontWeight.bold,
          //                   ),
          //                 ),
          //                 Container(
          //                   padding: const EdgeInsets.symmetric(
          //                       horizontal: 10, vertical: 4),
          //                   decoration: BoxDecoration(
          //                     color: Colors.orange,
          //                     borderRadius: BorderRadius.circular(20),
          //                   ),
          //                   child: const Text(
          //                     'OUT',
          //                     style: TextStyle(
          //                       color: Colors.white,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //             const Divider(height: 20),
          //             _infoRow('Fabric Code', item['FABRIC_CODE']?.toString() ?? '-'),
          //           // _infoRow('Roll Code', item['ROLL CODE']?.toString() ?? '-'),
          //           //_infoRow('Roll Code', item['rollCode']?.toString() ?? '-'), // visa
          //
          //             _infoRow('Net Weight (Kg)', item['NET_WEIGHT (Kg)']?.toString() ?? '-'),
          //             _infoRow('Roll Length (Mtr)', item['ROLL_LENGTH (Mtr)']?.toString() ?? '-'),
          //             _infoRow('Supervisor', item['SUPERVISOR']?.toString() ?? '-'),
          //             _infoRow('Location', item['LOCATION']?.toString() ?? '-'),
          //           ],
          //         ),
          //       ),
          //     );
          //   },
          // );

          return Column(
            children: [
              /// Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: C.appBar1.withOpacity(.08),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  "Total Records : ${items.length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 900),
                      child: SingleChildScrollView(
                        child: DataTable(
                          showBottomBorder: true,
                          headingRowHeight: 50,
                          dataRowMinHeight: 45,
                          // horizontalMargin: 3,
                          columnSpacing: 20,
                          dividerThickness: .6,
                          border: TableBorder.all(
                            color: Colors.grey.shade300,
                            width: .6,
                          ),

                          headingRowColor: WidgetStateProperty.all(
                            C.appBar1.withOpacity(.12),
                          ),

                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),

                          columns: const [
                            DataColumn(label: Center(child: Text("Barcode"))),
                            DataColumn(
                              label: Center(child: Text("Fabric Code")),
                            ),
                            DataColumn(
                              label: Center(child: Text("Weight (Kg)")),
                            ),
                            DataColumn(
                              label: Center(child: Text("Length (Mtr)")),
                            ),
                            DataColumn(
                              label: Center(child: Text("Supervisor")),
                            ),
                            DataColumn(label: Center(child: Text("Location"))),

                            DataColumn(label: Center(child: Text("Status"))),
                          ],

                          rows: List.generate(items.length, (index) {
                            final item = items[index];
                            final bool isIn = item["ACTIVEIN"] == "IN";

                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>((
                                states,
                              ) {
                                if (index.isEven) {
                                  return Colors.grey.shade50;
                                }
                                return Colors.white;
                              }),
                              cells: [
                                /// Barcode
                                DataCell(
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      item["BARCODE"] ?? "-",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                                /// Fabric Code
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      item["FABRIC_CODE"] ?? "-",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                                /// Weight
                                DataCell(
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      item['NET_WEIGHT (Kg)']?.toString() ??
                                          "-",
                                    ),
                                  ),
                                ),

                                /// Length
                                DataCell(
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      item['ROLL_LENGTH (Mtr)']?.toString() ??
                                          "-",
                                    ),
                                  ),
                                ),

                                /// Supervisor
                                DataCell(
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      item["SUPERVISOR"] ?? "-",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                                /// Location
                                DataCell(
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      item["LOCATION"] ?? "-",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                                /// In Date

                                /// Status
                                DataCell(
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isIn
                                            ? Colors.green
                                            : C.actionOrange,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        isIn ? "IN" : "OUT",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  //
  // String _formatDate(dynamic date) {
  //   if (date == null || date.toString().isEmpty) return '-';
  //   return date.toString().split('T').first;
  // }


}
