import 'package:IMS/services/DashboardApiServices.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/getSupervisors/getSupervisors.dart';
import '../../Color/Colorclass.dart';
import '../../JBL/JBLWebbing/Reports_model/outReportModel.dart';
import 'ReportmodelClass/ReportModelClass.dart';
import 'ReportmodelClass/WebOutDetailsclass.dart' hide WebbingOutReportModel;

class WebbOutReportDetailsScreen extends StatelessWidget {
  final String date;

  const WebbOutReportDetailsScreen({Key? key, required this.date})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.primary,
        title: const Text("Webbing Out Stock",style: TextStyle(color: C.bg),),
        centerTitle: true,
        iconTheme: IconThemeData(color: C.bg),
      ),
      body: FutureBuilder<WebbingOutDetailsModel?>(
        future: DashboardService.fetchWebbingScannedOutItems(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No Data Found"));
          }

          final items = snapshot.data!.items;

          if (items.isEmpty) {
            return const Center(child: Text("No Items Found"));
          }

          return  Column(
            children: [
              /// Total Records
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: C.primary.withOpacity(.08),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                    ),
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
                    child: SizedBox(
                      width: 1900,
                      child: Column(
                        children: [

                          /// Header
                          Container(
                            height: 48,
                            color: C.primary.withOpacity(.12),
                            child: const Row(
                              children: [
                                _HeaderCell("Barcode", 80),
                                _HeaderCell("SR No", 70),
                                _HeaderCell("Roll Code", 70),
                                _HeaderCell("BOM No", 100),
                                _HeaderCell("Lot No", 100),
                                _HeaderCell("Fabric Code", 220),
                                _HeaderCell("Weight", 90),
                                _HeaderCell("Length", 90),
                                _HeaderCell("Party Name", 180),
                                _HeaderCell("Work Order", 140),
                                _HeaderCell("Order Type", 120),
                                _HeaderCell("Belt Type", 120),
                                _HeaderCell("Belt Width", 100),
                                _HeaderCell("Belt GSM", 100),
                                _HeaderCell("Date", 110),
                                _HeaderCell("Time", 90),
                                _HeaderCell("Status", 100),
                              ],
                            ),
                          ),

                          const Divider(height: 1),

                          /// Body
                          Expanded(
                            child: ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: Colors.grey.shade300),
                              itemBuilder: (context, index) {
                                final item = items[index];

                                return Container(
                                  color: index.isEven
                                      ? Colors.grey.shade50
                                      : Colors.white,
                                  height: 50,
                                  child: Row(
                                    children: [

                                      _DataCell(item.barcode, 80),

                                      _DataCell(item.srNo.toString(), 70),

                                      _DataCell(item.rollCode, 70),

                                      _DataCell(item.weekNo, 100),

                                      _DataCell(item.lotNo, 100),

                                      _DataCell(item.fabricCode, 220),

                                      _DataCell(
                                        item.rollWeight.toString(),
                                        90,
                                      ),

                                      _DataCell(
                                        item.rollLength.toString(),
                                        90,
                                      ),

                                      _DataCell(item.partyName, 180),

                                      _DataCell(item.workOrderNo, 140),

                                      _DataCell(item.orderType, 120),

                                      _DataCell(item.beltType, 120),

                                      _DataCell(item.beltWidth, 100),

                                      _DataCell(item.beltGSM, 100),

                                      _DataCell(
                                        DateFormat("dd-MM-yyyy")
                                            .format(item.date),
                                        110,
                                      ),

                                      _DataCell(item.time, 90),

                                      SizedBox(
                                        width: 100,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                              BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              "OUT",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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

}


class _DataCell extends StatelessWidget {
  final String text;
  final double width;

  const _DataCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Text(
        text.isEmpty ? "-" : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}


