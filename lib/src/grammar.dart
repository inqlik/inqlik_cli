part of qvs_parser;

class FuncDesc {
  final String name;
  final bool isSetExpressionPossible;
  final int minCardinality;
  final int maxCardinality;
  final bool isDistinctPossible;
  final bool isTotalPossible;
  const FuncDesc(this.name, this.isSetExpressionPossible, this.minCardinality,
      this.maxCardinality,
      {this.isDistinctPossible: false, this.isTotalPossible: false});
}
class QvsGrammar extends GrammarParser {
  QvsGrammar() : super(new QvsGrammarDefinition());
}

class QvsGrammarDefinition extends GrammarDefinition {
  start() => ref(command).plus().end().flatten();
  command() => ref(whenClause).optional().seq(ref(sqlTables)
      .or(ref(load))
      .or(ref(controlStatement))
      .or(ref(call))
      .or(ref(sleep))
      .or(ref(switchStatement))
      .or(ref(defaultStatement))
      .or(ref(caseStatement))
      .or(ref(dropFields))
      .or(ref(dropTable))
      .or(ref(renameTable))
      .or(ref(renameField))
      .or(ref(qualify))
      .or(ref(alias))
      .or(ref(binaryStatement))
      .or(ref(storeTable))
      .or(ref(commentWith))
      .or(ref(trace))
      .or(ref(execute))
      .or(ref(sqltables))
      .or(ref(directory))
      .or(ref(doWhile))
      .or(ref(includeDirective))
      .or(ref(connect))
      .or(ref(disconnect))
      .or(ref(assignment)));
  renameTable() => ref(_keyword,'RENAME')
      .seq(ref(_keyword,'TABLE'))
      .seq(ref(fieldref))
      .seq(ref(_keyword,'TO'))
      .seq(ref(fieldref))
      .seq(char(';'))
      .trim(ref(spacer));
  renameField() => ref(_keyword,'RENAME')
      .seq(ref(_keyword,'FIELD'))
      .seq(ref(fieldref))
      .seq(ref(_keyword,'TO'))
      .seq(ref(fieldref))
      .seq(char(';'))
      .trim(ref(spacer))
      .flatten();
  fieldref() => ref(_keyword,
      ref(identifier).or(ref(fieldrefInBrackets)).or(ref(str)).trim(ref(spacer)));
  load() => ref(tableDesignator)
      .optional()
      .seq(ref(loadPerfix).star())
      .seq(ref(_keyword,'MAPPING').optional())
      .seq(ref(preloadFunc).optional())
      .seq(ref(_keyword,'LOAD')
          .or(ref(_keyword,'SQL').optional().seq(ref(_keyword,'SELECT'))))
      .seq(ref(_keyword,'DISTINCT').optional())
      .seq(ref(selectList).trim(ref(spacer)))
      .seq(ref(loadSource).or(ref(whereClause)).optional().trim(ref(spacer)))
      .seq(char(';'))
      .trim(ref(spacer));
  loadPerfix() => ref(_keyword,'NOCONCATENATE')
      .or(ref(_word,'BUFFER').seq(ref(bufferModifier).optional()))
      .or(ref(_word,'BUNDLE').seq(ref(_word,'INFO').optional()))
      .or(ref(_word,'ADD').seq(ref(_word,'ONLY').optional()));
  sleep() =>
      ref(_keyword,'SLEEP').seq(ref(integer).trim(ref(spacer))).seq(ref(_keyword,';'));
  bufferModifier() =>
      ref(_keyword,'(')
          .seq(ref(_keyword,'INCREMENTAL').or(ref(_keyword,'STALE')
              .seq(ref(_keyword,'AFTER').optional())
              .seq(ref(number))
              .seq(ref(_keyword,'DAYS').or(ref(_keyword,'HOURS')).optional())))
          .seq(ref(_keyword,')'));
  loadSource() => ref(loadSourceAutogenerate)
      .or(ref(loadSourceInline))
      .or(ref(loadSourceStandart));
  loadSourceStandart() => ref(_keyword,'RESIDENT')
      .or(ref(_keyword,'FROM'))
      .seq(ref(tableOrFilename))
      .seq(ref(whereClause).optional())
      .seq(ref(groupBy).optional())
      .seq(ref(orderBy).optional());
  loadSourceInline() => ref(_keyword,'INLINE')
      .seq(ref(_keyword,'['))
      .seq(ref(_keyword,']').neg().plus())
      .seq(ref(_keyword,']'));
  loadSourceAutogenerate() => ref(_keyword,'autogenerate')
      .seq(ref(expression))
      .seq(ref(whereClause).optional())
      .seq(ref(whileClause).optional());
  from() => ref(_keyword,'FROM').seq(ref(fieldref));
  dropFields() => ref(_word,'DROP')
      .seq(ref(_word,'FIELDS').or(ref(_word,'FIELD')))
      .seq(ref(fieldrefs))
      .seq(ref(from).optional())
      .seq(char(';'))
      .trim(ref(spacer))
      .flatten();
  dropTable() => ref(_keyword,'DROP')
      .seq(ref(_keyword,'TABLE'))
      .seq(ref(_keyword,'S').or(ref(_keyword,'s')).optional())
      .seq(ref(fieldrefs))
      .seq(char(';'))
      .trim(ref(spacer));
  storeTable() => ref(_keyword,'STORE')
      .seq(ref(selectList).seq(ref(_keyword,'FROM')).optional())
      .seq(ref(fieldref))
      .seq(ref(_keyword,'INTO'))
      .seq(ref(tableOrFilename))
      .seq(ref(whereClause).optional())
      .seq(char(';'))
      .trim(ref(spacer))
      .flatten();

  selectList() => ref(fieldrefAs)
      .or(ref(_keyword,'*'))
      .separatedBy(char(',').trim(ref(spacer)), includeSeparators: false);
  trimFromStart() => trim(ref(spacer));
//    field() =>
//        ref(expression).seq(ref(_keyword,'as')).seq(ref(fieldref))
//        .or(ref(expression))
//        .trim(ref(spacer)).flatten();
  commentWith() => ref(_word,'COMMENT')
      .or(ref(_word,'TAG'))
      .or(ref(_word,'UNTAG'))
      .seq(ref(_word,'FIELD').or(ref(_word,'FIELDS')))
      .seq(ref(fieldrefs))
      .seq(ref(_word,'WITH'))
      .seq(ref(str).or(char(';').not().plus()))
      .seq(char(';'))
      .trim(ref(spacer))
      .flatten();
  doWhile() => ref(_keyword,'DO')
      .or(ref(_keyword,'LOOP'))
      .seq(ref(_keyword,'WHILE')
          .or(ref(_keyword,'UNTIL'))
          .seq(ref(expression))
          .optional())
      .seq(char(';').optional())
      .trim(ref(spacer));
  stringOrNotSemicolon() =>
      ref(str).or(char(';').neg()).starLazy(char(';')).flatten();
  join() => ref(_keyword,'LEFT')
      .or(ref(_keyword,'RIGHT'))
      .or(ref(_keyword,'INNER'))
      .optional()
      .seq(ref(_keyword,'JOIN').or(ref(_keyword,'KEEP')))
      .seq(ref(tableInParens).optional());
  preloadFunc() => ref(_keyword,'Hierarchy')
      .or(ref(_keyword,'HierarchyBelongsTo'))
      .or(ref(_keyword,'IntervalMatch'))
      .or(ref(_keyword,'CrossTable'))
      .seq(ref(simpleParens))
      .or(ref(_word,'FIRST').seq(ref(expression)));
  whileClause() => ref(_keyword,'while').seq(ref(expression)).flatten();
  subDeclaration() => ref(varName)
      .seq(ref(_keyword,'(').seq(ref(params)).seq(ref(_keyword,')')).optional());

