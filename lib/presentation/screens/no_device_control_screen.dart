// ignore_for_file: unused_local_variable, use_super_parameters, unnecessary_overrides, no_leading_underscores_for_local_identifiers, unused_import, empty_catches

import 'package:ezing/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class NoDeviceControlScreen extends StatefulWidget {
  const NoDeviceControlScreen({Key? key}) : super(key: key);

  @override
  State<NoDeviceControlScreen> createState() => _NoDeviceControlScreenState();
}

class _NoDeviceControlScreenState extends State<NoDeviceControlScreen>
    with TickerProviderStateMixin {
  String cycleId = "0";
  int mode = 0;
  @override
  void dispose() {
    super.dispose();
  }

  String name = "------";
  load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = (prefs.getString('name') ?? "------");
    });
  }

  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    load();
    super.initState();
  }

  onMessage(String mes) {
    List<String> m = mes.toString().trim().split(',');

    if (m.length > 2) {
      try {
        String _cycleId = m[0].toString();
        int _mode = int.parse(m[1].toString());
        int _battery = int.parse(m[2].toString());
        if (_battery >= 0 && _battery <= 100) {
        } else {}
        if (_mode == 1 ||
            _mode == 2 ||
            _mode == 3 ||
            _mode == 4 ||
            _mode == 5) {
        } else {}
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return HomeScreen(
      hasDevice: false,
      deviceName: "",
      connected: false,
      connect: () {},
      disconnect: () {},
      mode: mode,
      battery: 0,
      speed: 0,
      rangeLeft: 0,
      modeChange: (int modeNum) {
        // String mn = modeNum.toString();
        // setState(() {
        //   mode = modeNum;
        // });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please Connect to a Device"),
          ),
        );
      },
      isLoading: false,
    );
  }
}
