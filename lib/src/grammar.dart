part of qvs_parser;



class QvsGrammar extends CompositeParser {
//  void def(String name, Parser parser) {
//    super.def(name,parser);
//    print("const String $name = '$name';");
//  }
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
        ref(p.macroLine)
        .or(ref(p.load))
        .or(ref(p.controlStatement))
        .or(ref(p.call))
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
        .or(ref(p.assignment)));
    def(p.renameTable,
        _token('RENAME')
        .seq(_token('TABLE'))
        .seq(ref(p.fieldref))
        .seq(_token('TO'))
        .seq(ref(p.fieldref))
        .seq(char(';'))
        .trim(trimmer));
    def(p.renameField,
        _token('RENAME')
        .seq(_token('FIELD'))
        .seq(ref(p.fieldref))
        .seq(_token('TO'))
        .seq(ref(p.fieldref))
        .seq(char(';'))
        .trim(trimmer).flatten());

    def(p.load,
        ref(p.tableDesignator).optional()
        .seq(ref(p.loadPerfix).star())
        .seq(_token('MAPPING').optional())
        .seq(ref(p.precedingLoad).star())
        .seq(ref(p.preloadFunc).optional())
        .seq(_token('LOAD').or(_token('SELECT')))
        .seq(ref(p.selectList).trim(trimmer))
        .seq(ref(p.loadSource).trim(trimmer))
        .seq(char(';'))
          .trim(trimmer));
    def(p.precedingLoad,
        _token('LOAD')
        .seq(ref(p.selectList).trim(trimmer))
        .seq(char(';'))
          .trim(trimmer).flatten());
    def(p.loadPerfix,
      _token('NOCONCATENATE')
      .or(_word('BUFFER').seq(ref(p.bufferModifier).optional()))
      .or(_word('BUNDLE').seq(_word('INFO').optional()))
      .or(_word('ADD').seq(_word('ONLY').optional())));
    def(p.bufferModifier,
        _token('(')
        .seq(
          _token('INCREMENTAL')
          .or(
              _token('STALE')
              .seq(_token('AFTER').optional())
              .seq(ref(p.number))
              .seq(_token('DAYS').or(_token('HOURS')).optional())))
        .seq(_token(')')));
    def(p.loadSource,
        ref(p.loadSourceAutogenerate)
        .or(ref(p.loadSourceInline))
        .or(ref(p.loadSourceStandart)));
    def(p.loadSourceStandart,
        _token('RESIDENT').or(_token('FROM'))
        .seq(ref(p.tableOrFilename))
        .seq(ref(p.whereClause).optional())
        .seq(ref(p.groupBy).optional())
        .seq(ref(p.orderBy).optional())
        );
    def(p.loadSourceInline,
          _token('INLINE')
          .seq(_token('['))
          .seq(_token(']').neg().plus())
          .seq(_token(']')));
    def(p.loadSourceAutogenerate,
        _token('autogenerate')
        .seq(ref(p.expression))
        .seq(ref(p.whereClause).optional())
        .seq(ref(p.whileClause).optional()));
    def(p.from,
        _token('FROM')
        .seq(ref(p.fieldref)));
    def(p.dropFields,
        _token('DROP')
        .seq(_token('FIELD'))
        .seq(_token('S').optional())
        .seq(ref(p.fieldrefs))
        .seq(ref(p.from).optional())
        .seq(char(';'))
        .trim(trimmer).flatten());
    def(p.dropTable,
        _token('DROP')
        .seq(_token('TABLE'))
        .seq(_token('S').or(_token('s')).optional())
        .seq(ref(p.fieldrefs))
        .seq(char(';'))
        .trim(trimmer));
    def(p.storeTable,
        _token('STORE')
        .seq(ref(p.fieldref))
        .seq(_token('INTO'))
        .seq(ref(p.tableOrFilename))
        .seq(char(';'))
        .trim(trimmer).flatten());
    
    def(p.selectList,
        ref(p.field).or(_word('*')).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.field,
        ref(p.expression).seq(_token('as')).seq(ref(p.fieldref))
        .or(ref(p.expression))
        .trim(trimmer).flatten());
    def(p.commentWith,
        _word('COMMENT').or(_word('TAG')).or(_word('UNTAG'))
        .seq(_word('FIELD').or(_word('FIELDS')))
        .seq(ref(p.fieldrefs))
        .seq(_word('WITH'))
        .seq(ref(p.str).or(char(';').not().plus()))
        .seq(char(';')).trim(trimmer).flatten()
        );
    def(p.stringOrNotColon,
        ref(p.str)
        .or(char(';').neg().plusLazy(char(';')))
        );
    def(p.join,
        _token('LEFT').or(_token('RIGHT')).or(_token('INNER')).optional()
        .seq(_token('JOIN').or(_token('KEEP')))
        .seq(ref(p.tableInParens).optional()));
    def(p.preloadFunc,
        _token('Hierarchy')
          .or(_token('HierarchyBelongsTo'))
          .or(_token('IntervalMatch'))
          .or(_token('CrossTable'))
        .seq(ref(p.simpleParens))
        .flatten());
    def(p.whileClause,
        _token('while')
        .seq(ref(p.expression))
        .flatten());
    
    def(p.concatenate,
        _token('concatenate')
        .seq(ref(p.tableInParens).optional())
        .flatten());
    def(p.tableInParens,
        _token('(')
        .seq(ref(p.fieldref))
        .seq(_token(')'))
        );
    def(p.groupBy,
        _token('GROUP')
        .seq(_token('BY'))
        .seq(ref(p.params))
        );
    def(p.orderBy,
        _token('ORDER')
        .seq(_token('BY'))
        .seq(ref(p.fieldrefsOrderBy))
        );

    def(p.fieldrefs,
        ref(p.fieldref).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.fieldrefsOrderBy,
        ref(p.fieldrefOrderBy).separatedBy(char(',').trim(trimmer), includeSeparators: false));

    def(p.fieldrefOrderBy,
        ref(p.identifier)
        .or(ref(p.fieldrefInBrackets))
        .seq(_token('DESC').or(_token('ASC')).optional()));
    
    def(p.tableDesignator,
        ref(p.tableIdentifier)
        .or(ref(p.join))
        .or(ref(p.concatenate)).plus()
        .trim(trimmer)
        );
    def(p.tableIdentifier,
      ref(p.fieldref).seq(char(':').trim(trimmer))
    );
    def(p.subRoutine,
        word().or(char('.')).plus().trim(trimmer)
        .seq(char('(').trim(trimmer))
        .seq(ref(p.params).optional())
        .seq(char(')').trim(trimmer)).flatten());
    def(p.params,
        ref(p.expression).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.parens,
        char('(').trim(trimmer)
            .seq(ref(p.expression))
            .seq(char(')').trim(trimmer)).flatten());
    def(p.macro,
        _token(r'$(')
            .seq(word().or(anyIn(r'./\[]=')).plus().trim(trimmer))
            .seq(char(')').trim(trimmer)).flatten());
    
    def(p.tableOrFilename,
        word().or(anyIn(r'./\:').or(localLetter())).plus()
        .or(ref(p.fieldrefInBrackets))
        .or(ref(p.macro))
        .or(ref(p.str))
        .seq(ref(p.fileModifier).optional())
        .trim(trimmer));
