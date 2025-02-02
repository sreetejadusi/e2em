import 'package:ezing/data/datasource/mongodb.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_provider.dart';
import 'package:ezing/presentation/providers/location_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/widgets/logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State, Center;
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final int battery, speed, mode;
  final double rangeLeft;
  final String deviceName;
  final bool hasDevice, connecting, connected
      // ,disconnected
      ;
  final Function(int) modeChange;
  final Function() connect;
  final Function() disconnect;
  const HomeScreen({
    Key? key,
    required this.connect,
    required this.disconnect,
    required this.connecting,
    required this.connected,
    // required this.disconnected,
    required this.deviceName,
    required this.hasDevice,
    required this.modeChange,
    required this.mode,
    required this.battery,
    required this.speed,
    required this.rangeLeft,
  }) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double leftPortion = 0.60;
  double rightPortion = 0.40;
  double sidePadding = 24;
  Color scb = const Color(0xFF232323);

  @override
  Widget build(BuildContext context) {
    BluetoothProvider bp = context.watch<BluetoothProvider>();
    BluetoothDevicesProvider bdp = context.watch<BluetoothDevicesProvider>();
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width - sidePadding * 2;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Logo(
          width: MediaQuery.of(context).size.width * 0.25,
        ),
        actions: [
          IconButton(
              onPressed: () {
                if (!bp.bluetoothOn) {
                  FlutterBlueElves.instance.androidOpenBluetoothService((isOk) {
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
                  FlutterBlueElves.instance.androidOpenLocationService((isOk) {
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
      body: Container(
        color: Colors.white,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(sidePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: w * leftPortion,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: w * 0.60,
                                height: h * 0.07,
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(500),
                                    bottomLeft: Radius.circular(500),
                                    bottomRight: Radius.circular(500),
                                    topRight: Radius.circular(500),
                                  ),
                                ),
                              ),

                              SizedBox(height: 15),
                              //textTile(widget.rangeLeft, "km", "Range Left"),
                              textTile1(widget.rangeLeft, "", "Total KM"),
                              SizedBox(height: 25),

                              SizedBox(height: 15),
                              //textTile(widget.rangeLeft, "km", "Range Left"),
                              textTile(widget.speed, "km/h", "Speed"),
                              SizedBox(height: 25),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: batteryBox(context, widget.battery),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: w * rightPortion,
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              modeButton(
                                num: 1,
                                icon: Icons.power_settings_new,
                                title: " OFF ",
                              ),
                              modeButton(
                                num: 2,
                                icon: Icons.eco,
                                title: " ECO ",
                              ),
                              modeButton(
                                num: 3,
                                icon: Icons.flash_on,
                                title: " POWER ",
                              ),
                              modeButton(
                                num: 4,
                                icon: Icons.directions_walk,
                                title: " WALK ",
                              ),
                              modeButton(
                                num: 5,
                                icon: Icons.cable_outlined,
                                title: "CRUISE",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        title: Text(
                          widget.hasDevice
                              ? widget.deviceName
                              : "No Device Selected",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2a2a2a)),
                        ),
                        trailing: widget.hasDevice
                            ? InkWell(
                                onTap: widget.connected
                                    ? () {
                                        mongoDB.db
                                            .collection('s_devices')
                                            .update(
                                                {'km': '200', 'loc': 'sydney'},
                                                where.eq('id', '12346'));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content:
                                                    Text('Updated Db Loc')));
                                        widget.disconnect();

                                        setState(() {});
                                      }
                                    : widget.connecting
                                        ? () {}
                                        : () {
                                            widget.connect();
                                            mongoDB.db
                                                .collection('s_devices')
                                                .update({
                                              'km': '300',
                                              'loc': 'delhi'
                                            }, where.eq('id', '12346'));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Updated Db Loc')));
                                            setState(() {});
                                          },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: widget.connected
                                        ? Colors.redAccent
                                        : widget.connecting
                                            ? Colors.blueGrey
                                            : Color(0xFF56bb45),

                                    //Color(0xFF5d9451),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10),
                                    child: Text(
                                      widget.connected
                                          ? "Disconnect"
                                          : widget.connecting
                                              ? "Connecting"
                                              : "Connect",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget batteryBox(BuildContext context, int percentage) {
    final w = MediaQuery.of(context).size.width - sidePadding * 2 - 50;
    final h = MediaQuery.of(context).size.height;
    double height = h * 0.06;
    double innerW = ((height * 2) - 6 - 6) / 6.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            height: w * leftPortion * 0.28,
            width: w * leftPortion * 0.7,
            decoration: BoxDecoration(
              //color: Color(0xFF2a2a2a),
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 3,
                      ),
                      Container(
                        color: Color(0xFFdcd8de),
                      ),
                      SizedBox(
                        width: 3,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 4,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF56bb45),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                            bottomRight: Radius.circular(5),
                            topRight: Radius.circular(5),
                          ),
                        ),
                        width: percentage > 0
                            ? (w * leftPortion * 0.7 * (percentage / 100)) - 6
                            : 0,
                      ),
                      SizedBox(
                        width: 4,
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      percentage.toString() + "%",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            width: height * 0.20,
            height: height * 0.50,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(0),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget modeButton({
    required int num,
    required String title,
    required IconData icon,
  }) {
    bool selected = widget.mode == num;
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width - sidePadding * 2;
    UserDataProvider udp = context.read<UserDataProvider>();
    LocationProvider lp = context.read<LocationProvider>();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: InkWell(
          radius: 10,
          borderRadius: BorderRadius.circular(10.0),
          onTap: () async {
            final bool flag = await udp.checkFlag();
            if (flag) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error. Contact Admin.')));
            } else {
              widget.modeChange(num);
              lp.pushLocation(udp.user!.phone);
            }
            setState(() {});
          },
          child: Container(
            width: w * 0.31,
            decoration: BoxDecoration(
              //color: Colors.white,
              color: selected ? Color(0xFF56bb45) : Colors.white,
              /*border:!selected?null: Border.all(
                  color: Color(0xFF5d9451),
                  width: 3.0,
                  style: BorderStyle.solid),*/
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Icon(icon,
                        color: selected ? Colors.white : Colors.black),
                  ),
                  Text(
                    title,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget textTile(int num, String unit, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              text: num.toString(),
              style: TextStyle(
                //color: Colors.black,
                color: Color(0xFF2a2a2a),
                fontWeight: FontWeight.w500,
                fontSize: 60,
              ),
              children: [
                TextSpan(
                  text: " " + unit,
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    fontSize: 25,
                  ),
                ),
              ],
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget textTile1(double num, String unit, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              text: num.toString(),
              style: TextStyle(
                //color: Colors.black,
                color: Color(0xFF2a2a2a),
                fontWeight: FontWeight.w500,
                fontSize: 25,
              ),
              children: [
                TextSpan(
                  text: " " + unit,
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    fontSize: 25,
                  ),
                ),
              ],
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
