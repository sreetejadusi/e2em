import 'package:ezing/main.dart';
import 'package:ezing/presentation/providers/swap_station_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/screens/battery_swap_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    UserDataProvider userDataProvider = context.watch<UserDataProvider>();
    SwapStationProvider swapStationProvider =
        context.watch<SwapStationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final result = await userDataProvider.logout();
              if (result) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Entry(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Name'),
            subtitle: Text(userDataProvider.user!.name),
          ),
          ListTile(
            title: Text('Email'),
            subtitle: Text(userDataProvider.user!.email),
          ),
          ListTile(
            title: Text('Phone'),
            subtitle: Text(userDataProvider.user!.phone),
          ),
          ListTile(
            onTap: () async {
              await swapStationProvider
                  .navigateToAssignedSwapStation(userDataProvider.user!.phone);
            },
            title: Text('Locate Swap Station'),
            subtitle: Text('Navigate to assigned swap station'),
            trailing: Icon(FontAwesomeIcons.chevronRight),
          ),
          ListTile(
            onTap: () async {
              // Navigator.of(context).push(MaterialPageRoute(
              //   builder: (context) => BatterySwapScreen(),
              // ));
              showBatterySwapBottomSheet(context);
            },
            title: Text('Swap Battery'),
            subtitle: Text('Swap your battery'),
            trailing: Icon(FontAwesomeIcons.chevronRight),
          )
        ],
      ),
    );
  }
}
