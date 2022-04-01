import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:camera_web/camera_web.dart';
import 'package:collection/collection.dart';
import 'package:camera/camera.dart';
import 'package:flutter_festival_emojis/firebase_options.dart';
import 'package:provider/provider.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  cameras = await availableCameras();
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AddedEmojis(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CameraApp(),
      )
  ));
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> with TickerProviderStateMixin {
  CameraController? controller;

  @override
  void initState() {
    super.initState();

    controller = CameraController(cameras![2], ResolutionPreset.max);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller!.value.isInitialized) {
      return Container();
    }

    FirebaseFirestore.instance.collection('flutter-festival-emotions').orderBy('timestamp', descending: false)
    .limitToLast(1).snapshots().listen((snapshot) {
      AddedEmojis emojis = Provider.of<AddedEmojis>(context, listen: false);

        var value = 'flutter';
        var timeStamp = 0;
        var docId = '';

        var random = Random();
        for (var d in snapshot.docs) {
          var data = d.data();
          docId = d.id;
          value = data['emoji'];
          timeStamp = data['timestamp'];

          var animController = AnimationController(vsync: this,
            duration: Duration(seconds: (random.nextInt(5) + 2))
          )..forward().then((value) {
            // var sw = emojis.addedWidgets.keys.firstWhereOrNull((EmojiWidget e) => e.id == docId);
            // if (sw != null) {
            //   sw.ctrl!.dispose();
            //   emojis.removeWidget(sw);
            // }
          });

          var xPos = random.nextInt(4) + 1;
          var emojiWidget = EmojiWidget(
            id: docId,
            value: value,
            timeStamp: timeStamp,
          );
          var positionedWidget = Positioned(
            top: MediaQuery.of(context).size.height + 100, 
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(xPos.toDouble(), 0.0),
                end: Offset(xPos.toDouble(), -11.0)
              ).animate(CurvedAnimation(parent: animController, curve: Curves.easeInOut)),
              child: emojiWidget
            ),
          );

          
          emojis.addedWidget(positionedWidget, emojiWidget);
        }
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(controller!)),
          Container(
            margin: const EdgeInsets.only(top: 50),
            child: Image.asset(
              './assets/imgs/ffheader.png',
              width: 400
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(30),
              child: Image.asset(
                './assets/imgs/ffqrcode.png',
                width: 150
              ),
            ),
          ),
          Consumer<AddedEmojis>(
            builder: (context, service, child) {
              return Stack(
                children: service.addedWidgets.values.toList(),
              );
            }
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () {
                AddedEmojis addedEmojis = Provider.of<AddedEmojis>(context, listen: false);
                addedEmojis.triggerWidget();
              },
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                child: Text('Click'),
                color: Colors.white
              ),
            ),
          )
        ],
      )
    );
  }
}

class EmojiWidget extends StatelessWidget {

  final String? value;
  final int? timeStamp;
  final String? id;
  final AnimationController? ctrl;

  const EmojiWidget({ Key? key, this.id, this.value, this.timeStamp, this.ctrl }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/imgs/ffemoji_' + value! + '.png',
      width: 100,
      height: 100
    );
  }
}

class AddedEmojis extends ChangeNotifier {

  //List<Widget> addedWidgets = [];
  Map<EmojiWidget, Widget> addedWidgets = {};

  void addedWidget(Widget w, EmojiWidget emojiWidget) {
    addedWidgets[emojiWidget] = w;
  }

  void removeWidget(EmojiWidget w) {
    addedWidgets.remove(w);
    notifyListeners();
  }

  void triggerWidget() {
    var emojis = ['celebrate','clap','dash','flutter','heart','lol', 'sad', 'smile','surprise','thumb'];
    var random = Random();
    var val = random.nextInt(emojis.length);
    var emoji = emojis[val];
    FirebaseFirestore.instance.collection('flutter-festival-emotions').add({
      'emoji': emoji,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }
}