import 'dart:convert';
import 'package:campus_navigator/api/building/building_page_data.dart';

// Hand-written geometry/identities. No TU original plan/data is distributed.
BuildingPageData syntheticFloor({String id = 'test.318'}) {
  final rooms = {
    'points': [
      [
        [0, 0, 35, 0, 35, 35, 0, 35],
        [35, 0, 80, 0, 80, 50, 35, 50]
      ]
    ],
    'fills': ['#dddddd']
  };
  final labels = {
    'textFill': '#000000',
    'text': [
      {'x': 18, 'y': 18, 'qy': '318', 'mx': 32, 'my': 32},
      {'x': 32, 'y': 20, 'qy': '319A', 'mx': 80, 'my': 80},
      {'x': -25, 'y': -35, 'qy': 'Floor', 'mx': 0, 'my': 0, 'th': 0.01},
    ]
  };
  final body = '''<html><div id="menu_cont"><ul><li>Building</li><li><ul>
<li class="open"><a>00</a><ul><li><a>318</a></li></ul></li>
<li><a>01</a></li></ul></li></ul></div><script type="text/javascript">
var raeumeData = ${jsonEncode(rooms)};
raumbezData = ${jsonEncode(labels)};
var png_file_name = "TEST00";
 var subpics_size = 480;
 var data_canv_width = 200;
 var data_canv_height = 160;
 this.searchhelp = {"test.318":["raeume",0],"test.319A":["raeume",1]};
 this.raumclick = {"raeume0":["test.318","318"],"raeume1":["test.319A","319A"]};
ETplan.permahighlightRaum(1, raeume);
// ${'padding ' * 150}
</script></html>''';
  return BuildingPageData.fromHTMLText(body, ['test', '00', 'raum', id]);
}
