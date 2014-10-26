part of qvs_parser;



class QvsGrammar extends CompositeParser {
  void initialize() {
    _whitespace();
    _number();
    _expression();
    _qvs();
  }
  /**
   * Russian letters
   */
  localLetter() => range(1024,1273);
  Parser get trimmer => ref(p.whitespace);
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
//    def(p.,
//        _keyword('LOAD')
//        .seq(ref(p.selectList).trim(trimmer))
//        .seq(ref(p.whereClause).optional())
//        .seq(char(';'))
//          .trim(trimmer).flatten());
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
        .seq(expression().trim(trimmer).optional())
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
 
  expression() => new QvExpGrammar()['expression'];
  _expression() {
    def(p.expression,
        expression().trim(trimmer)
        );   
//    def(p.primaryExpression,
//        ref(p.str)
//        .or(ref(p.unaryExpression))
//        .or(ref(p.macroFunction))
//        .or(ref(p.function))
//        .or(ref(p.number))
//        .or(ref(p.fieldref))
//        .or(ref(p.parens)));
//    def(p.binaryExpression, ref(p.primaryExpression)
//        .seq(ref(p.binaryPart).star()).trim(trimmer).flatten());
//    def(p.binaryPart, ref(p.binaryOperator)
//        .seq(ref(p.primaryExpression)));
    def(p.fieldref,
          _keyword(ref(p.identifier)
          .or(ref(p.fieldrefInBrackets))
          .or(ref(p.str)).trim(trimmer)
          ));
    def(p.identifier,
        new QvExpGrammar()['identifier']
    ); 
    def(p.varName,
        new QvExpGrammar()['varName']
    ); 

    //    def(p.identifier,letter().or(anyIn('_%@').or(localLetter()))
//        .seq(word().or(anyIn('.%')).or(char('_')).or(localLetter().or(char(r'$'))).plus())
//        .or(letter())
//        .seq(whitespace().star().seq(char('(')).not())
//        .flatten().trim(trimmer));
//    def(p.varName,
//        word()
//          .or(localLetter())
//          .or(anyIn(r'._$#@'))
//            .plus().flatten().trim(trimmer)
//        );
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
//    def(p.function,
//        letter()
//        .seq(word().or(char('#')).plus()).flatten()
//        .trim(trimmer)
//        .seq(char('(').trim(trimmer))
//        .seq(ref(p.params).optional())
//        .seq(char(')').trim(trimmer)));
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
    def(p.subDeclaration,
          ref(p.varName)
          .seq(_keyword('(')
            .seq(ref(p.params))
            .seq(_keyword(')')).optional()));
//    def(p.unaryExpression,
//        _word('NOT').or(_keyword('-').or(_word('DISTINCT'))).trim(trimmer)
//            .seq(ref(p.expression))
//            .trim(trimmer).flatten());
//    def(p.binaryOperator,
//        _word('and')
//        .or(_word('or'))
//        .or(_word('xor'))
//        .or(_word('like'))
//        .or(_keyword('<='))
//        .or(_keyword('<>'))
//        .or(_keyword('!='))
//        .or(_keyword('>='))
//        .or(anyIn('+-/*<>=&'))
//        .or(_word('precedes'))
//        .trim(trimmer).flatten()
//        );
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


