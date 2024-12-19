import 'package:campus_navigator/api/building/room_page.dart';
import 'package:campus_navigator/painter.dart';
import 'package:flutter/material.dart';

Widget interactiveBuildingView(RoomPage roomResult,
    {Size size = const Size(300, 300)}) {
  return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(34.0),
      minScale: 0.001,
      maxScale: 16.0,
      child:
          CustomPaint(painter: MapPainter(roomResult: roomResult), size: size));
}

Widget asyncInteractiveBuildingView(Future<RoomPage> roomResult,
    {Size size = const Size(300, 300)}) {
  return FutureBuilder<RoomPage>(
    future: roomResult,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return interactiveBuildingView(snapshot.data!, size: size);
      } else if (snapshot.hasError) {
        return Text('${snapshot.error}');
      }
      return const SizedBox.shrink();
    },
  );
}

extension SmallestSquare on Size {
  /// Returns the Size that has `shortestSide` as its width and length
  Size smallestSquare() {
    return Size(shortestSide, shortestSide);
  }
}
