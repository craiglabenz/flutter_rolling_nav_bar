import 'package:flutter/material.dart';

import 'package:rolling_nav_bar/rolling_nav_bar.dart';

class StatefulTestWidget extends StatefulWidget {
  final Function(int)? onTap;
  StatefulTestWidget([this.onTap]);

  @override
  _StatefulTestWidget createState() => _StatefulTestWidget();
}

class _StatefulTestWidget extends State<StatefulTestWidget> {
  int activeIndex = 0;

  _onTap(int index) {
    setState(() {
      activeIndex = index;
    });
  }

  _forceNewIndex(int index) {
    setState(() {
      activeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('Active Index: $activeIndex', key: Key('activeIndexLabel')),
      bottomNavigationBar: Container(
        child: RollingNavBar.iconData(
          activeIndex: activeIndex,
          iconData: <IconData>[Icons.home, Icons.person, Icons.settings],
          iconText: <Widget>[Text('Home'), Text('Friends'), Text('Settings')],
          indicatorColors: <Color>[Colors.orange],
          onTap: (int index) {
            _onTap(index);
            if (widget.onTap != null) {
              widget.onTap!(index);
            }
          },
        ),
        height: 100,
        width: 400,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        key: Key('FAB'),
        onPressed: () {
          _forceNewIndex(activeIndex + 1);
          setState(() {});
        },
      ),
    );
  }
}
