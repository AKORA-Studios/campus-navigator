// Define a custom Form widget.
import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building.dart';
import 'package:campus_navigator/painter.dart';

class RoomView extends StatefulWidget {
  const RoomView(
      {super.key,
      required this.myController,
      required this.room,
      required this.name});
  final TextEditingController myController;
  final RoomResult room;
  final String name;

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    // widget.myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.name),
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20.0),
              //minScale: 0.1,
              //maxScale: 1.6,
              child: CustomPaint(
                painter: MapPainter(roomResult: widget.room),
                size: const Size(800, 900),
              ))
        ])));
  }
}
