import 'package:ezing/data/datasource/mongodb.dart';
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
import 'package:ezing/presentation/screens/start_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    ChangeNotifierProxyProvider2<BluetoothDevicesProvider, BluetoothProvider, BatterySwapProvider>(
      create: (context) => BatterySwapProvider(
          context.read<BluetoothDevicesProvider>(),
          context.read<BluetoothProvider>(),),
      update: (context, _bleProvider, _bluetoothProvider,
              batterySwapProvider) =>
          batterySwapProvider!
              .update(_bleProvider, _bluetoothProvider),
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
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF56BB45),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF56BB45),
        ),
      ),
      home: SafeArea(
        child: Scaffold(
          body: const Entry(),
        ),
      ),
    );
  }
}

class Entry extends StatelessWidget {
  const Entry({super.key});

  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser != null
        ? const Start()
        : const LoginScreen();
  }
}
