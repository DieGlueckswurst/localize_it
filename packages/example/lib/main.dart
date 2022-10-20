// import 'package:flutter/material.dart';
// import 'profile_model.dart';

// void main() {
//   runApp(const CodeGenExample());
// }

// class CodeGenExample extends StatelessWidget {
//   const CodeGenExample({Key key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: ProfilePage(),
//     );
//   }
// }

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({Key key}) : super(key: key);

//   @override
//   _ProfilePageState createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   ProfileModel profile = ProfileModel();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.green[600],
//         title: Text(
//           'Profile',
//           style: TextStyle(
//               fontSize: 44,
//               color: Colors.green[100],
//               fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               height: 150,
//               width: 150,
//               decoration: BoxDecoration(
//                   color: Colors.blueGrey[50],
//                   borderRadius: BorderRadius.circular(100)),
//               child: Center(
//                   child: Text(
//                 profile.name.substring(0, 1),
//                 style: TextStyle(
//                     fontSize: 72,
//                     color: Colors.green[100],
//                     fontWeight: FontWeight.bold),
//               )),
//             ),
//             const SizedBox(
//               height: 50,
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 for (String key in profile.variables.keys.toList())
//                   RichText(
//                     text: TextSpan(children: [
//                       TextSpan(
//                         text: '$key: '.toUpperCase(),
//                         style: TextStyle(
//                           fontSize: 24,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       TextSpan(
//                         text: '${profile.variables[key]}',
//                         style: TextStyle(
//                           fontSize: 36,
//                           color: Colors.green[200],
//                           fontWeight: FontWeight.bold,
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ]),
//                   )
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
