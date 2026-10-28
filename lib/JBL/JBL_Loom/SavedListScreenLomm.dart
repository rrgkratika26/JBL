// import 'package:IMS/services/getSupervisors/getSupervisors.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:get/get_navigation/src/extension_navigation.dart';
// import 'package:get/get_navigation/src/snackbar/snackbar.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:thermal_printer_plus/thermal_printer.dart';
//
// import '../../Color/Colorclass.dart';
// import '../../NARDANA/LoomReprts/LoomReports.dart';
// import 'LoomListSavedModel.dart';
//
// class SavedListScreen extends StatefulWidget {
//   const SavedListScreen({super.key});
//
//   @override
//   State<SavedListScreen> createState() => _SavedListScreenState();
// }
//
// class _SavedListScreenState extends State<SavedListScreen> {
//   late Future<List<LoomListModel>> futureData;
//   final _storage = GetStorage();
//   List<BluetoothInfo> printers = [];
//   bool isScanning = false;
//
//   Future<void> _checkPrinterConnection() async {
//     bool? isConnected = await PrintBluetoothThermal.connectionStatus;
//
//     Get.snackbar(
//       "Printer Status",
//       isConnected == true ? "✅ Printer Connected" : "❌ Printer Not Connected",
//       backgroundColor: isConnected == true ? Colors.green : Colors.red,
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     futureData = InStockService().fetchLoomList();
//   }
//
//   Future<void> scanPrinters() async {
//     setState(() {
//       isScanning = true;
//       printers.clear();
//     });
//
//     try {
//       final result = await PrintBluetoothThermal.pairedBluetooths;
//
//       setState(() {
//         printers = result;
//         isScanning = false;
//       });
//
//       if (printers.isEmpty) {
//         Get.snackbar(
//           "No Printer",
//           "No paired printers found",
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//         );
//       }
//     } catch (e) {
//       setState(() {
//         isScanning = false;
//       });
//
//       Get.snackbar(
//         "Error",
//         e.toString(),
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
//
//   void showPrinterList() async {
//     await scanPrinters();
//
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) {
//         return SizedBox(
//           height: 400,
//           child: Column(
//             children: [
//               const SizedBox(height: 15),
//
//               const Text(
//                 "Select Printer",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//
//               const Divider(),
//
//               if (isScanning)
//                 const Expanded(
//                   child: Center(child: CircularProgressIndicator()),
//                 )
//               else
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: printers.length,
//                     itemBuilder: (_, index) {
//                       final p = printers[index];
//
//                       return ListTile(
//                         leading: const Icon(Icons.print, color: Colors.blue),
//
//                         title: Text(p.name ?? "Unknown"),
//
//                         subtitle: Text(p.macAdress ?? ""),
//
//                         onTap: () async {
//                           _storage.write('printer_name', p.name);
//
//                           _storage.write('printer_address', p.macAdress);
//
//                           Navigator.pop(context);
//
//                           Get.snackbar(
//                             "Success",
//                             "Printer Connected",
//                             backgroundColor: Colors.green,
//                             colorText: Colors.white,
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: C.bg,
//       appBar: AppBar(
//         title: const Text("Loom List", style: TextStyle(color: C.bg)),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             // gradient: LinearGradient(
//             //   colors: [
//             //     C.appBar1,
//             //     C.appBar4,
//             //   ],
//             // ),
//             color: C.appBar1
//           ),
//         ),
//         // C.primary,
//         elevation: 0,
//         iconTheme: IconThemeData(color: C.bg),
//         actions: [
//           // IconButton(
//           //   icon: const Icon(Icons.bluetooth),
//           //   onPressed: _checkPrinterConnection,
//           // ),
//           IconButton(
//             icon: const Icon(Icons.bluetooth_searching,color: C.textHead,),
//             onPressed: showPrinterList,
//           ),
//         ],
//       ),
//       body: FutureBuilder<List<LoomListModel>>(
//         future: futureData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: C.appBar3),
//             );
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }
//
//           final data = snapshot.data!;
//
//           if (data.isEmpty) {
//             return const Center(child: Text("No Data Found"));
//           }
//
//           return Padding(
//             padding: const EdgeInsets.all(12),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(14),
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: SingleChildScrollView(
//                     child: DataTable(
//                       columnSpacing: 24,
//                       headingRowHeight: 50,
//                       dataRowHeight: 52,
//
//                       headingRowColor: MaterialStateProperty.all(C.border),
//
//                       columns: const [
//                         DataColumn(label: Text("ID")),
//                         DataColumn(label: Text("Barcode")),
//                         DataColumn(label: Text("Fabric Code")),
//                         // DataColumn(label: Text("Supervisor")),
//                         // DataColumn(label: Text("Party Name")),
//                         DataColumn(label: Text("OrderNo.")),
//                         // DataColumn(label: Text("Work Order")),
//                         // DataColumn(label: Text("Req.Qty(Kg)")),
//                         // DataColumn(label: Text("Req.Qty(Mtr)")),
//                         DataColumn(label: Text("Date")),
//                         DataColumn(label: Text("Time")),
//                         DataColumn(label: Text("Fab GSM")),
//                         // DataColumn(label: Text("Color")),
//                         DataColumn(label: Text("Net Wt")),
//                         DataColumn(label: Text("Roll L.Mtr")),
//                         // DataColumn(label: Text("Loom Type")),
//                         // DataColumn(label: Text("Department")),
//                         DataColumn(label: Text(" Print Barcode")),
//                       ],
//
//                       rows: List.generate(data.length, (index) {
//                         final e = data[index];
//
//                         return DataRow(
//                           color: MaterialStateProperty.all(
//                             index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
//                           ),
//                           cells: [
//                             DataCell(Text(e.id.toString())),
//                             DataCell(Text(e.barcode)),
//                             DataCell(Text(e.flattubegusset)),
//                             // DataCell(Text(e.supervisor)),
//                             // DataCell(Text(e.machineNo)),
//                             DataCell(Text(e.partyName)),
//
//                             /// ✅ NEW
//                             // DataCell(Text(e.workOrderNo)),
//                             //
//                             // DataCell(Text(e.requiredNetWt.toString())),
//                             // DataCell(Text(e.requiredQtyMtr.toString())),
//
//                             DataCell(
//                               Text(
//                                 e.date != null
//                                     ? "${e.date!.day}-${e.date!.month}-${e.date!.year}"
//                                     : "-",
//                               ),
//                             ),
//
//                             DataCell(Text(e.time)),
//                             DataCell(Text(e.gsm)),
//                             // DataCell(Text(e.color)),
//                             DataCell(Text(e.netWt.toString())),
//                             DataCell(Text(e.quantity.toString())),
//
//                             /// ✅ NEW
//                             // DataCell(Text(e.modelNo)),
//                             // DataCell(Text(e.department)),
//
//                             // DataCell(
//                             //   ElevatedButton(
//                             //     onPressed: () => _printBarcodeApi(e),
//                             //     child: const Text(
//                             //       "Print / Issue",
//                             //       style: TextStyle(color: C.success),
//                             //     ),
//                             //   ),
//                             // ),
//                             DataCell(
//                               ElevatedButton(
//                                 onPressed: () => _showIssueOptions(e),
//                                 child: const Text(
//                                   "Print / Issue",
//                                   style: TextStyle(color: C.success),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       }),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//     Future<void> _printBarcodeApi(LoomListModel item) async {
//       final address = _storage.read<String>('printer_address');
//       final name = _storage.read<String>('printer_name') ?? 'Printer';
//
//       if (address == null) {
//         Get.snackbar(
//           "Printer Error",
//           "❌ Please connect printer first",
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//         return;
//       }
//
//       /// 🔹 Confirm dialog
//       final confirm = await showDialog<bool>(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("Print Barcode"),
//           content: Text("Print barcode?\n\n${item.barcode}"),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text("Yes, Print"),
//             ),
//           ],
//         ),
//       );
//
//       if (confirm != true) return;
//
//       try {
//         /// 🔥 CONNECT PRINTER
//         await PrinterManager.instance.disconnect(type: PrinterType.bluetooth);
//         await Future.delayed(const Duration(milliseconds: 400));
//
//         await PrinterManager.instance.connect(
//           type: PrinterType.bluetooth,
//           model: BluetoothPrinterInput(
//             name: name,
//             address: address,
//             isBle: false,
//             autoConnect: false,
//           ),
//         );
//
//         await Future.delayed(const Duration(milliseconds: 800));
//
//         /// 🔥 WAKE PRINTER
//         await PrinterManager.instance.send(
//           type: PrinterType.bluetooth,
//           bytes: [27, 64],
//         );
//
//         await Future.delayed(const Duration(milliseconds: 200));
//
//         /// 🔥 TSPL LABEL (LIKE YOUR FIRST CODE)
//         String tspl =
//             '''
//   SIZE 100 mm,100 mm
//   GAP 3 mm,0 mm
//   DIRECTION 1
//   CLS
//
//   TEXT 30,80,"3",0,1,2,"${item.partyName}"
//
//   TEXT 40,140,"3",0,2,2,"BARCODE:${item.barcode}"
//   TEXT 40,200,"3",0,2,2,"OP:${item.operator}"
//
//   TEXT 40,260,"3",0,2,2,"SUP:${item.supervisor}"
//   TEXT 40,320,"3",0,2,2,"QTY:${item.quantity}"
//
//   QRCODE 240,390,L,12,A,0,"${item.barcode}"
//
//   TEXT 180,660,"3",0,2,2,"${item.barcode}"
//
//   PRINT 1
//   ''';
//
//         /// 🔥 PRINT
//         await PrinterManager.instance.send(
//           type: PrinterType.bluetooth,
//           bytes: tspl.codeUnits,
//         );
//
//         /// 🔥 OPTIONAL API CALL AFTER PRINT
//         final response = await InStockService().printBarcode(
//           id: item.id,
//           barcode: item.barcode,
//         );
//
//         Get.snackbar(
//           "Success",
//           response['message'] ?? "Printed Successfully",
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//         );
//       } catch (e) {
//         Get.snackbar(
//           "Error",
//           "❌ Print failed: $e",
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//       }
//     }
//
// //   Future<void> _printBarcodeApi(LoomListModel item) async {
// //     final address = _storage.read<String>('printer_address');
// //     final name = _storage.read<String>('printer_name') ?? 'Printer';
// //
// //     /// Printer selected or not
// //     if (address == null || address.isEmpty) {
// //       Get.snackbar(
// //         "Printer Error",
// //         "❌ Please connect printer first",
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //       );
// //       return;
// //     }
// //
// //     /// Confirm dialog
// //     final confirm = await showDialog<bool>(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         title: const Text("Print Barcode"),
// //         content: Text("Print barcode?\n\n${item.barcode}"),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context, false),
// //             child: const Text("Cancel"),
// //           ),
// //           ElevatedButton(
// //             onPressed: () => Navigator.pop(context, true),
// //             child: const Text("Yes, Print"),
// //           ),
// //         ],
// //       ),
// //     );
// //
// //     if (confirm != true) return;
// //
// //     try {
// //       /// Disconnect previous connection
// //       await PrinterManager.instance.disconnect(type: PrinterType.bluetooth);
// //
// //       await Future.delayed(const Duration(milliseconds: 500));
// //
// //       /// Connect printer
// //       await PrinterManager.instance.connect(
// //         type: PrinterType.bluetooth,
// //         model: BluetoothPrinterInput(
// //           name: name,
// //           address: address,
// //           isBle: false,
// //           autoConnect: false,
// //         ),
// //       );
// //
// //       await Future.delayed(const Duration(seconds: 1));
// //
// //       /// Verify connection
// //       bool? isConnected = await PrintBluetoothThermal.connectionStatus;
// //
// //       if (isConnected != true) {
// //         Get.snackbar(
// //           "Printer Error",
// //           "❌ Printer not connected",
// //           backgroundColor: Colors.red,
// //           colorText: Colors.white,
// //         );
// //
// //         return; // STOP HERE
// //       }
// //
// //       /// Wake printer
// //       await PrinterManager.instance.send(
// //         type: PrinterType.bluetooth,
// //         bytes: [27, 64],
// //       );
// //
// //       await Future.delayed(const Duration(milliseconds: 300));
// //
// //       String tspl =
// //           '''
// // SIZE 100 mm,100 mm
// // GAP 3 mm,0 mm
// // DIRECTION 1
// // CLS
// //
// // TEXT 30,80,"3",0,1,2,"${item.partyName}"
// //
// // TEXT 40,140,"3",0,2,2,"BARCODE:${item.barcode}"
// // TEXT 40,200,"3",0,2,2,"OP:${item.operator}"
// //
// // TEXT 40,260,"3",0,2,2,"SUP:${item.supervisor}"
// // TEXT 40,320,"3",0,2,2,"QTY:${item.quantity}"
// //
// // QRCODE 240,390,L,12,A,0,"${item.barcode}"
// //
// // TEXT 180,660,"3",0,2,2,"${item.barcode}"
// //
// // PRINT 1
// // ''';
// //
// //       /// Send print data
// //       await PrinterManager.instance.send(
// //         type: PrinterType.bluetooth,
// //         bytes: tspl.codeUnits,
// //       );
// //
// //       /// Wait before API call
// //       await Future.delayed(const Duration(seconds: 2));
// //
// //       /// API ONLY AFTER SUCCESSFUL PRINT
// //       final response = await InStockService().printBarcode(
// //         id: item.id,
// //         barcode: item.barcode,
// //       );
// //
// //       Get.snackbar(
// //         "Success",
// //         response['message'] ?? "Printed Successfully",
// //         backgroundColor: Colors.green,
// //         colorText: Colors.white,
// //       );
// //     } catch (e) {
// //       Get.snackbar(
// //         "Print Failed",
// //         "❌ $e",
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //       );
// //     }
// //   }
//
//
//
//
//   Future<bool?> _showPrintPreview(LoomListModel item) {
//     return showDialog<bool>(
//       context: context,
//       builder: (_) {
//         return AlertDialog(
//           title: const Text("Print Preview"),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//
//                 Text(
//                   item.partyName,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//
//                 const SizedBox(height: 15),
//
//                 QrImageView(
//                   data: item.barcode,
//                   version: QrVersions.auto,
//                   size: 180,
//                 ),
//
//                 const SizedBox(height: 15),
//
//                 Text("Barcode: ${item.barcode}"),
//                 Text("Operator: ${item.operator}"),
//                 Text("Supervisor: ${item.supervisor}"),
//                 Text("Qty: ${item.quantity}"),
//
//                 const SizedBox(height: 10),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.print),
//               label: const Text("Print"),
//               onPressed: () => Navigator.pop(context, true),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
//   Future<void> _showIssueOptions(LoomListModel item) async {
//     showModalBottomSheet(
//       backgroundColor: C.bg,
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) {
//         return Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "Choose Action",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//
//               const SizedBox(height: 20),
//
//               /// PRINT + ISSUE
//               SizedBox(
//                 width: double.infinity,
//
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: C.appBar4,
//                   ),
//                   icon: const Icon(Icons.print,color: C.textHigh,),
//                   label: const Text("Print + Issue",style: TextStyle(color: C.textHigh),),
//                   onPressed: () async {
//                     Navigator.pop(context);
//
//                     final ok = await _showPrintPreview(item);
//
//                     if (ok == true) {
//                       await _printBarcodeApi(item);
//                     }
//                   },
//                 ),
//               ),
//
//               const SizedBox(height: 12),
//
//               /// ONLY ISSUE
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: C.success,
//                   ),
//                   icon: const Icon(Icons.check,color: C.bg,),
//                   label: const Text(
//                     "Only Issue",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   onPressed: () async {
//                     Navigator.pop(context);
//
//                     await _issueWithoutPrint(item);
//                   },
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _issueWithoutPrint(LoomListModel item) async {
//     try {
//       final response = await InStockService().printBarcode(
//         id: item.id,
//         barcode: item.barcode,
//       );
//
//       Get.snackbar(
//         "Success",
//         response['message'] ?? "Issued Successfully",
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//       await Future.delayed(const Duration(seconds: 3));
//       // Previous screen par wapas
//       Get.offAll(() => const LoomReportScreen());
//
//     } catch (e) {
//       Get.snackbar(
//         "Error",
//         "❌ $e",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
// }

import 'package:IMS/AdminDashBoard/DepartmentDashboard.dart';
import 'package:IMS/services/getSupervisors/getSupervisors.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:thermal_printer_plus/thermal_printer.dart';

import '../../AdminDashBoard/AsiaDashBoard/dashBoard_screen.dart';
import '../../AdminDashBoard/NewAdminDashboard.dart';
import '../../Color/Colorclass.dart';
import 'LoomListSavedModel.dart';

class SavedListScreen extends StatefulWidget {
  const SavedListScreen({super.key});

  @override
  State<SavedListScreen> createState() => _SavedListScreenState();
}

class _SavedListScreenState extends State<SavedListScreen> {
  late Future<List<LoomListModel>> futureData;
  final _storage = GetStorage();
  List<BluetoothInfo> printers = [];
  bool isScanning = false;

  Future<void> _checkPrinterConnection() async {
    bool? isConnected = await PrintBluetoothThermal.connectionStatus;

    Get.snackbar(
      "Printer Status",
      isConnected == true ? "✅ Printer Connected" : "❌ Printer Not Connected",
      backgroundColor: isConnected == true ? Colors.green : Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void initState() {
    super.initState();
    futureData = InStockService().fetchLoomList();
  }

  Future<void> scanPrinters() async {
    setState(() {
      isScanning = true;
      printers.clear();
    });

    try {
      final result = await PrintBluetoothThermal.pairedBluetooths;

      setState(() {
        printers = result;
        isScanning = false;
      });

      if (printers.isEmpty) {
        Get.snackbar(
          "No Printer",
          "No paired printers found",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        isScanning = false;
      });

      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showPrinterList() async {
    await scanPrinters();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              const SizedBox(height: 15),

              const Text(
                "Select Printer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const Divider(),

              if (isScanning)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: printers.length,
                    itemBuilder: (_, index) {
                      final p = printers[index];

                      return ListTile(
                        leading: const Icon(Icons.print, color: Colors.blue),

                        title: Text(p.name ?? "Unknown"),

                        subtitle: Text(p.macAdress ?? ""),

                        onTap: () async {
                          _storage.write('printer_name', p.name);

                          _storage.write('printer_address', p.macAdress);

                          Navigator.pop(context);

                          Get.snackbar(
                            "Success",
                            "Printer Connected",
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text("Loom List", style: TextStyle(color: C.bg)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: C.appBar1),
        ),
        // C.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: C.bg),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 18, color: C.bg),
          onPressed: () => Get.offAll(() => const AdminDashboard()),

          // Get.offAll(() => const NewAdminDashboard())
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.bluetooth),
          //   onPressed: _checkPrinterConnection,
          // ),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching, color: C.textHead),
            onPressed: showPrinterList,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<LoomListModel>>(
          future: futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: C.appBar3),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final data = snapshot.data!;

            if (data.isEmpty) {
              return const Center(child: Text("No Data Found"));
            }

            return Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowHeight: 50,
                      dataRowHeight: 52,

                      headingRowColor: MaterialStateProperty.all(C.border),

                      columns: const [
                        DataColumn(label: Text("ID")),
                        DataColumn(label: Text("Barcode")),
                        DataColumn(label: Text("Operator")),
                        DataColumn(label: Text("Supervisor")),
                        DataColumn(label: Text("Party Name")),

                        DataColumn(label: Text("Work Order")),
                        DataColumn(label: Text("Req.Qty(Kg)")),
                        DataColumn(label: Text("Req.Qty(Mtr)")),
                        DataColumn(label: Text("Date")),
                        DataColumn(label: Text("Time")),
                        DataColumn(label: Text("Fab GSM")),
                        DataColumn(label: Text("Color")),
                        DataColumn(label: Text("Net Wt")),
                        DataColumn(label: Text("Roll L.Mtr")),
                        DataColumn(label: Text("Loom Type")),
                        DataColumn(label: Text("Department")),
                        DataColumn(label: Text(" Print Barcode")),
                      ],

                      rows: List.generate(data.length, (index) {
                        final e = data[index];

                        return DataRow(
                          color: MaterialStateProperty.all(
                            index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                          ),
                          cells: [
                            DataCell(Text(e.id.toString())),
                            DataCell(Text(e.barcode)),
                            DataCell(Text(e.operator)),
                            DataCell(Text(e.supervisor)),
                            DataCell(Text(e.partyName)),

                            /// ✅ NEW
                            DataCell(Text(e.workOrderNo)),

                            DataCell(Text(e.requiredNetWt.toString())),
                            DataCell(Text(e.requiredQtyMtr.toString())),

                            DataCell(
                              Text(
                                e.date != null
                                    ? "${e.date!.day}-${e.date!.month}-${e.date!.year}"
                                    : "-",
                              ),
                            ),

                            DataCell(Text(e.time)),
                            DataCell(Text(e.gsm)),
                            DataCell(Text(e.color)),
                            DataCell(Text(e.netWt.toString())),
                            DataCell(Text(e.quantity.toString())),

                            /// ✅ NEW
                            DataCell(Text(e.modelNo)),
                            DataCell(Text(e.department)),

                            // DataCell(
                            //   ElevatedButton(
                            //     onPressed: () => _printBarcodeApi(e),
                            //     child: const Text(
                            //       "Print / Issue",
                            //       style: TextStyle(color: C.success),
                            //     ),
                            //   ),
                            // ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () => _showIssueOptions(e),
                                child: const Text(
                                  "Print / Issue",
                                  style: TextStyle(color: C.success),
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
            );
          },
        ),
      ),
    );
  }

  // Future<bool?> _showPrintPreview(LoomListModel item) {
  //   return showDialog<bool>(
  //     context: context,
  //     builder: (_) {
  //       return Dialog(
  //         child: Container(
  //           width: 350,
  //           padding: const EdgeInsets.all(16),
  //           color: Colors.white,
  //           child: SingleChildScrollView(
  //             child: Column(
  //               children: [
  //                 Text(
  //                   item.partyName,
  //                   style: const TextStyle(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 20),
  //
  //                 Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Text(
  //                     "BARCODE : ${item.barcode}",
  //                     style: const TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 10),
  //
  //                 Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Text(
  //                     "OP : ${item.operator}",
  //                     style: const TextStyle(fontSize: 16),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 10),
  //
  //                 Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Text(
  //                     "SUP : ${item.supervisor}",
  //                     style: const TextStyle(fontSize: 16),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 10),
  //
  //                 Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Text(
  //                     "QTY : ${item.quantity}",
  //                     style: const TextStyle(fontSize: 16),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 25),
  //
  //                 BarcodeWidget(
  //                   barcode: Barcode.qrCode(),
  //                   data: item.barcode,
  //                   width: 180,
  //                   height: 180,
  //                 ),
  //
  //                 const SizedBox(height: 20),
  //
  //                 Text(
  //                   item.barcode,
  //                   style: const TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 25),
  //
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: OutlinedButton(
  //                         onPressed: () {
  //                           Navigator.pop(context, false);
  //                         },
  //                         child: const Text(
  //                           "Cancel",
  //                           style: TextStyle(color: C.primaryDark),
  //                         ),
  //                       ),
  //                     ),
  //
  //                     const SizedBox(width: 10),
  //
  //                     Expanded(
  //                       child: ElevatedButton(
  //                         onPressed: () {
  //                           Navigator.pop(context, true);
  //                         },
  //                         child: const Text(
  //                           "Print & Issue",
  //                           style: TextStyle(color: C.primaryDark),
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }


  Future<bool?> _showPrintPreview(LoomListModel item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final labelWidth = screenWidth - 48 > 360
        ? 360.0
        : screenWidth - 48;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Print Preview — 99 × 99 mm',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Label preview: same coordinates and data as the TSPL print.
                SizedBox(
                  width: labelWidth,
                  height: labelWidth,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      final scale = size / 800.0;

                      // TSPL x/y coordinates are scaled to the preview.
                      // Text is rotated 180 degrees, as in the print commands.
                      Widget textAt({
                        required double x,
                        required double y,
                        required String text,
                        double fontSize = 10,
                        FontWeight fontWeight = FontWeight.normal,
                      }) {
                        return Positioned(
                          left: (800 - x) * scale,
                          top: (800 - y) * scale,
                          child: Text(
                            text,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              height: 1,
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.black,
                            width: 1.2,
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          children: [
                            // Same QR data and approximate size as TSPL:
                            // QRCODE 741,365,L,9,A,180,...
                            Positioned(
                              left: (800 - 741) * scale,
                              top: (800 - 365) * scale,
                              child: SizedBox(
                                width: 105 * scale,
                                height: 105 * scale,
                                child: BarcodeWidget(
                                  barcode: Barcode.qrCode(),
                                  data: item.barcode,
                                  drawText: false,
                                  color: Colors.black,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),

                            // Same text values and coordinates as printer TSPL.
                            textAt(
                              x: 759,
                              y: 159,
                              text: item.barcode,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                            textAt(
                              x: 768,
                              y: 454,
                              text:  item.date != null
                                  ? DateFormat('dd-MM-yyyy').format(item.date!)
                                  : '',
                              fontSize: 9,
                            ),
                            textAt(
                              x: 258,
                              y: 763,
                              text: 'ROLL NO:${item.rollCode}',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAt(
                              x: 773,
                              y: 764,
                              text: 'LOOM:${item.loomNo}',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAt(
                              x: 768,
                              y: 686,
                              text: 'GSM:${item.gsm}',
                              fontSize: 10,
                            ),
                            textAt(
                              x: 773,
                              y: 609,
                              text: 'Party Name:${item.partyName}',
                              fontSize: 9,
                            ),
                            textAt(
                              x: 773,
                              y: 532,
                              text: 'WO.No:${item.workOrderNo}',
                              fontSize: 9,
                            ),
                            textAt(
                              x: 311,
                              y: 539,
                              text: 'MESH:${item.mesh}',
                              fontSize: 8,
                            ),

                            // textAt(
                            //   x: 426,
                            //   y: 391,
                            //   text: 'TR Wt(Kg):${item.netWt}',
                            //   fontSize: 9,
                            // ),
                            textAt(
                              x: 433,
                              y: 473,
                              text: 'GW Wt(Kg):${item.grossWeight}',
                              fontSize: 9,
                            ),
                            textAt(
                              x: 417,
                              y: 329,
                              text: 'NET Wt(Kg):${item.netWt}',
                              fontSize: 9,
                            ),
                            textAt(
                              x: 776,
                              y: 128,
                              text: item.flattubegusset,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAt(
                              x: 417,
                              y: 175,
                              text: '${item.operator}+${item.operator}',
                              fontSize: 8,
                            ),
                            textAt(
                              x: 433,
                              y: 247,
                              text: 'MTR:${item.requiredQtyMtr}',
                              fontSize: 9,
                            ),
                            textAt(
                              x: 137,
                              y: 64,
                              text: item.loomNo,
                              fontSize: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('Print & Issue'),
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _printBarcodeApi(LoomListModel item) async {
    final address = _storage.read<String>('printer_address');
    final name = _storage.read<String>('printer_name') ?? 'Printer';

    if (address == null) {
      Get.snackbar(
        "Printer Error",
        "❌ Please connect printer first",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    bool? ok = await _showPrintPreview(item);

    if (ok != true) return;

    /// 🔹 Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Print Barcode"),
        content: Text("Print barcode?\n\n${item.barcode}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Print"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      /// 🔥 CONNECT PRINTER
      await PrinterManager.instance.disconnect(type: PrinterType.bluetooth);
      await Future.delayed(const Duration(milliseconds: 400));

      await PrinterManager.instance.connect(
        type: PrinterType.bluetooth,
        model: BluetoothPrinterInput(
          name: name,
          address: address,
          isBle: false,
          autoConnect: false,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));

      /// 🔥 WAKE PRINTER
      await PrinterManager.instance.send(
        type: PrinterType.bluetooth,
        bytes: [27, 64],
      );

      await Future.delayed(const Duration(milliseconds: 200));

      /// 🔥 TSPL LABEL (LIKE YOUR FIRST CODE)
      //     String tspl =
      //         '''
      // SIZE 100 mm,100 mm
      // GAP 3 mm,0 mm
      // DIRECTION 1
      // CLS
      //
      // TEXT 30,80,"3",0,1,2,"${item.partyName}"
      //
      // TEXT 40,140,"3",0,2,2,"BARCODE:${item.barcode}"
      // TEXT 40,200,"3",0,2,2,"OP:${item.operator}"
      //
      // TEXT 40,260,"3",0,2,2,"SUP:${item.supervisor}"
      // TEXT 40,320,"3",0,2,2,"QTY:${item.quantity}"
      //
      // QRCODE 240,390,L,12,A,0,"${item.barcode}"
      //
      // TEXT 180,660,"3",0,2,2,"${item.barcode}"
      //
      // PRINT 1
      // ''';
      String tspl =
          '''
SIZE 99 mm,99 mm
GAP 3 mm,0 mm
DIRECTION 0,0
REFERENCE 0,0
OFFSET 0 mm
SET PEEL OFF
SET CUTTER OFF
SET PARTIAL_CUTTER OFF
SET TEAR ON
CLS
CODEPAGE 1252
QRCODE 741,365,L,9,A,180,M2,S7,"${item.barcode}"
TEXT 759,159,"ROMAN.TTF",180,1,12,"${item.barcode}"
TEXT 768,454,"0",180,13,22,"Date:${item.date}"
TEXT 258,763,"0",180,12,27,"ROLL NO:${item.rollCode}"
TEXT 773,764,"0",180,12,22,"LOOM:${item.loomNo}"
TEXT 768,686,"0",180,15,23,"GSM:${item.gsm}"
TEXT 773,609,"0",180,13,19,"Party Name:${item.partyName}"
TEXT 773,532,"0",180,13,26,"WO.No:${item.workOrderNo}"
TEXT 311,539,"ROMAN.TTF",180,1,12,"MESH:${item.mesh}"
TEXT 245,665,"0",180,16,22,"SIZE:${item.mesh}"
TEXT 426,391,"ROMAN.TTF",180,1,16,"TR Wt(Kg):${item.netWt}"
TEXT 433,473,"0",180,18,22,"GW Wt(Kg):${item.grossWeight}"
TEXT 417,329,"0",180,16,22,"NET Wt(Kg):${item.netWt}"
TEXT 776,128,"0",180,15,30,"${item.flattubegusset}"
TEXT 417,175,"ROMAN.TTF",180,1,12,"${item.operator}+${item.operator}"
// TEXT 433,247,"0",180,16,19,"MTR:${item.contNo}"
TEXT 137,64,"0",180,13,15,"${item.loomNo}"
PRINT 1,1
''';

      /// 🔥 PRINT
      await PrinterManager.instance.send(
        type: PrinterType.bluetooth,
        bytes: tspl.codeUnits,
      );

      /// 🔥 OPTIONAL API CALL AFTER PRINT
      // 🔥 API CALL AFTER PRINT
      final response = await InStockService().printJblBarcode(
        rollEntryId: item.id,
        barcode: item.barcode,
        forwardToDepartment: "RMD",
      );

      Get.snackbar(
        response["success"] == true ? "Success" : "Failed",
        response["message"] ?? "Barcode issued",
        backgroundColor: response["success"] == true
            ? Colors.green
            : Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Dashboard par tabhi navigate karein jab API success ho
      if (response["success"] == true) {
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        Get.offAll(() => const AdminDashboard());
      }

      /// Navigate to Dashboard
    } catch (e) {
      Get.snackbar(
        "Error",
        "❌ Print failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  //   Future<void> _printBarcodeApi(LoomListModel item) async {
  //     final address = _storage.read<String>('printer_address');
  //     final name = _storage.read<String>('printer_name') ?? 'Printer';
  //
  //     /// Printer selected or not
  //     if (address == null || address.isEmpty) {
  //       Get.snackbar(
  //         "Printer Error",
  //         "❌ Please connect printer first",
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //       );
  //       return;
  //     }
  //
  //     /// Confirm dialog
  //     final confirm = await showDialog<bool>(
  //       context: context,
  //       builder: (_) => AlertDialog(
  //         title: const Text("Print Barcode"),
  //         content: Text("Print barcode?\n\n${item.barcode}"),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.pop(context, true),
  //             child: const Text("Yes, Print"),
  //           ),
  //         ],
  //       ),
  //     );
  //
  //     if (confirm != true) return;
  //
  //     try {
  //       /// Disconnect previous connection
  //       await PrinterManager.instance.disconnect(type: PrinterType.bluetooth);
  //
  //       await Future.delayed(const Duration(milliseconds: 500));
  //
  //       /// Connect printer
  //       await PrinterManager.instance.connect(
  //         type: PrinterType.bluetooth,
  //         model: BluetoothPrinterInput(
  //           name: name,
  //           address: address,
  //           isBle: false,
  //           autoConnect: false,
  //         ),
  //       );
  //
  //       await Future.delayed(const Duration(seconds: 1));
  //
  //       /// Verify connection
  //       bool? isConnected = await PrintBluetoothThermal.connectionStatus;
  //
  //       if (isConnected != true) {
  //         Get.snackbar(
  //           "Printer Error",
  //           "❌ Printer not connected",
  //           backgroundColor: Colors.red,
  //           colorText: Colors.white,
  //         );
  //
  //         return; // STOP HERE
  //       }
  //
  //       /// Wake printer
  //       await PrinterManager.instance.send(
  //         type: PrinterType.bluetooth,
  //         bytes: [27, 64],
  //       );
  //
  //       await Future.delayed(const Duration(milliseconds: 300));
  //
  //       String tspl =
  //           '''
  // SIZE 100 mm,100 mm
  // GAP 3 mm,0 mm
  // DIRECTION 1
  // CLS
  //
  // TEXT 30,80,"3",0,1,2,"${item.partyName}"
  //

  // TEXT 40,140,"3",0,2,2,"BARCODE:${item.barcode}"
  // TEXT 40,200,"3",0,2,2,"OP:${item.operator}"
  //
  // TEXT 40,260,"3",0,2,2,"SUP:${item.supervisor}"
  // TEXT 40,320,"3",0,2,2,"QTY:${item.quantity}"
  //
  // QRCODE 240,390,L,12,A,0,"${item.barcode}"
  //
  // TEXT 180,660,"3",0,2,2,"${item.barcode}"
  //
  // PRINT 1
  // ''';
  //
  //       /// Send print data
  //       await PrinterManager.instance.send(
  //         type: PrinterType.bluetooth,
  //         bytes: tspl.codeUnits,
  //       );
  //
  //       /// Wait before API call
  //       await Future.delayed(const Duration(seconds: 2));
  //
  //       /// API ONLY AFTER SUCCESSFUL PRINT
  //       final response = await InStockService().printBarcode(
  //         id: item.id,
  //         barcode: item.barcode,
  //       );
  //
  //       Get.snackbar(
  //         "Success",
  //         response['message'] ?? "Printed Successfully",
  //         backgroundColor: Colors.green,
  //         colorText: Colors.white,
  //       );
  //     } catch (e) {
  //       Get.snackbar(
  //         "Print Failed",
  //         "❌ $e",
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //       );
  //     }
  //   }

  Future<void> _showIssueOptions(LoomListModel item) async {
    showModalBottomSheet(
      backgroundColor: C.bg,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Action",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// PRINT + ISSUE
              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: C.appBar4),
                  icon: const Icon(Icons.print, color: C.textHigh),
                  label: const Text(
                    "Print + Issue",
                    style: TextStyle(color: C.textHigh),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);

                    await _printBarcodeApi(item);
                  },
                ),
              ),

              const SizedBox(height: 12),

              /// ONLY ISSUE
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: C.success),
                  icon: const Icon(Icons.check, color: C.bg),
                  label: const Text(
                    "Only Issue",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);

                    await _issueWithoutPrint(item);
                  },
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _issueWithoutPrint(LoomListModel item) async {
    try {
      final response = await InStockService().printJblBarcode(
        rollEntryId: item.id,
        barcode: item.barcode,
        forwardToDepartment: "RMD",
      );

      Get.snackbar(
        response["success"] == true ? "Success" : "Failed",
        response["message"] ?? "Barcode issue failed",
        backgroundColor: response["success"] == true
            ? Colors.green
            : Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      if (response["success"] == true) {
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        Get.offAll(() => const AdminDashboard());
      }
    } catch (e) {
      Get.snackbar(
        "Issue Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
