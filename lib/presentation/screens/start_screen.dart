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
  int currentTabIndex = 1;

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
    sdp.init();
    await MongoDBConnection.instance.ensureConnection();
    await udp.syncUserData();
    udp.getUserData();
    await bdp.lastDeviceInit();
    await bp.checkAndRequestPermissions();
    Timer.periodic(Duration(seconds: 5), (timer) async {
      if ((bdp.connectedDevice == null ||
              bdp.connectedDevice!.isDisconnected) &&
          bp.isBluetoothOn) {
        print('CALLING SCAN');
        bdp.scan(context);
      }
    });
    setState(() {
      isLoading = false;
    });
  }

  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    load(); // Your existing load logic

    // Setup the lifecycle listener
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );
  }

  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // The app has come back to the foreground.
        // Proactively reconnect to minimize delay for the user's first action.
        print("APP STATE: Resumed. Reconnecting to MongoDB...");
        MongoDBConnection.instance.ensureConnection();
        break;
      case AppLifecycleState.paused:
        // The app is going to the background.
        // You could optionally close the connection here to free up resources.
        print("APP STATE: Paused.");
        // MongoDbManager.instance.close(); // Optional
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Handle other states if needed
        break;
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    MongoDBConnection.instance.close(); // Clean up on final dispose
    super.dispose();
  }

  // This key logic is what you identified as a problem area.
  // It forces the ControlScreen to rebuild completely.
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    BluetoothProvider bp = context.watch<BluetoothProvider>();
    BluetoothDevicesProvider bdp = context.watch<BluetoothDevicesProvider>();

    // The list of widgets for the tabs is now defined directly inside the IndexedStack's children.
    // This is the main change to fix the state preservation issue.
    void onTabTapped(int index) {
      setState(() {
        currentTabIndex = index;
      });
    }

    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            // SOLUTION: Use IndexedStack to preserve the state of each tab.
            // IndexedStack keeps all its children in the widget tree, but only shows the one
            // at the current 'index'. This prevents the screens from being destroyed and
            // recreated every time you switch tabs.
            : IndexedStack(
                index: currentTabIndex,
                children: <Widget>[
                  // Tab 0: Profile
                  const ProfileScreen(),

                  // Tab 1: Control Screen (logic handled internally)
                  // The conditional logic is now here. IndexedStack will show one of these
                  // and keep its state. When `bdp.connectedDevice` changes, this will
                  // swap the widget, but the state of other tabs remains safe.
                  if (bdp.connectedDevice != null) ...[
                    ControlScreen(
                      device: bdp.connectedDevice!,
                    ),
                  ] else ...[
                    const NoDeviceControlScreen()
                  ],

                  // Tab 2: Settings
                  const SettingScreen(),
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
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: Container(
                color: Colors.black,
                child: SizedBox(
                  child: BottomNavigationBar(
                    currentIndex: currentTabIndex,
                    showUnselectedLabels: false,
                    onTap: onTabTapped,
                    elevation: 0,
                    selectedItemColor: themeColor,
                    unselectedItemColor: const Color(0xFFFCFDF7),
                    showSelectedLabels: false,
                    iconSize: 30,
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
}
