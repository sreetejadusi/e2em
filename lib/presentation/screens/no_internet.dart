// ignore_for_file: use_build_context_synchronously

import 'package:ezing/data/functions/internet_connectiviy.dart';
import 'package:ezing/main.dart';
import 'package:flutter/material.dart';

class NoInternet extends StatelessWidget {
  const NoInternet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 100,
            ),
            const Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
                onPressed: () {
                  checkInternetConnectivity().then((value) {
                    if (value) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const Ezing()));
                    }
                  });
                },
                child: const Text('Retry'))
          ],
        ),
      ),
    );
  }
}
