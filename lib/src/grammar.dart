part of qvs_parser;

/**
 * Smalltalk grammar definition.
 */
class QvsGrammar extends CompositeParser {

  void initialize() {
    _whitespace();
    _number();
    _expression();
    _qvs();
//    action('table', (v) {
//      print(v);
//      print(v.join(''));
//    });
    
  }
  /**
   * Russian letters
   */
  localLetter() => range(1024,1273);
  Parser get trimmer => ref('whitespace');
  void _qvs() {
    def('start', ref('command').plus().end().flatten());
    def('command',
        ref('macroLine')
        .or(ref('load'))
        .or(ref('controlStatement'))
        .or(ref('call'))
        .or(ref('drop fields'))
        .or(ref('drop table'))
        .or(ref('rename table'))
        .or(ref('rename field'))
        .or(ref('qualify'))
        .or(ref('alias'))
        .or(ref('binaryStatement'))
        .or(ref('store table')) 
        .or(ref('assignment')));
    def('rename table',
        _token('RENAME')
        .seq(_token('TABLE'))
        .seq(ref('fieldref'))
        .seq(_token('TO'))
        .seq(ref('fieldref'))
        .seq(char(';'))
        .trim(trimmer));
    def('rename field',
        _token('RENAME')
        .seq(_token('FIELD'))
        .seq(ref('fieldref'))
        .seq(_token('TO'))
        .seq(ref('fieldref'))
        .seq(char(';'))
        .trim(trimmer).flatten());

    def('load',
        ref('tableDesignator').optional()
        .seq(ref('load perfix').star())
        .seq(_token('MAPPING').optional())
        .seq(ref('preceding load').star())
        .seq(ref('preload func').optional())
        .seq(_token('LOAD').or(_token('SELECT')))
        .seq(ref('selectList').trim(trimmer))
        .seq(ref('loadSource').trim(trimmer))
        .seq(char(';'))
          .trim(trimmer));
    def('preceding load',
        _token('LOAD')
        .seq(ref('selectList').trim(trimmer))
        .seq(char(';'))
          .trim(trimmer).flatten());
    def('load perfix',
      _token('NOCONCATENATE')
      .or(_token('ADD').seq(_token('ONLY').optional())));

    def('loadSource',
        ref('loadSourceAutogenerate')
        .or(ref('loadSourceInline'))
        .or(ref('loadSourceStandart')));
    def('loadSourceStandart',
        _token('RESIDENT').or(_token('FROM'))
        .seq(ref('tableOrFilename'))
        .seq(ref('whereClause').optional())
        .seq(ref('group by').optional())
        .seq(ref('order by').optional()));
    def('loadSourceInline',
          _token('INLINE')
          .seq(_token('['))
          .seq(_token(']').neg().plus())
          .seq(_token(']')));
    def('loadSourceAutogenerate',
        _token('autogenerate')
        .seq(ref('expression'))
        .seq(ref('while clause').optional()));
    def('from',
        _token('FROM')
        .seq(ref('fieldref')));
    def('drop fields',
        _token('DROP')
        .seq(_token('FIELD'))
        .seq(_token('S').optional())
        .seq(ref('fieldrefs'))
        .seq(ref('from').optional())
        .seq(char(';'))
        .trim(trimmer).flatten());
    def('drop table',
        _token('DROP')
        .seq(_token('TABLE'))
        .seq(_token('S').or(_token('s')).optional())
        .seq(ref('fieldrefs'))
        .seq(char(';'))
        .trim(trimmer));
    def('store table',
        _token('STORE')
        .seq(ref('fieldref'))
        .seq(_token('INTO'))
        .seq(ref('tableOrFilename'))
        .seq(char(';'))
        .trim(trimmer).flatten());
    
    def('selectList',
        ref('field').or(char('*')).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def('field',
        ref('expression').seq(_token('as')).seq(ref('fieldref'))
        .or(ref('expression'))
        .trim(trimmer).flatten());
    def('join',
        _token('LEFT').or(_token('RIGHT')).or(_token('INNER')).optional()
        .seq(_token('JOIN').or(_token('KEEP')))
        .seq(ref('table in parens').optional()));
    def('preload func',
        _token('Hierarchy').or(_token('IntervalMatch')).or(_token('CrossTable'))
        .seq(ref('simpleParens'))
        .flatten());
    def('while clause',
        _token('while')
        .seq(ref('expression'))
        .flatten());
    
    def('concatenate',
        _token('concatenate')
        .seq(ref('table in parens').optional())
        .flatten());
    def('table in parens',
        _token('(')
        .seq(ref('fieldref'))
        .seq(_token(')'))
        );
    def('group by',
        _token('GROUP')
        .seq(_token('BY'))
        .seq(ref('params'))
        );
    def('order by',
        _token('ORDER')
        .seq(_token('BY'))
        .seq(ref('fieldrefsOrderBy'))
        .flatten()
        );

    def('fieldrefs',
        ref('fieldref').separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def('fieldrefsOrderBy',
        ref('fieldrefOrderBy').separatedBy(char(',').trim(trimmer), includeSeparators: false));

    def('fieldrefOrderBy',
        ref('identifier')
        .or(ref('fieldrefInBrackets'))
        .seq(_token('DESC').optional()));
    
    def('tableDesignator',
        ref('tableIdentifier')
        .or(ref('join'))
        .or(ref('concatenate')).plus()
        .trim(trimmer)
        );
    def('tableIdentifier',
      ref('fieldref').seq(char(':').trim(trimmer))
    );
    def('subRoutine',
        word().or(char('.')).plus().trim(trimmer)
        .seq(char('(').trim(trimmer))
        .seq(ref('params').optional())
        .seq(char(')').trim(trimmer)).flatten());
    def('params',
        ref('expression').separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def('parens',
        char('(').trim(trimmer)
            .seq(ref('expression'))
            .seq(char(')').trim(trimmer)).flatten());
    def('macro',
        _token(r'$(')
            .seq(word().or(anyIn(r'./\[]=')).plus().trim(trimmer))
            .seq(char(')').trim(trimmer)).flatten());
    
    def('tableOrFilename',
        word().or(anyIn(r'./\:').or(localLetter())).plus()
        .or(ref('fieldrefInBrackets'))
        .or(ref('macro'))
        .or(ref('string'))
        .seq(ref('fileModifier').optional())
        .trim(trimmer));
//    def('fileName',
//        );
    def('whereClause',
        _token('where').or(_token('while')).trim(trimmer)
        .seq(ref('binaryExpression'))
        .trim(trimmer));
    def('assignment',
        _token('SET').or(_token('LET')).trim(trimmer)
        .seq(ref('identifier').or(ref('macro')).trim(trimmer))
        .seq(char('=').trim(trimmer))
        .seq(ref('expression').optional())
        .seq(char(';')).trim(trimmer).flatten()
        );
    def('call',
        _token('call').trim(trimmer)
        .seq(ref('subRoutine').trim(trimmer))
        .seq(char(';')).trim(trimmer).flatten()
        );
    def('simpleParens',
        char("(")
        .seq(char(")").neg().star())
        .seq(char(")")).trim(trimmer).flatten());
    def('macroLine',
        ref('macro').trim(trimmer)
        .seq(char(';')).trim(trimmer).flatten());
    def('fileModifierTokens',
        _token('embedded labels')
        .or(_token('explicit labels'))
        .or(_token('no')
            .seq(_token('quotes').
                or(_token('labels')).
                or(_token('eof'))))
        .or(_token('codepage is')
            .seq(ref('decimalInteger').plus())
            .or(_token('unicode'))
            .or(_token('ansi'))
            .or(_token('oem'))
            .or(_token('mac'))
            .or(_token('UTF').seq(char('-').optional().seq(char('8')))))
        .or(_token('table is').seq(ref('fieldref')))
        .or(_token('header').or(_token('record'))
            .seq(_token('is'))
            .seq(ref('decimalInteger'))
            .seq(_token('lines')))
        .or(_token('delimiter is').seq(ref('string')))
        .flatten());
    def('fileModifierElement',
        ref('fileModifierTokens')
        .or(ref('expression')));
    def('fileModifierElements',
        ref('fileModifierElement').separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def('fileModifier',
        _token('(')
         .seq(ref('fileModifierElements'))
         .seq(_token(')')));
    def('connect',
        _token('ODBC').or(_token('OLEDB')).or(_token('CUSTOM')).optional()
        .seq(_token('CONNECT'))
        .seq(_token('TO'))
        .seq(ref('string').trim(trimmer))
        .seq(ref('simpleParens').optional())
        .flatten()
        );
    def('controlStatement',
        ref('subStart')
        .or(ref('exit script'))
        .or(ref('forNextStart'))
        .or(ref('forEachStart'))
        .or(ref('ifStart'))
        .or(_token('ELSE'))
        .or(ref('controlStatementFinish')));
    def('controlStatementFinish',
        _token('END')
          .seq(_token('SUB').or(_token('IF')))
        .or(_token('NEXT')
          .seq(ref('identifier').optional()))
        .seq(_token(';').optional()));
    def('subStart',
        _token('SUB')
        .seq(ref('identifier').or(ref('function')))
        .seq(_token(';').optional()));
    def('exit script',
    _token('exit')
    .seq(_token('script'))
    .seq(_token(';').optional()));

    def('forNextStart',
        _token('FOR')
        .seq(ref('expression'))
        .seq(_token('to'))
        .seq(ref('expression'))
        .seq(_token(';').optional()));
    def('ifStart',
        _token('IF').or(_token('ELSEIF'))
        .seq(ref('expression'))
        .seq(_token('THEN'))
        .seq(_token(';').optional()));
    def('forEachStart',
        _token('FOR')
        .seq(_token('each'))
        .seq(ref('expression'))
        .seq(_token('each'))
        .seq(ref('expression'))
        .seq(_token(';').optional()));
    def('qualify',
        _token('UNQUALIFY').or(_token('QUALIFY'))
        .seq(ref('fieldrefOrStringList'))
        .seq(_token(';')).flatten());
    
    def('fieldrefOrStringList',
        ref('fieldrefOrString').separatedBy(char(',').trim(trimmer), includeSeparators: false));

    def('fieldrefOrString',
        ref('identifier')
        .or(ref('fieldrefInBrackets'))
        .or(ref('string')));
    def('fieldrefAs',
      ref('fieldref')
      .seq(_token('as')).
      seq(ref('fieldref')));
    def('fieldrefsAs',
      ref('fieldrefAs').separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def('alias',
      _token('ALIAS')
      .seq(ref('fieldrefsAs'))
      .seq(_token(';')));
    def('binaryStatement',
    _token('binary')
    .seq(ref('tableOrFilename'))
    .seq(_token(';')));

  }
  
  
  /** Defines the whitespace and comments. */
  void _whitespace() {
    
    def('whitespace', whitespace()
      .or(ref('singe line comment'))
      .or(ref('multi line comment')));
    def('singe line comment', string('//')
      .seq(Token.newlineParser().neg().star()));
    def('multi line comment', string('/*')
      .seq(string('*/').neg().star())
      .seq(string('*/')));
  }
 
  _expression() {
    def('expression',
        ref('binaryExpression').trim(trimmer)
        );   
    def('primaryExpression',
        ref('string')
        .or(ref('unaryExpression'))
        .or(ref('function'))
        .or(ref('number'))
        .or(ref('fieldref'))
        .or(ref('macro'))
        .or(ref('parens')));
    def('binaryExpression', ref('primaryExpression')
        .seq(ref('binaryPart').star()).trim(trimmer).flatten());
    def('binaryPart', ref('binaryOperator')
        .seq(ref('primaryExpression')));
    def('fieldref',
          _token(ref('identifier')
          .or(ref('macro'))
          .or(ref('fieldrefInBrackets'))));
    def('identifier',letter().or(char('_').or(char('@')).or(localLetter()))
        .seq(word().or(char('.')).or(char('_')).or(localLetter()).plus())
        .or(letter())
        .seq(whitespace().star().seq(char('(')).not())
        .flatten().trim(trimmer));
    def('fieldrefInBrackets', _token('[')
        .seq(_token(']').neg().plus())
        .seq(_token(']')).trim(trimmer).flatten());
    def('string',
            char("'")
              .seq(char("'").neg().star())
              .seq(char("'"))
            .or(char('"')
                .seq(char('"').neg().star())
                .seq(char('"'))).flatten());
   
    def('constant',
        ref('number').or(ref('string')));
    def('function',
        letter()
        .seq(word().or(char('.')).plus())
        .seq(char('#').optional())
        .trim(trimmer)
        .seq(char('(').trim(trimmer))
        .seq(ref('params').optional())
        .seq(char(')').trim(trimmer)).flatten());
    def('unaryExpression',
        _token('NOT').or(_token('-').or(_token('DISTINCT'))).trim(trimmer)
            .seq(ref('expression'))
            .trim(trimmer).flatten());
    def('binaryOperator',
        _token('and')
        .or(_token('or'))
        .or(_token('xor'))
        .or(_token('like'))
        .or(_token('<='))
        .or(_token('<>'))
        .or(_token('!='))
        .or(_token('>='))
        .or(anyIn('+-/*<>=&'))
        .or(_token('precedes'))
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
  
  void _number() {
    // Implementation borrowed from Smalltalk parser
    def('number', char('-').optional()
        .seq(ref('positiveNumber')).flatten());
    def('positiveNumber', ref('scaledDecimal')
        .or(ref('float'))
        .or(ref('integer')));

    def('integer', ref('radixInteger')
        .or(ref('decimalInteger')));
    def('decimalInteger', ref('digits'));
    def('digits', digit().plus());
    def('radixInteger', ref('radixSpecifier')
        .seq(char('r'))
        .seq(ref('radixDigits')));
    def('radixSpecifier', ref('digits'));
    def('radixDigits', pattern('0-9A-Z').plus());

    def('float', ref('mantissa')
        .seq(ref('exponentLetter')
            .seq(ref('exponent'))
            .optional()));
    def('mantissa', ref('digits')
        .seq(char('.'))
        .seq(ref('digits')));
    def('exponent', char('-')
        .seq(ref('decimalInteger')));
    def('exponentLetter', pattern('edq'));

    def('scaledDecimal', ref('scaledMantissa')
        .seq(char('s'))
        .seq(ref('fractionalDigits').optional()));
    def('scaledMantissa', ref('decimalInteger')
        .or(ref('mantissa')));
    def('fractionalDigits', ref('decimalInteger'));
  }

}
