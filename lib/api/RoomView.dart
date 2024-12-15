// Define a custom Form widget.
import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:campus_navigator/painter.dart';

class RoomView extends StatefulWidget {
  const RoomView({super.key, required this.myController, required this.room});
  final TextEditingController myController;
  final RoomResult room;

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    widget.myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Home"),
        ),
        body:SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            children: <Widget>[
              CustomPaint(
                size: const Size(300, 300),
                painter: MapPainter(roomResult: widget.room),
              ),
              Text('eeee'),
            ],
          ),
        ],
      ),
    ));
  }
}
