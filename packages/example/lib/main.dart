import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

void main() {
  runApp(const CodeGenExample());
}

class CodeGenExample extends StatelessWidget {
  const CodeGenExample({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ProfileModel profile = ProfileModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        title: Text(
          'Profile',
          style: TextStyle(
              fontSize: 44,
              color: Colors.green[100],
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(100)),
              child: Center(
                  child: Text(
                'Das ist ein ewig langer Text der nervt. Er geht sogar über mehrere Zeilen. Wenn das funktioniert, freue ich mich sehr.'
                    .tr,
                style: TextStyle(
                    fontSize: 72,
                    color: Colors.green[100],
                    fontWeight: FontWeight.bold),
              )),
            ),
            const SizedBox(
              height: 50,
            ),
            Text('Ich habe h\n,unger'.tr),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String get tr => '';
}
