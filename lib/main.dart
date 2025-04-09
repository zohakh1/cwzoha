import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'YOUR_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_SENDER_ID',
      projectId: 'YOUR_PROJECT_ID',
    ),
  );
  await storeNotification(message.notification?.body ?? 'No message');
}

Future<void> storeNotification(String message) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> history = prefs.getStringList('notifications') ?? [];
  history.add(message);
  await prefs.setStringList('notifications', history);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyA2AkxEOTkZkYs8jpRO1V2FbmMT294UuIQ',
      appId: 'com.example.inclass_14',
      messagingSenderId: '72241599450',
      projectId: 'in-class-14-bd060',
    ),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_notification');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Notifications',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _token;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    initMessaging();
    loadHistory();
  }

  void initMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("FCM Token: $token");
    setState(() => _token = token);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Foreground message received");

      String type = message.data['type'] ?? 'regular';
      String body = message.notification?.body ?? 'No content';

      await storeNotification(body);
      await loadHistory();

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'main_channel',
        'Main Channel',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.high,
        color: type == 'important' ? Colors.red : Colors.blue,
      );

      NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? 'Notification',
        body,
        notificationDetails,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened from background: ${message.notification?.title}');
    });
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('notifications') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FCM Notification Demo"),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                loadHistory();
              })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SelectableText("Your FCM Token:\n$_token"),
            const SizedBox(height: 20),
            const Text("Notification History", style: TextStyle(fontSize: 18)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(_history[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
