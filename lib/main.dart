import 'dart:math';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_festival_emojis/firebase_options.dart';

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
        // TODO: switch between EmotionsPage (the app that users post emotions)
        // and CameraApp() (the app you use to view the emotions posted)
        home: CameraApp(), // EmotionsPage
      )
  ));
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> with TickerProviderStateMixin {
  CameraController? controller;
  List<EmojiWidget> stackWidgets = [];

  @override
  void initState() {
    super.initState();

    controller = CameraController(cameras![1], ResolutionPreset.max);
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

            if (emojis.addedWidgets.isNotEmpty) {
              emojis.addedWidgets.removeAt(0);
            }
          });

          var xPos = random.nextInt(4) + 1;
          var positionedWidget = Positioned(
            top: MediaQuery.of(context).size.height + 100, 
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(xPos.toDouble(), 0.0),
                end: Offset(xPos.toDouble(), -13.0)
              ).animate(CurvedAnimation(parent: animController, curve: Curves.easeInOut)),
              child: EmojiWidget(
                id: docId,
                value: value,
                timeStamp: timeStamp,
              )
            ),
          );

          emojis.addedWidget(positionedWidget);
        }
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(controller!)),
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
                children: service.addedWidgets,
              );
            }
          ),
        ],
      )
    );
  }
}

class EmotionsPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    AddedEmojis emojisService = Provider.of<AddedEmojis>(context, listen: false);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Center(
              child: Image.asset('assets/imgs/header.png'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(crossAxisCount: 3,
                children: List.generate(Utils.emojis.length, (index) {
                  return SizedBox(
                    width: 20,
                    height: 20,
                    child: ClipOval(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.grey.withOpacity(0.1),
                          highlightColor: Colors.grey.withOpacity(0.1),
                          onTap: () {
                            emojisService.sendEmotion(Utils.emojis[index]);
                          },
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            height: 20,
                            child: Image.asset('assets/imgs/ffemoji_' + Utils.emojis[index] + '.png',
                              width: 20, height: 20,
                              fit: BoxFit.contain
                            )
                          ),
                        )
                      ),
                    ),
                  );
                })
              ),
            ),
            Center(
              child: Image.asset('assets/imgs/builtwith.png',
                width: MediaQuery.of(context).size.width - 200
              ),
            )
          ],
        ),
      ),
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

  List<Widget> addedWidgets = [];

  void addedWidget(Widget w) {
    addedWidgets.add(w);
    notifyListeners();
  }

  void removeWidget(Widget w) {
    removeWidget(w);
    notifyListeners();
  }

  void triggerWidget() {
    var random = Random();
    var val = random.nextInt(Utils.emojis.length);
    var emoji = Utils.emojis[val];
    FirebaseFirestore.instance.collection('flutter-festival-emotions').add({
      'emoji': emoji,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }

  void sendEmotion(String emotion) {
    FirebaseFirestore.instance.collection('flutter-festival-emotions').add({
      'emoji': emotion,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }
}

class Utils {

  static List<String> emojis = ['celebrate','clap','dash','flutter','heart','lol', 'sad', 'smile','surprise','thumb'];
}