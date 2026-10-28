import 'package:flutter/material.dart';
import '../../../Color/Colorclass.dart';
import '../../../services/getSupervisors/getSupervisors.dart';

class LaminationDetailScreen extends StatelessWidget {
  final String date;
  final String plant;

  LaminationDetailScreen({Key? key, required this.date, required this.plant})
    : super(key: key);

  final InStockService _service = InStockService();

  @override
  Widget build(BuildContext context) {
    debugPrint("Selected Plant 👉 $plant");
    debugPrint("Selected Date 👉 $date");
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: C.bg),
        title: Text('Lamination In Report', style: TextStyle(color: C.bg)),

        centerTitle: true,
        backgroundColor: C.appBar1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.getLaminationScannedItems(date: date, plant: plant),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('No Lamination data found'));
          }

          return Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1200,
                  child: Column(
                    children: [
                      /// Header
                      Container(
                        height: 50,
                        color: C.appBar1.withOpacity(.12),
                        child: Row(
                          children: const [
                            HeaderCell("Barcode", 80),
                            HeaderCell("BOM No", 120),
                            HeaderCell("Fabric Code", 200),
                            HeaderCell("Roll Code", 100),
                            HeaderCell("Weight", 90),
                            HeaderCell("Length", 90),
                            HeaderCell("Supervisor", 150),
                            HeaderCell("Location", 120),
                            HeaderCell("Status", 120),
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
                                  DataCellWidget(item["BARCODE"], 120),
                                  DataCellWidget(item["BOM_NO"], 100),
                                  DataCellWidget(item["FABRIC_CODE"], 200),
                                  DataCellWidget(item["ROLL CODE"], 100),
                                  DataCellWidget(item["NET_WEIGHT (Kg)"], 90),
                                  DataCellWidget(item["ROLL_LENGTH (Mtr)"], 90),
                                  DataCellWidget(item["SUPERVISOR"], 150),
                                  DataCellWidget(item["LOCATION"], 120),
                                  SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: C.primaryDark,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          "LAMINATION",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
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
          );
        },
      ),
    );
  }
}

class HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const HeaderCell(this.text, this.width, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class DataCellWidget extends StatelessWidget {
  final dynamic value;
  final double width;

  const DataCellWidget(this.value, this.width, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(value?.toString() ?? "-", overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class TableHeading extends StatelessWidget {
  final String title;
  final double width;

  const TableHeading(this.title, this.width, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class TableCellText extends StatelessWidget {
  final dynamic value;
  final double width;

  const TableCellText(this.value, this.width, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(value?.toString() ?? "-", overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
