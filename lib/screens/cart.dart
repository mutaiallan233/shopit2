import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopit/screens/home.dart';
import 'package:mpesa_flutter_plugin/initializer.dart';
import 'package:mpesa_flutter_plugin/mpesa_flutter_plugin.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Mycart extends StatefulWidget {
  @override
  _MycartState createState() => _MycartState();
}

class _MycartState extends State<Mycart> {
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String checkoutRequestID;
  Future<void> startCheckout({String userPhone, String amount}) async {
    dynamic transactionInitialization;
    try {
      transactionInitialization = await MpesaFlutterPlugin.initializeMpesaSTKPush(
          businessShortCode: "174379",
          transactionType: TransactionType.CustomerPayBillOnline,
          amount: double.parse(amount),
          partyA: userPhone,
          partyB: "174379",
          callBackURL: Uri(
              scheme: "https",
              host: "us-central1-phone-login-414b0.cloudfunctions.net",
              path: "/main/lmno/callback"),
          accountReference: 'mpesa test',
          phoneNumber: userPhone,
          transactionDesc: 'purchase',
          baseUri: Uri(scheme: "https", host: "sandbox.safaricom.co.ke"),
          passKey:
              "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919");

      print('transaction result: \n' + transactionInitialization.toString());
      firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userproduct);
        firestore
            .collection('receipts')
            .doc(transactionInitialization['CheckoutRequestID'])
            .set({'map': snapshot.data()}, SetOptions(merge: true)).then(
                (value) => firestore
                        .collection('receipts')
                        .doc(transactionInitialization['CheckoutRequestID'])
                        .set({
                      'uid': _auth.currentUser.uid,
                      'reqid': transactionInitialization['CheckoutRequestID']
                    }, SetOptions(merge: true)));
      });

      return transactionInitialization;
    } catch (e) {
      print('exception' + e.toString());
    }
  }

  String product;
  int sum;
  int grandtotal = 0;
  int total = 0;
  List<int> quantityselectedperitem = List();
  List<int> newpriceperitem = List();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final usercartdoc = FirebaseFirestore.instance
      .collection('user')
      .doc(FirebaseAuth.instance.currentUser.uid);
  final userproduct = FirebaseFirestore.instance
      .collection('cashier')
      .doc(FirebaseAuth.instance.currentUser.uid);
  TextEditingController _controller;
  Future<void> _alertdialog() async {
    await firestore
        .collection('cashier')
        .doc(_auth.currentUser.uid)
        .get()
        .then((value) async {
      if (value.data().isNotEmpty) {
        var usercart = firestore
            .collection('user')
            .doc(_auth.currentUser.uid)
            .collection('cart')
            .where('in stock', isEqualTo: true)
            .get();
        return showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('confirm purchase of:'),
                actions: [
                  ButtonBar(
                    children: [
                      FlatButton(
                        child: Text('no'),
                        onPressed: () {
                          Navigator.pop(context, false);
                          Fluttertoast.showToast(
                              msg: 'cancelled',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        },
                      ),
                      FlatButton(
                        child: Text('confirm'),
                        onPressed: () async {
                          Navigator.pop(context, false);

                          DocumentReference _reference = usercartdoc;

                          firestore.runTransaction((transaction) async {
                            DocumentSnapshot snapshot =
                                await transaction.get(_reference);

                            startCheckout(
                                userPhone: snapshot.data()['phone'].toString(),
                                amount: grandtotal.toString());
                          }).then((value) {
                            Fluttertoast.showToast(
                                msg: 'input pin in the mpesa prompt',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          });

                          await usercartdoc
                              .collection('cart')
                              .get()
                              .then((value) {
                            value.docs.forEach((element) async {
                              var deductthis = element.data()['quantity'];

                              print(element.data()['name'] +
                                  ' - ' +
                                  deductthis.toString());

                              DocumentReference ref = firestore
                                  .collection('items')
                                  .doc(element.data()['name']);

                              firestore.runTransaction((transaction) async {
                                DocumentSnapshot snap =
                                    await transaction.get(ref);

                                transaction.update(ref, {
                                  'quantity': snap.data()['quantity'] -=
                                      deductthis
                                });
                              });
                            });
                          });
                        },
                      )
                    ],
                  )
                ],
                // content: ListView.builder(itemBuilder: (context, index) {
                //   usercart.then((value) {
                //     value.docs.forEach((element) {});
                //   });
                // })
                content: SingleChildScrollView(
                  child: Stack(
                    children: [
                      StreamBuilder(
                          stream: firestore
                              .collection('cashier')
                              .doc(_auth.currentUser.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              DocumentSnapshot snap = snapshot.data;
                              return Stack(
                                children: [
                                  Container(
                                    child: ListBody(
                                      children:
                                          snap.data().keys.map((fieldname) {
                                        return Text(
                                            'item: ' + fieldname + '\n\n');
                                      }).toList(),
                                    ),
                                  ),
                                  Container(
                                    child: ListBody(
                                      children:
                                          snap.data().values.map((fieldValue) {
                                        return Text('\nquantity: ' +
                                            fieldValue.toString() +
                                            '\n');
                                      }).toList(),
                                    ),
                                  )
                                ],
                              );
                            }
                            return Center(child: CircularProgressIndicator());
                          }),
                      Positioned(
                          right: 1,
                          bottom: 1,
                          child:
                              Text('total: ' + grandtotal.toString() + ' ksh'))
                    ],
                  ),
                ),
              );
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference user = firestore.collection('user');

    DocumentReference cashier =
        firestore.collection('cashier').doc(_auth.currentUser.uid);
    // DocumentReference items = firestore.collection('items').doc();

    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream:
              user.doc(_auth.currentUser.uid).collection('cart').snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Container(
                  color: Colors.redAccent,
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.redAccent,
                        ),
                        Text('Something went wrong'),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              // return SplashScreen(
              //   seconds: 10,
              //   title: Text('🛒 ShopIt'),
              // );
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return Scaffold(
              floatingActionButton: FloatingActionButton(onPressed: () async {
                print('fab' + grandtotal.toString());
                await _alertdialog();
              }),
              // appBar: AppBar(
              //   actions: [
              //     GestureDetector(
              //       child: FlatButton.icon(
              //           icon: Icon(Icons.remove_shopping_cart),
              //           label: Text('clear cart'),
              //           onPressed: () async {
              //             usercartdoc.collection('cart').get().then((value) {
              //               for (DocumentSnapshot doc in value.docs) {
              //                 doc.reference.delete().then((value) {
              //                   cashier.set({});
              //                 });
              //                 Navigator.pushReplacement(
              //                     context,
              //                     MaterialPageRoute(
              //                         builder: (context) => HomePage()));
              //               }
              //             });
              //           }),
              //     )
              //   ],
              // ),
              body: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
                  itemCount: snapshot.data.docs.length,
                  // ignore: missing_return
                  itemBuilder: (context, index) {
                    DocumentSnapshot cart = snapshot.data.docs[index];

                    if (quantityselectedperitem.length <
                        snapshot.data.docs.length) {
                      quantityselectedperitem.add(0);
                    }

                    if (newpriceperitem.length < snapshot.data.docs.length) {
                      newpriceperitem.add(cart.data()['price']);
                    }

                    _incrementCounter(int index) {
                      setState(() {
                        quantityselectedperitem[index]++;
                      });
                    }

                    _decrementCounter(int index) {
                      if (quantityselectedperitem[index] <= 1) {
                        setState(() {
                          quantityselectedperitem[index] = 1;
                        });
                      } else {
                        setState(() {
                          quantityselectedperitem[index]--;
                        });
                      }
                    }

                    newpriceperitem[index] =
                        cart.data()['price'] * quantityselectedperitem[index];

                    sum = 0;

                    grandtotal = 0;

                    quantityselectedperitem.forEach((i) {
                      sum += i;
                    });

                    if (cart.data()['in stock'] == true) {}

                    newpriceperitem.forEach((i) async {
                      grandtotal += i;

                      await cashier.update({
                        cart.data()['name']: quantityselectedperitem[index]
                      });
                    });

                    if (quantityselectedperitem[index] > 0) {
                      product = cart.data()['name'];
                    }

                    firestore.runTransaction((transaction) async {
                      DocumentSnapshot snapshot =
                          await transaction.get(cashier);

                      if (!snapshot.exists) {
                        print('nothing found');
                      }

                      if (snapshot.data()[cart.data()['name']] <
                          quantityselectedperitem[index]) {
                        cashier
                            .update({cart.data()['name']: FieldValue.delete()});
                      }
                      if (snapshot.data()[cart.data()['name']] == 0) {
                        cashier
                            .update({cart.data()['name']: FieldValue.delete()});
                      }
                    });

                    if (cart.data()['in stock'] == true) {
                      return Container(
                        child: Card(
                          elevation: 4,
                          child: Stack(
                            fit: StackFit.loose,
                            alignment: Alignment.center,
                            children: [
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Container(
                                          height: 90,
                                          width: 90,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                          child: CachedNetworkImage(
                                            imageUrl: cart.data()['image'],
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    Container(
                                              height: 90,
                                              width: 90,
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
                                            placeholder: (context, url) =>
                                                Icon(Icons.fastfood),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Column(
                                          children: [
                                            Text('in cart: ' +
                                                quantityselectedperitem[index]
                                                    .toString()),
                                            Text('price: ' +
                                                newpriceperitem[index]
                                                    .toString()),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  ListTile(
                                    title: Column(
                                      children: [
                                        Text(cart.data()['name']),
                                        Text('ksh ' +
                                            cart.data()['price'].toString()),
                                        Row(
                                          children: [
                                            IconButton(
                                                icon: Icon(Icons.add_circle),
                                                onPressed: () async {
                                                  DocumentReference items =
                                                      FirebaseFirestore.instance
                                                          .collection('items')
                                                          .doc(cart
                                                              .data()['name']);

                                                  firestore.runTransaction(
                                                      (transaction) async {
                                                    DocumentSnapshot snapshot =
                                                        await transaction
                                                            .get(items);

                                                    if (!snapshot.exists) {
                                                      print('not found');
                                                    }

                                                    if (snapshot.data()[
                                                            'quantity'] <
                                                        1) {
                                                      print(
                                                          'oops!! out of stock!');
                                                    }

                                                    if ((snapshot.data()[
                                                                'quantity'] -
                                                            1) >
                                                        quantityselectedperitem[
                                                            index]) {
                                                      _incrementCounter(index);

                                                      await cashier.update({
                                                        cart.data()['name']:
                                                            quantityselectedperitem[
                                                                index],

                                                        // 'total': grandtotal
                                                      });

                                                      await firestore
                                                          .collection('user')
                                                          .doc(_auth
                                                              .currentUser.uid)
                                                          .collection('cart')
                                                          .doc(cart
                                                              .data()['name'])
                                                          .update({
                                                        'quantity':
                                                            quantityselectedperitem[
                                                                index]
                                                      });

                                                      print(grandtotal);
                                                    }
                                                  });
                                                }),
                                            IconButton(
                                                icon: Icon(Icons.remove_circle),
                                                onPressed: () async {
                                                  _decrementCounter(index);

                                                  await cashier.update({
                                                    cart.data()['name']:
                                                        quantityselectedperitem[
                                                            index],

                                                    // 'total': grandtotal
                                                  });

                                                  await firestore
                                                      .collection('user')
                                                      .doc(
                                                          _auth.currentUser.uid)
                                                      .collection('cart')
                                                      .doc(cart.data()['name'])
                                                      .update({
                                                    'quantity':
                                                        quantityselectedperitem[
                                                            index]
                                                  });

                                                  print(grandtotal);
                                                }),
                                            IconButton(
                                                icon: Icon(Icons.delete),
                                                onPressed: () async {
                                                  Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              HomePage()));

                                                  await firestore
                                                      .collection('user')
                                                      .doc(
                                                          _auth.currentUser.uid)
                                                      .collection('cart')
                                                      .doc(cart.data()['name'])
                                                      .delete();

                                                  await cashier.update({
                                                    cart.data()['name']:
                                                        FieldValue.delete(),
                                                  });
                                                })
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }

                    if (cart.data()['in stock'] == false) {
                      return Container(
                        child: Card(
                          child: Stack(
                            fit: StackFit.loose,
                            alignment: Alignment.center,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    child: CachedNetworkImage(
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        progressIndicatorBuilder: (context, url,
                                                downloadProgress) =>
                                            CircularProgressIndicator(
                                                value:
                                                    downloadProgress.progress),
                                        imageUrl: cart.data()['image']),
                                  ),
                                  Text('this item is not available'),
                                  GestureDetector(
                                    child: Text('remove product'),
                                    onTap: () async {
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  HomePage()));

                                      await firestore
                                          .collection('user')
                                          .doc(_auth.currentUser.uid)
                                          .collection('cart')
                                          .doc(cart.data()['name'])
                                          .delete();
                                      await cashier.update({
                                        cart.data()['name']:
                                            FieldValue.delete(),
                                      });
                                    },
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }
                    if (cart.data().isEmpty) {
                      return Center(
                        child: Text('nothing in cart'),
                      );
                    }
                  }),
            );
          },
        ),
      ],
    );
  }
}
