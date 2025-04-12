// ignore_for_file: deprecated_member_use

import 'package:ezing/data/functions/constants.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_provider.dart';
import 'package:ezing/presentation/providers/location_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final int battery, speed, mode;
  final double rangeLeft;
  final String deviceName;
  final bool hasDevice, connecting, connected;
  final Function(int) modeChange;
  final Function() connect;
  final Function() disconnect;
  final bool isLoading;
  const HomeScreen({
    super.key,
    required this.connect,
    required this.disconnect,
    required this.connecting,
    required this.connected,
    required this.deviceName,
    required this.hasDevice,
    required this.modeChange,
    required this.mode,
    required this.battery,
    required this.speed,
    required this.rangeLeft,
    required this.isLoading,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double sidePadding = 24;
  Color scb = const Color(0xFF232323);

  @override
  Widget build(BuildContext context) {
    BluetoothProvider bp = context.watch<BluetoothProvider>();
    BluetoothDevicesProvider bdp = context.watch<BluetoothDevicesProvider>();
    LocationProvider lp = context.watch<LocationProvider>();
    UserDataProvider udp = context.watch<UserDataProvider>();
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width - sidePadding * 2;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFCFDF7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 48, left: 24, right: 24),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Logo(
                    width: MediaQuery.of(context).size.width * 0.25,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      if (!bp.bluetoothOn) {
                        FlutterBlueElves.instance
                            .androidOpenBluetoothService((isOk) {
                          debugPrint(isOk
                              ? "The user agrees to turn on the Bluetooth function"
                              : "The user does not agrees to turn on the Bluetooth function");
                        });
                      }
                    },
                    icon: Icon(
                      Icons.bluetooth,
                      color: bp.bluetoothOn ? Colors.green : Colors.red,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (!bp.gpsOn) {
                        FlutterBlueElves.instance
                            .androidOpenLocationService((isOk) {
                          debugPrint(isOk
                              ? "The user agrees to turn on the positioning function"
                              : "The user does not agree to enable the positioning function");
                        });
                      }
                    },
                    icon: Icon(
                      Icons.location_on,
                      color: bp.gpsOn ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: h * 0.5,
              padding: const EdgeInsets.all(84),
              decoration: const BoxDecoration(
                color: Color(0xFFFCFDF7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Container(
                width: w * 0.5,
                height: w * 0.5,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 15,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: w * 0.25,
                      width: w * 0.5,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        // border: Border.all(
                        //   color: Color.fromARGB(255, 150, 150, 150),
                        //   width: 1,
                        // ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 3,
                            blurRadius: 7,
                            offset: const Offset(0, 0),
                          )
                        ],
                      ),
                      child: batteryBox(context, widget.battery),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.only(top: 20),
                      width: w * 0.5,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        // border: Border.all(
                        //   color: Color.fromARGB(255, 150, 150, 150),
                        //   width: 1,
                        // ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 3,
                            blurRadius: 7,
                            offset: const Offset(0, 0),
                          )
                        ],
                      ),
                      child: textTile1(widget.rangeLeft, "KM", ""),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  actionButton(
                    text: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.mode == 1 ? "ON" : "OFF",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        widget.isLoading
                            ? const CircularProgressIndicator()
                            : Switch(
                                value: widget.mode == 1,
                                activeColor: Colors.white,
                                inactiveTrackColor: Colors.white,
                                thumbColor:
                                    const WidgetStatePropertyAll(Colors.black),
                                trackOutlineColor:
                                    const WidgetStatePropertyAll(Colors.black),
                                thumbIcon: WidgetStatePropertyAll(Icon(
                                  Icons.power_settings_new,
                                  color: widget.mode == 1
                                      ? themeColor
                                      : Colors.red,
                                )),
                                inactiveThumbColor: Colors.red,
                                onChanged: (_) {
                                  widget.modeChange(widget.mode == 1 ? 0 : 1);
                                  lp.pushLocation(udp.user!.phone);
                                }),
                      ],
                    ),
                    color: widget.connected ? Colors.red : Colors.green,
                    onTap: () {},
                  ),
                  actionButton(
                    text: widget.hasDevice
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.deviceName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: widget.connected
                                        ? themeColor
                                        : widget.connecting
                                            ? Colors.blueGrey
                                            : Colors.redAccent,

                                    //Color(0xFF5d9451),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10),
                                    child: Text(
                                      widget.connected
                                          ? "Connected"
                                          : widget.connecting
                                              ? "Connecting"
                                              : "Disconnected",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            widget.hasDevice
                                ? widget.deviceName
                                : bdp.scanning
                                    ? "Scanning"
                                    : "No Device",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    color: Colors.black,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton(
      {required Widget text, required Color color, required Function onTap}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () => onTap(),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.35,
          height: MediaQuery.of(context).size.width * 0.35,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Center(
            child: text,
          ),
        ),
      ),
    );
  }

  Widget batteryBox(BuildContext context, int percentage) {
    final w = MediaQuery.of(context).size.width - sidePadding * 2 - 200;
    final h = MediaQuery.of(context).size.height;
    double height = h * 0.06;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            height: w * 0.28,
            width: w * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: Stack(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 3),
                      Container(
                        color: const Color(0xFFdcd8de),
                      ),
                      const SizedBox(width: 3),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              percentage > 25 ? themeColor : Colors.redAccent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                            bottomRight: Radius.circular(5),
                            topRight: Radius.circular(5),
                          ),
                        ),
                        width: percentage > 0
                            ? (w * 0.7 * (percentage / 100)) - 6
                            : 0,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  // Center(
                  //   child: Text(
                  //     percentage.toString() + "%",
                  //     style: TextStyle(
                  //       fontSize: 17,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
        Card(
          elevation: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            width: height * 0.20,
            height: height * 0.50,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(0),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget textTile1(double num, String unit, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: num.toString(),
            style: const TextStyle(
              color: Color(0xFF2a2a2a),
              fontWeight: FontWeight.w500,
              fontSize: 28,
            ),
            children: [
              TextSpan(
                text: " $unit",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
