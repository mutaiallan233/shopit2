import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopit/services/authservice.dart';
import 'package:mpesa_flutter_plugin/mpesa_flutter_plugin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopit/theme.dart';
import 'package:splashscreen/splashscreen.dart';

void main() {
  MpesaFlutterPlugin.setConsumerKey("q4EXwkP7u5OjQ7tKjEKGWupbZ7lGKOXH");
  MpesaFlutterPlugin.setConsumerSecret("TMF0TYJwIkpPQrS5");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  //final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeChanger>(
      create: (_) => ThemeChanger(ThemeData.dark()),
      child: new MaterialAppWithTheme(),
    );
  }
}

class MaterialAppWithTheme extends StatelessWidget {
  const MaterialAppWithTheme({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeChanger>(context);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '🛒 Shopit',
        theme: theme.getTheme(),
        home: FutureBuilder(
          // Initialize FlutterFire:
          future: Firebase.initializeApp(),
          builder: (context, snapshot) {
            // Check for errors
            if (snapshot.hasError) {
              return Scaffold(
                  body: Container(
                      color: Colors.red,
                      child: Center(
                          child: Column(
                        children: [
                          Icon(Icons.warning),
                          Text('something went wrong!! 🤔')
                        ],
                      ))));
            }

            // Once complete, show your application
            if (snapshot.connectionState == ConnectionState.done) {
              return SplashScreen(
                backgroundColor: Colors.black,
                seconds: 5,
                navigateAfterSeconds: AuthService().handleAuth(),
                title: Text(
                  '🛒 ShopIt',
                  style: TextStyle(color: Colors.white, fontSize: 30),
                ),
              );
            }

            // Otherwise, show something whilst waiting for initialization to complete
            return SplashScreen(
              seconds: 10,
              // image: Image.asset(
              //   'assets/icons/splash.png',
              //   fit: BoxFit.cover,
              // ),
              title: Text('🛒 ShopIt'),
            );
          },
        ));
  }
}
//(),