  concatenate() => ref(_keyword,'concatenate').seq(ref(tableInParens).optional());
  tableInParens() => ref(_keyword,'(').seq(ref(fieldref)).seq(ref(_keyword,')'));
  groupBy() => ref(_keyword,'GROUP').seq(ref(_keyword,'BY')).seq(ref(params));
  orderBy() => ref(_keyword,'ORDER').seq(ref(_keyword,'BY')).seq(ref(fieldrefsOrderBy));

  fieldrefs() => ref(fieldref).separatedBy(char(',').trim(ref(spacer)),
      includeSeparators: false);
  fieldrefsOrderBy() => ref(fieldrefOrderBy).separatedBy(
      char(',').trim(ref(spacer)), includeSeparators: false);

  fieldrefOrderBy() => ref(identifier)
      .or(ref(fieldrefInBrackets))
      .seq(ref(_keyword,'DESC').or(ref(_keyword,'ASC')).optional());
  tableDesignator() => ref(tableIdentifier)
      .or(ref(join))
      .or(ref(concatenate))
      .plus()
      .trim(ref(spacer));
  tableIdentifier() => ref(fieldref).seq(char(':').trim(ref(spacer)));
  params() => ref(expression).separatedBy(char(',').trim(ref(spacer)),
      includeSeparators: false);
  paramsOptional() => ref(expression)
      .optional()
      .separatedBy(char(',').trim(ref(spacer)), includeSeparators: false);
  parens() => char('(')
      .trim(ref(spacer))
      .seq(ref(expression))
      .seq(char(')').trim(ref(spacer)))
      .flatten();
  tableOrFilename() => word()
      .or(anyIn(r'./\:?*').or(localLetter()))
      .plus()
      .or(ref(fieldrefInBrackets).separatedBy(char('.'),
          includeSeparators: true))
      .or(ref(str))
      .seq(ref(fileModifier).or(ref(tableSelectModifier)).optional())
      .trim(ref(spacer));
  includeDirective() => ref(_keyword,r'$(')
      .seq(ref(_keyword,'must_').optional())
      .seq(ref(_keyword,'include='))
      .seq(ref(tableOrFilename).trim(ref(spacer)))
      .seq(ref(_keyword,')'))
      .seq(ref(_keyword,';').optional())
      .trim(ref(spacer));
  whereClause() => ref(_keyword,'where')
      .or(ref(_keyword,'while'))
      .trim(ref(spacer))
      .seq(ref(expression))
      .trim(ref(spacer));
  whenClause() => ref(_keyword,'when')
      .or(ref(_keyword,'unless'))
      .seq(ref(expression))
      .trim(ref(spacer));

  letAssignment() => ref(_keyword,'LET')
      .optional()
      .seq(ref(identifier).or(ref(fieldrefInBrackets)))
      .seq(char('=').trim(ref(spacer)))
      .seq(ref(expression).trim(ref(spacer)).optional())
      .seq(char(';').trim(ref(spacer)));
  setAssignment() => ref(_keyword,'SET')
      .seq(ref(identifier).or(ref(fieldrefInBrackets)))
      .seq(char('=').trim(ref(spacer)))
      .seq(ref(stringOrNotSemicolon))
      .seq(char(';').trim(ref(spacer)));
  assignment() => ref(setAssignment).or(ref(letAssignment));
  sqlTables() =>
      ref(tableDesignator).seq(ref(_keyword,'SQLTABLES')).seq(ref(_keyword,';'));

  call() => ref(_word,'call')
      .trim(ref(spacer))
      .seq(word().or(char('.')).plus().trim(ref(spacer)).flatten())
      .seq(char('(')
          .trim(ref(spacer))
          .seq(ref(params).plus())
          .seq(char(')').trim(ref(spacer)))
          .optional())
      .seq(ref(_keyword,';').optional())
      .trim(ref(spacer));
  simpleParens() => char("(")
      .seq(char(")").neg().star())
      .seq(char(")"))
      .trim(ref(spacer))
      .flatten();
  fileModifierTokens() =>
      ref(_keyword,'embedded labels')
          .or(ref(_keyword,'ooxml'))
          .or(ref(_keyword,'explicit labels'))
          .or(ref(_keyword,'no').seq(
              ref(_keyword,'quotes').or(ref(_keyword,'labels')).or(ref(_keyword,'eof'))))
          .or(ref(_keyword,'codepage is')
              .seq(ref(decimalInteger).plus())
              .or(ref(_keyword,'unicode'))
              .or(ref(_keyword,'ansi'))
              .or(ref(_keyword,'oem'))
              .or(ref(_keyword,'mac'))
              .or(ref(_keyword,'UTF').seq(char('-').optional().seq(char('8')))))
          .or(ref(_keyword,'table is')
              .seq(ref(fieldref).or(ref(number)).or(ref(str))))
          .or(ref(_keyword,'header')
              .or(ref(_keyword,'record'))
              .seq(ref(_keyword,'is'))
              .seq(ref(decimalInteger))
              .seq(ref(_keyword,'lines')))
          .or(ref(_keyword,'delimiter is').seq(ref(str).or(ref(_keyword,'spaces'))))
          .flatten();
  fileModifierElement() => ref(fileModifierTokens).or(ref(expression));
  fileModifierElements() => ref(fileModifierElement).separatedBy(
      char(',').trim(ref(spacer)), includeSeparators: false);
  fileModifier() =>
      ref(_keyword,'(').seq(ref(fileModifierElements)).seq(ref(_keyword,')'));
  tableSelectModifier() => ref(_keyword,'WITH')
      .seq(ref(_keyword,'('))
      .seq(word().plus().trim(ref(spacer)))
      .seq(ref(_keyword,')'));
  connect() => ref(_keyword,'ODBC')
      .or(ref(_keyword,'OLEDB'))
      .or(ref(_keyword,'CUSTOM'))
      .optional()
      .seq(ref(_keyword,'CONNECT64')
          .or(ref(_keyword,'CONNECT32'))
          .or(ref(_keyword,'CONNECT')))
      .seq(ref(_keyword,'TO'))
      .seq(ref(str).or(ref(fieldrefInBrackets)))
      .seq(ref(simpleParens).optional())
      .seq(ref(_keyword,';'));
  controlStatement() => ref(subStart)
      .or(ref(exitScript))
      .or(ref(forNextStart))
      .or(ref(forEachFileMaskStart))
      .or(ref(forEachStart))
      .or(ref(ifStart))
      .or(ref(_keyword,'ELSE'))
      .or(ref(controlStatementFinish));
  controlStatementFinish() => ref(_keyword,'END')
      .seq(ref(_keyword,'SUB').or(ref(_keyword,'SWITCH')).or(ref(_keyword,'IF')))
      .or(ref(_keyword,'NEXT').seq(ref(identifier).optional()))
      .seq(ref(_keyword,';').optional());
  subStart() =>
      ref(_keyword,'SUB').seq(ref(subDeclaration)).seq(ref(_keyword,';').optional());
  exitScript() => ref(_keyword,'exit')
      .seq(ref(_keyword,'script')
          .or(ref(_keyword,'sub'))
          .or(ref(_keyword,'for'))
          .or(ref(_keyword,'do')))
      .seq(ref(whenClause).optional())
      .seq(ref(_keyword,';').optional());
  forNextStart() => ref(_keyword,'FOR')
      .seq(ref(identifier))
      .seq(ref(_keyword,'='))
      .seq(ref(expression))
      .seq(ref(_keyword,'to'))
      .seq(ref(expression))
      .seq(ref(_keyword,'STEP').seq(ref(expression)).optional())
      .seq(ref(_keyword,';').optional());
  ifStart() => ref(_keyword,'IF')
      .or(ref(_keyword,'ELSEIF'))
      .seq(ref(expression))
      .seq(ref(_keyword,'THEN'))
      .seq(ref(_keyword,';').optional());
  forEachStart() => ref(_word,'FOR')
      .seq(ref(_word,'each'))
      .seq(ref(identifier))
      .seq(ref(_word,'in'))
      .seq(ref(params))
      .seq(ref(_keyword,';').optional());
  forEachFileMaskStart() => ref(_word,'FOR')
      .seq(ref(_word,'each'))
      .seq(ref(identifier))
      .seq(ref(_word,'in'))
      .seq(ref(_keyword,'filelist').or(ref(_keyword,'dirlist')))
      .seq(ref(_keyword,'('))
      .seq(ref(expression))
      .seq(ref(_keyword,')'))
      .seq(ref(_keyword,';').optional());
  qualify() => ref(_keyword,'UNQUALIFY')
      .or(ref(_keyword,'QUALIFY'))
      .seq(ref(fieldrefOrStringList).or(ref(_keyword,'*')))
      .seq(ref(_keyword,';'))
      .flatten();

