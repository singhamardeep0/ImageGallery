import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imagegallery/uploadImage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, bool> likes = {};

class Gallery extends StatefulWidget {
  @override
  _GalleryState createState() => _GalleryState();
}


class _GalleryState extends State<Gallery> {

  List<bool> liked = [];
  final _fireStore = Firestore.instance;
  final _auth = FirebaseAuth.instance;
  var storage = FlutterSecureStorage();
  
  Widget PhotoCard(sender , url , like, doc) {
    url = url.replaceAll('~','//');
    print(url);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25)
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(width: 10,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.person,size: 30,color: Colors.blue,),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(sender,style: TextStyle(
                  color: Colors.black,
                  fontSize: 17
                ),),
              ),
            ],
          ),
          SizedBox(height: 5,),
          Container(
            height: 250,
              width: double.infinity,
              child: Image.network(url, fit: BoxFit.cover,
                loadingBuilder:( context, Widget child,ImageChunkEvent loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null ?
                      loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
                          : null,
                    ),
                  );
                },
              )),
          SizedBox(height: 15,),
          Row(
            children: <Widget>[
              SizedBox(width: 25,),
              likes[doc] == true ?GestureDetector(
                child: Icon(Icons.favorite,size: 30, color: Colors.red,),
                onTap: () async {
                  like  = like - 1;
                  var response = _fireStore.collection('urls').document(doc).updateData({'url': url, 'sender': sender, 'likes': like});
                  setState(() async {
                    var val = false;
                    likes.update(doc, (bool) => val);
                    var res = await storage.write(key: doc, value: 'false');
                  });
                },
              ) : GestureDetector(
                child: Icon(Icons.favorite_border,size: 30,),
                onTap: () async {
                  like  = like + 1;
                  var response = _fireStore.collection('urls').document(doc).updateData({'url': url, 'sender': sender, 'likes': like});
                  setState(()async {
                    var val = true;
                    likes.update(doc, (bool)=> val);
                    var res = await storage.write(key: doc, value: 'true');
                  });
                },
              ),
              Expanded(
                child: SizedBox(
                  width: 5000,
                ),
              ),
              Text('$like Likes',style: TextStyle(
                fontSize: 19
              ),),
              SizedBox(width: 25,)
            ],
          ),
          SizedBox(height: 10,)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Gallery'),
      ),
      body: Center(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              StreamBuilder<QuerySnapshot>(
                stream: _fireStore.collection('urls').snapshots(),
                builder: (context, snapshot) {
                  var doc = snapshot.data;
                  final messages = snapshot.data.documents.reversed;
                  List<Widget> wid = [];

                  for (var message in messages) {
                    final doc = message.documentID;
                    var isliked = storage.read(key: doc);
                    bool val;
                    if(isliked == 'true')
                      val = true;
                    else
                      val = false;
                    likes.putIfAbsent(doc, () => val);

                    final url = message.data['url'];
                    final msender = message.data['sender'];
                    final like = message.data['likes'];
                    final mw = PhotoCard( msender, url, like, doc
                    );
                    wid.add(mw);
                  }
                  return Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(10.0),
                      children: wid,
                    ),
                  );
                },
              ),
            ],
          ),
        )
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> ImageUpload()));
        },
        label: Text('Upload Image',style: TextStyle(fontSize: 15),),
      ),
    );
  }
}
