part of qvs_parser;

class FuncDesc {
  final String name;
  final bool isSetExpressionPossible;
  final int minCardinality;
  final int maxCardinality;
  final bool isDistinctPossible;
  final bool isTotalPossible;
  const FuncDesc(this.name,this.isSetExpressionPossible,this.minCardinality,this.maxCardinality,{this.isDistinctPossible: false, this.isTotalPossible:false});
}


class QvsGrammar extends CompositeParser {
//  void def(String name, Parser parser) {
//    print('def($name');
//    super.def(name,parser);
//  }
  void initialize() {
    _whitespace();
    _number();
    _setExpression();
    _qv();
    _expression();
    _qvs();
  }
  void _qvs() {
    def(p.start, ref(p.command).plus().end().flatten());
    def(p.command,
        ref(p.whenClause).optional().seq(
        ref(p.sqlTables)
        .or(ref(p.load))
        .or(ref(p.controlStatement))
        .or(ref(p.call))
        .or(ref(p.sleep))
        .or(ref(p.switchStatement))
        .or(ref(p.defaultStatement))
        .or(ref(p.caseStatement))
        .or(ref(p.dropFields))
        .or(ref(p.dropTable))
        .or(ref(p.renameTable))
        .or(ref(p.renameField))
        .or(ref(p.qualify))
        .or(ref(p.alias))
        .or(ref(p.binaryStatement))
        .or(ref(p.storeTable)) 
        .or(ref(p.commentWith))
        .or(ref(p.trace))
        .or(ref(p.execute))
        .or(ref(p.sqltables))
        .or(ref(p.directory))
        .or(ref(p.doWhile))
        .or(ref(p.includeDirective))
        .or(ref(p.connect))
        .or(ref(p.disconnect))
        .or(ref(p.assignment))));
    def(p.renameTable,
        _keyword('RENAME')
        .seq(_keyword('TABLE'))
        .seq(ref(p.fieldref))
        .seq(_keyword('TO'))
        .seq(ref(p.fieldref))
        .seq(char(';'))
        .trim(trimmer));
    def(p.renameField,
        _keyword('RENAME')
        .seq(_keyword('FIELD'))
        .seq(ref(p.fieldref))
        .seq(_keyword('TO'))
        .seq(ref(p.fieldref))
        .seq(char(';'))
        .trim(trimmer).flatten());
    def(p.fieldref,
          _keyword(ref(p.identifier)
          .or(ref(p.fieldrefInBrackets))
          .or(ref(p.str)).trim(trimmer)
          ));
    def(p.load,
        ref(p.tableDesignator).optional()
        .seq(ref(p.loadPerfix).star())
        .seq(_keyword('MAPPING').optional())
        .seq(ref(p.preloadFunc).optional())
        .seq(_keyword('LOAD').or(_keyword('SQL').optional().seq(_keyword('SELECT'))))
        .seq(_keyword('DISTINCT').optional())
        .seq(ref(p.selectList).trim(trimmer))
        .seq(ref(p.loadSource).or(ref(p.whereClause)).optional().trim(trimmer))
        .seq(char(';'))
          .trim(trimmer));
    def(p.loadPerfix,
      _keyword('NOCONCATENATE')
      .or(_word('BUFFER').seq(ref(p.bufferModifier).optional()))
      .or(_word('BUNDLE').seq(_word('INFO').optional()))
      .or(_word('ADD').seq(_word('ONLY').optional())));
    def(p.sleep,
      _keyword('SLEEP').
       seq(ref(p.integer).trim(trimmer)).
       seq(_keyword(';')));
    def(p.bufferModifier,
        _keyword('(')
        .seq(
          _keyword('INCREMENTAL')
          .or(
              _keyword('STALE')
              .seq(_keyword('AFTER').optional())
              .seq(ref(p.number))
              .seq(_keyword('DAYS').or(_keyword('HOURS')).optional())))
        .seq(_keyword(')')));
    def(p.loadSource,
        ref(p.loadSourceAutogenerate)
        .or(ref(p.loadSourceInline))
        .or(ref(p.loadSourceStandart)));
    def(p.loadSourceStandart,
        _keyword('RESIDENT').or(_keyword('FROM'))
        .seq(ref(p.tableOrFilename))
        .seq(ref(p.whereClause).optional())
        .seq(ref(p.groupBy).optional())
        .seq(ref(p.orderBy).optional())
        );
    def(p.loadSourceInline,
          _keyword('INLINE')
          .seq(_keyword('['))
          .seq(_keyword(']').neg().plus())
          .seq(_keyword(']')));
    def(p.loadSourceAutogenerate,
        _keyword('autogenerate')
        .seq(ref(p.expression))
        .seq(ref(p.whereClause).optional())
        .seq(ref(p.whileClause).optional()));
    def(p.from,
        _keyword('FROM')
        .seq(ref(p.fieldref)));
    def(p.dropFields,
        _word('DROP')
        .seq(_word('FIELDS').or(_word('FIELD')))
        .seq(ref(p.fieldrefs))
        .seq(ref(p.from).optional())
        .seq(char(';'))
        .trim(trimmer).flatten());
    def(p.dropTable,
        _keyword('DROP')
        .seq(_keyword('TABLE'))
        .seq(_keyword('S').or(_keyword('s')).optional())
        .seq(ref(p.fieldrefs))
        .seq(char(';'))
        .trim(trimmer));
    def(p.storeTable,
        _keyword('STORE')
        .seq(ref(p.selectList).seq(_keyword('FROM')).optional())
        .seq(ref(p.fieldref))
        .seq(_keyword('INTO'))
        .seq(ref(p.tableOrFilename))
        .seq(ref(p.whereClause).optional())
        .seq(char(';'))
        .trim(trimmer).flatten());
    
    def(p.selectList,
        ref(p.fieldrefAs).or(_keyword('*')).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.trimFromStart,
        trim(trimmer));
//    def(p.field,
//        ref(p.expression).seq(_keyword('as')).seq(ref(p.fieldref))
//        .or(ref(p.expression))
//        .trim(trimmer).flatten());
    def(p.commentWith,
        _word('COMMENT').or(_word('TAG')).or(_word('UNTAG'))
        .seq(_word('FIELD').or(_word('FIELDS')))
        .seq(ref(p.fieldrefs))
        .seq(_word('WITH'))
        .seq(ref(p.str).or(char(';').not().plus()))
        .seq(char(';')).trim(trimmer).flatten()
        );
    def(p.doWhile,
        _keyword('DO').or(_keyword('LOOP'))
        .seq(_keyword('WHILE').or(_keyword('UNTIL')).seq(ref(p.expression)).optional())
        .seq(char(';').optional()).trim(trimmer)
        );
    def(p.stringOrNotSemicolon,
        ref(p.str)
        .or(char(';').neg()).starLazy(char(';')).flatten()
        );
    def(p.join,
        _keyword('LEFT').or(_keyword('RIGHT')).or(_keyword('INNER')).optional()
        .seq(_keyword('JOIN').or(_keyword('KEEP')))
        .seq(ref(p.tableInParens).optional()));
    def(p.preloadFunc,
        _keyword('Hierarchy')
          .or(_keyword('HierarchyBelongsTo'))
          .or(_keyword('IntervalMatch'))
          .or(_keyword('CrossTable'))
        .seq(ref(p.simpleParens))
        .or(_word('FIRST')
            .seq(ref(p.expression))));
    def(p.whileClause,
        _keyword('while')
        .seq(ref(p.expression))
        .flatten());
    def(p.subDeclaration,
          ref(p.varName)
          .seq(_keyword('(')
            .seq(ref(p.params))
            .seq(_keyword(')')).optional()));

    def(p.concatenate,
        _keyword('concatenate')
        .seq(ref(p.tableInParens).optional()));
    def(p.tableInParens,
        _keyword('(')
        .seq(ref(p.fieldref))
        .seq(_keyword(')'))
        );
    def(p.groupBy,
        _keyword('GROUP')
        .seq(_keyword('BY'))
        .seq(ref(p.params))
        );
    def(p.orderBy,
        _keyword('ORDER')
        .seq(_keyword('BY'))
        .seq(ref(p.fieldrefsOrderBy))
        );

    def(p.fieldrefs,
        ref(p.fieldref).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.fieldrefsOrderBy,
        ref(p.fieldrefOrderBy).separatedBy(char(',').trim(trimmer), includeSeparators: false));

    def(p.fieldrefOrderBy,
        ref(p.identifier)
        .or(ref(p.fieldrefInBrackets))
        .seq(_keyword('DESC').or(_keyword('ASC')).optional()));
    def(p.tableDesignator,
        ref(p.tableIdentifier)
        .or(ref(p.join))
        .or(ref(p.concatenate)).plus()
        .trim(trimmer)
        );
    def(p.tableIdentifier,
      ref(p.fieldref).seq(char(':').trim(trimmer))
    );
    def(p.params,
        ref(p.expression).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.paramsOptional,
        ref(p.expression).optional().separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.parens,
        char('(').trim(trimmer)
            .seq(ref(p.expression))
            .seq(char(')').trim(trimmer)).flatten());
    def(p.tableOrFilename,
        word().or(anyIn(r'./\:?*').or(localLetter())).plus()
        .or(ref(p.fieldrefInBrackets))
        .or(ref(p.str))
        .seq(ref(p.fileModifier).or(ref(p.tableSelectModifier)).optional())
        .trim(trimmer));
    def(p.includeDirective,
        _keyword(r'$(').
        seq(_keyword('must_').optional()).
        seq(_keyword('include=')).
        seq(ref(p.tableOrFilename).trim(trimmer)).
        seq(_keyword(')')).
        seq(_keyword(';').optional()).trim(trimmer)
        );
    def(p.whereClause,
        _keyword('where').or(_keyword('while')).trim(trimmer)
        .seq(ref(p.expression))
        .trim(trimmer));
    def(p.whenClause,
        _keyword('when').or(_keyword('unless'))
        .seq(ref(p.expression))
        .trim(trimmer));

    def(p.letAssignment,
        _keyword('LET').optional()
        .seq(ref(p.identifier).or(ref(p.fieldrefInBrackets)))
        .seq(char('=').trim(trimmer))
        .seq(ref(p.expression).trim(trimmer).optional())
        .seq(char(';').trim(trimmer))
    );
    def(p.setAssignment,
        _keyword('SET')
        .seq(ref(p.identifier).or(ref(p.fieldrefInBrackets)))
        .seq(char('=').trim(trimmer))
        .seq(ref(p.stringOrNotSemicolon))
        .seq(char(';').trim(trimmer))
        );
    def(p.assignment,
        ref(p.setAssignment)
        .or(ref(p.letAssignment))
        );
    def(p.sqlTables,
        ref(p.tableDesignator)
        .seq(_keyword('SQLTABLES'))
        .seq(_keyword(';'))
        );

    def(p.call,
        _word('call').trim(trimmer)
        .seq(word().or(char('.')).plus().trim(trimmer).flatten())
                    .seq(char('(').trim(trimmer)
                    .seq(ref(p.params).plus())
                    .seq(char(')').trim(trimmer)).optional())
        .seq(_keyword(';').optional()).trim(trimmer)
        );
    def(p.simpleParens,
        char("(")
        .seq(char(")").neg().star())
        .seq(char(")")).trim(trimmer).flatten());
    def(p.fileModifierTokens,
        _keyword('embedded labels')
        .or(_keyword('ooxml'))
        .or(_keyword('explicit labels'))
        .or(_keyword('no')
            .seq(_keyword('quotes').
                or(_keyword('labels')).
                or(_keyword('eof'))))
        .or(_keyword('codepage is')
            .seq(ref(p.decimalInteger).plus())
            .or(_keyword('unicode'))
            .or(_keyword('ansi'))
            .or(_keyword('oem'))
            .or(_keyword('mac'))
            .or(_keyword('UTF').seq(char('-').optional().seq(char('8')))))
        .or(_keyword('table is')
            .seq(ref(p.fieldref)
                  .or(ref(p.number))
                  .or(ref(p.str))))
        .or(_keyword('header').or(_keyword('record'))
            .seq(_keyword('is'))
            .seq(ref(p.decimalInteger))
            .seq(_keyword('lines')))
        .or(_keyword('delimiter is').seq(ref(p.str)))
        .flatten());
    def(p.fileModifierElement,
        ref(p.fileModifierTokens)
        .or(ref(p.expression)));
    def(p.fileModifierElements,
        ref(p.fileModifierElement).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.fileModifier,
        _keyword('(')
         .seq(ref(p.fileModifierElements))
         .seq(_keyword(')')));
    def(p.tableSelectModifier,
        _keyword('WITH')
         .seq(_keyword('('))
         .seq(word().plus().trim(trimmer))
         .seq(_keyword(')')));
    def(p.connect,
        _keyword('ODBC').or(_keyword('OLEDB')).or(_keyword('CUSTOM')).optional()
        .seq(_keyword('CONNECT64').or(_keyword('CONNECT32')).or(_keyword('CONNECT')))
        .seq(_keyword('TO'))
        .seq(ref(p.str).or(ref(p.fieldrefInBrackets)))
        .seq(ref(p.simpleParens).optional())
        .seq(_keyword(';'))
        );
    def(p.controlStatement,
        ref(p.subStart)
        .or(ref(p.exitScript))
        .or(ref(p.forNextStart))
        .or(ref(p.forEachFileMaskStart))
        .or(ref(p.forEachStart))
        .or(ref(p.ifStart))
        .or(_keyword('ELSE'))
        .or(ref(p.controlStatementFinish)));
    def(p.controlStatementFinish,
        _keyword('END')
          .seq(_keyword('SUB').
            or(_keyword('SWITCH')).  
            or(_keyword('IF')))
        .or(_keyword('NEXT')
          .seq(ref(p.identifier).optional()))
        .seq(_keyword(';').optional()));
    def(p.subStart,
        _keyword('SUB')
        .seq(ref(p.subDeclaration))
        .seq(_keyword(';').optional()));
    def(p.exitScript,
    _keyword('exit')
    .seq(_keyword('script').
        or(_keyword('sub')).
        or(_keyword('for')).
        or(_keyword('do')))
    .seq(ref(p.whenClause).optional())
    .seq(_keyword(';').optional()));
    def(p.forNextStart,
        _keyword('FOR')
        .seq(ref(p.identifier))
        .seq(_keyword('='))
        .seq(ref(p.expression))
        .seq(_keyword('to'))
        .seq(ref(p.expression))
        .seq(_keyword('STEP').seq(ref(p.expression)).optional())
        .seq(_keyword(';').optional()));
    def(p.ifStart,
        _keyword('IF').or(_keyword('ELSEIF'))
        .seq(ref(p.expression))
        .seq(_keyword('THEN'))
        .seq(_keyword(';').optional()));
    def(p.forEachStart,
        _word('FOR')
        .seq(_word('each'))
        .seq(ref(p.identifier))
        .seq(_word('in'))
        .seq(ref(p.params))
        .seq(_keyword(';').optional()));
    def(p.forEachFileMaskStart,
        _word('FOR')
        .seq(_word('each'))
        .seq(ref(p.identifier))
        .seq(_word('in'))
        .seq(_keyword('filelist').or(_keyword('dirlist')))
        .seq(_keyword('('))
        .seq(ref(p.expression))
        .seq(_keyword(')'))
        .seq(_keyword(';').optional()));
    def(p.qualify,
        _keyword('UNQUALIFY').or(_keyword('QUALIFY'))
        .seq(ref(p.fieldrefOrStringList).or(_keyword('*')))
        .seq(_keyword(';')).flatten());
    
    def(p.fieldrefOrStringList,
        ref(p.fieldrefOrString).separatedBy(char(',').trim(trimmer), includeSeparators: false));

    def(p.fieldrefOrString,
        ref(p.identifier)
        .or(ref(p.fieldrefInBrackets))
        .or(ref(p.str)));
    def(p.fieldrefAs,
      ref(p.expression)
            .seq(_keyword('as')).
            seq(ref(p.fieldref)).
          or(ref(p.expression)));
    def(p.fieldrefsAs,
      ref(p.fieldrefAs).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.alias,
      _keyword('ALIAS')
      .seq(ref(p.fieldrefsAs))
      .seq(_keyword(';')));
    def(p.binaryStatement,
    _keyword('binary')
    .seq(ref(p.tableOrFilename))
    .seq(_keyword(';')));
   def(p.trace,
     _word('TRACE')
     .seq(char(';').neg().plus())
     .seq(_keyword(';'))
   );
   def(p.execute,
     _word('EXECUTE')
     .seq(char(';').neg().plus())
     .seq(_keyword(';'))
   );
   def(p.sqltables,
     _keyword('SQLTABLES')
     .seq(_keyword(';'))
   );
   def(p.defaultStatement,
     _keyword('default')
     .seq(_keyword(';').optional())
   );
   def(p.caseStatement,
     _keyword('case')
     .seq(ref(p.expression))
     .seq(_keyword(';').optional())
   );

   def(p.switchStatement,
     _keyword('switch')
     .seq(ref(p.expression))
     .seq(_keyword(';').optional())
   );

   def(p.directory,
     _keyword('DIRECTORY')
     .seq(char(';').neg().star())
     .seq(_keyword(';'))
   );
   def(p.disconnect,
     _keyword('disconnect')
     .seq(_keyword(';'))
   );

   
  }
  
