// ignore_for_file: use_build_context_synchronously

import 'package:ezing/main.dart';
import 'package:ezing/presentation/providers/battery_swap_provider.dart';
import 'package:ezing/presentation/providers/swap_station_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    UserDataProvider userDataProvider = context.watch<UserDataProvider>();
    context.watch<BatterySwapProvider>();
    context.watch<SwapStationProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF7),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final result = await userDataProvider.logout();
              if (result) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Entry(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  title: const Text('Name'),
                  subtitle: Text(userDataProvider.user!.name),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  title: const Text('Email'),
                  subtitle: Text(userDataProvider.user!.email),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  title: const Text('Phone'),
                  subtitle: Text(userDataProvider.user!.phone),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  title: const Text('Vehicle ID'),
                  subtitle: Text(userDataProvider.user!.vehicle),
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 3.0),
            //   child: Material(
            //     elevation: 10,
            //     borderRadius: BorderRadius.circular(10),
            //     child: ListTile(
            //       onTap: () async {
            //         await swapStationProvider.navigateToAssignedSwapStation(
            //             userDataProvider.user!.phone);
            //       },
            //       title: Text('Locate Swap Station'),
            //       subtitle: Text('Navigate to assigned swap station'),
            //       trailing: Icon(FontAwesomeIcons.chevronRight),
            //     ),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 3.0),
            //   child: Material(
            //     elevation: 10,
            //     borderRadius: BorderRadius.circular(10),
            //     child: ListTile(
            //       onTap: () async {
            //         // Navigator.of(context).push(MaterialPageRoute(
            //         //   builder: (context) => BatterySwapScreen(),
            //         // ));
            //         if (await batterySwapProvider.canSwapBattery(
            //             userDataProvider.user!.phone, context)) {
            //           // showBatterySwapBottomSheet(context);
            //         }
            //       },
            //       title: Text('Swap Battery'),
            //       subtitle: Text('Swap your battery'),
            //       trailing: Icon(FontAwesomeIcons.chevronRight),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
