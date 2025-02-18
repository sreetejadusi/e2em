import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataProvider with ChangeNotifier {
  String get homeName => _homeName;
  String _homeName = "";

  bool get autoConnect => _autoConnect;
  bool _autoConnect = false;

  String get roomName => _roomName;
  String _roomName = "";

  Future<void> autoConnectInit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _autoConnect = (prefs.getBool('autoConnect') ?? true);
    notifyListeners();
  }

  Future<void> changeAutoConnectWaiting(bool b) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoConnect', b);
    autoConnectInit();
    notifyListeners();
  }

  Future<void> homeNameInit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _homeName = (prefs.getString('homeName') ?? "");
    if (_homeName.isEmpty) {
      changeHomeName("Bucky Home");
    }
    notifyListeners();
  }

  Future<void> roomNameInit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _roomName = (prefs.getString('roomName') ?? "");
    if (_roomName.isEmpty) {
      changeRoomName("Main Door");
    }
    notifyListeners();
  }

  Future<void> changeHomeName(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('homeName', name);
    homeNameInit();
    notifyListeners();
  }

  Future<void> changeRoomName(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('roomName', name);
    roomNameInit();
    notifyListeners();
  }
}
