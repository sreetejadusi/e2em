// ignore_for_file: use_build_context_synchronously, avoid_print, no_wildcard_variable_uses, prefer_const_constructors, unused_import

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

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  ValueNotifier<PhoneNumber> phonenumber =
      ValueNotifier(PhoneNumber(phoneNumber: '', dialCode: '', isoCode: ''));
  bool isOtpSent = false;
  bool isNewUser = false;

  void showSnackBar(String data) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data),
        duration: Duration(seconds: 5),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    UserDataProvider udp = context.watch<UserDataProvider>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/appbar_logo.png',
          width: width * 0.3,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: StatefulBuilder(builder: (context, subState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: height * 0.01,
                ),
                Text(
                  isNewUser ? 'ONBOARDING' : 'LOGIN',
                  style: TextStyle(
                    letterSpacing: 0,
                    fontSize:
                        Theme.of(context).textTheme.displayLarge!.fontSize,
                  ),
                ),
                Text(
                  isNewUser
                      ? 'WELCOME!'
                      : 'enter your phone number to get started',
                  style: TextStyle(
                    letterSpacing: 0,
                    fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
                  ),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                Visibility(
                  visible: isOtpSent && !isNewUser,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        phonenumber.value.phoneNumber.toString(),
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
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(500))),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: InternationalPhoneNumberInput(
                              inputBorder: InputBorder.none,
                              hintText: 'Mobile number',
                              selectorConfig: const SelectorConfig(
                                selectorType:
                                    PhoneInputSelectorType.BOTTOM_SHEET,
                                showFlags: false,
                              ),
                              onInputChanged: (_) {
                                phonenumber.value = _;
                              },
                              autoValidateMode: AutovalidateMode.disabled,
                              initialValue: PhoneNumber(isoCode: 'IN'),
                            )),
                      )
                    : isOtpSent && !isNewUser
                        ? PinCodeTextField(
                            textStyle: Theme.of(context).textTheme.bodyLarge!,
                            keyboardType: TextInputType.number,
                            appContext: context,
                            length: 6,
                            pinTheme: PinTheme(),
                            onCompleted: (_) async {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              final result = await udp.verifyOtp(
                                  prefs.getString('verificationId') ?? '',
                                  _.toString());
                              if (result) {
                                showSnackBar('OTP verified successfully');
                                print(
                                    '--------------------------------------------');
                                final phoneExists = await udp.doesPhoneExists(
                                    phonenumber.value.parseNumber());
                                print("phoneavailable$phoneExists");
                                if (!phoneExists) {
                                  subState(() {
                                    isNewUser = true;
                                  });
                                } else {
                                  await udp.loginUser(
                                      phonenumber.value.parseNumber());
                                  Navigator.of(context)
                                      .pushReplacement(MaterialPageRoute(
                                    builder: (context) => Entry(),
                                  ));
                                }
                              } else {
                                showSnackBar('OTP verification failed');
                              }
                            },
                          )
                        : Container(),
                SizedBox(
                  height: height * 0.01,
                ),
                Visibility(
                  visible: !isOtpSent,
                  child: ValueListenableBuilder(
                    builder: (context, _, widget) {
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: phonenumber.value.parseNumber().isEmpty
                              ? () {}
                              : () async {
                                  final result = await udp.sendOtp(
                                      phonenumber.value.phoneNumber.toString());
                                  subState(() {
                                    isOtpSent = result;
                                  });
                                  if (result) {
                                    showSnackBar('OTP sent successfully');
                                  } else {
                                    showSnackBar('OTP sending failed');
                                  }
                                },
                          child: const Text('Send OTP'),
                        ),
                      );
                    },
                    valueListenable: phonenumber,
                  ),
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
                        height: height * 0.02,
                      ),
                      ValueListenableBuilder(
                        builder: (context, _, widget) {
                          return SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: nameController.text.isEmpty
                                  ? () {}
                                  : () async {
                                      await udp.registerUser(
                                          nameController.text,
                                          emailController.text,
                                          phonenumber.value.parseNumber());
                                      Navigator.of(context)
                                          .pushReplacement(MaterialPageRoute(
                                        builder: (context) => Entry(),
                                      ));
                                    },
                              child: const Text('Register'),
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
