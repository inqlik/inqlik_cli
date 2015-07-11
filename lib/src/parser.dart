library qvs_parser;

import 'package:petitparser/petitparser.dart';
import 'reader.dart';
import 'productions.dart' as p;
part 'grammar.dart';

QvsParser newParser(QlikViewReader reader) => new QvsParser(reader);
Result qv_parse(Parser parser, String source) {
  Result res;
  try {
    res = parser.parse(source);
  } catch (e) {
    if (e is Result) {
      res = e;
    } else {
      throw e;
    }
  }
  return res;
}

class QvsReaderGrammarDefinition extends QvsGrammarDefinition {
  QlikViewReader reader;
  QvsReaderGrammarDefinition(this.reader) : super();
  letAssignment() => super.letAssignment().map((list) {
    String varName = list[1];
    String varValue = list[3];
    reader.processAssignmentCommand(varName, varValue, true);
    return list;
  });

  setAssignment() => super.setAssignment().map((list) {
    String varName = list[1];
    String varValue = list[3];
    reader.processAssignmentCommand(varName, varValue, false);
    return list;
  });
  call() => super.call().map((list) {
    String subName = list[1];
    List<String> actualParams = [];
    if (list[2] != null) {
      actualParams.addAll(list[2][1][0]);
    }
    return [subName, actualParams];
  });

  forNextStart() => super.forNextStart().map((list) {
    reader.processAssignmentCommand(list[1], list[3], true);
    return list;
  });
  forEachStart() => super.forEachStart().map((list) {
    reader.processAssignmentCommand(list[2], list[4][0], true);
    return list;
  });
  forEachFileMaskStart() => super.forEachFileMaskStart().map((list) {
    reader.processAssignmentCommand(list[2], list[6], true);
    return list;
  });
  String _stripBrakets(value) {
    String val;
    if (value is Token) {
      val = value.value;
    } else {
      val = value;
    }
    if (val.startsWith('[')) {
      val = val.substring(1, val.length - 1);
    }
    return val;
  }
  dropTable() => super.dropTable().map((v) {
    for (var table in v[3]) {
      reader.removeTable(_stripBrakets(table));
    }
    return v;
  });
  renameTable() => super.renameTable().map((v) {
    reader.removeTable(_stripBrakets(v[2]));
    reader.addTable(_stripBrakets(v[4]));
    return v;
  });

  tableIdentifier() => super.tableIdentifier().map((v) {
    reader.addTable(_stripBrakets(v[0]));
    return v;
  });

//
//  action(p.renameTable, (v) {
//  reader.removeTable(_stripBrakets(v[2]));
//  reader.addTable(v[4]);
//  });
//  action(p.tableIdentifier, (v){
//  reader.addTable(_stripBrakets(v[0]));
//  return v;
//  });

}

class QvsParser extends GrammarParser {
  QlikViewReader reader;
  QvsReaderGrammarDefinition definition;
  QvsParser(QlikViewReader reader)
      : super(new QvsReaderGrammarDefinition(reader)) {
    this.reader = reader;
    definition = new QvsReaderGrammarDefinition(reader);
  }

  Result guarded_parse(String source, [Function production]) {
    if (production == null) {
      production = definition.start;
    }
    var parser = definition.build(start: production).end();
    return qv_parse(parser, source);
  }
  Result unguarded_parse(String source, [Function production]) {
    Result res;
    if (production == null) {
      production = definition.command;
    }
    var parser = definition.build(start: production).end();
    res = parser.parse(source);
    return res;
  }
}

class QvsParser1 extends QvsGrammar {
  QlikViewReader reader;
  QvsGrammarDefinition definition = new QvsGrammarDefinition();
  QvsParser1(this.reader) : super();
  String _stripBrakets(String val) {
    if (val.startsWith('[')) {
      val = val.substring(1, val.length - 1);
    }
    return val;
  }

  void qv_action(String name, Function function) {
    redef(name, (parser) => new QvActionParser(parser, function));
  }
  Result guarded_parse(String source, [Function production]) {
    var parser = definition.build(start: production).end();
    return qv_parse(parser, source);
  }
  Result unguarded_parse(String source, [Function production]) {
    Result res;
    var parser = definition.build(start: production).end();
    res = parser.parse(source);
    return res;
  }