  void _setExpression() {
    def(p.setExpression,
      _keyword('{').
      seq(ref(p.setEntity)).
      seq(_keyword('}')));
    def(p.setEntity,
      ref(p.setEntityPrimary).separatedBy(ref(p.setOperator), includeSeparators: true));
    def(p.setEntitySimple,
      ref(p.setIdentifier).
      seq(ref(p.setModifier).optional()).
      or(ref(p.setModifier)));
    def(p.setEntityPrimary,
      ref(p.setEntitySimple).or(ref(p.setEntityInParens)));
    def(p.setEntityInParens, _keyword('(').seq(ref(p.setEntity)).seq(_keyword(')')));
    def(p.setIdentifier,
      _keyword(r'$').seq(_keyword('_').optional()).seq(ref(p.integer)).
      or(_keyword('1')).
      or(_keyword(r'$')).
      or(ref(p.identifier)).
      or(ref(p.fieldrefInBrackets)));
    def(p.setOperator,
      _keyword(r'+').
      or(_keyword(r'-')).
      or(_keyword(r'*')).
      or(_keyword(r'/')));
    def(p.setElement,
      ref(p.number).
      or(ref(p.str)).
      or(ref(p.macroExpression)).
      or(ref(p.identifier)));
    def(p.setElementList,
        ref(p.setElement).separatedBy(_keyword(','), includeSeparators: false));
    def(p.setElementSet,
      ref(p.setElementFunction).
      or(ref(p.identifier)).
      or(_keyword('{').seq(ref(p.setElementList).optional()).seq(_keyword('}'))));
    def(p.setElementSetInParens, _keyword('(').seq(ref(p.setElementSetExpression)).seq(_keyword(')')));
    def(p.setElementSetPrimary,
      ref(p.setElementSet).or(ref(p.setElementSetInParens)));
    def(p.setElementSetExpression,
      ref(p.setElementSetPrimary).separatedBy(ref(p.setOperator), includeSeparators: true));

    def(p.setFieldSelection,
      ref(p.fieldName).
      seq(_keyword('=').
          or(_keyword('-=')).
          or(_keyword('+=')).
          or(_keyword('*=')).
          or(_keyword('/='))).
      seq(ref(p.setElementSetExpression).optional()).
      or(ref(p.fieldName)));
    def(p.setModifier,
      _keyword('<').
      seq(ref(p.setFieldSelection).separatedBy(_keyword(','), includeSeparators: false)).
      seq(_keyword('>')));
    def(p.setElementFunction,
      _keyword('P').or(_keyword('E')).
      seq(_keyword('(')).
      seq(ref(p.setExpression)).
      seq(ref(p.fieldName).optional()).
      seq(_keyword(')')));
    
  }

