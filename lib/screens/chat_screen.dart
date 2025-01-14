import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class ChatScreen extends StatefulWidget {
  static String id = "ChatScreen";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isLoading = false;
  String message;
  List<Map<String, dynamic>> messages;
  final messageTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(icon: Icon(Icons.logout), onPressed: onLogoutPressed),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MessageList(),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          message = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                        controller: messageTextController,
                      ),
                    ),
                    FlatButton(
                      onPressed: onSendPressed,
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  onLogoutPressed() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  onSendPressed() {
    messageTextController.clear();
    FirebaseFirestore.instance.collection("messages").add({
      "text": message,
      "sender": FirebaseAuth.instance.currentUser.email,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });
  }
}

class MessageList extends StatelessWidget {
  const MessageList({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("messages")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) => Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  reverse: true,
                  children: snapshot.data.docs
                      .map((e) => Message(
                            text: e.data()["text"],
                            sender: e.data()["sender"],
                          ))
                      .toList(),
                ),
              ),
            ));
  }
}

class Message extends StatelessWidget {
  final String text;
  final String sender;

  const Message({this.text, this.sender});

  @override
  Widget build(BuildContext context) {
    bool isMine = FirebaseAuth.instance.currentUser.email == sender;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: !isMine,
            child: Text(
              sender,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(
            height: 4,
          ),
          Material(
            color: isMine ? Colors.lightBlueAccent : Colors.blueAccent,
            borderRadius: isMine
                ? BorderRadius.all(Radius.circular(20))
                : BorderRadius.all(Radius.circular(20))
                    .copyWith(topLeft: Radius.zero),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