  void initialize() {
    super.initialize();
    qv_action(p.function, (Result result, int savedPosition) {
//      print(result.value);
      String funcName = result.value[0];
      List<String> params = result.value[5];
      if (params == null) {
        params = [];
      }
      if (!BUILT_IN_FUNCTIONS.containsKey(funcName.toUpperCase())) {
        throw result.failure(
            "Unknown buil-in function `$funcName`", savedPosition);
      }
      var funcDesc = BUILT_IN_FUNCTIONS[funcName.toUpperCase()];
//      if (!funcDesc.isSetExpressionPossible) {
//         if (result.value[2] != null) {
//           throw result.failure("Set expression is prohibited in function `$funcName`", savedPosition);
//         }
//      }
      int actualCardinality = 0;
      if (params != null) {
        actualCardinality = params.length;
      }
      if (funcDesc.minCardinality > actualCardinality) {
        throw result.failure(
            "Function `$funcName` should have no less then ${funcDesc.minCardinality} params. Actual param number is ${params.length}",
            savedPosition);
      }
      if (funcDesc.maxCardinality < actualCardinality) {
        throw result.failure(
            "Function `$funcName` should have no more then ${funcDesc.maxCardinality} params. Actual param number is ${params.length}",
            savedPosition);
      }

      return result;
    });

    qv_action(p.identifier, (Result result, int savedPosition) {
      if (!reader.testIdentifier(result.value)) {
        throw result.failure(
            "Field `${result.value}` not found in fieldList", savedPosition);
      }
      return result;
    });

    action(p.call, (List list) {
      String subName = list[1];
      List<String> actualParams = [];
      if (list[2] != null) {
        actualParams.addAll(list[2][1][0]);
      }
      return [subName, actualParams];
    });

    action(p.assignment, (List list) {
      bool isLetCommand =
          list[0] == null || (list[0] as String).trim().toUpperCase() == 'LET';
      String varName = list[1];
      String varValue = list[3];
      reader.processAssignmentCommand(varName, varValue, isLetCommand);
      return list;
    });
    action(p.forNextStart, (List list) {
      reader.processAssignmentCommand(list[1], list[3], true);
      return list;
    });
    action(p.forEachStart, (List list) {
      reader.processAssignmentCommand(list[2], list[4][0], true);
      return list;
    });
    action(p.forEachFileMaskStart, (List list) {
      reader.processAssignmentCommand(list[2], list[6], true);
      return list;
    });
    action(p.dropTable, (v) {
      for (var table in v[3]) {
        reader.removeTable(_stripBrakets(table));
      }
    });
    action(p.load, (v) {
//      print('LOAD STATEMENT: $v');
    });

    action(p.renameTable, (v) {
      reader.removeTable(_stripBrakets(v[2]));
      reader.addTable(v[4]);
    });
    action(p.tableIdentifier, (v) {
      reader.addTable(_stripBrakets(v[0]));
      return v;
    });
    action(p.macroFunction, (v) {
//      print("macro ${v[1][0]} param ${v[1][2]}");
      return [v[1][0], v[1][2]];
    });
  }
}

class QvDelegateParser extends Parser {
  Parser _delegate;

  QvDelegateParser(this._delegate);

  @override
  Result parseOn(Context context) {
    return _delegate.parseOn(context);
  }

  @override
  List<Parser> get children => [_delegate];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (_delegate == source) {
      _delegate = target;
    }
  }

  @override
  Parser copy() => new QvDelegateParser(_delegate);
}

class QvActionParser extends QvDelegateParser {
  final Function _function;

  QvActionParser(parser, this._function) : super(parser);

  @override
  Result parseOn(Context context) {
    int savedPosition = context.position;
    var result = _delegate.parseOn(context);
    if (result.isSuccess) {
      return _function(result, savedPosition);
    } else {
      return result;
    }
  }

  @override
  Parser copy() => new QvActionParser(_delegate, _function);

  @override
  bool hasEqualProperties(QvActionParser other) {
    return super.hasEqualProperties(other) && _function == other._function;
  }
}
