import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopit/screens/cart.dart';
//import 'package:shopit/screens/change_theme.dart';
import 'package:shopit/screens/login.dart';
import 'package:shopit/services/authservice.dart';
import 'package:splashscreen/splashscreen.dart';

import '../theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

// bool _light = true;

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  final formkey = GlobalKey<FormState>();
  final myController = TextEditingController();
  bool validate = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  DocumentReference reference = FirebaseFirestore.instance
      .collection('cashier')
      .doc(FirebaseAuth.instance.currentUser.uid);
  DocumentReference ref = FirebaseFirestore.instance
      .collection('user')
      .doc(FirebaseAuth.instance.currentUser.uid)
      .collection('cart')
      .doc();
  final usercartdoc = FirebaseFirestore.instance
      .collection('user')
      .doc(FirebaseAuth.instance.currentUser.uid);
  @override
  Widget build(BuildContext context) {
    ThemeChanger _themeChanger = Provider.of<ThemeChanger>(context);

    /// ----  Spooky Theme  ----
    final spookyPrimary = Color(0xFF000000);
    final spookyAccent = Color(0xFF03A400);
    // final spookyAccent = Color(0xFFBB86FC);
    final spookyBackground = Color(0xFF4A4A4A);
    final spookyTheme = ThemeData(
      textTheme: TextTheme(bodyText1: TextStyle(color: Colors.amber)),
      cardTheme: CardTheme(color: Colors.grey),
      primaryIconTheme: IconThemeData(color: Colors.red),
      buttonBarTheme:
          ButtonBarThemeData(buttonTextTheme: ButtonTextTheme.accent),
      canvasColor: Colors.grey[800],
      dialogBackgroundColor: Colors.grey[600],
      buttonTheme: ButtonThemeData(
          buttonColor: Colors.green, textTheme: ButtonTextTheme.accent),
      tabBarTheme: TabBarTheme(
          labelColor: Colors.green, unselectedLabelColor: Colors.green[200]),
      primaryColor: spookyPrimary,
      accentColor: spookyAccent,
      backgroundColor: spookyBackground,
    );
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('items').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(
            backgroundColor: Colors.black,
            seconds: 5,
            navigateAfterSeconds: AuthService().handleAuth(),
            title: Text(
              '🛒 ShopIt',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            drawer: Drawer(
              child: Column(
                children: [
                  DrawerHeader(child: Image.asset('assets/clip.png')),
                  Form(
                    key: formkey,
                    child: TextFormField(
                      // ignore: missing_return
                      validator: (value) {
                        if ((value).isEmpty) {
                          return 'Value can\'t be Empty';
                        }
                      },
                      decoration: InputDecoration(
                          labelText: 'enter mpesa receipt number',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12))),
                      controller: myController,
                    ),
                  ),
                  FlatButton(
                      onPressed: () async {
                        if (formkey.currentState.validate()) {
                          await firestore
                              .collection('receipts')
                              .where('receiptNumber',
                                  isEqualTo: myController.text)
                              .get()
                              .then((value) async {
                            value.docs.forEach((element) {
                              if (!element.exists) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                      content: Text('nothing to show')),
                                );
                              }
                              Map fieldnames = element.data()['map'];
                              if (element.data()['checkedOut'] == true) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                      content: Text(
                                          'umeshanunua hii kitu\nbloody you!\n😡😡😡😡')),
                                );
                              } else
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('test'),
                                      actions: [
                                        FlatButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: Text('ok'))
                                      ],
                                      content: SingleChildScrollView(
                                        child: Stack(
                                          fit: StackFit.loose,
                                          children: [
                                            ListBody(
                                              children: fieldnames.keys
                                                  .map((mapinfo) {
                                                return Text('item: ' +
                                                    mapinfo +
                                                    '\n\n');
                                              }).toList(),
                                            ),
                                            ListBody(
                                              children: fieldnames.values
                                                  .map((mapinfo) {
                                                return Text('\nquantity: ' +
                                                    mapinfo.toString() +
                                                    '\n');
                                              }).toList(),
                                            ),
                                            Positioned(
                                              bottom: 1,
                                              right: 1,
                                              child: Text('total: ' +
                                                  element
                                                      .data()['total']
                                                      .toString()),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                            });
                          });
                        }
                      },
                      child: Text('view receipt')),
                  FlatButton(
                      child: Text('Dark Theme'),
                      onPressed: () => _themeChanger.setTheme(spookyTheme)),
                  FlatButton(
                      child: Text('Light Theme'),
                      onPressed: () =>
                          _themeChanger.setTheme(ThemeData.light())),
                ],
              ),
            ),
            appBar: AppBar(
              elevation: 0,
              bottom: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.home),
                    text: "Home",
                  ),
                  Tab(icon: Icon(Icons.shopping_cart), text: "Cart"),
                ],
              ),
              title: Text('🛒 ShopIt'),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.exit_to_app,
                    size: 30.0,
                  ),
                  onPressed: () {
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text('Wanna SignOut?'),
                            actions: [
                              FlatButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('No'),
                              ),
                              FlatButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                  AuthService().signOut();
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => LoginPage()));
                                },
                                child: Text('Yes'),
                              ),
                            ],
                          );
                        });
                  },
                ),
              ],
            ),
            body: TabBarView(
              children: [
                ListView(
                  children: snapshot.data.docs.map((DocumentSnapshot document) {
                    firestore.runTransaction((transaction) async {
                      DocumentSnapshot snapshot =
                          await transaction.get(reference);

                      while (document.data()['quantity'] <
                          snapshot.data()[document.data()['name']]) {
                        await firestore
                            .collection('user')
                            .doc(_auth.currentUser.uid)
                            .collection('cart')
                            .doc(document.data()['name'])
                            .update({
                          'in stock': false,
                          'price': 0,
                          'quantity': 0
                        }).then((value) async {
                          await firestore
                              .collection('cashier')
                              .doc(_auth.currentUser.uid)
                              .update({
                            document.data()['name']: FieldValue.delete()
                          });
                        });
                      }
                    });
                    // DocumentReference receipts =
                    //     firestore.collection('receipts').doc();
                    // firestore.runTransaction((transaction) async {
                    //   DocumentSnapshot recsnap =
                    //       await transaction.get(receipts);
                    //   Map mapdata = recsnap.data()['map'];
                    //   if (recsnap.data()['paid'] == false) {
                    //     print(mapdata.keys.toString());
                    //     print(mapdata.values.toString());
                    //     mapdata.keys.forEach((element) {
                    //       firestore
                    //           .collection('items')
                    //           .doc(element)
                    //           .update({'quantity': mapdata.values});
                    //     });
                    //   }
                    // });
                    firestore
                        .collection('receipts')
                        .where('uid', isEqualTo: _auth.currentUser.uid)
                        .get()
                        .then((value) {
                      value.docs.forEach((element) {
                        if (element.data()['paid'] == false) {
                          Map map = element.data()['map'];
                          map.keys.forEach((e) {
                            firestore
                                .collection('user')
                                .doc(_auth.currentUser.uid)
                                .collection('cart')
                                .doc(e)
                                .get()
                                .then((value) {
                              var addthis = value.data()['quantity'];
                              firestore
                                  .collection('items')
                                  .doc(e)
                                  .update({'quantity': addthis});
                            });
                          });
                        }
                      });
                    });
                    // firestore
                    //     .collection('receipts')
                    //     .where('paid', isEqualTo: false)
                    //     .get()
                    //     .then((value) {
                    //   value.docs.forEach((element) {
                    //     Map map = element.data()['map'];
                    //     map.keys.forEach((e) {
                    //       map.values.forEach((add) {
                    //         DocumentReference documentReference =
                    //             firestore.collection('items').doc(e);
                    //         firestore.runTransaction((transaction) async {
                    //           DocumentSnapshot snapshot =
                    //               await transaction.get(documentReference);
                    //           var val = snapshot.data()['quantity'];
                    //           print(val);
                    //         });
                    //       });
                    //     });
                    //   });
                    // });

                    if (document.data()['quantity'] < 1) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(document.data()['url']),
                            radius: 30,
                          ),
                          title: Text(document.data()['name']),
                          subtitle: Text('out of stock'),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: Container(
                          child: CachedNetworkImage(
                            imageUrl: document.data()['url'],
                            imageBuilder: (context, imageProvider) => Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                  // colorFilter: ColorFilter.mode(
                                  //     Colors.red, BlendMode.colorBurn)
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Icon(Icons.fastfood),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                        ),
                        title: Text(document.data()['name']),
                        subtitle: Text(document.data()['quantity'].toString()),
                        trailing: IconButton(
                            icon: Icon(Icons.add_shopping_cart),
                            color: Colors.green,
                            onPressed: () async {
                              try {
                                await firestore
                                    .collection('user')
                                    .doc(_auth.currentUser.uid)
                                    .collection('cart')
                                    .doc(document.data()['name'])
                                    .get()
                                    .then((doc) {
                                  if (document.data()['quantity'] == 0) {
                                    Fluttertoast.showToast(
                                        msg: document.data()['name'] +
                                            ' is out of stock',
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: Colors.black,
                                        textColor: Colors.white,
                                        fontSize: 16.0);
                                  } else {
                                    if (!doc.exists) {
                                      firestore
                                          .collection('user')
                                          .doc(_auth.currentUser.uid)
                                          .collection('cart')
                                          .doc(document.data()['name'])
                                          .set({
                                        'image': document.data()['url'],
                                        'name': document.data()['name'],
                                        'price': document.data()['price'],
                                        'quantity': 0,
                                        'in stock': true
                                      });

                                      firestore
                                          .collection('cashier')
                                          .doc(_auth.currentUser.uid)
                                          .set({document.data()['name']: 0});

                                      Fluttertoast.showToast(
                                          msg: document.data()['name'] +
                                              ' added to cart ✔',
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.black,
                                          textColor: Colors.white,
                                          fontSize: 16.0);
                                    } else {
                                      Fluttertoast.showToast(
                                          msg: document.data()['name'] +
                                              ' is already in cart',
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.black,
                                          textColor: Colors.white,
                                          fontSize: 16.0);
                                    }
                                  }
                                });
                              } catch (e) {
                                print(e);
                              }
                            }),
                      ),
                    );
                  }).toList(),
                ),
                Mycart()
              ],
            ),
          ),
        );
      },
    );
  }
}