  fieldrefOrStringList() => ref(fieldrefOrString).separatedBy(
      char(',').trim(ref(spacer)), includeSeparators: false);

  fieldrefOrString() =>
      ref(identifier).or(ref(fieldrefInBrackets)).or(ref(str));
  fieldrefAs() => ref(expression)
      .seq(ref(_keyword,'as'))
      .seq(ref(fieldref))
      .or(ref(expression));
  fieldrefsAs() => ref(fieldrefAs).separatedBy(char(',').trim(ref(spacer)),
      includeSeparators: false);
  alias() => ref(_keyword,'ALIAS').seq(ref(fieldrefsAs)).seq(ref(_keyword,';'));
  binaryStatement() =>
      ref(_keyword,'binary').seq(ref(tableOrFilename)).seq(ref(_keyword,';'));
  trace() => ref(_word,'TRACE').seq(char(';').neg().plus()).seq(ref(_keyword,';'));
  execute() => ref(_word,'EXECUTE').seq(char(';').neg().plus()).seq(ref(_keyword,';'));
  sqltables() => ref(_keyword,'SQLTABLES').seq(ref(_keyword,';'));
  defaultStatement() => ref(_keyword,'default').seq(ref(_keyword,';').optional());
  caseStatement() =>
      ref(_keyword,'case').seq(ref(expression)).seq(ref(_keyword,';').optional());

  switchStatement() =>
      ref(_keyword,'switch').seq(ref(expression)).seq(ref(_keyword,';').optional());

  directory() =>
      ref(_keyword,'DIRECTORY').seq(char(';').neg().star()).seq(ref(_keyword,';'));
  disconnect() => ref(_keyword,'disconnect').seq(ref(_keyword,';'));

  setExpression() => ref(_keyword,'{').seq(ref(setEntity)).seq(ref(_keyword,'}'));
  setEntity() => ref(setEntityPrimary).separatedBy(ref(setOperator),
      includeSeparators: true);
  setEntitySimple() =>
      ref(setIdentifier).seq(ref(setModifier).optional()).or(ref(setModifier));
  setEntityPrimary() => ref(setEntitySimple).or(ref(setEntityInParens));
  setEntityInParens() => ref(_keyword,'(').seq(ref(setEntity)).seq(ref(_keyword,')'));
  setIdentifier() => ref(_keyword,r'$')
      .seq(ref(_keyword,'_').optional())
      .seq(ref(integer))
      .or(ref(_keyword,'1'))
      .or(ref(_keyword,r'$'))
      .or(ref(alternateStateIdentifier))
      .or(ref(fieldrefInBrackets));
  alternateStateIdentifier() => letter()
      .or(anyIn(r'_%@$').or(localLetter()))
      .seq(word()
          .or(anyIn('.%'))
          .or(char('_'))
          .or(localLetter().or(char(r'$')))
          .plus())
      .or(letter())
      .flatten()
      .trim(ref(spacer));
  setOperator() =>
      ref(_keyword,r'+').or(ref(_keyword,r'-')).or(ref(_keyword,r'*')).or(ref(_keyword,r'/'));
  setElement() =>
      ref(number).or(ref(str)).or(ref(macroExpression)).or(ref(identifier));
  setElementList() =>
      ref(setElement).separatedBy(ref(_keyword,','), includeSeparators: false);
  setElementSet() => ref(setElementFunction)
      .or(ref(identifier))
      .or(ref(_keyword,'{').seq(ref(setElementList).optional()).seq(ref(_keyword,'}')));
  setElementSetInParens() =>
      ref(_keyword,'(').seq(ref(setElementSetExpression)).seq(ref(_keyword,')'));
  setElementSetPrimary() => ref(setElementSet).or(ref(setElementSetInParens));
  setElementSetExpression() => ref(setElementSetPrimary).separatedBy(
      ref(setOperator), includeSeparators: true);

  setFieldSelection() => ref(fieldName)
      .seq(ref(_keyword,'=')
          .or(ref(_keyword,'-='))
          .or(ref(_keyword,'+='))
          .or(ref(_keyword,'*='))
          .or(ref(_keyword,'/=')))
      .seq(ref(setElementSetExpression).optional())
      .or(ref(fieldName));
  setModifier() => ref(_keyword,'<')
      .seq(ref(setFieldSelection).separatedBy(ref(_keyword,','),
          includeSeparators: false))
      .seq(ref(_keyword,'>'));
  setElementFunction() => ref(_keyword,'P')
      .or(ref(_keyword,'E'))
      .seq(ref(_keyword,'('))
      .seq(ref(setExpression))
      .seq(ref(fieldName).optional())
      .seq(ref(_keyword,')'));

  /**
   * Russian letters
   */
  localLetter() => range(1024, 1273);
  
//    start() => ref(expression).end().flatten());
//    stringOrNotSemicolon() =>
//        ref(str)
//        .or(char(';').neg()).starLazy(char(';')).flatten()
//        );
//    params() =>
//        ref(expression).separatedBy(char(',').trim(ref(spacer)), includeSeparators: false);
  totalClause() => ref(_keyword,'TOTAL').seq(ref(totalModifier).optional());
  distinctClause() => ref(_keyword,'NODISTINCT').or(ref(_keyword,'DISTINCT'));
  totalModifier() => ref(_keyword,'<')
      .seq(ref(fieldName).separatedBy(char(',').trim(ref(spacer)),
          includeSeparators: false))
      .seq(ref(_keyword,'>'));
  functionModifier() =>
      ref(distinctClause).or(ref(totalClause).or(ref(setExpression)));

  /** Defines the whitespace and comments. */

  spacer() => whitespace()
      .or(ref(singeLineComment))
      .or(ref(remComment))
      .or(ref(multiLineComment));
  singeLineComment() => string('//').seq(Token.newlineParser().neg().star());
  remComment() => string('REM').seq(Token.newlineParser().neg().star());
  multiLineComment() =>
      string('/*').seq(string('*/').neg().star()).seq(string('*/'));

  expression() => string(r'$($(=')
      .seq(ref(binaryExpression))
      .seq(ref(_keyword,')').seq(ref(_keyword,')')))
      .or(ref(macroExpression))
      .or(ref(binaryExpression).trim(ref(spacer)));
  macroExpression() =>
      string(r'$(=').seq(ref(binaryExpression)).seq(ref(_keyword,')'));

  primaryExpression() => ref(str)
      .or(ref(unaryExpression))
      .or(ref(macroFunction))
      .or(ref(function))
      .or(ref(number))
      .or(ref(fieldName))
      .or(ref(parens));
  binaryExpression() => ref(primaryExpression)
      .seq(ref(binaryPart).star())
      .trim(ref(spacer))
      .flatten();
  binaryPart() => ref(binaryOperator).seq(ref(primaryExpression));
  fieldName() => ref(_keyword,ref(identifier).or(ref(fieldrefInBrackets)));
  identifier() => letter()
      .or(anyIn(r'_%@$').or(localLetter()))
      .seq(word()
          .or(anyIn('.%'))
          .or(char('_'))
          .or(localLetter().or(char(r'$')))
          .plus())
      .or(letter())
      .flatten()
      .trim(ref(spacer));
  varName() => word()
      .or(localLetter())
      .or(anyIn(r'._$#@'))
      .plus()
      .flatten()
      .trim(ref(spacer));
  fieldrefInBrackets() => ref(_keyword,'[')
      .seq(ref(_keyword,']').neg().plus())
      .seq(ref(_keyword,']'))
      .trim(ref(spacer))
      .flatten();
  str() => char("'")
      .seq(char("'").neg().star())
      .seq(char("'"))
      .or(char('"').seq(char('"').neg().star()).seq(char('"')))
      .flatten();

