import 'package:ezing/data/datasource/mongodb.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_provider.dart';
import 'package:ezing/presentation/providers/data_provider.dart';
import 'package:ezing/presentation/providers/saved_devices_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/screens/control_screen.dart';
import 'package:ezing/presentation/screens/devices_screen.dart';
import 'package:ezing/presentation/screens/home_screen.dart';
import 'package:ezing/presentation/screens/no_device_control_screen.dart';
import 'package:ezing/presentation/screens/profile_screen.dart';
import 'package:ezing/presentation/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

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
    bdp.resetName();
    BluetoothProvider bp = context.read<BluetoothProvider>();
    DataProvider dp = context.read<DataProvider>();
    SavedDevicesProvider sdp = context.read<SavedDevicesProvider>();
    UserDataProvider udp = context.read<UserDataProvider>();
    sdp.init();
    dp.autoConnectInit();
    await MongoDBConnection.mongoDB.init();
    udp.getUserData();
    await bdp.lastDeviceInit();
    Future.delayed(const Duration(seconds: 0), () async {
      await bp.check(context);
    });

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (bp.gpsOn && bp.bluetoothOn) {
        bdp.scan(context);
      }
    });
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    load();
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
      const DevicesScreen(),
      if (bdp.connectedDevice != null) ...[
        ControlScreen(
          device: bdp.connectedDevice!,
          rebuild: (String key) {
            setState(() {
              //csKey = key;
            });
          },
          //key: Key(csKey),
        ),
      ] else ...[
        const NoDeviceControlScreen(),
      ],
      const ProfileScreen(),
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  color: Colors.black54,
                  // color: Color(0xFF2a2a2a),
                  child: SizedBox(
                    //height: 70,
                    child: BottomNavigationBar(
                      currentIndex: bdp.tabIndex,
                      showUnselectedLabels: false,
                      onTap: onTabTapped,
                      elevation: 0,
                      selectedItemColor: Color(0xFF56bb45),
                      unselectedItemColor: Colors.white,
                      showSelectedLabels: false,
                      iconSize: 30,
                      //selectedItemColor: firstAccentColor,
                      backgroundColor: Colors.black54,
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.dashboard),
                          label: "Devices",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: "Home",
                        ),
                        BottomNavigationBarItem(
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
      ),
    );
  }

  void onTabTapped(int index) {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    if (index == 0) {
      bdp.changeConnectedDevice(null, "--------");
    } else {}
    setState(() {});
    bdp.changeTabIndex(index);
  }
}
