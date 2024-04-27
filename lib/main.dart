// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:encrypt/encrypt.dart' as e;
// import 'package:encrypt/encrypt_io.dart';
import 'package:pointycastle/asymmetric/api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Firestore Cloud Function',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:
          const MyHomePage(title: 'Flutter Firebase Firestore Cloud Function'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String symmetricKeyString = "";
  String publicKey = "";
  String userId = "";
  e.IV iv = e.IV.fromLength(16);
  // List cards = List<String>.generate(4, (index) => "No $index");

  final usernameTextController = TextEditingController();
  final cardnumberTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    getPublicKey();
  }

  e.Encrypter getAESEncrypter(String symmetricKeyString) {
    e.Key symmetricKey = e.Key.fromBase64(symmetricKeyString);
    return e.Encrypter(e.AES(symmetricKey));
  }

  e.Encrypter getRSAEncrypter(String publicKey) {
    RSAAsymmetricKey rsaAsymmetricKey = e.RSAKeyParser().parse(publicKey);
    RSAPublicKey rsaPublicKey =
        RSAPublicKey(rsaAsymmetricKey.modulus!, rsaAsymmetricKey.exponent!);

    return e.Encrypter(
        e.RSA(publicKey: rsaPublicKey, encoding: e.RSAEncoding.OAEP));
  }

  Future<void> getPublicKey() async {
    HttpsCallableResult result =
        await FirebaseFunctions.instance.httpsCallable('getpublickey').call();
    publicKey = result.data;
    print("publicKey : $publicKey");
  }

  Future<void> signup() async {
    e.Key symmetricKey = e.Key.fromSecureRandom(16);
    symmetricKeyString = symmetricKey.base64;

    print("username : ${usernameTextController.text}");
    print("symmetricKey : $symmetricKeyString");

    // RSAAsymmetricKey rsaAsymmetricKey = e.RSAKeyParser().parse(publicKey);
    // RSAPublicKey rsaPublicKey =
    //     RSAPublicKey(rsaAsymmetricKey.modulus!, rsaAsymmetricKey.exponent!);

    // final encrypterRSA = e.Encrypter(
    //     e.RSA(publicKey: rsaPublicKey, encoding: e.RSAEncoding.OAEP));
    // final encrypterAES = e.Encrypter(e.AES(symmetricKey));

    final encrypterRSA = getRSAEncrypter(publicKey);
    final encrypterAES = getAESEncrypter(symmetricKeyString);

    String symmetricEncryptedData = encrypterAES
        .encrypt(usernameTextController.text, iv: iv)
        .base64; // symmetric key encrypted data

    print("symmetricEncryptedData : $symmetricEncryptedData");

    String username = encrypterRSA
        .encrypt(symmetricEncryptedData)
        .base64; // public key encrypted data
    String symmetricKeyHash = encrypterRSA
        .encrypt("${symmetricKeyString}Hash")
        .base64; // public key encrypted symmetricKeyHash

    HttpsCallableResult result =
        await FirebaseFunctions.instance.httpsCallable('adduser').call(
      {
        "username": username,
        "symmetricKeyHash": symmetricKeyHash,
      },
    );
    userId = result.data;
    print("userId : ${result.data}");
  }

  Future<void> saveCardNumber() async {
    String cardNumberText = cardnumberTextController.text;
    print("cardNumber : $cardNumberText");

    final encrypterRSA = getRSAEncrypter(publicKey);
    final encrypterAES = getAESEncrypter(symmetricKeyString);

    String symmetricEncryptedData = encrypterAES
        .encrypt(cardNumberText, iv: iv)
        .base64; // symmetric key encrypted data

    print("symmetricEncryptedCardNumber : $symmetricEncryptedData");

    String cardNumber = encrypterRSA
        .encrypt(symmetricEncryptedData)
        .base64; // public key encrypted data

    print("publicKeyEncryptedCardNumber : $cardNumber");

    HttpsCallableResult result =
        await FirebaseFunctions.instance.httpsCallable('savecardnumber').call(
      {
        "cardNumber": cardNumber,
        "userId": userId,
      },
    );
    cardnumberTextController.clear();
    print("cardId : ${result.data}");
  }

  Future<void> loadCardNumbers() async {
    final encrypterRSA = getRSAEncrypter(publicKey);

    // String symmetricEncryptedData = encrypterAES
    //     .encrypt(cardNumberText, iv: iv)
    //     .base64; // symmetric key encrypted data

    // String cardNumber = encrypterRSA
    //     .encrypt(symmetricEncryptedData)
    //     .base64; // public key encrypted data

    HttpsCallableResult result =
        await FirebaseFunctions.instance.httpsCallable('loadcardnumbers').call({
      "userId": userId,
    });

    print("Data : ${result.data}");
    // final data = jsonDecode(result.data);
    // print(data);

    String symmetricKeyHash = result.data["symmetricKey"];
    String symmetricKeyString = symmetricKeyHash.split('Hash')[0];

    final encrypterAES = getAESEncrypter(symmetricKeyString);
    List<dynamic> cards = result.data["cardsArray"];

    print("symmetricKeyHash : $symmetricKeyHash");
    for (var i = 0; i < cards.length; i++) {
      print("card ${i + 1} : ${cards[i]}");

      String cardDecrypted = encrypterAES.decrypt(e.Encrypted.from64(cards[i]),
          iv: iv); // symmetric key encrypted data
      print("card ${i + 1} : $cardDecrypted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: usernameTextController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Enter username',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(80, 40)),
                        child: const Text("Sign Up"),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextFormField(
                    controller: cardnumberTextController,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter your card number',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: saveCardNumber,
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(80, 40)),
                        child: const Text("Save"),
                      ),
                      ElevatedButton(
                        onPressed: loadCardNumbers,
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(80, 40)),
                        child: const Text("Load"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ListView.builder(
          //     itemCount: cards.length,
          //     itemBuilder: (context, index) {
          //       String card = cards[index];
          //       return ListTile(
          //         title: Text("No $index"),
          //         subtitle: Text(card),
          //       );
          //     }),
        ],
      ),
    );
  }
}