  constant() => ref(number).or(ref(str));
  function() => letter()
      .seq(word().or(char('#')).plus())
      .flatten()
      .trim(ref(spacer))
      .seq(char('(').trim(ref(spacer)))
      .seq(ref(functionModifier).optional())
      .seq(ref(functionModifier).optional())
      .seq(ref(functionModifier).optional())
      .seq(ref(params).optional())
      .seq(char(')').trim(ref(spacer)));
  userFunction() => word()
      .or(anyIn('._#'))
      .plus()
      .flatten()
      .trim(ref(spacer))
      .seq(char('(').trim(ref(spacer)))
      .seq(ref(paramsOptional).optional())
      .seq(char(')').trim(ref(spacer)));
  macroFunction() =>
      ref(_keyword,r'$(').seq(ref(userFunction)).seq(ref(_keyword,')').trim(ref(spacer)));
  unaryExpression() => ref(_keyword,'NOT')
      .or(ref(_keyword,'-'))
      .trim(ref(spacer))
      .seq(ref(expression))
      .trim(ref(spacer))
      .flatten();
  binaryOperator() => ref(_word,'and')
      .or(ref(_word,'or'))
      .or(ref(_word,'xor'))
      .or(ref(_word,'like'))
      .or(ref(_keyword,'<='))
      .or(ref(_keyword,'<>'))
      .or(ref(_keyword,'!='))
      .or(ref(_keyword,'>='))
      .or(anyIn('+-/*<>=&'))
      .or(ref(_word,'precedes'))
      .trim(ref(spacer))
      .flatten();

  /** Defines a token parser that ignore case and consumes whitespace. */
  _keyword(input) {
    if (input is String) {
      input = input.length == 1 ? char(input) : stringIgnoreCase(input);
    }
    return input.token().trim(ref(spacer));
  }
   _word (dynamic input) {
     if (input is String) {
       input = stringIgnoreCase(input + ' ');
     }
    return input.token().trim(ref(spacer));
  }

  number() => char('-').optional().seq(ref(positiveNumber)).flatten();
  positiveNumber() => ref(scaledDecimal) |
      ref(float) |
      char('.').seq(ref(digits)) |
      ref(integer);

  integer() => ref(radixInteger).or(ref(decimalInteger));
  decimalInteger() => ref(digits);
  digits() => digit().plus();
  radixInteger() => ref(radixSpecifier) & char('r') & ref(radixDigits);
  radixSpecifier() => ref(digits);
  radixDigits() => pattern('0-9A-Z').plus();
  float() =>
      ref(mantissa).seq(ref(exponentLetter).seq(ref(exponent)).optional());
  mantissa() => ref(digits).seq(char('.')).seq(ref(digits));
  exponent() => char('-').seq(ref(decimalInteger));
  exponentLetter() => pattern('edq');
  scaledDecimal() =>
      ref(scaledMantissa).seq(char('s')).seq(ref(fractionalDigits).optional());
  scaledMantissa() => ref(decimalInteger).or(ref(mantissa));
  fractionalDigits() => ref(decimalInteger);
}

