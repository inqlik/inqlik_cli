part of qvs_parser;

/**
 * Smalltalk grammar definition.
 */
class QvsGrammar extends CompositeParser {

  void initialize() {
    _whitespace();
    _number();
    _qvs();
//    _builtIns();
  }
  void _qvs() {
    def('start', ref('command').plus().end().flatten());
    def('command',
        ref('macroLine')
        .or(ref('load'))
        .or(ref('call'))
        .or(ref('drop fields'))
        .or(ref('drop table'))
        .or(ref('rename table'))
        .or(ref('rename field'))
        .or(ref('store table')) 
        .or(ref('load inline'))
        .or(ref('load autogenerate'))        
        .or(ref('assignment')));
    def('rename table',
        _token('RENAME')
        .seq(_token('TABLE'))
        .seq(ref('fieldref'))
        .seq(_token('TO'))
        .seq(ref('fieldref'))
        .seq(char(';'))
        .trim(ref('whitespace')).flatten());
    def('rename field',
        _token('RENAME')
        .seq(_token('FIELD'))
        .seq(ref('fieldref'))
        .seq(_token('TO'))
        .seq(ref('fieldref'))
        .seq(char(';'))
        .trim(ref('whitespace')).flatten());

    def('load',
        ref('tableDesignator').optional()
        .seq(_token('Noconcatenate').optional())
        .seq(_token('MAPPING').optional())
        .seq(ref('preceding load').star())
        .seq(ref('preload func').optional())
        .seq(_token('LOAD'))
        .seq(ref('selectList').trim(ref('whitespace')))
        .seq(_token('RESIDENT').or(_token('FROM')))
        .seq(ref('table'))
        .seq(ref('whereClause').optional())
        .seq(ref('group by').optional())
        .seq(ref('order by').optional())
        .seq(char(';'))
          .trim(ref('whitespace')).flatten());
    def('preceding load',
        _token('LOAD')
        .seq(ref('selectList').trim(ref('whitespace')))
        .seq(char(';'))
          .trim(ref('whitespace')).flatten());
   
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
        .trim(ref('whitespace')).flatten());
    def('drop table',
        _token('DROP')
        .seq(_token('TABLE'))
        .seq(ref('fieldref'))
        .seq(char(';'))
        .trim(ref('whitespace')).flatten());
    def('store table',
        _token('STORE')
        .seq(ref('fieldref'))
        .seq(_token('INTO'))
        .seq(ref('table'))
        .seq(char(';'))
        .trim(ref('whitespace')).flatten());
    
    def('selectList',
        ref('field').or(char('*')).separatedBy(char(',').trim(ref('whitespace')), includeSeparators: false));
    def('field',
        ref('expression').seq(_token('as')).seq(ref('fieldref'))
        .or(ref('expression'))
        .trim(ref('whitespace')).flatten());
    def('expression',
        ref('binaryExpression').trim(ref('whitespace'))
        );   
    def('join',
        _token('LEFT').or(_token('RIGHT')).or(_token('INNER')).optional()
        .seq(_token('JOIN').or(_token('KEEP')))
        .seq(ref('table in parens').optional())
        .flatten());
    def('preload func',
        _token('Hierarchy').or(_token('IntervalMatch'))
        .seq(ref('simpleParens'))
        .flatten());
    def('load inline',
        ref('tableDesignator').optional()
          .seq(_token('LOAD'))
          .seq(_token('*'))
          .seq(_token('INLINE'))
          .seq(_token('['))
          .seq(_token(']').neg().plus())
          .seq(_token(']'))
          .seq(char(';'))
          .trim(ref('whitespace')).flatten());
    def('load autogenerate',
        ref('tableDesignator').optional()
        .seq(_token('Noconcatenate').optional())
        .seq(_token('LOAD'))
        .seq(_token('DISTINCT').optional())
        .seq(ref('selectList').trim(ref('whitespace')))
        .seq(_token('autogenerate'))
        .seq(ref('expression'))
        .seq(ref('while clause').optional())
        .seq(char(';'))
          .trim(ref('whitespace')).flatten());
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

    def('primaryExpression',
        ref('string')
        .or(ref('unaryExpression'))
        .or(ref('function'))
        .or(ref('number'))
        .or(ref('fieldref'))
        .or(ref('macro'))
        .or(ref('parens')));
    
