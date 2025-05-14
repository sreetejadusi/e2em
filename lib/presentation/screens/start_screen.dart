// ignore_for_file: unused_local_variable, use_super_parameters, unnecessary_const, prefer_const_literals_to_create_immutables, use_build_context_synchronously

import 'dart:async';

import 'package:ezing/data/datasource/mongodb.dart';
import 'package:ezing/data/functions/constants.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_provider.dart';
import 'package:ezing/presentation/providers/data_provider.dart';
import 'package:ezing/presentation/providers/saved_devices_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/screens/control_screen.dart';
import 'package:ezing/presentation/screens/no_device_control_screen.dart';
import 'package:ezing/presentation/screens/profile_screen.dart';
import 'package:ezing/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Start extends StatefulWidget {
  const Start({Key? key}) : super(key: key);

  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  bool isLoading = false;
  load() async {
    setState(() {
      isLoading = true;
    });
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    BluetoothProvider bp = context.read<BluetoothProvider>();
    DataProvider dp = context.read<DataProvider>();
    SavedDevicesProvider sdp = context.read<SavedDevicesProvider>();
    UserDataProvider udp = context.read<UserDataProvider>();
    bdp.lastDeviceInit();
    bdp.changeTabIndex(0);
    sdp.init();
    await MongoDBConnection.mongoDB.init();
    await udp.syncUserData();
    udp.getUserData();
    await bdp.lastDeviceInit();
    Future.delayed(const Duration(seconds: 0), () async {
      await bp.check(context);
    });
    bdp.changeTabIndex(1);
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (bdp.connectedDevice == null) {
        print('CALLING SCAN');
        bdp.scan(context);
      }
    });
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    load();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String csKey = "0";
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    BluetoothProvider bp = context.watch<BluetoothProvider>();
    BluetoothDevicesProvider bdp = context.watch<BluetoothDevicesProvider>();
    List<Widget> tabs = [
      const ProfileScreen(),
      if (bdp.connectedDevice != null) ...[
        ControlScreen(
          device: bdp.connectedDevice!,
          rebuild: (String key) {
            setState(() {
              csKey = key;
            });
          },
          key: Key(csKey),
        ),
        // StreamScreen()
      ] else ...[
        const NoDeviceControlScreen()
      ],
      const SettingScreen(),
    ];
    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: tabs[bdp.tabIndex]),
                ],
              ),
        bottomNavigationBar: Container(
          color: const Color(0xFFFCFDF7),
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: const Radius.circular(20),
                bottomRight: const Radius.circular(20),
              ),
              child: Container(
                color: Colors.black,
                // color: Color(0xFF2a2a2a),
                child: SizedBox(
                  //height: 70,
                  child: BottomNavigationBar(
                    currentIndex: bdp.tabIndex,
                    showUnselectedLabels: false,
                    onTap: onTabTapped,
                    elevation: 0,
                    selectedItemColor: themeColor,
                    unselectedItemColor: const Color(0xFFFCFDF7),
                    showSelectedLabels: false,
                    iconSize: 30,
                    //selectedItemColor: firstAccentColor,
                    backgroundColor: Colors.black54,
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.dashboard),
                        label: "Devices",
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: "Home",
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.settings),
                        label: "Settings",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onTabTapped(int index) {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    // if (index == 0) {
    //   bdp.changeConnectedDevice(null, "--------");
    // } else {}
    setState(() {});
    bdp.changeTabIndex(index);
  }
}