const Map<String, FuncDesc> BUILT_IN_FUNCTIONS = const <String, FuncDesc>{
  'ABOVE': const FuncDesc('ABOVE', false, 1, 3, isTotalPossible: true),
  'AFTER': const FuncDesc('AFTER', false, 1, 3, isTotalPossible: true),
  'ACOS': const FuncDesc('ACOS', false, 1, 1),
  'ADDMONTHS': const FuncDesc('ADDMONTHS', false, 2, 3),
  'ADDYEARS': const FuncDesc('ADDYEARS', true, 0, 999),
  'AGE': const FuncDesc('AGE', false, 2, 2),
  'AGGR': const FuncDesc('AGGR', true, 2, 999),
  'ALT': const FuncDesc('ALT', false, 2, 999),
  'APPLYCODEPAGE': const FuncDesc('APPLYCODEPAGE', false, 2, 2),
  'APPLYMAP': const FuncDesc('APPLYMAP', false, 2, 3),
  'ARGB': const FuncDesc('ARGB', false, 4, 4),
  'ASIN': const FuncDesc('ASIN', false, 1, 1),
  'ATAN': const FuncDesc('ATAN', false, 1, 1),
  'ATAN2': const FuncDesc('ATAN2', false, 2, 2),
  'ATTRIBUTE': const FuncDesc('ATTRIBUTE', false, 2, 2),
  'AUTHOR': const FuncDesc('AUTHOR', true, 0, 999),
  'AUTONUMBER': const FuncDesc('AUTONUMBER', false, 1, 2),
  'AUTONUMBERHASH128': const FuncDesc('AUTONUMBERHASH128', false, 1, 999),
  'AUTONUMBERHASH256': const FuncDesc('AUTONUMBERHASH256', false, 1, 999),
  'AVG': const FuncDesc('AVG', true, 1, 1),
  'BEFORE': const FuncDesc('BEFORE', false, 1, 3, isTotalPossible: true),
  'BELOW': const FuncDesc('BELOW', false, 1, 3, isTotalPossible: true),
  'BITCOUNT': const FuncDesc('BITCOUNT', false, 1, 1),
  'BLACK': const FuncDesc('BLACK', false, 0, 1),
  'BLACKANDSCHOLE': const FuncDesc('BLACKANDSCHOLE', false, 6, 6),
  'BLUE': const FuncDesc('BLUE', false, 0, 1),
  'BOTTOM': const FuncDesc('BOTTOM', false, 1, 3, isTotalPossible: true),
  'BROWN': const FuncDesc('BROWN', false, 0, 1),
  'CAPITALIZE': const FuncDesc('CAPITALIZE', false, 1, 1),
  'CEIL': const FuncDesc('CEIL', false, 1, 3),
  'CHI2TEST_CHI2': const FuncDesc('CHI2TEST_CHI2', true, 0, 999),
  'CHI2TEST_DF': const FuncDesc('CHI2TEST_DF', true, 0, 999),
  'CHI2TEST_P': const FuncDesc('CHI2TEST_P', true, 0, 999),
  'CHIDIST': const FuncDesc('CHIDIST', false, 2, 2),
  'CHIINV': const FuncDesc('CHIINV', false, 2, 2),
  'CHR': const FuncDesc('CHR', false, 1, 1),
  'CLASS': const FuncDesc('CLASS', false, 2, 4),
  'CLIENTPLATFORM': const FuncDesc('CLIENTPLATFORM', false, 0, 0),
  'COLOR': const FuncDesc('COLOR', false, 1, 2),
  'COLORMAPHUE': const FuncDesc('COLORMAPHUE', true, 0, 999),
  'COLORMAPJET': const FuncDesc('COLORMAPJET', true, 0, 999),
  'COLORMIX1': const FuncDesc('COLORMIX1', false, 3, 3),
  'COLORMIX2': const FuncDesc('COLORMIX2', false, 3, 4),
  'COLUMN': const FuncDesc('COLUMN', false, 1, 1),
  'COLUMNNO': const FuncDesc('COLUMNNO', false, 0, 0, isTotalPossible: true),
  'COMBIN': const FuncDesc('COMBIN', false, 2, 2),
  'COMPUTERNAME': const FuncDesc('COMPUTERNAME', false, 0, 0),
  'CONCAT': const FuncDesc('CONCAT', true, 1, 3, isDistinctPossible: true),
  'CONNECTSTRING': const FuncDesc('CONNECTSTRING', false, 0, 0),
  'CONVERTTOLOCALTIME': const FuncDesc('CONVERTTOLOCALTIME', false, 1, 3),
  'CORREL': const FuncDesc('CORREL', true, 0, 999),
  'COS': const FuncDesc('COS', false, 1, 1),
  'COSH': const FuncDesc('COSH', false, 1, 1),
  'COUNT': const FuncDesc('COUNT', true, 1, 1, isDistinctPossible: true),
  'CYAN': const FuncDesc('CYAN', false, 0, 1),
  'DARKGRAY': const FuncDesc('DARKGRAY', false, 0, 1),
  'DATE#': const FuncDesc('DATE#', false, 1, 2),
  'DATE': const FuncDesc('DATE', false, 1, 2),
  'DAY': const FuncDesc('DAY', false, 1, 1),
  'DAYEND': const FuncDesc('DAYEND', false, 1, 3),
  'DAYLIGHTSAVING': const FuncDesc('DAYLIGHTSAVING', false, 0, 0),
  'DAYNAME': const FuncDesc('DAYNAME', false, 1, 3),
  'DAYNUMBEROFQUARTER': const FuncDesc('DAYNUMBEROFQUARTER', false, 1, 2),
  'DAYNUMBEROFYEAR': const FuncDesc('DAYNUMBEROFYEAR', false, 1, 2),
  'DAYSTART': const FuncDesc('DAYSTART', false, 1, 3),
  'DIV': const FuncDesc('DIV', false, 2, 2),
  'DIMENSIONALITY': const FuncDesc('DIMENSIONALITY', false, 0, 0),
  'DOCUMENTNAME': const FuncDesc('DOCUMENTNAME', false, 0, 0),
  'DOCUMENTPATH': const FuncDesc('DOCUMENTPATH', false, 0, 0),
  'DOCUMENTTITLE': const FuncDesc('DOCUMENTTITLE', false, 0, 0),
  'DUAL': const FuncDesc('DUAL', false, 2, 2),
  'E': const FuncDesc('E', false, 0, 0),
  'EVALUATE': const FuncDesc('EVALUATE', false, 1, 1),
  'EVEN': const FuncDesc('EVEN', false, 1, 1),
  'EXISTS': const FuncDesc('EXISTS', false, 1, 2),
  'EXP': const FuncDesc('EXP', false, 1, 1),
  'FABS': const FuncDesc('FABS', false, 1, 1),
  'FACT': const FuncDesc('FACT', false, 1, 1),
  'FALSE': const FuncDesc('FALSE', false, 0, 0),
  'FDIST': const FuncDesc('FDIST', false, 3, 3),
  'FIELDINDEX': const FuncDesc('FIELDINDEX', false, 2, 2),
  'FIELDNAME': const FuncDesc('FIELDNAME', false, 1, 2),
  'FIELDNUMBER': const FuncDesc('FIELDNUMBER', false, 1, 2),
  'FIELDVALUE': const FuncDesc('FIELDVALUE', false, 2, 2),
  'FIELDVALUECOUNT': const FuncDesc('FIELDVALUECOUNT', false, 1, 1),
  'FILEBASENAME': const FuncDesc('FILEBASENAME', false, 0, 0),
  'FILEDIR': const FuncDesc('FILEDIR', false, 0, 0),
  'FILEEXTENSION': const FuncDesc('FILEEXTENSION', false, 0, 0),
  'FILENAME': const FuncDesc('FILENAME', false, 0, 0),
  'FILEPATH': const FuncDesc('FILEPATH', false, 0, 0),
  'FILESIZE': const FuncDesc('FILESIZE', false, 0, 0),
  'FILETIME': const FuncDesc('FILETIME', false, 0, 1),
  'FINDONEOF': const FuncDesc('FINDONEOF', false, 2, 3),
  'FINV': const FuncDesc('FINV', false, 3, 3),
  'FIRST': const FuncDesc('FIRST', false, 1, 3, isTotalPossible: true),
  'FIRSTSORTEDVALUE':
      const FuncDesc('FIRSTSORTEDVALUE', true, 1, 3, isDistinctPossible: true),
  'FIRSTVALUE': const FuncDesc('FIRSTVALUE', true, 1, 1),
  'FIRSTWORKDATE': const FuncDesc('FIRSTWORKDATE', false, 2, 999),
  'FLOOR': const FuncDesc('FLOOR', false, 1, 3),
  'FMOD': const FuncDesc('FMOD', false, 2, 2),
  'FRAC': const FuncDesc('FRAC', false, 1, 1),
  'FRACTILE': const FuncDesc('FRACTILE', true, 0, 999),
  'FV': const FuncDesc('FV', false, 3, 5),
  'GETACTIVESHEETID': const FuncDesc('GETACTIVESHEETID', false, 0, 0),
  'GETALTERNATIVECOUNT': const FuncDesc('GETALTERNATIVECOUNT', false, 1, 1),
  'GETEXCLUDEDCOUNT': const FuncDesc('GETEXCLUDEDCOUNT', false, 1, 1),
  'GETEXTENDEDPROPERTY': const FuncDesc('GETEXTENDEDPROPERTY', false, 1, 2),
  'GETCURRENTFIELD': const FuncDesc('GETCURRENTFIELD', false, 1, 1),
  'GETCURRENTSELECTIONS': const FuncDesc('GETCURRENTSELECTIONS', false, 0, 4),
  'GETFIELDSELECTIONS': const FuncDesc('GETFIELDSELECTIONS', false, 1, 3),
  'GETFOLDERPATH': const FuncDesc('GETFOLDERPATH', false, 0, 0),
  'GETNOTSELECTEDCOUNT': const FuncDesc('GETNOTSELECTEDCOUNT', false, 1, 2),
  'GETOBJECTFIELD': const FuncDesc('GETOBJECTFIELD', false, 0, 1),
  'GETPOSSIBLECOUNT': const FuncDesc('GETPOSSIBLECOUNT', false, 1, 1),
  'GETSELECTEDCOUNT': const FuncDesc('GETSELECTEDCOUNT', false, 1, 2),
  'GETREGISTRYSTRING': const FuncDesc('GETREGISTRYSTRING', true, 0, 999),
  'GMT': const FuncDesc('GMT', false, 0, 0),
  'GREEN': const FuncDesc('GREEN', false, 0, 1),
  'HASH128': const FuncDesc('HASH128', false, 1, 999),
  'HASH160': const FuncDesc('HASH160', false, 1, 999),
  'HASH256': const FuncDesc('HASH256', false, 1, 999),
  'HOUR': const FuncDesc('HOUR', false, 1, 1),
  'HRANK': const FuncDesc('HRANK', false, 1, 3, isTotalPossible: true),
  'HSL': const FuncDesc('HSL', false, 3, 3),
  'IF': const FuncDesc('IF', false, 2, 3),
  'INDAY': const FuncDesc('INDAY', false, 3, 4),
  'INDAYTOTIME': const FuncDesc('INDAYTOTIME', false, 3, 4),
  'INDEX': const FuncDesc('INDEX', false, 2, 3),
  'INLUNARWEEK': const FuncDesc('INLUNARWEEK', false, 3, 4),
  'INLUNARWEEKTODATE': const FuncDesc('INLUNARWEEKTODATE', false, 3, 4),
  'INMONTH': const FuncDesc('INMONTH', false, 3, 3),
  'INMONTHS': const FuncDesc('INMONTHS', false, 4, 5),
  'INMONTHSTODATE': const FuncDesc('INMONTHSTODATE', false, 4, 5),
  'INMONTHTODATE': const FuncDesc('INMONTHTODATE', false, 3, 3),
  'INPUT': const FuncDesc('INPUT', false, 1, 2),
  'INPUTAVG': const FuncDesc('INPUTAVG', true, 0, 999),
  'INPUTSUM': const FuncDesc('INPUTSUM', true, 0, 999),
  'INQUARTER': const FuncDesc('INQUARTER', false, 3, 4),
  'INQUARTERTODATE': const FuncDesc('INQUARTERTODATE', false, 3, 4),
  'INTERVAL': const FuncDesc('INTERVAL', false, 1, 2),
  'INTERVAL#': const FuncDesc('INTERVAL#', false, 1, 2),
  'INWEEK': const FuncDesc('INWEEK', false, 3, 4),
  'INWEEKTODATE': const FuncDesc('INWEEKTODATE', false, 3, 4),
  'INYEAR': const FuncDesc('INYEAR', false, 3, 4),
  'INYEARTODATE': const FuncDesc('INYEARTODATE', false, 3, 4),
  'IRR': const FuncDesc('IRR', true, 0, 999),
  'ISNULL': const FuncDesc('ISNULL', false, 1, 1),
  'ISNUM': const FuncDesc('ISNUM', false, 1, 1),
  'ISPARTIALRELOAD': const FuncDesc('ISPARTIALRELOAD', false, 0, 0),
  'ISTEXT': const FuncDesc('ISTEXT', false, 1, 1),
  'ITERNO': const FuncDesc('ITERNO', false, 0, 0),
  'KEEPCHAR': const FuncDesc('KEEPCHAR', false, 2, 2),
  'KURTOSIS': const FuncDesc('KURTOSIS', true, 0, 999),
  'LAST': const FuncDesc('LAST', false, 1, 3, isTotalPossible: true),
  'LASTVALUE': const FuncDesc('LASTVALUE', true, 1, 1),
  'LASTWORKDATE': const FuncDesc('LASTWORKDATE', false, 2, 999),
  'LEFT': const FuncDesc('LEFT', false, 2, 2),
  'LEN': const FuncDesc('LEN', false, 1, 1),
  'LIGHTBLUE': const FuncDesc('LIGHTBLUE', false, 0, 1),
  'LIGHTCYAN': const FuncDesc('LIGHTCYAN', false, 0, 1),
  'LIGHTGRAY': const FuncDesc('LIGHTGRAY', false, 0, 1),
  'LIGHTGREEN': const FuncDesc('LIGHTGREEN', false, 0, 1),
  'LIGHTMAGENTA': const FuncDesc('LIGHTMAGENTA', false, 0, 1),
  'LIGHTRED': const FuncDesc('LIGHTRED', false, 0, 1),
  'LINEST_B': const FuncDesc('LINEST_B', true, 0, 999),
  'LINEST_DF': const FuncDesc('LINEST_DF', true, 0, 999),
  'LINEST_F': const FuncDesc('LINEST_F', true, 0, 999),
  'LINEST_M': const FuncDesc('LINEST_M', true, 0, 999),
  'LINEST_R2': const FuncDesc('LINEST_R2', true, 0, 999),
  'LINEST_SEB': const FuncDesc('LINEST_SEB', true, 0, 999),
  'LINEST_SEM': const FuncDesc('LINEST_SEM', true, 0, 999),
  'LINEST_SEY': const FuncDesc('LINEST_SEY', true, 0, 999),
  'LINEST_SSREG': const FuncDesc('LINEST_SSREG', true, 0, 999),
  'LINEST_SSRESID': const FuncDesc('LINEST_SSRESID', true, 0, 999),
  'LOCALTIME': const FuncDesc('LOCALTIME', false, 0, 2),
  'LOG': const FuncDesc('LOG', false, 1, 1),
  'LOG10': const FuncDesc('LOG10', false, 1, 1),
  'LOOKUP': const FuncDesc('LOOKUP', false, 3, 4),
  'LOWER': const FuncDesc('LOWER', false, 1, 1),
  'LTRIM': const FuncDesc('LTRIM', false, 1, 1),
  'LUNARWEEKEND': const FuncDesc('LUNARWEEKEND', false, 1, 3),
  'LUNARWEEKNAME': const FuncDesc('LUNARWEEKNAME', false, 1, 3),
  'LUNARWEEKSTART': const FuncDesc('LUNARWEEKSTART', false, 1, 3),
  'MAGENTA': const FuncDesc('MAGENTA', false, 0, 1),
  'MAKEDATE': const FuncDesc('MAKEDATE', false, 1, 3),
  'MAKETIME': const FuncDesc('MAKETIME', false, 1, 4),
  'MAKEWEEKDATE': const FuncDesc('MAKEWEEKDATE', false, 1, 3),
  'MAPSUBSTRING': const FuncDesc('MAPSUBSTRING', false, 2, 2),
  'MATCH': const FuncDesc('MATCH', false, 2, 999),
  'MAX': const FuncDesc('MAX', true, 1, 2),
  'MAXSTRING': const FuncDesc('MAXSTRING', true, 1, 1),
  'MEDIAN': const FuncDesc('MEDIAN', true, 0, 999),
  'MID': const FuncDesc('MID', false, 2, 3),
  'MIN': const FuncDesc('MIN', true, 1, 2),
  'MINSTRING': const FuncDesc('MINSTRING', true, 1, 1),
  'MINUTE': const FuncDesc('MINUTE', false, 1, 1),
  'MISSINGCOUNT':
      const FuncDesc('MISSINGCOUNT', true, 1, 1, isDistinctPossible: true),
  'MIXMATCH': const FuncDesc('MIXMATCH', false, 2, 999),
  'MOD': const FuncDesc('MOD', false, 2, 2),
  'MODE': const FuncDesc('MODE', true, 1, 1),
  'MONEY': const FuncDesc('MONEY', false, 1, 4),
  'MONEY#': const FuncDesc('MONEY#', false, 1, 4),
  'MONTH': const FuncDesc('MONTH', false, 1, 1),
  'MONTHEND': const FuncDesc('MONTHEND', false, 1, 2),
  'MONTHNAME': const FuncDesc('MONTHNAME', false, 1, 2),
  'MONTHSEND': const FuncDesc('MONTHSEND', false, 2, 4),
  'MONTHSNAME': const FuncDesc('MONTHSNAME', false, 2, 4),
  'MONTHSSTART': const FuncDesc('MONTHSSTART', false, 2, 4),
  'MONTHSTART': const FuncDesc('MONTHSTART', false, 1, 2),
  'MSGBOX': const FuncDesc('MSGBOX', false, 1, 5),
  'NETWORKDAYS': const FuncDesc('NETWORKDAYS', false, 2, 999),
  'NOOFCOLUMNS':
      const FuncDesc('NOOFCOLUMNS', false, 0, 0, isTotalPossible: true),
  'NOOFFIELDS': const FuncDesc('NOOFFIELDS', false, 0, 1),
  'NOOFREPORTS': const FuncDesc('NOOFREPORTS', false, 0, 0),
  'NOOFROWS': const FuncDesc('NOOFROWS', false, 0, 1, isTotalPossible: true),
  'NOOFTABLES': const FuncDesc('NOOFTABLES', false, 0, 0),
  'NORMDIST': const FuncDesc('NORMDIST', false, 3, 3),
  'NORMINV': const FuncDesc('NORMINV', false, 3, 3),
  'NOW': const FuncDesc('NOW', false, 0, 1),
  'NPER': const FuncDesc('NPER', false, 3, 5),
  'NPV': const FuncDesc('NPV', true, 0, 999),
  'NULL': const FuncDesc('NULL', false, 0, 0),
  'NULLCOUNT':
      const FuncDesc('NULLCOUNT', true, 1, 1, isDistinctPossible: true),
  'NUM': const FuncDesc('NUM', false, 1, 4),
  'NUM#': const FuncDesc('NUM#', false, 1, 4),
  'NUMAVG': const FuncDesc('NUMAVG', false, 1, 999),
  'NUMCOUNT': const FuncDesc('NUMCOUNT', false, 1, 999),
  'NUMERICCOUNT':
      const FuncDesc('NUMERICCOUNT', true, 1, 1, isDistinctPossible: true),
  'NUMMAX': const FuncDesc('NUMMAX', false, 1, 999),
  'NUMMIN': const FuncDesc('NUMMIN', false, 1, 999),
  'NUMSUM': const FuncDesc('NUMSUM', false, 1, 999),
  'ODD': const FuncDesc('ODD', false, 1, 1),
  'ONLY': const FuncDesc('ONLY', true, 1, 1),
  'ORD': const FuncDesc('ORD', false, 1, 1),
  'OSUSER': const FuncDesc('OSUSER', false, 0, 0),
  'PEEK': const FuncDesc('PEEK', false, 1, 3),
  'PERMUT': const FuncDesc('PERMUT', false, 2, 2),
  'PI': const FuncDesc('PI', false, 0, 0),
  'PICK': const FuncDesc('PICK', false, 2, 999),
  'PMT': const FuncDesc('PMT', false, 3, 5),
  'POW': const FuncDesc('POW', false, 2, 2),
  'PREVIOUS': const FuncDesc('PREVIOUS', false, 1, 1),
  'PURGECHAR': const FuncDesc('PURGECHAR', false, 2, 2),
  'PV': const FuncDesc('PV', false, 3, 5),
  'QLIKTECHBLUE': const FuncDesc('QLIKTECHBLUE', false, 0, 0),
  'QLIKTECHGRAY': const FuncDesc('QLIKTECHGRAY', false, 0, 0),
  'QLIKVIEWVERSION': const FuncDesc('QLIKVIEWVERSION', false, 0, 0),
  'QUARTEREND': const FuncDesc('QUARTEREND', false, 1, 3),
  'QUARTERNAME': const FuncDesc('QUARTERNAME', false, 1, 3),
  'QUARTERSTART': const FuncDesc('QUARTERSTART', false, 1, 3),
  'QVDCREATETIME': const FuncDesc('QVDCREATETIME', false, 1, 1),
  'QVDFIELDNAME': const FuncDesc('QVDFIELDNAME', false, 2, 2),
  'QVDNOOFFIELDS': const FuncDesc('QVDNOOFFIELDS', false, 1, 1),
  'QVDNOOFRECORDS': const FuncDesc('QVDNOOFRECORDS', false, 1, 1),
  'QVDTABLENAME': const FuncDesc('QVDTABLENAME', false, 1, 1),
  'QVUSER': const FuncDesc('QVUSER', true, 0, 999),
  'RAND': const FuncDesc('RAND', false, 0, 0),
  'RANGEAVG': const FuncDesc('RANGEAVG', false, 1, 999),
  'RANGECORREL': const FuncDesc('RANGECORREL', false, 2, 999),
  'RANGECOUNT': const FuncDesc('RANGECOUNT', false, 1, 999),
  'RANGEFRACTILE': const FuncDesc('RANGEFRACTILE', false, 1, 999),
  'RANGEIRR': const FuncDesc('RANGEIRR', false, 1, 999),
  'RANGEKURTOSIS': const FuncDesc('RANGEKURTOSIS', false, 1, 999),
  'RANGEMAX': const FuncDesc('RANGEMAX', false, 1, 999),
  'RANGEMAXSTRING': const FuncDesc('RANGEMAXSTRING', false, 1, 999),
  'RANGEMIN': const FuncDesc('RANGEMIN', false, 1, 999),
  'RANGEMINSTRING': const FuncDesc('RANGEMINSTRING', false, 1, 999),
  'RANGEMISSINGCOUNT': const FuncDesc('RANGEMISSINGCOUNT', false, 1, 999),
  'RANGEMODE': const FuncDesc('RANGEMODE', false, 1, 999),
  'RANGENPV': const FuncDesc('RANGENPV', false, 1, 999),
  'RANGENULLCOUNT': const FuncDesc('RANGENULLCOUNT', false, 1, 999),
  'RANGENUMERICCOUNT': const FuncDesc('RANGENUMERICCOUNT', false, 1, 999),
  'RANGEONLY': const FuncDesc('RANGEONLY', false, 1, 999),
  'RANGESKEW': const FuncDesc('RANGESKEW', false, 1, 999),
  'RANGESTDEV': const FuncDesc('RANGESTDEV', false, 1, 999),
  'RANGESUM': const FuncDesc('RANGESUM', false, 1, 999),
  'RANGETEXTCOUNT': const FuncDesc('RANGETEXTCOUNT', false, 1, 999),
  'RANGEXIRR': const FuncDesc('RANGEXIRR', false, 1, 999),
  'RANGEXNPV': const FuncDesc('RANGEXNPV', false, 1, 999),
  'RANK': const FuncDesc('RANK', false, 1, 3, isTotalPossible: true),
  'RATE': const FuncDesc('RATE', false, 3, 5),
  'RECNO': const FuncDesc('RECNO', false, 0, 0),
  'RED': const FuncDesc('RED', false, 0, 1),
  'mage'
      'RELOADTIME': const FuncDesc('RELOADTIME', false, 0, 0),
  'REPEAT': const FuncDesc('REPEAT', false, 1, 1),
  'REPLACE': const FuncDesc('REPLACE', false, 3, 3),
  'REPORTCOMMENT': const FuncDesc('REPORTCOMMENT', false, 1, 1),
  'REPORTID': const FuncDesc('REPORTID', false, 1, 1),
  'REPORTNAME': const FuncDesc('REPORTNAME', false, 1, 1),
  'REPORTNUMBER': const FuncDesc('REPORTNUMBER', false, 1, 1),
  'RGB': const FuncDesc('RGB', false, 3, 3),
  'RIGHT': const FuncDesc('RIGHT', false, 2, 2),
  'ROUND': const FuncDesc('ROUND', false, 1, 3),
  'ROWNO': const FuncDesc('ROWNO', false, 0, 0, isTotalPossible: true),
  'RTRIM': const FuncDesc('RTRIM', false, 1, 1),
  'SECOND': const FuncDesc('SECOND', false, 1, 1),
  'SECONDARYDIMENSIONALITY':
      const FuncDesc('SECONDARYDIMENSIONALITY', false, 0, 0),
  'SETDATEYEAR': const FuncDesc('SETDATEYEAR', false, 2, 2),
  'SETDATEYEARMONTH': const FuncDesc('SETDATEYEARMONTH', false, 2, 3),
  'SIGN': const FuncDesc('SIGN', false, 1, 1),
  'SIN': const FuncDesc('SIN', true, 0, 999),
  'SINH': const FuncDesc('SINH', false, 1, 1),
  'SKEW': const FuncDesc('SKEW', true, 0, 999),
  'SQR': const FuncDesc('SQR', false, 1, 1),
  'SQRT': const FuncDesc('SQRT', false, 1, 1),
  'STDEV': const FuncDesc('STDEV', true, 0, 999),
  'STERR': const FuncDesc('STERR', true, 0, 999),
  'STEYX': const FuncDesc('STEYX', true, 0, 999),
  'SUBFIELD': const FuncDesc('SUBFIELD', false, 2, 3),
  'SUBSTRINGCOUNT': const FuncDesc('SUBSTRINGCOUNT', false, 2, 3),
  'SUM': const FuncDesc('SUM', true, 1, 1, isDistinctPossible: true),
  'SYSCOLOR': const FuncDesc('SYSCOLOR', false, 1, 1),
  'TABLENAME': const FuncDesc('TABLENAME', false, 1, 1),
  'TABLENUMBER': const FuncDesc('TABLENUMBER', false, 1, 1),
  'TAN': const FuncDesc('TAN', false, 1, 1),
  'TANH': const FuncDesc('TANH', false, 1, 1),
  'TDIST': const FuncDesc('TDIST', false, 3, 3),
  'TEXT': const FuncDesc('TEXT', false, 1, 1),
  'TEXTBETWEEN': const FuncDesc('TEXTBETWEEN', false, 3, 4),
  'TEXTCOUNT':
      const FuncDesc('TEXTCOUNT', true, 1, 1, isDistinctPossible: true),
  'TIME': const FuncDesc('TIME', false, 1, 2),
  'TIME#': const FuncDesc('TIME#', false, 1, 2),
  'TIMESTAMP': const FuncDesc('TIMESTAMP', false, 1, 2),
  'TIMESTAMP#': const FuncDesc('TIMESTAMP#', false, 1, 2),
  'TIMEZONE': const FuncDesc('TIMEZONE', false, 0, 0),
  'TINV': const FuncDesc('TINV', false, 2, 2),
  'TODAY': const FuncDesc('TODAY', false, 0, 1),
  'TOP': const FuncDesc('TOP', false, 1, 3, isTotalPossible: true),
  'TRIM': const FuncDesc('TRIM', false, 1, 1),
  'TRUE': const FuncDesc('TRUE', false, 0, 0),
  'TTEST1_CONF': const FuncDesc('TTEST1_CONF', true, 0, 999),
  'TTEST1_DF': const FuncDesc('TTEST1_DF', true, 0, 999),
  'TTEST1_DIF': const FuncDesc('TTEST1_DIF', true, 0, 999),
  'TTEST1_LOWER': const FuncDesc('TTEST1_LOWER', true, 0, 999),
  'TTEST1_SIG': const FuncDesc('TTEST1_SIG', true, 0, 999),
  'TTEST1_STERR': const FuncDesc('TTEST1_STERR', true, 0, 999),
  'TTEST1_T': const FuncDesc('TTEST1_T', true, 0, 999),
  'TTEST1_UPPER': const FuncDesc('TTEST1_UPPER', true, 0, 999),
  'TTEST1W_CONF': const FuncDesc('TTEST1W_CONF', true, 0, 999),
  'TTEST1W_DF': const FuncDesc('TTEST1W_DF', true, 0, 999),
  'TTEST1W_DIF': const FuncDesc('TTEST1W_DIF', true, 0, 999),
  'TTEST1W_LOWER': const FuncDesc('TTEST1W_LOWER', true, 0, 999),
  'TTEST1W_SIG': const FuncDesc('TTEST1W_SIG', true, 0, 999),
  'TTEST1W_STERR': const FuncDesc('TTEST1W_STERR', true, 0, 999),
  'TTEST1W_T': const FuncDesc('TTEST1W_T', true, 0, 999),
  'TTEST1W_UPPER': const FuncDesc('TTEST1W_UPPER', true, 0, 999),
  'TTEST_CONF': const FuncDesc('TTEST_CONF', true, 0, 999),
  'TTEST_DF': const FuncDesc('TTEST_DF', true, 0, 999),
  'TTEST_DIF': const FuncDesc('TTEST_DIF', true, 0, 999),
  'TTEST_LOWER': const FuncDesc('TTEST_LOWER', true, 0, 999),
  'TTEST_SIG': const FuncDesc('TTEST_SIG', true, 0, 999),
  'TTEST_STERR': const FuncDesc('TTEST_STERR', true, 0, 999),
  'TTEST_T': const FuncDesc('TTEST_T', true, 0, 999),
  'TTEST_UPPER': const FuncDesc('TTEST_UPPER', true, 0, 999),
  'TTESTW_CONF': const FuncDesc('TTESTW_CONF', true, 0, 999),
  'TTESTW_DF': const FuncDesc('TTESTW_DF', true, 0, 999),
  'TTESTW_DIF': const FuncDesc('TTESTW_DIF', true, 0, 999),
  'TTESTW_LOWER': const FuncDesc('TTESTW_LOWER', true, 0, 999),
  'TTESTW_SIG': const FuncDesc('TTESTW_SIG', true, 0, 999),
  'TTESTW_STERR': const FuncDesc('TTESTW_STERR', true, 0, 999),
  'TTESTW_T': const FuncDesc('TTESTW_T', true, 0, 999),
  'TTESTW_UPPER': const FuncDesc('TTESTW_UPPER', true, 0, 999),
  'UPPER': const FuncDesc('UPPER', false, 1, 1),
  'UTC': const FuncDesc('UTC', false, 0, 0),
  'VRANK': const FuncDesc('VRANK', false, 1, 3, isTotalPossible: true),
  'WEEK': const FuncDesc('WEEK', false, 1, 1),
  'WEEKDAY': const FuncDesc('WEEKDAY', false, 1, 1),
  'WEEKEND': const FuncDesc('WEEKEND', false, 1, 3),
  'WEEKNAME': const FuncDesc('WEEKNAME', false, 1, 3),
  'WEEKSTART': const FuncDesc('WEEKSTART', false, 1, 3),
  'WEEKYEAR': const FuncDesc('WEEKYEAR', false, 1, 1),
  'WHITE': const FuncDesc('WHITE', false, 0, 1),
  'WILDMATCH': const FuncDesc('WILDMATCH', false, 2, 999),
  'WILDMATCH5': const FuncDesc('WILDMATCH5', true, 0, 999),
  'XIRR': const FuncDesc('XIRR', true, 0, 999),
  'XNPV': const FuncDesc('XNPV', true, 0, 999),
  'YEAR': const FuncDesc('YEAR', false, 1, 1),
  'YEAR2DATE': const FuncDesc('YEAR2DATE', true, 0, 999),
  'YEAREND': const FuncDesc('YEAREND', false, 1, 3),
  'YEARNAME': const FuncDesc('YEARNAME', false, 1, 3),
  'YEARSTART': const FuncDesc('YEARSTART', false, 1, 3),
  'YEARTODATE': const FuncDesc('YEARTODATE', false, 1, 4),
  'YELLOW': const FuncDesc('YELLOW', false, 0, 1),
  'ZTEST_CONF': const FuncDesc('ZTEST_CONF', true, 0, 999),
  'ZTEST_DIF': const FuncDesc('ZTEST_DIF', true, 0, 999),
  'ZTEST_LOWER': const FuncDesc('ZTEST_LOWER', true, 0, 999),
  'ZTEST_SIG': const FuncDesc('ZTEST_SIG', true, 0, 999),
  'ZTEST_STERR': const FuncDesc('ZTEST_STERR', true, 0, 999),
  'ZTEST_UPPER': const FuncDesc('ZTEST_UPPER', true, 0, 999),
  'ZTEST_Z': const FuncDesc('ZTEST_Z', true, 0, 999),
  'ZTESTW_CONF': const FuncDesc('ZTESTW_CONF', true, 0, 999),
  'ZTESTW_DIF': const FuncDesc('ZTESTW_DIF', true, 0, 999),
  'ZTESTW_LOWER': const FuncDesc('ZTESTW_LOWER', true, 0, 999),
  'ZTESTW_SIG': const FuncDesc('ZTESTW_SIG', true, 0, 999),
  'ZTESTW_STERR': const FuncDesc('ZTESTW_STERR', true, 0, 999),
  'ZTESTW_UPPER': const FuncDesc('ZTESTW_UPPER', true, 0, 999),
  'ZTESTW_Z': const FuncDesc('ZTESTW_UPPER', true, 0, 999),
  // FILTER SPECIFIERS
  'FILTERS': const FuncDesc('FILTERS', false, 0, 999),
  'REMOVE': const FuncDesc('REMOVE', false, 0, 999),
  'ROWCND': const FuncDesc('ROWCND', false, 0, 999),
  'STRCND': const FuncDesc('STRCND', false, 0, 999),
  'POS': const FuncDesc('POS', false, 0, 999),
  'COLXTR': const FuncDesc('COLXTR', false, 0, 999),
  'UNWRAP': const FuncDesc('UNWRAP', false, 0, 999),
  'ROTATE': const FuncDesc('ROTATE', false, 0, 999),
  'TRANSPOSE': const FuncDesc('TRANSPOSE', false, 0, 999),
  'SELECT': const FuncDesc('SELECT', false, 0, 999)
};
