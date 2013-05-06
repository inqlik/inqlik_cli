// Copyright (c) 2013, Lukas Renggli <renggli@gmail.com>

library simple_tests;

import 'package:qvs_parser/qvs_parser.dart';
import 'package:unittest/unittest.dart';
import 'package:petitparser/petitparser.dart';

var qvs = new QvsGrammar();


Result _parse(String source, String production) {
  var parser = qvs[production].end();
  return parser.parse(source);
}

dynamic shouldFail(String source, String production) {
  return expect(_parse(source, production).isFailure,isTrue);
}

dynamic shouldPass(String source, String production) {
  return expect(_parse(source, production).isSuccess,isTrue);
}

void main() {
  test('testIdentifier1', () {
    return shouldPass('SimpleName', 'identifier');
  });
  test('testIdentifier2', () {
    return shouldPass('_SimpleNameWithUnderscore', 'identifier');
  });
  test('testIdentifier3', () {
    return shouldPass('@4', 'identifier');
  });
  test('testIdentifier4', () {
    return shouldPass('_КодНоменклатуры', 'identifier');
  });
  test('testIdentifier5', () {
    return shouldFail('~КодНоменклатуры', 'identifier');
  });

}
