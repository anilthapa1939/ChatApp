import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:newChat/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class login extends StatefulWidget {
  @override
  _loginState createState() => _loginState();
}

class _loginState extends State<login> {
  bool pageinitialize = true;
  final googleSignIn = GoogleSignIn();
  final firebaseAuth = FirebaseAuth.instance;
  @override
  void initState() {
    ifUserIsLoggedIn();
    super.initState();
  }

  ifUserIsLoggedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    bool userLoggedIn = (sharedPreferences.getString('id') ?? '').isNotEmpty;
    if (userLoggedIn) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Home(),
      ));
    } else {
      setState(() {
        pageinitialize = true;
      });
    }
  }

  handleSignIn() async {
    final res = await googleSignIn.signIn();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final auth = await res.authentication;
    final credentials = GoogleAuthProvider.getCredential(
        idToken: auth.idToken, accessToken: auth.accessToken);
    final firebaseuser =
        (await firebaseAuth.signInWithCredential(credentials)).user;

    if (firebaseuser != null) {
      final result = (await Firestore.instance
              .collection('users')
              .where('id', isEqualTo: firebaseuser.uid)
              .getDocuments())
          .documents;
      if (result.length == 0) {
        Firestore.instance
            .collection('users')
            .document(firebaseuser.uid)
            .setData({
          "name": firebaseuser.displayName,
          "id": firebaseuser.uid,
          "profile_pic": firebaseuser.photoUrl,
          "created_at": DateTime.now().millisecondsSinceEpoch,
        });
        sharedPreferences.setString("id", firebaseuser.uid);
        sharedPreferences.setString("name", firebaseuser.displayName);
        sharedPreferences.setString("profile_pic", firebaseuser.photoUrl);

        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => Home(),
        ));
      } else {
        sharedPreferences.setString("id", result[0]["id"]);
        sharedPreferences.setString("name", result[0]["name"]);
        sharedPreferences.setString("profile_pic", result[0]["profile_pic"]);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => Home(),
        ));
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login page'),
      ),
      body: (pageinitialize)
          ? Center(
              child: RaisedButton(
                child: Text("Sign In"),
                onPressed: handleSignIn,
              ),
            )
          : Center(
              child: SizedBox(
                height: 36,
                width: 36,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
    );
  }
}
