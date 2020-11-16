import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopit/screens/home.dart';
import 'package:shopit/screens/login.dart';

class AuthService {
  //handles Auth
  handleAuth() {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            return HomePage();
          } else {
            return LoginPage();
          }
        });
  }

  //sign out
  signOut() {
    FirebaseAuth.instance.signOut();
  }

//sign in
  signIn(AuthCredential authCreds) async {
    try {
      UserCredential result =
          await FirebaseAuth.instance.signInWithCredential(authCreds);

      User user = result.user;
      await FirebaseFirestore.instance.collection('user').doc(user.uid).set({
        'uid': user.uid,
        'phone': int.parse(user.phoneNumber),
      });
    } catch (e) {
      print(e);
    }
  }

  //sign in with OTP
  signInWithOTP(smsCode, verId) async {
    AuthCredential authCreds =
        PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    signIn(authCreds);
  }
}