  /**
   * Russian letters
   */
  localLetter() => range(1024,1273);
  Parser get trimmer => ref(p.whitespace);
  void _qv() {
//    def(p.start, ref(p.expression).end().flatten());
//    def(p.stringOrNotSemicolon,
//        ref(p.str)
//        .or(char(';').neg()).starLazy(char(';')).flatten()
//        );
//    def(p.params,
//        ref(p.expression).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.totalClause,
        _keyword('TOTAL')
        .seq(ref(p.totalModifier).optional()));
    def(p.distinctClause,
        _keyword('NODISTINCT')
        .or(_keyword('DISTINCT')));
    def(p.totalModifier,
        _keyword('<')
        .seq(ref(p.fieldName).separatedBy(char(',').trim(trimmer), includeSeparators: false))
        .seq(_keyword('>')));
    def(p.functionModifier,
        ref(p.distinctClause)
        .or(ref(p.totalClause)
        .or(ref(p.setExpression))));
  }
  
  
  /** Defines the whitespace and comments. */
  void _whitespace() {
    
    def(p.whitespace, whitespace()
      .or(ref(p.singeLineComment))
      .or(ref(p.remComment))
      .or(ref(p.multiLineComment)));
    def(p.singeLineComment, string('//')
      .seq(Token.newlineParser().neg().star()));
    def(p.remComment, string('REM')
      .seq(Token.newlineParser().neg().star()));
    def(p.multiLineComment, string('/*')
      .seq(string('*/').neg().star())
      .seq(string('*/')));
  }
 
  _expression() {
    def(p.expression,
        string(r'$($(=').
        seq(ref(p.binaryExpression)).
        seq(_keyword(')').seq(_keyword(')'))).
        or(ref(p.macroExpression)).
        or(ref(p.binaryExpression).trim(trimmer))
        );
    def(p.macroExpression,
        string(r'$(=').
        seq(ref(p.binaryExpression)).
        seq(_keyword(')'))
        );
    
    def(p.primaryExpression,
        ref(p.str)
        .or(ref(p.unaryExpression))
        .or(ref(p.macroFunction))
        .or(ref(p.function))
        .or(ref(p.number))
        .or(ref(p.fieldName))
        .or(ref(p.parens)));
    def(p.binaryExpression, ref(p.primaryExpression)
        .seq(ref(p.binaryPart).star()).trim(trimmer).flatten());
    def(p.binaryPart, ref(p.binaryOperator)
        .seq(ref(p.primaryExpression)));
    def(p.fieldName,
          _keyword(ref(p.identifier)
          .or(ref(p.fieldrefInBrackets))));
    def(p.identifier,letter().or(anyIn(r'_%@$').or(localLetter()))
        .seq(word().or(anyIn('.%')).or(char('_')).or(localLetter().or(char(r'$'))).plus())
        .or(letter())
//        .seq(whitespace().star().seq(char('(')).not())
        .flatten().trim(trimmer));
    def(p.varName,
        word()
          .or(localLetter())
          .or(anyIn(r'._$#@'))
            .plus().flatten().trim(trimmer)
        );
    def(p.fieldrefInBrackets, _keyword('[')
        .seq(_keyword(']').neg().plus())
        .seq(_keyword(']')).trim(trimmer).flatten());
    def(p.str,
            char("'")
              .seq(char("'").neg().star())
              .seq(char("'"))
            .or(char('"')
                .seq(char('"').neg().star())
                .seq(char('"'))).flatten());
   
    def(p.constant,
        ref(p.number).or(ref(p.str)));
    def(p.function,
        letter()
        .seq(word().or(char('#')).plus()).flatten()
        .trim(trimmer)
        .seq(char('(').trim(trimmer))
        .seq(ref(p.functionModifier).optional())
        .seq(ref(p.functionModifier).optional())
        .seq(ref(p.functionModifier).optional())
        .seq(ref(p.params).optional())
        .seq(char(')').trim(trimmer)));
    def(p.userFunction,
        word().or(anyIn('._#')).plus().flatten()
        .trim(trimmer)
        .seq(char('(').trim(trimmer))
        .seq(ref(p.paramsOptional).optional())
        .seq(char(')').trim(trimmer)));
    def(p.macroFunction,
            _keyword(r'$(')
                .seq(ref(p.userFunction))
                .seq(_keyword(')').trim(trimmer)));
    def(p.unaryExpression,
        _word('NOT').or(_keyword('-')).trim(trimmer)
            .seq(ref(p.expression))
            .trim(trimmer).flatten());
    def(p.binaryOperator,
        _word('and')
        .or(_word('or'))
        .or(_word('xor'))
        .or(_word('like'))
        .or(_keyword('<='))
        .or(_keyword('<>'))
        .or(_keyword('!='))
        .or(_keyword('>='))
        .or(anyIn('+-/*<>=&'))
        .or(_word('precedes'))
        .trim(trimmer).flatten()
        );
  }
  
  /** Defines a token parser that ignore case and consumes whitespace. */
  Parser _keyword(dynamic input) {
    var parser = input is Parser ? input :
        input.length == 1 ? char(input) :
        stringIgnoreCase(input);
    return parser.trim(trimmer);
  }
 
  Parser _word(dynamic input) {
    var parser = input is Parser ? input :
        input.length == 1 ? char(input) :
        stringIgnoreCase(input);
    return parser.seq(ref(p.whitespace)).trim(trimmer);
  }
 
  
  void _number() {
    // Implementation borrowed from Smalltalk parser
    def(p.number, char('-').optional()
        .seq(ref(p.positiveNumber)).flatten());
    def(p.positiveNumber, ref(p.scaledDecimal)
        .or(ref(p.float))
        .or(char('.').seq(ref(p.digits)))
        .or(ref(p.integer)));

    def(p.integer, ref(p.radixInteger)
        .or(ref(p.decimalInteger)));
    def(p.decimalInteger, ref(p.digits));
    def(p.digits, digit().plus());
    def(p.radixInteger, ref(p.radixSpecifier)
        .seq(char('r'))
        .seq(ref(p.radixDigits)));
    def(p.radixSpecifier, ref(p.digits));
    def(p.radixDigits, pattern('0-9A-Z').plus());

    def(p.float, ref(p.mantissa)
        .seq(ref(p.exponentLetter)
            .seq(ref(p.exponent))
            .optional()));
    def(p.mantissa, ref(p.digits)
        .seq(char('.'))
        .seq(ref(p.digits)));
    def(p.exponent, char('-')
        .seq(ref(p.decimalInteger)));
    def(p.exponentLetter, pattern('edq'));

    def(p.scaledDecimal, ref(p.scaledMantissa)
        .seq(char('s'))
        .seq(ref(p.fractionalDigits).optional()));
    def(p.scaledMantissa, ref(p.decimalInteger)
        .or(ref(p.mantissa)));
    def(p.fractionalDigits, ref(p.decimalInteger));
  }

}


