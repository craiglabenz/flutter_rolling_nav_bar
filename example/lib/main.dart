import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:polygon_clipper/polygon_clipper.dart';
import 'package:rolling_nav_bar/rolling_nav_bar.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color logoColor;

  @override
  void initState() {
    logoColor = Colors.red[600];
    super.initState();
  }

  _onAnimate(AnimationUpdate update) {
    setState(() {
      logoColor = update.color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.blue[100],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Rolling Nav Bar'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return Stack(
              children: <Widget>[
                Positioned(
                  top: 100,
                  height: 414,
                  width: MediaQuery.of(context).size.width,
                  child: ClipPolygon(
                    sides: 6,
                    borderRadius: 15,
                    child: Container(
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      color: logoColor,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 140, 30, 0),
                          child: Transform(
                            transform: Matrix4.skew(0.1, -0.55),
                            child: Text(
                              'Rolling\nNav Bar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 70,
                                fontFeatures: <FontFeature>[
                                  FontFeature.enable('smcp')
                                ],
                                shadows: <Shadow>[
                                  Shadow(
                                    offset: Offset(5, 5),
                                    blurRadius: 3.0,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                  Shadow(
                                    offset: Offset(5, 5),
                                    blurRadius: 8.0,
                                    color: Color.fromARGB(125, 0, 0, 255),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  height: 95,
                  width: MediaQuery.of(context).size.width,
                  // Option 1: Recommended
                  child: RollingNavBar.iconData(
                    animationCurve: Curves.linear,
                    animationType: AnimationType.roll,
                    baseAnimationSpeed: 200,
                    iconData: <IconData>[
                      Icons.home,
                      Icons.people,
                      Icons.account_circle,
                      Icons.chat,
                      Icons.settings,
                    ],
                    iconColors: <Color>[Colors.grey[800]],
                    iconText: <Widget>[
                      Text('Home',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Friends',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Account',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Chat',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Settings',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    indicatorColors: <Color>[
                      Colors.red,
                      Colors.orange,
                      Colors.green,
                      Colors.blue,
                      Colors.purple,
                    ],
                    iconSize: 25,
                    indicatorRadius: 30,
                    onAnimate: _onAnimate,
                  ),

                  // Option 2: More work, but there if you need it
                  // child: RollingNavBar.children(
                  //   children: <Widget>[
                  //     Text('1', style: TextStyle(color: Colors.grey)),
                  //     Text('2', style: TextStyle(color: Colors.grey)),
                  //     Text('3', style: TextStyle(color: Colors.grey)),
                  //   ],
                  // ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