//    def(p.fileName,
//        );
    def(p.whereClause,
        _token('where').or(_token('while')).trim(trimmer)
        .seq(ref(p.binaryExpression))
        .trim(trimmer));
    def(p.assignment,
        _token('SET').or(_token('LET')).trim(trimmer)
        .seq(ref(p.identifier).or(ref(p.macro)).trim(trimmer))
        .seq(char('=').trim(trimmer))
        .seq(ref(p.expression).optional())
        .seq(char(';'))
        );
    def(p.call,
        _word('call').trim(trimmer)
        .seq(word().or(char('.')).plus().trim(trimmer))
                    .seq(char('(').trim(trimmer)
                    .seq(ref(p.params).plus())
                    .seq(char(')').trim(trimmer)).optional())
        .seq(char(';')).trim(trimmer).flatten()
        );
    def(p.simpleParens,
        char("(")
        .seq(char(")").neg().star())
        .seq(char(")")).trim(trimmer).flatten());
    def(p.macroLine,
        ref(p.macro).trim(trimmer)
        .seq(char(';')).trim(trimmer).flatten());
    def(p.fileModifierTokens,
        _token('embedded labels')
        .or(_token('explicit labels'))
        .or(_token('no')
            .seq(_token('quotes').
                or(_token('labels')).
                or(_token('eof'))))
        .or(_token('codepage is')
            .seq(ref(p.decimalInteger).plus())
            .or(_token('unicode'))
            .or(_token('ansi'))
            .or(_token('oem'))
            .or(_token('mac'))
            .or(_token('UTF').seq(char('-').optional().seq(char('8')))))
        .or(_token('table is').seq(ref(p.fieldref)))
        .or(_token('header').or(_token('record'))
            .seq(_token('is'))
            .seq(ref(p.decimalInteger))
            .seq(_token('lines')))
        .or(_token('delimiter is').seq(ref(p.str)))
        .flatten());
    def(p.fileModifierElement,
        ref(p.fileModifierTokens)
        .or(ref(p.expression)));
    def(p.fileModifierElements,
        ref(p.fileModifierElement).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.fileModifier,
        _token('(')
         .seq(ref(p.fileModifierElements))
         .seq(_token(')')));
    def(p.connect,
        _token('ODBC').or(_token('OLEDB')).or(_token('CUSTOM')).optional()
        .seq(_token('CONNECT'))
        .seq(_token('TO'))
        .seq(ref(p.str).trim(trimmer))
        .seq(ref(p.simpleParens).optional())
        .flatten()
        );
    def(p.controlStatement,
        ref(p.subStart)
        .or(ref(p.exitScript))
        .or(ref(p.forNextStart))
        .or(ref(p.forEachStart))
        .or(ref(p.ifStart))
        .or(_token('ELSE'))
        .or(ref(p.controlStatementFinish)));
    def(p.controlStatementFinish,
        _token('END')
          .seq(_token('SUB').or(_token('IF')))
        .or(_token('NEXT')
          .seq(ref(p.identifier).optional()))
        .seq(_token(';').optional()));
    def(p.subStart,
        _token('SUB')
        .seq(ref(p.identifier).or(ref(p.function)))
        .seq(_token(';').optional()));
    def(p.exitScript,
    _token('exit')
    .seq(_token('script'))
    .seq(_token(';').optional()));

    def(p.forNextStart,
        _token('FOR')
        .seq(ref(p.expression))
        .seq(_token('to'))
        .seq(ref(p.expression))
        .seq(_token(';').optional()));
    def(p.ifStart,
        _token('IF').or(_token('ELSEIF'))
        .seq(ref(p.expression))
        .seq(_token('THEN'))
        .seq(_token(';').optional()));
    def(p.forEachStart,
        _token('FOR')
        .seq(_token('each'))
        .seq(ref(p.expression))
        .seq(_token('each'))
        .seq(ref(p.expression))
        .seq(_token(';').optional()));
    def(p.qualify,
        _token('UNQUALIFY').or(_token('QUALIFY'))
        .seq(ref(p.fieldrefOrStringList))
        .seq(_token(';')).flatten());
    
    def(p.fieldrefOrStringList,
        ref(p.fieldrefOrString).separatedBy(char(',').trim(trimmer), includeSeparators: false));

    def(p.fieldrefOrString,
        ref(p.identifier)
        .or(ref(p.fieldrefInBrackets))
        .or(ref(p.str)));
    def(p.fieldrefAs,
      ref(p.fieldref)
      .seq(_token('as')).
      seq(ref(p.fieldref)));
    def(p.fieldrefsAs,
      ref(p.fieldrefAs).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.alias,
      _token('ALIAS')
      .seq(ref(p.fieldrefsAs))
      .seq(_token(';')));
    def(p.binaryStatement,
    _token('binary')
    .seq(ref(p.tableOrFilename))
    .seq(_token(';')));
   def(p.trace,
     _word('TRACE')
     .seq(char(';').neg().plus())
     .seq(char(';'))
   );

  }
  
  
  /** Defines the whitespace and comments. */
  void _whitespace() {
    
    def(p.whitespace, whitespace()
      .or(ref(p.singeLineComment))
      .or(ref(p.multiLineComment)));
    def(p.singeLineComment, string('//')
      .seq(Token.newlineParser().neg().star()));
    def(p.multiLineComment, string('/*')
      .seq(string('*/').neg().star())
      .seq(string('*/')));
  }
 
  _expression() {
    def(p.expression,
        ref(p.binaryExpression).trim(trimmer)
        );   
    def(p.primaryExpression,
        ref(p.str)
        .or(ref(p.unaryExpression))
        .or(ref(p.function))
        .or(ref(p.number))
        .or(ref(p.fieldref))
        .or(ref(p.macro))
        .or(ref(p.parens)));
    def(p.binaryExpression, ref(p.primaryExpression)
        .seq(ref(p.binaryPart).star()).trim(trimmer).flatten());
    def(p.binaryPart, ref(p.binaryOperator)
        .seq(ref(p.primaryExpression)));
    def(p.fieldref,
          _token(ref(p.identifier)
          .or(ref(p.macro))
          .or(ref(p.fieldrefInBrackets))));
    def(p.identifier,letter().or(char('_').or(char('@')).or(localLetter()))
        .seq(word().or(char('.')).or(char('_')).or(localLetter()).plus())
        .or(letter())
        .seq(whitespace().star().seq(char('(')).not())
        .flatten().trim(trimmer));
    def(p.fieldrefInBrackets, _token('[')
        .seq(_token(']').neg().plus())
        .seq(_token(']')).trim(trimmer).flatten());
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
        .seq(word().or(char('.')).plus())
        .seq(char('#').optional())
        .trim(trimmer)
        .seq(char('(').trim(trimmer))
        .seq(ref(p.params).optional())
        .seq(char(')').trim(trimmer)).flatten());
    def(p.unaryExpression,
        _word('NOT').or(_token('-').or(_word('DISTINCT'))).trim(trimmer)
            .seq(ref(p.expression))
            .trim(trimmer).flatten());
    def(p.binaryOperator,
        _word('and')
        .or(_word('or'))
        .or(_word('xor'))
        .or(_word('like'))
        .or(_token('<='))
        .or(_token('<>'))
        .or(_token('!='))
        .or(_token('>='))
        .or(anyIn('+-/*<>=&'))
        .or(_word('precedes'))
        .trim(trimmer).flatten()
        );
  }
  
  /** Defines a token parser that ignore case and consumes whitespace. */
  Parser _token(dynamic input) {
    var parser = input is Parser ? input :
        input.length == 1 ? char(input) :
        stringIgnoreCase(input);
    return parser.token().trim(trimmer);
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

    def(P.float, ref(p.mantissa)
        .seq(ref(p.exponentLetter)
            .seq(ref(p.exponent))
            .optional()));
    def(P.mantissa, ref(p.digits)
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

class P {
  static const String mantissa = 'mantissa';
  static const String float = 'float';

}

const String qualify = 'qualify';
