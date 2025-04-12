// ignore_for_file: use_build_context_synchronously, avoid_print, no_wildcard_variable_uses, prefer_const_constructors, unused_import

import 'package:ezing/data/functions/constants.dart';
import 'package:ezing/main.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

TextEditingController nameController = TextEditingController();
TextEditingController emailController = TextEditingController();
TextEditingController phoneController = TextEditingController();
ValueNotifier<String> phonenumber = ValueNotifier('');

bool isOtpSent = false;
bool isNewUser = false;
String otpValue = '';

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false; // Add this variable to track loading state

  void showSnackBar(String data) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data),
        duration: Duration(seconds: 5),
      ));
    });
  }

  @override
  void initState() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    isOtpSent = false;
    isNewUser = false;
    otpValue = '';
    isLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    UserDataProvider udp = context.watch<UserDataProvider>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: height * 0.1,
        // shape: Border.fromBorderSide(BorderSide(color: themeColor)),
        automaticallyImplyLeading: false,
        title: Visibility(
          visible: isOtpSent || isNewUser,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(0, 2))
                ]),
            child: IconButton(
              onPressed: () {
                if (isNewUser) {
                  setState(() {
                    isOtpSent = true;
                    isNewUser = false;
                  });
                } else if (isOtpSent) {
                  setState(() {
                    isNewUser = false;
                    isOtpSent = false;
                  });
                }
              },
              icon: Icon(Icons.chevron_left),
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
        child: Center(
          child: StatefulBuilder(builder: (context, subState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/appbar_logo.png',
                  width: width * 0.3,
                ),
                SizedBox(
                  height: height * 0.04,
                ),
                Text(
                  isNewUser
                      ? 'Just a few more details'
                      : isOtpSent
                          ? "Enter 6 digit OTP"
                          : 'Enter your\nphone number',
                  style: TextStyle(
                      letterSpacing: 0,
                      fontSize:
                          Theme.of(context).textTheme.displaySmall?.fontSize,
                      fontWeight: FontWeight.bold),
                ),
                Visibility(
                  visible: isOtpSent && !isNewUser,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        phonenumber.value.isNotEmpty
                            ? 'sent to ${phonenumber.value}'
                            : '',
                        style:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                !isOtpSent
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            keyboardType: TextInputType.phone,
                            controller: phoneController,
                            onChanged: (value) {
                              phonenumber.value = value;
                            },
                            decoration: const InputDecoration(
                              hintText: '10 digit phone number',
                              hintStyle: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      )
                    : isOtpSent && !isNewUser
                        ? PinCodeTextField(
                            textStyle: Theme.of(context).textTheme.bodyLarge!,
                            keyboardType: TextInputType.number,
                            appContext: context,
                            length: 6,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: width * 0.1,
                              activeColor: Colors.black,
                              inactiveColor: Colors.black,
                              selectedColor: Colors.black,
                            ),
                            onCompleted: (_) async {
                              otpValue = _;
                            },
                          )
                        : Container(),
                SizedBox(
                  height: height * 0.03,
                ),
                ValueListenableBuilder(
                  builder: (context, _, widget) {
                    return Visibility(
                      visible: !isNewUser,
                      child: InkWell(
                        onTap: phonenumber.value.isEmpty || isLoading
                            ? () {}
                            : () async {
                                setState(() {
                                  isLoading = true; // Set loading state to true
                                });
                                if (isOtpSent) {
                                  print(otpValue);
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  final result = await udp.verifyOtp(
                                      prefs.getString('verificationId') ?? '',
                                      otpValue.toString());
                                  if (result) {
                                    showSnackBar('OTP verified successfully');
                                    print(
                                        '--------------------------------------------');
                                    final phoneExists = await udp
                                        .doesPhoneExists(phonenumber.value);
                                    print("phoneavailable$phoneExists");
                                    if (!phoneExists) {
                                      subState(() {
                                        isNewUser = true;
                                      });
                                    } else {
                                      await udp.loginUser(phonenumber.value);
                                      Navigator.of(context)
                                          .pushReplacement(MaterialPageRoute(
                                        builder: (context) => Entry(),
                                      ));
                                    }
                                  } else {
                                    showSnackBar('OTP verification failed');
                                  }
                                } else {
                                  if (phonenumber.value.length == 10) {
                                    final result = await udp
                                        .sendOtp('+91${phonenumber.value}');
                                    subState(() {
                                      isOtpSent = result;
                                    });
                                    if (result) {
                                      showSnackBar('OTP sent successfully');
                                    } else {
                                      showSnackBar('OTP sending failed');
                                    }
                                  } else {
                                    showSnackBar(
                                        'Please enter a valid phone number');
                                  }
                                }
                                setState(() {
                                  isLoading =
                                      false; // Set loading state to false
                                });
                              },
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.1,
                            vertical: height * 0.01,
                          ),
                          child: Text(
                            isLoading
                                ? 'Loading...'
                                : 'Continue', // Change text based on loading state
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                  valueListenable: phonenumber,
                ),
                Visibility(
                  visible: isNewUser,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(500))),
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              FontAwesomeIcons.user,
                              size: 16,
                            ),
                            hintText: 'Name',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: height * 0.02,
                      ),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(500))),
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              FontAwesomeIcons.envelope,
                              size: 16,
                            ),
                            hintText: 'Email Address',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: height * 0.05,
                      ),
                      ValueListenableBuilder(
                        builder: (context, _, widget) {
                          return SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: nameController.text.isEmpty ||
                                      isLoading
                                  ? () {}
                                  : () async {
                                      setState(() {
                                        isLoading =
                                            true; // Set loading state to true
                                      });
                                      await udp.registerUser(
                                          nameController.text,
                                          emailController.text,
                                          phonenumber.value);
                                      Navigator.of(context)
                                          .pushReplacement(MaterialPageRoute(
                                        builder: (context) => Entry(),
                                      ));
                                      setState(() {
                                        isLoading =
                                            false; // Set loading state to false
                                      });
                                    },
                              child: Text(isLoading
                                  ? 'Loading...'
                                  : 'Register'), // Change text based on loading state
                            ),
                          );
                        },
                        valueListenable: nameController,
                      ),
                      SizedBox(
                        height: height * 0.03,
                      ),
                    ],
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
  }
}
