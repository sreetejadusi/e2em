import 'package:ezing/presentation/providers/battery_swap_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

void showBatterySwapBottomSheet(BuildContext context) {
  TextEditingController currentBatteryController = TextEditingController();
  TextEditingController newBatteryController = TextEditingController();

  void scanBarcode(TextEditingController controller) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ScanBarcodeScreen(),
    );
    if (result != null) {
      controller.text = result;
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      BatterySwapProvider bsp = sheetContext.read<BatterySwapProvider>();
      UserDataProvider udp = sheetContext.read<UserDataProvider>();
      return Padding(
        padding:
            MediaQuery.of(sheetContext).viewInsets + const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Battery Swap",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: currentBatteryController,
                    decoration:
                        InputDecoration(labelText: "Current Battery ID"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner),
                  onPressed: () => scanBarcode(currentBatteryController),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newBatteryController,
                    decoration: InputDecoration(labelText: "New Battery ID"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner),
                  onPressed: () => scanBarcode(newBatteryController),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await bsp.swapBattery(
                    udp.user!.phone,
                    currentBatteryController.text,
                    newBatteryController.text,
                    context);
                if (result) {
                  Navigator.pop(sheetContext);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to swap battery")));
                }
              },
              child: Text("Confirm Swap"),
            ),
          ],
        ),
      );
    },
  );
}

class ScanBarcodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan QR/Barcode")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            Navigator.pop(context, barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}
