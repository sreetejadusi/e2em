import 'package:ezing/main.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    UserDataProvider userDataProvider = context.watch<UserDataProvider>();
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
      body: const Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}