const Map<String, FuncDesc> BUILT_IN_FUNCTIONS = const <String, FuncDesc>{
  'ABOVE':const FuncDesc('ABOVE',false,1,3,isTotalPossible:true),
  'AFTER':const FuncDesc('AFTER',false,1,3,isTotalPossible:true),
  'ACOS':const FuncDesc('ACOS',false,1,1),
  'ADDMONTHS':const FuncDesc('ADDMONTHS',false,2,3),
  'ADDYEARS':const FuncDesc('ADDYEARS',true,0,999),
  'AGE':const FuncDesc('AGE',false,2,2),
  'AGGR':const FuncDesc('AGGR',true,2,999),
  'ALT':const FuncDesc('ALT',false,2,999),
  'APPLYCODEPAGE':const FuncDesc('APPLYCODEPAGE',false,2,2),
  'APPLYMAP':const FuncDesc('APPLYMAP',false,2,3),
  'ARGB':const FuncDesc('ARGB',false,4,4),
  'ASIN':const FuncDesc('ASIN',false,1,1),
  'ATAN':const FuncDesc('ATAN',false,1,1),
  'ATAN2':const FuncDesc('ATAN2',false,2,2),
  'ATTRIBUTE':const FuncDesc('ATTRIBUTE',false,2,2),
  'AUTHOR':const FuncDesc('AUTHOR',true,0,999),
  'AUTONUMBER':const FuncDesc('AUTONUMBER',false,1,2),
  'AUTONUMBERHASH128':const FuncDesc('AUTONUMBERHASH128',false,1,999),
  'AUTONUMBERHASH256':const FuncDesc('AUTONUMBERHASH256',false,1,999),
  'AVG':const FuncDesc('AVG',true,1,1),
  'BEFORE':const FuncDesc('BEFORE',false,1,3,isTotalPossible:true), 
  'BELOW':const FuncDesc('BELOW',false,1,3,isTotalPossible:true),
  'BITCOUNT':const FuncDesc('BITCOUNT',false,1,1),
  'BLACK':const FuncDesc('BLACK',false,0,1),
  'BLACKANDSCHOLE':const FuncDesc('BLACKANDSCHOLE',false,6,6),
  'BLUE':const FuncDesc('BLUE',false,0,1),
  'BOTTOM':const FuncDesc('BOTTOM',false,1,3,isTotalPossible:true),  
  'BROWN':const FuncDesc('BROWN',false,0,1),
  'CAPITALIZE':const FuncDesc('CAPITALIZE',false,1,1),
  'CEIL':const FuncDesc('CEIL',false,1,3),
  'CHI2TEST_CHI2':const FuncDesc('CHI2TEST_CHI2',true,0,999),
  'CHI2TEST_DF':const FuncDesc('CHI2TEST_DF',true,0,999),
  'CHI2TEST_P':const FuncDesc('CHI2TEST_P',true,0,999),
  'CHIDIST':const FuncDesc('CHIDIST',false,2,2),
  'CHIINV':const FuncDesc('CHIINV',false,2,2),
  'CHR':const FuncDesc('CHR',false,1,1),
  'CLASS':const FuncDesc('CLASS',false,2,4),
  'CLIENTPLATFORM':const FuncDesc('CLIENTPLATFORM',false,0,0),
  'COLOR':const FuncDesc('COLOR',false,1,2),
  'COLORMAPHUE':const FuncDesc('COLORMAPHUE',true,0,999),
  'COLORMAPJET':const FuncDesc('COLORMAPJET',true,0,999),
  'COLORMIX1':const FuncDesc('COLORMIX1',false,3,3),
  'COLORMIX2':const FuncDesc('COLORMIX2',false,3,4),
  'COLUMN':const FuncDesc('COLUMN',false,1,1),
  'COLUMNNO':const FuncDesc('COLUMNNO',false,0,0,isTotalPossible:true),
  'COMBIN':const FuncDesc('COMBIN',false,2,2),
  'COMPUTERNAME':const FuncDesc('COMPUTERNAME',false,0,0),
  'CONCAT':const FuncDesc('CONCAT',true,1,3,isDistinctPossible:true),
  'CONNECTSTRING':const FuncDesc('CONNECTSTRING',false,0,0),
  'CONVERTTOLOCALTIME':const FuncDesc('CONVERTTOLOCALTIME',false,1,3),
  'CORREL':const FuncDesc('CORREL',true,0,999),
  'COS':const FuncDesc('COS',false,1,1),
  'COSH':const FuncDesc('COSH',false,1,1),
  'COUNT':const FuncDesc('COUNT',true,1,1,isDistinctPossible:true),
  'CYAN':const FuncDesc('CYAN',false,0,1),
  'DARKGRAY':const FuncDesc('DARKGRAY',false,0,1),
  'DATE#':const FuncDesc('DATE#',false,1,2),
  'DATE':const FuncDesc('DATE',false,1,2),
  'DAY':const FuncDesc('DAY',false,1,1),
  'DAYEND':const FuncDesc('DAYEND',false,1,3),
  'DAYLIGHTSAVING':const FuncDesc('DAYLIGHTSAVING',false,0,0),
  'DAYNAME':const FuncDesc('DAYNAME',false,1,3),
  'DAYNUMBEROFQUARTER':const FuncDesc('DAYNUMBEROFQUARTER',false,1,2),
  'DAYNUMBEROFYEAR':const FuncDesc('DAYNUMBEROFYEAR',false,1,2),
  'DAYSTART':const FuncDesc('DAYSTART',false,1,3),
  'DIV':const FuncDesc('DIV',false,2,2),
  'DIMENSIONALITY':const FuncDesc('DIMENSIONALITY',false,0,0),
  'DOCUMENTNAME':const FuncDesc('DOCUMENTNAME',false,0,0),
  'DOCUMENTPATH':const FuncDesc('DOCUMENTPATH',false,0,0),
  'DOCUMENTTITLE':const FuncDesc('DOCUMENTTITLE',false,0,0),
  'DUAL':const FuncDesc('DUAL',false,2,2),
  'E':const FuncDesc('E',false,0,0),
  'EVALUATE':const FuncDesc('EVALUATE',false,1,1),
  'EVEN':const FuncDesc('EVEN',false,1,1),
  'EXISTS':const FuncDesc('EXISTS',false,1,2),
  'EXP':const FuncDesc('EXP',false,1,1),
  'FABS':const FuncDesc('FABS',false,1,1),
  'FACT':const FuncDesc('FACT',false,1,1),
  'FALSE':const FuncDesc('FALSE',false,0,0),
  'FDIST':const FuncDesc('FDIST',false,3,3),
  'FIELDINDEX':const FuncDesc('FIELDINDEX',false,2,2),
  'FIELDNAME':const FuncDesc('FIELDNAME',false,1,2),
  'FIELDNUMBER':const FuncDesc('FIELDNUMBER',false,1,2),
  'FIELDVALUE':const FuncDesc('FIELDVALUE',false,2,2),
  'FIELDVALUECOUNT':const FuncDesc('FIELDVALUECOUNT',false,1,1),
  'FILEBASENAME':const FuncDesc('FILEBASENAME',false,0,0),
  'FILEDIR':const FuncDesc('FILEDIR',false,0,0),
  'FILEEXTENSION':const FuncDesc('FILEEXTENSION',false,0,0),
  'FILENAME':const FuncDesc('FILENAME',false,0,0),
  'FILEPATH':const FuncDesc('FILEPATH',false,0,0),
  'FILESIZE':const FuncDesc('FILESIZE',false,0,0),
  'FILETIME':const FuncDesc('FILETIME',false,0,1),
  'FINDONEOF':const FuncDesc('FINDONEOF',false,2,3),
  'FINV':const FuncDesc('FINV',false,3,3),
  'FIRST':const FuncDesc('FIRST',false,1,3,isTotalPossible:true),
  'FIRSTSORTEDVALUE':const FuncDesc('FIRSTSORTEDVALUE',true,1,3,isDistinctPossible:true),
  'FIRSTVALUE':const FuncDesc('FIRSTVALUE',true,1,1),
  'FIRSTWORKDATE':const FuncDesc('FIRSTWORKDATE',false,2,999),
  'FLOOR':const FuncDesc('FLOOR',false,1,3),
  'FMOD':const FuncDesc('FMOD',false,2,2),
  'FRAC':const FuncDesc('FRAC',false,1,1),
  'FRACTILE':const FuncDesc('FRACTILE',true,0,999),
  'FV':const FuncDesc('FV',false,3,5),
  'GETACTIVESHEETID':const FuncDesc('GETACTIVESHEETID',false,0,0),
  'GETALTERNATIVECOUNT':const FuncDesc('GETALTERNATIVECOUNT',false,1,1),
  'GETEXCLUDEDCOUNT':const FuncDesc('GETEXCLUDEDCOUNT',false,1,1),
  'GETEXTENDEDPROPERTY':const FuncDesc('GETEXTENDEDPROPERTY',false,1,2),
  'GETCURRENTFIELD':const FuncDesc('GETCURRENTFIELD',false,1,1),
  'GETCURRENTSELECTIONS':const FuncDesc('GETCURRENTSELECTIONS',false,0,4),  
  'GETFIELDSELECTIONS':const FuncDesc('GETFIELDSELECTIONS',false,1,3),
  'GETFOLDERPATH':const FuncDesc('GETFOLDERPATH',false,0,0),
  'GETNOTSELECTEDCOUNT':const FuncDesc('GETNOTSELECTEDCOUNT',false,1,2),
  'GETOBJECTFIELD':const FuncDesc('GETOBJECTFIELD',false,0,1),
  'GETPOSSIBLECOUNT':const FuncDesc('GETPOSSIBLECOUNT',false,1,1),
  'GETSELECTEDCOUNT':const FuncDesc('GETSELECTEDCOUNT',false,1,2),
  'GETREGISTRYSTRING':const FuncDesc('GETREGISTRYSTRING',true,0,999),
  'GMT':const FuncDesc('GMT',false,0,0),
  'GREEN':const FuncDesc('GREEN',false,0,1),
  'HASH128':const FuncDesc('HASH128',false,1,999),
  'HASH160':const FuncDesc('HASH160',false,1,999),
  'HASH256':const FuncDesc('HASH256',false,1,999),
  'HOUR':const FuncDesc('HOUR',false,1,1),
  'HRANK':const FuncDesc('HRANK',false,1,3,isTotalPossible:true),
  'HSL':const FuncDesc('HSL',false,3,3),
  'IF':const FuncDesc('IF',false,2,3),
  'INDAY':const FuncDesc('INDAY',false,3,4),
  'INDAYTOTIME':const FuncDesc('INDAYTOTIME',false,3,4),
  'INDEX':const FuncDesc('INDEX',false,2,3),
  'INLUNARWEEK':const FuncDesc('INLUNARWEEK',false,3,4),
  'INLUNARWEEKTODATE':const FuncDesc('INLUNARWEEKTODATE',false,3,4),
  'INMONTH':const FuncDesc('INMONTH',false,3,3),
  'INMONTHS':const FuncDesc('INMONTHS',false,4,5),
  'INMONTHSTODATE':const FuncDesc('INMONTHSTODATE',false,4,5),
  'INMONTHTODATE':const FuncDesc('INMONTHTODATE',false,3,3),
  'INPUT':const FuncDesc('INPUT',false,1,2),
  'INPUTAVG':const FuncDesc('INPUTAVG',true,0,999),
  'INPUTSUM':const FuncDesc('INPUTSUM',true,0,999),
  'INQUARTER':const FuncDesc('INQUARTER',false,3,4),
  'INQUARTERTODATE':const FuncDesc('INQUARTERTODATE',false,3,4),
  'INTERVAL':const FuncDesc('INTERVAL',false,1,2),
  'INTERVAL#':const FuncDesc('INTERVAL#',false,1,2),
  'INWEEK':const FuncDesc('INWEEK',false,3,4),
  'INWEEKTODATE':const FuncDesc('INWEEKTODATE',false,3,4),
  'INYEAR':const FuncDesc('INYEAR',false,3,4),
  'INYEARTODATE':const FuncDesc('INYEARTODATE',false,3,4),
  'IRR':const FuncDesc('IRR',true,0,999),
  'ISNULL':const FuncDesc('ISNULL',false,1,1),
  'ISNUM':const FuncDesc('ISNUM',false,1,1),
  'ISPARTIALRELOAD':const FuncDesc('ISPARTIALRELOAD',false,0,0),
  'ISTEXT':const FuncDesc('ISTEXT',false,1,1),
  'ITERNO':const FuncDesc('ITERNO',false,0,0),
  'KEEPCHAR':const FuncDesc('KEEPCHAR',false,2,2),
  'KURTOSIS':const FuncDesc('KURTOSIS',true,0,999),
  'LAST':const FuncDesc('LAST',false,1,3,isTotalPossible:true),
  'LASTVALUE':const FuncDesc('LASTVALUE',true,1,1),
  'LASTWORKDATE':const FuncDesc('LASTWORKDATE',false,2,999),
  'LEFT':const FuncDesc('LEFT',false,2,2),
  'LEN':const FuncDesc('LEN',false,1,1),
  'LIGHTBLUE':const FuncDesc('LIGHTBLUE',false,0,1),
  'LIGHTCYAN':const FuncDesc('LIGHTCYAN',false,0,1),
  'LIGHTGRAY':const FuncDesc('LIGHTGRAY',false,0,1),
  'LIGHTGREEN':const FuncDesc('LIGHTGREEN',false,0,1),
  'LIGHTMAGENTA':const FuncDesc('LIGHTMAGENTA',false,0,1),
  'LIGHTRED':const FuncDesc('LIGHTRED',false,0,1),
  'LINEST_B':const FuncDesc('LINEST_B',true,0,999),
  'LINEST_DF':const FuncDesc('LINEST_DF',true,0,999),
  'LINEST_F':const FuncDesc('LINEST_F',true,0,999),
  'LINEST_M':const FuncDesc('LINEST_M',true,0,999),
  'LINEST_R2':const FuncDesc('LINEST_R2',true,0,999),
  'LINEST_SEB':const FuncDesc('LINEST_SEB',true,0,999),
  'LINEST_SEM':const FuncDesc('LINEST_SEM',true,0,999),
  'LINEST_SEY':const FuncDesc('LINEST_SEY',true,0,999),
  'LINEST_SSREG':const FuncDesc('LINEST_SSREG',true,0,999),
  'LINEST_SSRESID':const FuncDesc('LINEST_SSRESID',true,0,999),
  'LOCALTIME':const FuncDesc('LOCALTIME',false,0,2),
  'LOG':const FuncDesc('LOG',false,1,1),
  'LOG10':const FuncDesc('LOG10',false,1,1),
  'LOOKUP':const FuncDesc('LOOKUP',false,3,4),
  'LOWER':const FuncDesc('LOWER',false,1,1),
  'LTRIM':const FuncDesc('LTRIM',false,1,1),
  'LUNARWEEKEND':const FuncDesc('LUNARWEEKEND',false,1,3),
  'LUNARWEEKNAME':const FuncDesc('LUNARWEEKNAME',false,1,3),
  'LUNARWEEKSTART':const FuncDesc('LUNARWEEKSTART',false,1,3),
  'MAGENTA':const FuncDesc('MAGENTA',false,0,1),
  'MAKEDATE':const FuncDesc('MAKEDATE',false,1,3),
  'MAKETIME':const FuncDesc('MAKETIME',false,1,4),
  'MAKEWEEKDATE':const FuncDesc('MAKEWEEKDATE',false,1,3),
  'MAPSUBSTRING':const FuncDesc('MAPSUBSTRING',false,2,2),
  'MATCH':const FuncDesc('MATCH',false,2,999),
  'MAX':const FuncDesc('MAX',true,1,2),
  'MAXSTRING':const FuncDesc('MAXSTRING',true,1,1),
  'MEDIAN':const FuncDesc('MEDIAN',true,0,999),
  'MID':const FuncDesc('MID',false,2,3),
  'MIN':const FuncDesc('MIN',true,1,2),
  'MINSTRING':const FuncDesc('MINSTRING',true,1,1),
  'MINUTE':const FuncDesc('MINUTE',false,1,1),
  'MISSINGCOUNT':const FuncDesc('MISSINGCOUNT',true,1,1,isDistinctPossible:true),
  'MIXMATCH':const FuncDesc('MIXMATCH',false,2,999),
  'MOD':const FuncDesc('MOD',false,2,2),
  'MODE':const FuncDesc('MODE',true,1,1),
  'MONEY':const FuncDesc('MONEY',false,1,4),
  'MONEY#':const FuncDesc('MONEY#',false,1,4),
  'MONTH':const FuncDesc('MONTH',false,1,1),
  'MONTHEND':const FuncDesc('MONTHEND',false,1,2),
  'MONTHNAME':const FuncDesc('MONTHNAME',false,1,2),
  'MONTHSEND':const FuncDesc('MONTHSEND',false,2,4),
  'MONTHSNAME':const FuncDesc('MONTHSNAME',false,2,4),
  'MONTHSSTART':const FuncDesc('MONTHSSTART',false,2,4),
  'MONTHSTART':const FuncDesc('MONTHSTART',false,1,2),
  'MSGBOX':const FuncDesc('MSGBOX',false,1,5),
  'NETWORKDAYS':const FuncDesc('NETWORKDAYS',false,2,999),
  'NOOFCOLUMNS':const FuncDesc('NOOFCOLUMNS',false,0,0,isTotalPossible:true),
  'NOOFFIELDS':const FuncDesc('NOOFFIELDS',false,0,1),
  'NOOFREPORTS':const FuncDesc('NOOFREPORTS',false,0,0),
  'NOOFROWS':const FuncDesc('NOOFROWS',false,0,1,isTotalPossible:true),
  'NOOFTABLES':const FuncDesc('NOOFTABLES',false,0,0),
  'NORMDIST':const FuncDesc('NORMDIST',false,3,3),
  'NORMINV':const FuncDesc('NORMINV',false,3,3),
  'NOW':const FuncDesc('NOW',false,0,1),
  'NPER':const FuncDesc('NPER',false,3,5),
  'NPV':const FuncDesc('NPV',true,0,999),
  'NULL':const FuncDesc('NULL',false,0,0),
  'NULLCOUNT':const FuncDesc('NULLCOUNT',true,1,1,isDistinctPossible:true),
  'NUM':const FuncDesc('NUM',false,1,4),
  'NUM#':const FuncDesc('NUM#',false,1,4),
  'NUMAVG':const FuncDesc('NUMAVG',false,1,999),
  'NUMCOUNT':const FuncDesc('NUMCOUNT',false,1,999),
  'NUMERICCOUNT':const FuncDesc('NUMERICCOUNT',true,1,1,isDistinctPossible:true),
  'NUMMAX':const FuncDesc('NUMMAX',false,1,999),
  'NUMMIN':const FuncDesc('NUMMIN',false,1,999),
  'NUMSUM':const FuncDesc('NUMSUM',false,1,999),
  'ODD':const FuncDesc('ODD',false,1,1),
  'ONLY':const FuncDesc('ONLY',true,1,1),
  'ORD':const FuncDesc('ORD',false,1,1),
  'OSUSER':const FuncDesc('OSUSER',false,0,0),
  'PEEK':const FuncDesc('PEEK',false,1,3),
  'PERMUT':const FuncDesc('PERMUT',false,2,2),
  'PI':const FuncDesc('PI',false,0,0),
  'PICK':const FuncDesc('PICK',false,2,999),
  'PMT':const FuncDesc('PMT',false,3,5),
  'POW':const FuncDesc('POW',false,2,2),
  'PREVIOUS':const FuncDesc('PREVIOUS',false,1,1),
  'PURGECHAR':const FuncDesc('PURGECHAR',false,2,2),
  'PV':const FuncDesc('PV',false,3,5),
  'QLIKTECHBLUE':const FuncDesc('QLIKTECHBLUE',false,0,0),
  'QLIKTECHGRAY':const FuncDesc('QLIKTECHGRAY',false,0,0),
  'QLIKVIEWVERSION':const FuncDesc('QLIKVIEWVERSION',false,0,0),
  'QUARTEREND':const FuncDesc('QUARTEREND',false,1,3),
  'QUARTERNAME':const FuncDesc('QUARTERNAME',false,1,3),
  'QUARTERSTART':const FuncDesc('QUARTERSTART',false,1,3),
  'QVDCREATETIME':const FuncDesc('QVDCREATETIME',false,1,1),
  'QVDFIELDNAME':const FuncDesc('QVDFIELDNAME',false,2,2),
  'QVDNOOFFIELDS':const FuncDesc('QVDNOOFFIELDS',false,1,1),
  'QVDNOOFRECORDS':const FuncDesc('QVDNOOFRECORDS',false,1,1),
  'QVDTABLENAME':const FuncDesc('QVDTABLENAME',false,1,1),
  'QVUSER':const FuncDesc('QVUSER',true,0,999),
  'RAND':const FuncDesc('RAND',false,0,0),
  'RANGEAVG':const FuncDesc('RANGEAVG',false,1,999),
  'RANGECORREL':const FuncDesc('RANGECORREL',false,2,999),
  'RANGECOUNT':const FuncDesc('RANGECOUNT',false,1,999),
  'RANGEFRACTILE':const FuncDesc('RANGEFRACTILE',false,1,999),
  'RANGEIRR':const FuncDesc('RANGEIRR',false,1,999),
  'RANGEKURTOSIS':const FuncDesc('RANGEKURTOSIS',false,1,999),
  'RANGEMAX':const FuncDesc('RANGEMAX',false,1,999),
  'RANGEMAXSTRING':const FuncDesc('RANGEMAXSTRING',false,1,999),
  'RANGEMIN':const FuncDesc('RANGEMIN',false,1,999),
  'RANGEMINSTRING':const FuncDesc('RANGEMINSTRING',false,1,999),
  'RANGEMISSINGCOUNT':const FuncDesc('RANGEMISSINGCOUNT',false,1,999),
  'RANGEMODE':const FuncDesc('RANGEMODE',false,1,999),
  'RANGENPV':const FuncDesc('RANGENPV',false,1,999),
  'RANGENULLCOUNT':const FuncDesc('RANGENULLCOUNT',false,1,999),
  'RANGENUMERICCOUNT':const FuncDesc('RANGENUMERICCOUNT',false,1,999),
  'RANGEONLY':const FuncDesc('RANGEONLY',false,1,999),
  'RANGESKEW':const FuncDesc('RANGESKEW',false,1,999),
  'RANGESTDEV':const FuncDesc('RANGESTDEV',false,1,999),
  'RANGESUM':const FuncDesc('RANGESUM',false,1,999),
  'RANGETEXTCOUNT':const FuncDesc('RANGETEXTCOUNT',false,1,999),
  'RANGEXIRR':const FuncDesc('RANGEXIRR',false,1,999),
  'RANGEXNPV':const FuncDesc('RANGEXNPV',false,1,999),
  'RANK':const FuncDesc('RANK',false,1,3,isTotalPossible:true),
  'RATE':const FuncDesc('RATE',false,3,5),
  'RECNO':const FuncDesc('RECNO',false,0,0),
  'RED':const FuncDesc('RED',false,0,1),'mage'
  'RELOADTIME':const FuncDesc('RELOADTIME',false,0,0),
  'REPEAT':const FuncDesc('REPEAT',false,1,1),
  'REPLACE':const FuncDesc('REPLACE',false,3,3),
  'REPORTCOMMENT':const FuncDesc('REPORTCOMMENT',false,1,1),
  'REPORTID':const FuncDesc('REPORTID',false,1,1),
  'REPORTNAME':const FuncDesc('REPORTNAME',false,1,1),
  'REPORTNUMBER':const FuncDesc('REPORTNUMBER',false,1,1),
  'RGB':const FuncDesc('RGB',false,3,3),
  'RIGHT':const FuncDesc('RIGHT',false,2,2),
  'ROUND':const FuncDesc('ROUND',false,1,3),
  'ROWNO':const FuncDesc('ROWNO',false,0,0,isTotalPossible:true),
  'RTRIM':const FuncDesc('RTRIM',false,1,1),
  'SECOND':const FuncDesc('SECOND',false,1,1),
  'SECONDARYDIMENSIONALITY':const FuncDesc('SECONDARYDIMENSIONALITY',false,0,0),
  'SETDATEYEAR':const FuncDesc('SETDATEYEAR',false,2,2),
  'SETDATEYEARMONTH':const FuncDesc('SETDATEYEARMONTH',false,2,3),
  'SIGN':const FuncDesc('SIGN',false,1,1),
  'SIN':const FuncDesc('SIN',true,0,999),
  'SINH':const FuncDesc('SINH',false,1,1),
  'SKEW':const FuncDesc('SKEW',true,0,999),
  'SQR':const FuncDesc('SQR',false,1,1),
  'SQRT':const FuncDesc('SQRT',false,1,1),
  'STDEV':const FuncDesc('STDEV',true,0,999),
  'STERR':const FuncDesc('STERR',true,0,999),
  'STEYX':const FuncDesc('STEYX',true,0,999),
  'SUBFIELD':const FuncDesc('SUBFIELD',false,2,3),
  'SUBSTRINGCOUNT':const FuncDesc('SUBSTRINGCOUNT',false,2,3),
  'SUM':const FuncDesc('SUM',true,1,1,isDistinctPossible:true),
  'SYSCOLOR':const FuncDesc('SYSCOLOR',false,1,1),
  'TABLENAME':const FuncDesc('TABLENAME',false,1,1),
  'TABLENUMBER':const FuncDesc('TABLENUMBER',false,1,1),
  'TAN':const FuncDesc('TAN',false,1,1),
  'TANH':const FuncDesc('TANH',false,1,1),
  'TDIST':const FuncDesc('TDIST',false,3,3),
  'TEXT':const FuncDesc('TEXT',false,1,1),
  'TEXTBETWEEN':const FuncDesc('TEXTBETWEEN',false,3,4),
  'TEXTCOUNT':const FuncDesc('TEXTCOUNT',true,1,1,isDistinctPossible:true),
  'TIME':const FuncDesc('TIME',false,1,2),
  'TIME#':const FuncDesc('TIME#',false,1,2),
  'TIMESTAMP':const FuncDesc('TIMESTAMP',false,1,2),
  'TIMESTAMP#':const FuncDesc('TIMESTAMP#',false,1,2),
  'TIMEZONE':const FuncDesc('TIMEZONE',false,0,0),
  'TINV':const FuncDesc('TINV',false,2,2),
  'TODAY':const FuncDesc('TODAY',false,0,1),
  'TOP':const FuncDesc('TOP',false,1,3,isTotalPossible:true),  
  'TRIM':const FuncDesc('TRIM',false,1,1),
  'TRUE':const FuncDesc('TRUE',false,0,0),
  'TTEST1_CONF':const FuncDesc('TTEST1_CONF',true,0,999),
  'TTEST1_DF':const FuncDesc('TTEST1_DF',true,0,999),
  'TTEST1_DIF':const FuncDesc('TTEST1_DIF',true,0,999),
  'TTEST1_LOWER':const FuncDesc('TTEST1_LOWER',true,0,999),
  'TTEST1_SIG':const FuncDesc('TTEST1_SIG',true,0,999),
  'TTEST1_STERR':const FuncDesc('TTEST1_STERR',true,0,999),
  'TTEST1_T':const FuncDesc('TTEST1_T',true,0,999),
  'TTEST1_UPPER':const FuncDesc('TTEST1_UPPER',true,0,999),
  'TTEST1W_CONF':const FuncDesc('TTEST1W_CONF',true,0,999),
  'TTEST1W_DF':const FuncDesc('TTEST1W_DF',true,0,999),
  'TTEST1W_DIF':const FuncDesc('TTEST1W_DIF',true,0,999),
  'TTEST1W_LOWER':const FuncDesc('TTEST1W_LOWER',true,0,999),
  'TTEST1W_SIG':const FuncDesc('TTEST1W_SIG',true,0,999),
  'TTEST1W_STERR':const FuncDesc('TTEST1W_STERR',true,0,999),
  'TTEST1W_T':const FuncDesc('TTEST1W_T',true,0,999),
  'TTEST1W_UPPER':const FuncDesc('TTEST1W_UPPER',true,0,999),
  'TTEST_CONF':const FuncDesc('TTEST_CONF',true,0,999),
  'TTEST_DF':const FuncDesc('TTEST_DF',true,0,999),
  'TTEST_DIF':const FuncDesc('TTEST_DIF',true,0,999),
  'TTEST_LOWER':const FuncDesc('TTEST_LOWER',true,0,999),
  'TTEST_SIG':const FuncDesc('TTEST_SIG',true,0,999),
  'TTEST_STERR':const FuncDesc('TTEST_STERR',true,0,999),
  'TTEST_T':const FuncDesc('TTEST_T',true,0,999),
  'TTEST_UPPER':const FuncDesc('TTEST_UPPER',true,0,999),
  'TTESTW_CONF':const FuncDesc('TTESTW_CONF',true,0,999),
  'TTESTW_DF':const FuncDesc('TTESTW_DF',true,0,999),
  'TTESTW_DIF':const FuncDesc('TTESTW_DIF',true,0,999),
  'TTESTW_LOWER':const FuncDesc('TTESTW_LOWER',true,0,999),
  'TTESTW_SIG':const FuncDesc('TTESTW_SIG',true,0,999),
  'TTESTW_STERR':const FuncDesc('TTESTW_STERR',true,0,999),
  'TTESTW_T':const FuncDesc('TTESTW_T',true,0,999),
  'TTESTW_UPPER':const FuncDesc('TTESTW_UPPER',true,0,999),
  'UPPER':const FuncDesc('UPPER',false,1,1),
  'UTC':const FuncDesc('UTC',false,0,0),
  'VRANK':const FuncDesc('VRANK',false,1,3,isTotalPossible:true),
  'WEEK':const FuncDesc('WEEK',false,1,1),
  'WEEKDAY':const FuncDesc('WEEKDAY',false,1,1),
  'WEEKEND':const FuncDesc('WEEKEND',false,1,3),
  'WEEKNAME':const FuncDesc('WEEKNAME',false,1,3),
  'WEEKSTART':const FuncDesc('WEEKSTART',false,1,3),
  'WEEKYEAR':const FuncDesc('WEEKYEAR',false,1,1),
  'WHITE':const FuncDesc('WHITE',false,0,1),
  'WILDMATCH':const FuncDesc('WILDMATCH',false,2,999),
  'WILDMATCH5':const FuncDesc('WILDMATCH5',true,0,999),
  'XIRR':const FuncDesc('XIRR',true,0,999),
  'XNPV':const FuncDesc('XNPV',true,0,999),
  'YEAR':const FuncDesc('YEAR',false,1,1),
  'YEAR2DATE':const FuncDesc('YEAR2DATE',true,0,999),
  'YEAREND':const FuncDesc('YEAREND',false,1,3),
  'YEARNAME':const FuncDesc('YEARNAME',false,1,3),
  'YEARSTART':const FuncDesc('YEARSTART',false,1,3),
  'YEARTODATE':const FuncDesc('YEARTODATE',false,1,4),
  'YELLOW':const FuncDesc('YELLOW',false,0,1),
  'ZTEST_CONF':const FuncDesc('ZTEST_CONF',true,0,999),
  'ZTEST_DIF':const FuncDesc('ZTEST_DIF',true,0,999),
  'ZTEST_LOWER':const FuncDesc('ZTEST_LOWER',true,0,999),
  'ZTEST_SIG':const FuncDesc('ZTEST_SIG',true,0,999),
  'ZTEST_STERR':const FuncDesc('ZTEST_STERR',true,0,999),
  'ZTEST_UPPER':const FuncDesc('ZTEST_UPPER',true,0,999),
  'ZTEST_Z':const FuncDesc('ZTEST_Z',true,0,999),
  'ZTESTW_CONF':const FuncDesc('ZTESTW_CONF',true,0,999),
  'ZTESTW_DIF':const FuncDesc('ZTESTW_DIF',true,0,999),
  'ZTESTW_LOWER':const FuncDesc('ZTESTW_LOWER',true,0,999),
  'ZTESTW_SIG':const FuncDesc('ZTESTW_SIG',true,0,999),
  'ZTESTW_STERR':const FuncDesc('ZTESTW_STERR',true,0,999),
  'ZTESTW_UPPER':const FuncDesc('ZTESTW_UPPER',true,0,999),
  'ZTESTW_Z':const FuncDesc('ZTESTW_UPPER',true,0,999)  
};

