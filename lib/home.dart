import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newChat/ChatScreen.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GoogleSignIn googleSignIn = new GoogleSignIn();
  String UserId;
  @override
  void initState() {
    getUserId();
    super.initState();
  }

  getUserId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    UserId = sharedPreferences.getString("id");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          RaisedButton(
              child: Text("Logout"),
              onPressed: () async {
                await googleSignIn.signOut();
                Navigator.of(context).pop();
              })
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.hasData != null) {
            return ListView.builder(
              itemBuilder: (listContext, index) =>
                  buildItem(snapshot.data.documents[index]),
              itemCount: snapshot.data.documents.length,
            );
          }
          return Container();
        },
      ),
    );
  }

  buildItem(doc) {
    return (UserId != doc['id']
        ? GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(docs: doc),
                  ));
            },
            child: Card(
              color: Colors.blue,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  child: Center(
                    child: Text(doc["name"]),
                  ),
                ),
              ),
            ),
          )
        : Container());
  }
}
