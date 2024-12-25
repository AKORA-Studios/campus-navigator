import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

/// Matches variables declarations that define a JS object
final RegExp variableDeclarationExp =
    RegExp(r"^var (\w+) = ({[^;]+)", multiLine: true);

/// Matches variables assignments that assign a JS object
final RegExp variableAssignmentsExp =
    RegExp(r"^(\w+) = ({[^;]+)", multiLine: true);

final RegExp stringVariableExp =
    RegExp(r'var ([\w_]+) = "([^"]+)";', multiLine: true);

final RegExp numberVariableExp =
    RegExp(r'(var)? ([\w_]+) = ([\d.]+);', multiLine: true);

// Matches JS object attribute names
final RegExp jsObjectExp = RegExp(r'([,{\[]) *(\w+):', multiLine: true);

class HTMLData {
  final Document document;
  final String script;
  final Map<String, dynamic> declaredVariables;
  final Map<String, dynamic> assignedVariables;
  final Map<String, String> stringVariables;
  final Map<String, double> numberVariables;

  const HTMLData({
    required this.document,
    required this.script,
    required this.declaredVariables,
    required this.assignedVariables,
    required this.stringVariables,
    required this.numberVariables,
  });

  factory HTMLData.fromBody(String body) {
    final document = parse(body);
    final elements =
        document.querySelectorAll('script[type="text/javascript"]');
    final script =
        elements.singleWhere((e) => e.innerHtml.length > 1000).innerHtml;

    // Parse all variables with JSON object like values
    Map<String, dynamic> declaredVariables =
        parseJSVariables(variableDeclarationExp, script);

    // ignore: unused_local_variable
    Map<String, dynamic> assignedVariables =
        parseJSVariables(variableAssignmentsExp, script);

    // String variables
    Map<String, String> stringVariables = {};
    for (final Match m in stringVariableExp.allMatches(script)) {
      stringVariables[m[1]!] = m[2]!;
    }

    // Number variables
    Map<String, double> numberVariables = {};
    for (final Match m in numberVariableExp.allMatches(script)) {
      var val = double.tryParse(m[3]!);
      if (val == null || numberVariables.containsKey(m[2])) continue;
      numberVariables[m[2]!] = val;
    }

    return HTMLData(
      document: document,
      script: script,
      declaredVariables: declaredVariables,
      assignedVariables: assignedVariables,
      stringVariables: stringVariables,
      numberVariables: numberVariables,
    );
  }
}

Map<String, dynamic> parseJSVariables(RegExp regExp, String script) {
  Map<String, dynamic> declaredVariables = {};

  var matches = regExp.allMatches(script);
  for (final Match m in matches) {
    String varName = m[1]!;
    String valueJsNotation = m[2]!;

    // Convert javascript object notation to JSON object notation
    // { a: 1 }  ->  { "a": 1 }
    String valueJsonNotation =
        valueJsNotation.replaceAllMapped(jsObjectExp, (m) {
      return '${m[1]}"${m[2]!}":';
    });

    declaredVariables[varName] = jsonDecode(valueJsonNotation);
  }

  return declaredVariables;
}