    def('binaryExpression', ref('primaryExpression')
        .seq(ref('binaryPart').star()).trim(ref('whitespace')).flatten());
    def('binaryPart', ref('binaryOperator')
        .seq(ref('primaryExpression')));
    def('fieldref',
          ref('identifier')
          .or(ref('fieldrefInBrackets')));
    def('fieldrefs',
        ref('fieldref').separatedBy(char(',').trim(ref('whitespace')), includeSeparators: false));
    def('fieldrefsOrderBy',
        ref('fieldrefOrderBy').separatedBy(char(',').trim(ref('whitespace')), includeSeparators: false));

    def('fieldrefOrderBy',
        ref('identifier')
        .or(ref('fieldrefInBrackets'))
        .seq(_token('DESC').optional()));
    
    def('identifier',letter().or(char('_').or(char('@')))
        .seq(word().or(char('.')).or(char('_')).plus())
        .seq(whitespace().star().seq(char('(')).not())
        .flatten().trim(ref('whitespace')));
    def('fieldrefInBrackets', _token('[')
        .seq(_token(']').neg().plus())
        .seq(_token(']')).trim(ref('whitespace')).flatten());
    def('string',
            char("'")
            .seq(char("'").neg().star())
            .seq(char("'")).flatten());
    def('tableDesignator',
        ref('fieldref').seq(char(':'))
        .or(ref('join'))
        .or(ref('concatenate')).plus()
        .trim(ref('whitespace')).flatten()
        );
    def('constant',
        ref('number').or(ref('string')));
    def('function',
        letter()
        .seq(word().plus())
        .seq(char('#').optional())
        .trim(ref('whitespace'))
        .seq(char('(').trim(ref('whitespace')))
        .seq(ref('params').optional())
        .seq(char(')').trim(ref('whitespace'))).flatten());
    def('subRoutine',
        word().or(char('.')).plus().trim(ref('whitespace'))
        .seq(char('(').trim(ref('whitespace')))
        .seq(ref('params').optional())
        .seq(char(')').trim(ref('whitespace'))).flatten());
    def('params',
        ref('expression').separatedBy(char(',').trim(ref('whitespace')), includeSeparators: false));
    def('parens',
        char('(').trim(ref('whitespace'))
            .seq(ref('expression'))
            .seq(char(')').trim(ref('whitespace'))).flatten());
    def('macro',
        _token(r'$(')
            .seq(word().or(anyIn(r'./\[]=')).plus().trim(ref('whitespace')))
            .seq(char(')').trim(ref('whitespace'))).flatten());
    
    def('unaryExpression',
        _token('NOT').or(_token('-').or(_token('DISTINCT'))).trim(ref('whitespace'))
            .seq(ref('expression'))
            .trim(ref('whitespace')).flatten());
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
        .trim(ref('whitespace')).flatten()
        );
    def('table',
        word().or(anyIn(r'./\[]:')).plus()
        .seq(ref('simpleParens').optional())
        .trim(ref('whitespace')));
    def('whereClause',
        _token('where').trim(ref('whitespace'))
        .seq(ref('binaryExpression'))
        .trim(ref('whitespace')));
    def('assignment',
        _token('SET').or(_token('LET')).trim(ref('whitespace'))
        .seq(ref('identifier').trim(ref('whitespace')))
        .seq(char('=').trim(ref('whitespace')))
        .seq(ref('expression').optional())
        .seq(char(';')).trim(ref('whitespace')).flatten()
        );
    def('call',
        _token('call').trim(ref('whitespace'))
        .seq(ref('subRoutine').trim(ref('whitespace')))
        .seq(char(';')).trim(ref('whitespace')).flatten()
        );
    def('simpleParens',
        char("(")
        .seq(char(")").neg().star())
        .seq(char(")")).trim(ref('whitespace')).flatten());
    def('value',
        ref('string')
        .or(ref('number'))
        .or(ref('array'))
        .or(ref('function')));   
    def('array',
        char('[').trim(ref('whitespace'))
        .seq(ref('elements').optional())
        .seq(char(']').trim(ref('whitespace'))));
    def('elements',
      ref('value').separatedBy(char(',').trim(ref('whitespace')), includeSeparators: false));
    def('macroLine',
        ref('macro').trim(ref('whitespace'))
        .seq(char(';')).trim(ref('whitespace')).flatten());
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

  /** Defines a token parser that consumes whitespace. */
  Parser _token(dynamic input) {
    var parser = input is Parser ? parser :
        input.length == 1 ? char(input) :
        stringIgnoreCase(input);
    return parser.token().trim(ref('whitespace'));
  }
  
  void _number() {
    // the original implementation uses the hand written number
    // parser of the system, this is the spec of the ANSI standard
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
