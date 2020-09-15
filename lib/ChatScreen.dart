import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'fullimage.dart';

class ChatPage extends StatefulWidget {
  final docs;
  const ChatPage({Key key, this.docs}) : super(key: key);
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String groupChatId;
  String userId;
  File _image;
  String downloadUrl;
  String dltmsg = "this message was deleted";
  var uuid = Uuid();
  TextEditingController msgComposeController = TextEditingController();
  ScrollController scrollController = ScrollController();
  StorageReference storageReference = FirebaseStorage.instance.ref();

  @override
  void dispose() {
    msgComposeController.dispose();
    super.dispose();
  }

  void initState() {
    getGroupChatId();
    super.initState();
  }

  void _getImage() async {
    _image = File(await ImagePicker()
        .getImage(source: ImageSource.camera)
        .then((pickedFile) => pickedFile.path));
    StorageReference sref = storageReference.child("chats/").child(uuid.v4());
    StorageUploadTask storageUploadTask = sref.child("chats/").putFile(_image);

    if (storageUploadTask.isSuccessful || storageUploadTask.isComplete) {
      final String url = await sref.getDownloadURL();
      print("The download URL is " + url);
    } else if (storageUploadTask.isInProgress) {
      storageUploadTask.events.listen((event) {
        double percentage = 100 *
            (event.snapshot.bytesTransferred.toDouble() /
                event.snapshot.totalByteCount.toDouble());
        print("THe percentage " + percentage.toString());
      });

      StorageTaskSnapshot storageTaskSnapshot =
          await storageUploadTask.onComplete;
      downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();

      print("Download URL " + downloadUrl.toString());
    } else {
      print("Enter A valid Image");
    }
    uploadtoFiretsore();
  }

  void _getImagegallery() async {
    _image = File(await ImagePicker()
        .getImage(source: ImageSource.gallery)
        .then((pickedFile) => pickedFile.path));
    StorageReference sref = storageReference.child("chats/").child(uuid.v4());
    StorageUploadTask storageUploadTask = sref.child("chats/").putFile(_image);

    if (storageUploadTask.isSuccessful || storageUploadTask.isComplete) {
      final String url = await sref.getDownloadURL();
      print("The download URL is " + url);
    } else if (storageUploadTask.isInProgress) {
      storageUploadTask.events.listen((event) {
        double percentage = 100 *
            (event.snapshot.bytesTransferred.toDouble() /
                event.snapshot.totalByteCount.toDouble());
        print("THe percentage " + percentage.toString());
      });

      StorageTaskSnapshot storageTaskSnapshot =
          await storageUploadTask.onComplete;
      downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();

      print("Download URL " + downloadUrl.toString());
    } else {
      print("Enter A valid Image");
    }
    uploadtoFiretsore();
  }

