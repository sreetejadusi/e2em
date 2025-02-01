import 'dart:async';

import 'package:ezing/data/datasource/mongodb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final String name;
  final String email;
  final String phone;
  final bool flag;

  UserModel(
      {required this.name,
      required this.email,
      required this.phone,
      required this.flag});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      flag: map['flag'] ?? false,
    );
  }
}

class UserDataProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _user = UserModel(
      name: prefs.getString('name') ?? '',
      email: prefs.getString('email') ?? '',
      phone: prefs.getString('phone') ?? '',
      flag: prefs.getBool('flag') ?? false,
    );
    notifyListeners();
  }

  bool checkLogin() => _user?.phone.isNotEmpty ?? false;

  Future<bool> loginUser(String phone) async {
    MongoDBConnection connection = MongoDBConnection();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final result = await connection.db
        .collection('users')
        .findOne(where.eq('phone', phone));
    if (result != null) {
      _user = UserModel.fromMap(result);
      await prefs.setString('name', _user!.name);
      await prefs.setString('email', _user!.email);
      await prefs.setString('phone', _user!.phone);
      await prefs.setBool('flag', _user!.flag);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      await prefs.clear();
      _user = null;
      notifyListeners();
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkFlag() async {
    if (_user == null) return true;
    MongoDBConnection connection = MongoDBConnection();
    final result = await connection.db
        .collection('users')
        .findOne(where.eq('phone', _user!.phone));
    return result?['flag'] ?? true;
  }

  Future<bool> sendOtp(String phoneNumber) async {
    Completer<bool> completer = Completer<bool>();
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
        notifyListeners();
        completer.complete(true);
      },
      verificationFailed: (FirebaseAuthException e) {
        completer.complete(false);
      },
      codeSent: (String verificationId, int? resendToken) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('verificationId', verificationId);
        notifyListeners();
        completer.complete(true);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    return completer.future;
  }

  Future<bool> verifyOtp(String verificationId, String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> resendOtp(String phoneNumber) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
        notifyListeners();
      },
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('verificationId', verificationId);
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<bool> registerUser(String name, String email, String phone) async {
    MongoDBConnection connection = MongoDBConnection();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final result = await connection.db.collection('users').insertOne({
      'name': name,
      'email': email,
      'phone': phone,
      'flag': false,
    });
    if (result.isSuccess) {
      _user = UserModel(name: name, email: email, phone: phone, flag: false);
      await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setString('phone', phone);
      await prefs.setBool('flag', false);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> doesPhoneExists(String phone) async {
    MongoDBConnection connection = MongoDBConnection();
    final result = await connection.db
        .collection('users')
        .findOne(where.eq('phone', phone));
    return result != null;
  }
}
