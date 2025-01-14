import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'painter.dart';

Widget interactiveFloorView(BuildingPageData roomResult, BuildContext context,
    {Size size = const Size(300, 300)}) {
  final painter = MapPainter(roomResult: roomResult, context: context);
  void down(PointerDownEvent evt) {
    painter.mousePos = evt.localPosition;
  }

  return InteractiveViewer(
      // How much empty space there is until the user cant scroll out even further
      boundaryMargin: const EdgeInsets.all(300.0),
      minScale: 0.001,
      maxScale: 16.0,
      child: Listener(
          onPointerDown: down,
          child: CustomPaint(painter: painter, size: size)));
}

Widget asyncFloorView(Future<BuildingPageData> roomResult,
    {Size size = const Size(300, 300)}) {
  return FutureBuilder<BuildingPageData>(
    future: roomResult,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return interactiveFloorView(
          snapshot.data!,
          context,
          size: size,
        );
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
