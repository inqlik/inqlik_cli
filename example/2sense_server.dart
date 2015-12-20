library reader_tests;

import "package:dart_qv/engine.dart";
import 'package:inqlik_cli/src/qv_exp_reader.dart';

main() async {
  var reader = newReader()
    ..readFile(r'example\exp_files\App.Variables.qlikview-vars');
  final variableReferencePattern =
      new RegExp(r'\$\(([\wА-Яа-яA-Za-z._0-9]*)[)(]');
  var referencedVariables = new Set<String>();
  int variableCounter = 0;
  int measureCounter = 0;
  var expressionMap = new Map<String, ExpressionData>();
  for (var entry in reader.entries) {
    if (entry.entryType == EntryType.EXPRESSION) {
      var data = entry.expression.getData();
      expressionMap[data.name] = data;
      variableCounter++;
      if (data.label != '' && data.comment != '') {
        measureCounter++;
      }
      for (var m in variableReferencePattern
          .allMatches(entry.expression.expandedDefinition)) {
        referencedVariables.add(m.group(1));
      }
    }
  }
  print(
      'Variables: $variableCounter, referenced variables: ${referencedVariables
          .length}, measures: $measureCounter');
  final testAppName = 'ad15f27f-7ae9-42d8-b0f6-c0b2f7c61890';
  var engine = new Engine();
  var global = await engine.init();
  print(global);
  var app = await global.openDoc(testAppName);

  for (ExpressionData expression
      in expressionMap.values.where((e) => e.label != '' && e.comment != '')) {
    var mDef = new MeasureDef(
        'Measure_' + expression.name, expression.definition, expression.label,
        description: expression.comment, tags: ['Imported', expression.name]);
    print(await app.createOrUpdateMeasure(mDef));
  }
  var notFound = new Set<String>();
  for (var varName in referencedVariables) {
    var expression = expressionMap[varName];
    if (expression == null) {
      notFound.add(varName);
    } else {
      var vDef = new VariableDef(expression.name,
          expression.definition, expression.comment, tags: ['Imported']);
      print(await app.createVariableEx(vDef));
    }
  }

  print('Not found variables: $notFound');

  print(await app.saveObjects());
  engine.close();
}
