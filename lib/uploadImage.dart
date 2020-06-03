import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

FirebaseUser loggedInUser;

class ImageUpload extends StatefulWidget {
  @override
  _ImageUploadState createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  File sampleImage;
  bool imagepicked = false;

  final _fireStore = Firestore.instance;
  final store = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  initState() {
    super.initState();
    getCurrentUser();
  }

  Future getimagefromgallery() async {
    var tempImage = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      sampleImage = tempImage;
      imagepicked = true;
    });
  }

  Future getimagefromcamera() async {
    var tempImage = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      sampleImage = tempImage;
      imagepicked = true;
    });
  }

  void displaySuccessBox(context, title, text) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            contentPadding: EdgeInsets.only(top: 10.0),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green),
                ),
                SizedBox(
                  width: 7,
                ),
                Icon(
                  Icons.check,
                  size: 25,
                  color: Colors.green,
                )
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                heightFactor: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      );
  bool isSpinner = false;
  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: isSpinner,
      child: Scaffold(
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            imagepicked
                ? Image.file(
                    sampleImage,
                    height: 300,
                    width: 300,
                  )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
              crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 50,),
                        GestureDetector(
                            child: Container(
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.camera,size: 50, color: Colors.blue,),
                                    Text(
                                      'Click with camera',
                                      style: TextStyle(fontSize: 20, color: Colors.black),
                                    ),
                                  ],
                                )),
                            onTap: getimagefromcamera
                          ),
                        SizedBox(height: 50,),
                        GestureDetector(
                            child: Container(
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.photo_library,size: 50, color: Colors.green,),
                                    Text(
                                      'Pick from gallery',
                                      style: TextStyle(fontSize: 20, color: Colors.black),
                                    ),
                                  ],
                                )),
                            onTap: getimagefromgallery
                        ),
                      ],
                    ),
                  ],
                ),
            SizedBox(
              height: 70,
            ),
            imagepicked
                ? GestureDetector(
                    onTap: () async {
                      setState(() {
                        isSpinner = true;
                      });
                      var name = DateTime.now();
                      final StorageReference firebaseStorageRef =
                          store.ref().child('$name');
                      final StorageUploadTask task =
                          await firebaseStorageRef.putFile(sampleImage);
                      StorageTaskSnapshot taskSnapshot = await task.onComplete;
                      String url = await taskSnapshot.ref.getDownloadURL();
                      url = url.replaceAll('//', '~');
                      print(url);
                      var response = _fireStore
                          .collection('urls')
                          .document("$name")
                          .setData({
                        'url': url,
                        'sender': loggedInUser.email,
                        'likes': 0
                      });
                      print(response.hashCode);
                      setState(() {
                        isSpinner = false;
                      });
                      print(url);
                      Navigator.pop(context);
                      displaySuccessBox(
                          context, 'Successful', 'Your image is uploaded');
                    },
                    child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 32.0, right: 32, top: 12, bottom: 12),
                          child: Text(
                            'Upload',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        )),
                  )
                : Container()
          ],
        )),
      ),
    );
  }
}