  getGroupChatId() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    userId = sharedPreferences.getString('id');
    String anotherUserId = widget.docs['id'];
    if (userId.compareTo(anotherUserId) > 0) {
      groupChatId = '$userId ~ $anotherUserId';
    } else {
      groupChatId = '$anotherUserId ~ $userId';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        backgroundColor: Colors.green,
        title: Text("Chat"),
        actions: [
          Icon(
            Icons.video_call,
            size: 30.0,
          ),
          SizedBox(
            width: 25.0,
          ),
          Icon(
            Icons.call,
            size: 30.0,
          ),
          SizedBox(
            width: 25.0,
          ),
          Icon(Icons.more_vert),
        ],
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('messages')
            .document(groupChatId)
            .collection(groupChatId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              color: Colors.lightGreen[50],
              child: Column(
                children: [
                  Expanded(
                      child: ListView.builder(
                          controller: scrollController,
                          itemCount: snapshot.data.documents.length,
                          reverse: true,
                          itemBuilder: (listcontext, index) {
                            final list = snapshot.data.documents;
                            return GestureDetector(
                              onLongPress: () {
                                if (snapshot.data.documents[index]
                                        ["senderId"] ==
                                    userId) {
                                  showMenu(
                                    position: RelativeRect.fromLTRB(
                                        100, 600, 150, 400),
                                    items: <PopupMenuEntry>[
                                      PopupMenuItem(
                                        child: Row(
                                          children: [
                                            MaterialButton(
                                              onPressed: () async {
                                                String dltmsg =
                                                    "this message was deleted";
                                                await Firestore.instance
                                                    .runTransaction((Transaction
                                                        myTransaction) async {
                                                  if (snapshot.data
                                                              .documents[index]
                                                          ["type"] ==
                                                      "text") {
                                                    await myTransaction.update(
                                                        snapshot
                                                            .data
                                                            .documents[index]
                                                            .reference,
                                                        {
                                                          "content": dltmsg,
                                                        });
                                                  } else {
                                                    await myTransaction.update(
                                                        snapshot
                                                            .data
                                                            .documents[index]
                                                            .reference,
                                                        {
                                                          "mediaUrl": dltmsg,
                                                        });
                                                  }
                                                });
                                              },
                                              child: Text(
                                                  "Delete messsage For Everyone "),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                    context: context,
                                  );
                                }
                              },
                              child: buildItem(snapshot.data.documents[index]),
                            );
                          }
                          // },
                          )),
                  SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0, right: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20.0),
                                    topRight: Radius.circular(20.0),
                                    bottomLeft: Radius.circular(20.0),
                                    bottomRight: Radius.circular(20.0))),
                            child: Row(
                              children: <Widget>[
                                SizedBox(width: 8.0),
                                IconButton(
                                  icon: Icon(Icons.camera_alt,
                                      size: 30.0, color: Colors.black),
                                  onPressed: () {
                                    _getImage();
                                  },
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: TextField(
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontStyle: FontStyle.italic),
                                    controller: msgComposeController,
                                    decoration: InputDecoration(
                                      hintText: 'Type your Message',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _getImagegallery();
                                  },
                                  icon: Icon(
                                    Icons.image,
                                    color: Colors.blue,
                                    size: 30.0,
                                  ),
                                ),
                                SizedBox(width: 8.0),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 8.0,
                        ),
                        GestureDetector(
                          onTap: () {
                            sendmsg();
                          },
                          child: CircleAvatar(
                            child: Icon(Icons.send),
                            backgroundColor: Colors.green[200],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: SizedBox(
                height: 36.0,
                width: 36,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  uploadtoFiretsore() async {
    var ref = Firestore.instance
        .collection('messages')
        .document(groupChatId)
        .collection(groupChatId)
        .document(DateTime.now().millisecondsSinceEpoch.toString());

    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(ref, {
        "senderId": userId,
        "anotherUserId": widget.docs['id'],
        "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
        "content": '',
        "mediaUrl": downloadUrl.toString(),
        "type": 'Image',
      });
    });
    scrollController.animateTo(0.0,
        duration: Duration(milliseconds: 100), curve: Curves.bounceInOut);
  }

  sendmsg() {
    String msg = msgComposeController.text.trim();
    if (msg.isNotEmpty) {
      var ref = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());
      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(ref, {
          "senderId": userId,
          "anotherUserId": widget.docs['id'],
          "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "content": msg,
          "mediaUrl": '',
          "type": 'text',
        });
      });
      msgComposeController.clear();
      scrollController.animateTo(0.0,
          duration: Duration(milliseconds: 100), curve: Curves.bounceInOut);
    } else {
      print("Enter Some Text To print");
    }
  }

  buildItem(doc) {
    var date =
        new DateTime.fromMillisecondsSinceEpoch(int.parse(doc["timestamp"]));
    DateTime now = date;
    String time = DateFormat.jm().format(now);
    return Container(
      child: Padding(
          padding: EdgeInsets.only(
            top: 8.0,
            left: ((doc['senderId']) == userId) ? 160 : 10,
            right: ((doc['senderId']) == userId) ? 10 : 160,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width - 84,
            decoration: BoxDecoration(
              color: ((doc['senderId'] == userId)
                  ? Colors.green[100]
                  : Colors.yellow[50]),
              borderRadius: (((doc['senderId'] == userId)
                  ? BorderRadius.only(
                      topLeft: Radius.circular(5.0),
                      bottomRight: Radius.circular(5.0),
                      topRight: Radius.circular(5.0))
                  : BorderRadius.only(
                      topLeft: Radius.circular(5.0),
                      bottomRight: Radius.circular(5.0),
                      topRight: Radius.circular(5.0)))),
            ),
            child: Container(
              child: Column(
                children: [
                  SizedBox(
                    height: 5.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 15.0, top: 5.0, right: 5.0, bottom: 5.0),
                    child: Row(
                      children: [
                        (doc["type"] == "text")
                            ? Flexible(
                                child: Text(
                                  ('${doc['content']}'),
                                  maxLines: 50,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 15.0),
                                ),
                              )
                            : (doc['mediaUrl'] == dltmsg)
                                ? Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(
                                        width: 8.0,
                                      ),
                                      Text(
                                        ('${doc['mediaUrl']}'),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15.0),
                                      ),
                                    ],
                                  )
                                : GestureDetector(
                                    child: Image.network('${doc['mediaUrl']}',
                                        height: 250.0,
                                        width: 220.0,
                                        fit: BoxFit.cover),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FullImagePageRoute(
                                                      doc['mediaUrl'])));
                                    },
                                  ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: ((doc['senderId'] == userId)
                            ? const EdgeInsets.only(left: 170.0)
                            : const EdgeInsets.only(left: 170.0)),
                        child: Row(
                          children: [
                            Text(
                              time,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
