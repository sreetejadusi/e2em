// ignore: unused_import
// ignore_for_file: use_build_context_synchronously

import 'package:ezing/data/datasource/mongodb.dart';
import 'package:ezing/data/functions/constants.dart';
import 'package:ezing/data/functions/internet_connectiviy.dart';
import 'package:ezing/firebase_options.dart';
import 'package:ezing/presentation/providers/battery_swap_provider.dart';
import 'package:ezing/presentation/providers/ble_data_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_provider.dart';
import 'package:ezing/presentation/providers/data_provider.dart';
import 'package:ezing/presentation/providers/location_provider.dart';
import 'package:ezing/presentation/providers/saved_devices_provider.dart';
import 'package:ezing/presentation/providers/swap_station_provider.dart';
import 'package:ezing/presentation/screens/login_screen.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/screens/no_internet.dart';
import 'package:ezing/presentation/screens/start_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await mongoDB.init();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => BluetoothProvider()),
    ChangeNotifierProvider(create: (_) => BluetoothDevicesProvider()),
    ChangeNotifierProvider(create: (_) => BLEDataProvider()),
    ChangeNotifierProvider(create: (_) => DataProvider()),
    ChangeNotifierProvider(create: (_) => SavedDevicesProvider()),
    ChangeNotifierProvider(create: (_) => UserDataProvider()),
    ChangeNotifierProvider(create: (_) => LocationProvider()),
    ChangeNotifierProvider(create: (_) => SwapStationProvider()),
    ChangeNotifierProxyProvider2<BluetoothDevicesProvider, BluetoothProvider,
        BatterySwapProvider>(
      create: (context) => BatterySwapProvider(
        context.read<BluetoothDevicesProvider>(),
        context.read<BluetoothProvider>(),
      ),
      update:
          (context, bleProvider, bluetoothProvider, batterySwapProvider) =>
              batterySwapProvider!.update(bleProvider, bluetoothProvider),
    ),
  ], child: const Ezing()));
}

class Ezing extends StatelessWidget {
  const Ezing({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: themeColor,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: themeColor,
        ),
      ),
      home: const SafeArea(
        child: Scaffold(
          body: Entry(),
        ),
      ),
    );
  }
}

class Entry extends StatefulWidget {
  const Entry({super.key});

  @override
  State<Entry> createState() => _EntryState();
}

class _EntryState extends State<Entry> {
  bool isLoading = true;
  @override
  void initState() {
    checkInternetConnectivity().then((value) async {
      if (value) {
        await mongoDB.init();
        UserDataProvider user = context.read<UserDataProvider>();
        if(FirebaseAuth.instance.currentUser != null) {
          await user.getUserData();
          await user.syncUserData();
        }
        setState(() {
          isLoading = false;
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NoInternet(),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    UserDataProvider user = context.watch<UserDataProvider>();
    return isLoading
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : FirebaseAuth.instance.currentUser != null && user.checkLogin()
            ? const Start()
            : const LoginScreen();
  }
}
