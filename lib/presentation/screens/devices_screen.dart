// ignore_for_file: deprecated_member_use, use_super_parameters, non_constant_identifier_names, use_build_context_synchronously, unused_local_variable

import 'dart:async';

import 'package:ezing/data/datasource/mongodb.dart';
import 'package:ezing/data/functions/internet_connectiviy.dart';
import 'package:ezing/data/models/saved_device.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_provider.dart';
import 'package:ezing/presentation/providers/location_provider.dart';
import 'package:ezing/presentation/providers/saved_devices_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/widgets/components.dart';
import 'package:ezing/presentation/widgets/logo.dart';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State, Center;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  ///
  final formKey = GlobalKey<FormState>();
  String expanded = "";
  String editName = "";
  TextEditingController edit_name = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController id = TextEditingController();
  TextEditingController password = TextEditingController();

  //bool addDevice = false;

  ///
  load() async {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    BluetoothProvider bp = context.read<BluetoothProvider>();
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (bp.gpsOn && bp.bluetoothOn && !bdp.scanning) {
        bdp.scan(context);
      }
    });
  }

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  void dispose() {
    // BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    // try {
    //   bdp.connectedDevice?.disConnect();
    // } catch (e) {
    //   if (kDebugMode) {
    //     print(e);
    //   }
    // }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BluetoothProvider bp = context.watch<BluetoothProvider>();
    BluetoothDevicesProvider bdp = context.watch<BluetoothDevicesProvider>();
    SavedDevicesProvider sdp = context.watch<SavedDevicesProvider>();
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Logo(
            width: MediaQuery.of(context).size.width * 0.25,
          ),
          actions: [
            IconButton(
                onPressed: () {
                  if (!bp.bluetoothOn) {
                    FlutterBlueElves.instance
                        .androidOpenBluetoothService((isOk) {
                      debugPrint(isOk
                          ? "The user agrees to turn on the Bluetooth function"
                          : "The user does not agrees to turn on the Bluetooth function");
                    });
                  }
                },
                icon: Icon(
                  Icons.bluetooth,
                  color: bp.bluetoothOn ? Colors.green : Colors.red,
                )),
            IconButton(
                onPressed: () {
                  if (!bp.gpsOn) {
                    FlutterBlueElves.instance
                        .androidOpenLocationService((isOk) {
                      debugPrint(isOk
                          ? "The user agrees to turn on the positioning function"
                          : "The user does not agree to enable the positioning function");
                    });
                  }
                },
                icon: Icon(
                  Icons.location_on,
                  color: bp.gpsOn ? Colors.green : Colors.red,
                )),
          ],
        ),
        backgroundColor: Colors.transparent,
        //bottomNavigationBar:
        floatingActionButton: (bp.gpsOn && bp.bluetoothOn)
            ? FloatingActionButton(
                backgroundColor: bdp.scanning ? Colors.red : Colors.blue,
                onPressed: () {
                  bdp.scan(context);
                },
                tooltip: 'scan',
                child: Icon(
                  bdp.scanning ? Icons.stop : Icons.find_replace,
                  color: Colors.white,
                ),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListTile(
                title: const Text(
                  "Devices",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                trailing: FloatingActionButton(
                  heroTag: "toggle",
                  mini: true,
                  backgroundColor: Colors.blue,
                  onPressed: () async {
                    bool con = await checkInternetConnectivity();
                    if (con) {
                      showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return SingleChildScrollView(
                                child: Container(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              child: addNewDevice(),
                            ));
                          });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("No Internet Connection"),
                        duration: Duration(seconds: 3),
                      ));
                    }
                    /*setState(() {
                            addDevice = !addDevice;
                          });*/
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: <Widget>[
                  const SizedBox(
                    height: 8,
                  ),

                  /* Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: const Text("Added Devices",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                  ),*/
                  for (var i = 0; i < sdp.devices.length; i++) ...[
                    tile(sdp.devices[i]),
                  ],

                  ///
                  /*for (int i = 0; i < bdp.hideConnectedList.length; i++) ...[
                    //if (bdp.hideConnectedList[i].uuids.isNotEmpty) ...[
                    tileHCD(bdp.hideConnectedList[i]),
                    //],
                  ],
                  for (int i = 0; i < bdp.scanResultList.length; i++) ...[
                    //if (bdp.scanResultList[i].uuids.isNotEmpty) ...[
                    tileSR(bdp.scanResultList[i]),
                    //],
                  ],*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tile(SavedDeviceModel d) {
    SavedDevicesProvider sdp = context.read<SavedDevicesProvider>();
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    UserDataProvider udp = context.read<UserDataProvider>();
    LocationProvider lp = context.read<LocationProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                ListTile(
                  onTap: () {
                    if (expanded == d.id) {
                      setState(() {
                        expanded = " ";
                      });
                    } else {
                      setState(() {
                        expanded = d.id;
                      });
                    }
                  },
                  tileColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 3),
                  /* leading: */
                  title: Text(
                    d.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  horizontalTitleGap: 5,
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        editName = "";
                        edit_name.clear();
                      });
                      if (expanded == d.id) {
                        setState(() {
                          expanded = " ";
                        });
                      } else {
                        setState(() {
                          expanded = d.id;
                        });
                      }
                    },
                    icon: Icon(
                      expanded == d.id
                          ? Icons.keyboard_arrow_up_sharp
                          : Icons.keyboard_arrow_down_sharp,
                      size: 30,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                if (expanded == d.id) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: editName == d.id
                              ? TextFormField(
                                  controller: edit_name,
                                  //initialValue: initial,
                                  keyboardType: TextInputType.text,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Name cannot be empty";
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 17),
                                  decoration: InputDecoration(
                                    border: border,
                                    enabledBorder: border,
                                    errorBorder: errorBorder,
                                    focusedBorder: focusedBorder,
                                    labelText: 'Name',
                                    //labelStyle: buttonTextStyle,
                                  ),
                                )
                              : Text(
                                  d.name,
                                  style: const TextStyle(fontSize: 17),
                                ),
                        ),
                      ),
                      // Spacer(),
                      IconButton(
                        onPressed: () {
                          if (d.id == editName) {
                            sdp.editDeviceName(context, d.id, edit_name.text);
                            setState(() {
                              editName = "";
                              edit_name.clear();
                            });
                          } else {
                            setState(() {
                              editName = d.id;
                              edit_name.text = d.name;
                            });
                          }
                        },
                        icon: Icon(
                          editName == d.id
                              ? Icons.save_outlined
                              : Icons.edit_outlined,
                          // size: 30,
                          color: editName == d.id ? Colors.green : Colors.black,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          sdp.removeDevice(context, d.id);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          //size: 30,
                          color: Color(0xFFFF5353),
                        ),
                      ),
                    ],
                  ),
                ],
                if (expanded == d.id) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Chip(
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        label: Text(d.id),
                      ),
                      const Spacer(),
                      if (bdp.checksr(d.id) != null) ...[
                        InkWell(
                          onTap: () {
                            ScanResult sri = bdp.checksr(d.id)!;
                            Device toConnectDevice =
                                sri.connect(connectTimeout: 10000);
                            bdp
                                .changeConnectedDevice(
                                    toConnectDevice, sri.name ?? "--------")
                                .then((value) {
                              lp.pushLocation(udp.user!.phone);
                            });
                            String ss = sri.name ?? "-----";
                            String s = ss.trim();
                            bdp.changeLastDevice(s);
                            bdp.changeTabIndex(1);
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF5d9451),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                            height: 40,
                            width: 132,
                            child: const Center(
                              child: Text(
                                "Connect",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          height: 40,
                          width: 132,
                          child: const Center(
                            child: Text(
                              "Not Detected",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
                /*if (d.id == editName) ...[
                  editDeviceName(d),
                  SizedBox(
                    height: 20,
                  ),
                ]*/
              ],
            ),
          ),
        ),
      ),
    );
  }

  clearAddDevice() {
    setState(() {
      name.clear();
      id.clear();
      password.clear();
    });
  }

  Widget tileHCD(HideConnectedDevice hcd) {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    UserDataProvider udp = context.read<UserDataProvider>();
    LocationProvider lp = context.read<LocationProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: ListTile(
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        trailing:
            //hcd.uuids.isNotEmpty
            // ?
            ActionChip(
          onPressed: () async {
            Device toConnectDevice = hcd.connect(connectTimeout: 10000);
            bdp.changeConnectedDevice(toConnectDevice, hcd.name ?? "--------");
            lp.pushLocation(udp.user!.phone);

            String ss = hcd.name ?? "-----";
            String s = ss.trim();
            bdp.changeLastDevice(s);
            bdp.changeTabIndex(1);
          },
          label: const Text("Connect"),
        ),
        //: const Text("NOT BLE"),
        subtitle: Text(hcd.id),
        title: Text(hcd.name ?? "Unnamed Device"),
      ),
    );
  }

  Widget tileSR(ScanResult sr) {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    UserDataProvider udp = context.read<UserDataProvider>();
    LocationProvider lp = context.read<LocationProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        tileColor: Theme.of(context).cardColor,
        leading: Chip(
          backgroundColor: Colors.transparent,
          label: Text(sr.rssi.toString()),
        ),
        trailing:
            //sr.uuids.isNotEmpty
            // ?
            ActionChip(
          onPressed: () async {
            Device toConnectDevice = sr.connect(connectTimeout: 10000);
            bdp.changeConnectedDevice(toConnectDevice, sr.name ?? "--------");
            lp.pushLocation(udp.user!.phone);

            String ss = sr.name ?? "-----";
            String s = ss.trim();
            bdp.changeLastDevice(s);
            bdp.changeTabIndex(1);
          },
          label: const Text("Connect"),
        ),
        //: const Text("NOT BLE"),
        subtitle: Text(sr.id),
        title: Text(sr.name ?? "Unnamed Device"),
      ),
    );
  }

  Widget addNewDevice() {
    SavedDevicesProvider sdp = context.read<SavedDevicesProvider>();
    double w = MediaQuery.of(context).size.width;
    return Form(
      key: formKey,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(16.0), topLeft: Radius.circular(16.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 15,
              ),
              ListTile(
                title: const Text(
                  "Add Device",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    //size: 30,
                    color: Color(0xFF2a2a2a),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                controller: name,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Name cannot be empty";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: linedBorder,
                  enabledBorder: linedBorder,
                  errorBorder: linedErrorBorder,
                  focusedBorder: linedFocusedBorder,
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  labelText: 'Name',
                  labelStyle: linedLabelStyle,
                  // labelStyle: buttonTextStyle,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              TextFormField(
                controller: id,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "ID cannot be empty";
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: linedBorder,
                  enabledBorder: linedBorder,
                  errorBorder: linedErrorBorder,
                  focusedBorder: linedFocusedBorder,
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  labelText: 'ID',
                  labelStyle: linedLabelStyle,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              TextFormField(
                controller: password,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Password cannot be empty";
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: linedBorder,
                  enabledBorder: linedBorder,
                  errorBorder: linedErrorBorder,
                  focusedBorder: linedFocusedBorder,
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  labelText: 'Password',
                  labelStyle: linedLabelStyle,
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      clearAddDevice();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        //color: Color(0xFF0079E9),
                        border: Border.all(width: 1, color: Colors.white),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                      height: 40,
                      width: w * 0.35,
                      child: const Center(
                        child: Text(
                          "Clear",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      if (formKey.currentState!.validate()) {
                        await MongoDBConnection.mongoDB
                            .checkMongoDBConnection();
                        DbCollection dc = mongoDB.db.collection('t_devices');
                        await dc
                            .find({'id': id.text, 'password': password.text})
                            .toList()
                            .then((value) async {
                              if (true) {
                                if (sdp.devices
                                    .where((element) => element.id == id.text)
                                    .toList()
                                    .isEmpty) {
                                  sdp.addDevice(
                                      context,
                                      SavedDeviceModel(
                                          id: id.text, name: name.text));
                                  clearAddDevice();
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("Device already exists"),
                                    duration: Duration(seconds: 3),
                                  ));
                                }
                                // ignore: dead_code
                              } else {}
                            });
                      }
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF5d9451),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      height: 40,
                      width: w * 0.35,
                      child: const Center(
                        child: Text(
                          "Add",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'dart:io';
import '../providers/index.dart';
import '../utils/index.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  load() async {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    BluetoothProvider bp = context.read<BluetoothProvider>();
  /*  Future.delayed(const Duration(milliseconds: 1000), () async {
      if (bp.gpsOn && bp.bluetoothOn && !bdp.scanning) {
        bdp.scan(context);
      }
    });*/
  }

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  void dispose() {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    try {
      bdp.connectedDevice?.disConnect();
    } catch (e) {
      print(e);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BluetoothProvider bp = context.watch<BluetoothProvider>();
    BluetoothDevicesProvider bdp = context.watch<BluetoothDevicesProvider>();
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          floatingActionButton: (bp.gpsOn && bp.bluetoothOn)
              ? FloatingActionButton(
                  backgroundColor: bdp.scanning ? Colors.red :secondAccentColor,
                  onPressed: () {
                    bdp.scan(context);
                  },
                  tooltip: 'scan',
                  child: Icon(bdp.scanning ? Icons.stop : Icons.find_replace),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: <Widget>[
              for (int i = 0; i < bdp.hideConnectedList.length; i++) ...[
                //if (bdp.hideConnectedList[i].uuids.isNotEmpty) ...[
                tileHCD(bdp.hideConnectedList[i]),
                //],
              ],
              for (int i = 0; i < bdp.scanResultList.length; i++) ...[
                //if (bdp.scanResultList[i].uuids.isNotEmpty) ...[
                tileSR(bdp.scanResultList[i]),
                //],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget tileHCD(HideConnectedDevice hcd) {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: ListTile(
        tileColor: firstAccentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        trailing:
            //hcd.uuids.isNotEmpty
            // ?
            ActionChip(
          onPressed: () async {
            Device toConnectDevice = hcd.connect(connectTimeout: 10000);
            bdp.changeConnectedDevice(toConnectDevice);
            String ss = hcd.name ?? "-----";
            String s = ss.trim();
            bdp.changeLastDevice(s);
            bdp.changeTabIndex(1);
          },
          label: const Text("Connect"),
        ),
        //: const Text("NOT BLE"),
        subtitle: Text(hcd.id),
        title: Text(hcd.name ?? "Unnamed Device"),
      ),
    );
  }

  Widget tileSR(ScanResult sr) {
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        tileColor: firstAccentColor,
        leading: Chip(
          backgroundColor: Colors.transparent,
          label: Text(sr.rssi.toString()),
        ),
        trailing:
            //sr.uuids.isNotEmpty
            // ?
            ActionChip(
          onPressed: () async {
            Device toConnectDevice = sr.connect(connectTimeout: 10000);
            bdp.changeConnectedDevice(toConnectDevice);
            String ss = sr.name ?? "-----";
            String s = ss.trim();
            bdp.changeLastDevice(s);
            bdp.changeTabIndex(1);
          },
          label: const Text("Connect"),
        ),
        //: const Text("NOT BLE"),
        subtitle: Text(sr.id),
        title: Text(sr.name ?? "Unnamed Device"),
      ),
    );
  }
}
*/
