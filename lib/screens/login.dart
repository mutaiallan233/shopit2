import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopit/services/authservice.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formkey = GlobalKey<FormState>();
  TextEditingController phoneNoController = TextEditingController();
  String phoneNo, verificationId, smsCode;
  bool codeSent = false;
  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    setState(() {
      phoneNo = internationalizedPhoneNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛒 ShopIt'),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Container(
          color: Colors.greenAccent,
          child: Form(
            key: formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 50),
                  child: Text(
                    'LogIn',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 25, left: 25),
                  child: TextFormField(
                    // ignore: missing_return
                    validator: (value) {
                      if ((value).isEmpty) {
                        return 'please enter a valid phone number';
                      }
                      if ((value).length < 9) {
                        return 'please enter a valid phone number';
                      }
                      if (!(value).startsWith('07')) {
                        return 'please enter a valid phone number';
                      }
                    },
                    keyboardType: TextInputType.phone,

                    //autovalidate: true,
                    maxLength: 10,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'phone number',
                    ),
                    onChanged: (val) {
                      setState(() {
                        this.phoneNo = val;
                      });
                    },
                  ),
                ),
                codeSent
                    ? Padding(
                        padding: EdgeInsets.only(right: 25, left: 25),
                        child: TextFormField(
                          // ignore: missing_return
                          validator: (value) {
                            if ((value).isEmpty) {
                              return 'invalid verification code';
                            }
                          },
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter verification code sent'),
                          onChanged: (val) {
                            setState(() {
                              this.smsCode = val;
                            });
                          },
                        ),
                      )
                    : Container(),
                Padding(
                  padding: EdgeInsets.only(left: 65, right: 65),
                  child: SizedBox(
                    child: RaisedButton(
                      onPressed: () {
                        if (formkey.currentState.validate()) {
                          codeSent
                              ? AuthService()
                                  .signInWithOTP(smsCode, verificationId)
                              : verifyPhone('+254' + phoneNo.toString());
                        } else {
                          print('invalid phone number');
                        }
                      },
                      child: Center(
                        child: codeSent ? Text('verify') : Text('login'),
                      ),
                    ),
                  ),
                ),
                Divider(
                  color: Colors.brown,
                ),
                SizedBox(
                  height: 20,
                  child: Text('OR'),
                ),
                SizedBox(
                  height: 20,
                ),
                SignInButton(Buttons.Google, onPressed: () {})
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> verifyPhone(phoneNo) async {
    final PhoneVerificationCompleted verified =
        (AuthCredential authResult) async {
      AuthService().signIn(authResult);
    };
    final PhoneVerificationFailed verificationFailed = (authException) {};
    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this.verificationId = verId;
      setState(() {
        this.codeSent = true;
      });
    };
    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this.verificationId = verId;
    };
    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNo,
        timeout: Duration(seconds: 20),
        verificationCompleted: verified,
        verificationFailed: verificationFailed,
        codeSent: smsSent,
        codeAutoRetrievalTimeout: autoTimeout);
    // print(phoneNo.toString());
  }
}
