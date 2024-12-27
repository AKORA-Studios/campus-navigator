import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/painter.dart';
import 'package:flutter/material.dart';

Widget interactiveBuildingView(BuildingPageData roomResult,
    {Size size = const Size(300, 300)}) {
  return InteractiveViewer(
      // How much empty space there is until the user cant scroll out even further
      boundaryMargin: const EdgeInsets.all(300.0),
      minScale: 0.001,
      maxScale: 16.0,
      child:
          CustomPaint(painter: MapPainter(roomResult: roomResult), size: size));
}

Widget asyncInteractiveBuildingView(Future<BuildingPageData> roomResult,
    {Size size = const Size(300, 300)}) {
  return FutureBuilder<BuildingPageData>(
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
