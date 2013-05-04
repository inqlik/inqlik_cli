library qlikview_script;

import 'package:petitparser/petitparser.dart';

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
        .or(ref('assignment')));
    def('load',
        ref('tableDesignator').optional()
        .seq(_token('LOAD').trim(ref('whitespace')))
        .seq(ref('selectList'))
        .seq(_token('FROM').or(_token('RESIDENT')))
        .seq(ref('table'))
        .seq(ref('whereClause').optional())
        .seq(char(';'))
          .trim(ref('whitespace')).flatten());
    def('selectList',
        ref('field').or(char('*')).separatedBy(char(',').trim(ref('whitespace')), includeSeparators: false));
    def('field',
        ref('expression').seq(_token('as')).seq(ref('fieldref'))
        .or(ref('fieldref'))
        .trim(ref('whitespace')).flatten());
    def('expression',
        ref('binaryExpression').trim(ref('whitespace'))
        );   
    def('join',
        _token('left').or(_token('right')).optional()
        );
    def('primaryExpression',
        ref('string')
        .or(ref('negatedExpression'))
        .or(ref('function'))
        .or(ref('number'))
        .or(ref('fieldref'))
        .or(ref('macro'))
        .or(ref('parens')));
    
    def('binaryExpression', ref('primaryExpression')
        .seq(ref('binaryPart').star())..trim(ref('whitespace')).flatten());
    def('binaryPart', ref('binaryOperator')
        .seq(ref('primaryExpression')));
    def('fieldref',
          ref('identifier')
          .or(ref('fieldrefInBrackets')));
    def('identifier',letter()
        .seq(word().or(char('.')).plus())
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
    
    def('negatedExpression',
        _token('NOT').trim(ref('whitespace'))
            .seq(ref('expression'))
            .trim(ref('whitespace')).flatten());
    def('binaryOperator',
        _token('and')
        .or(_token('or'))
        .or(_token('xor'))
        .or(_token('like'))
        .or(_token('<='))
        .or(_token('>='))
        .or(anyIn('+-/*<>=&'))
        .or(_token('precedes'))
        .trim(ref('whitespace')).flatten()
        );
    def('table',
        word().or(anyIn(r'./\[]')).plus()
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

  void _builtIns() {
    def('builtInFunctionName',
   _token('if')
  .or(_token('aggr'))
  .or(_token('left'))
  .or(_token('right'))
  .or(_token('acos'))
  .or(_token('addmonths'))
  .or(_token('addyears'))
  .or(_token('age'))
  .or(_token('alt'))
  .or(_token('applycodepage'))
  .or(_token('applymap'))
  .or(_token('argb'))
  .or(_token('asin'))
  .or(_token('atan'))
  .or(_token('atan2'))
  .or(_token('attribute'))
  .or(_token('author'))
  .or(_token('autonumber'))
  .or(_token('autonumberhash128'))
  .or(_token('autonumberhash256'))
  .or(_token('avg'))
  .or(_token('bitcount'))
  .or(_token('black'))
  .or(_token('blackandschole'))
  .or(_token('blue'))
  .or(_token('brown'))
  .or(_token('capitalize'))
  .or(_token('ceil'))
  .or(_token('chi2test_chi2'))
  .or(_token('chi2test_df'))
  .or(_token('chi2test_p'))
  .or(_token('chidist'))
  .or(_token('chiinv'))
  .or(_token('chr'))
  .or(_token('class'))
  .or(_token('clientplatform'))
  .or(_token('color'))
  .or(_token('colormaphue'))
  .or(_token('colormapjet'))
  .or(_token('colormix1'))
  .or(_token('colormix2'))
  .or(_token('combin'))
  .or(_token('computername'))
  .or(_token('concat'))
  .or(_token('connectstring'))
  .or(_token('converttolocaltime'))
  .or(_token('correl'))
  .or(_token('cos'))
  .or(_token('cosh'))
  .or(_token('count'))
  .or(_token('cyan'))
  .or(_token('darkgray'))
  .or(_token('date'))
  .or(_token('date#'))
  .or(_token('day'))
  .or(_token('dayend'))
  .or(_token('daylightsaving'))
  .or(_token('dayname'))
  .or(_token('daynumberofquarter'))
  .or(_token('daynumberofyear'))
  .or(_token('daystart'))
  .or(_token('div'))
  .or(_token('DocumentName'))
  .or(_token('DocumentPath'))
  .or(_token('DocumentTitle'))
  .or(_token('Dual'))
  .or(_token('e'))
  .or(_token('Evaluate'))
  .or(_token('Even'))
  .or(_token('Exists'))
  .or(_token('exp'))
  .or(_token('fabs'))
  .or(_token('Fact'))
  .or(_token('False'))
  .or(_token('FDIST'))
  .or(_token('FieldIndex'))
  .or(_token('FieldName'))
  .or(_token('FieldNumber'))
  .or(_token('FieldValue'))
  .or(_token('FieldValueCount'))
  .or(_token('FileBaseName'))
  .or(_token('FileDir'))
  .or(_token('FileExtension'))
  .or(_token('FileName'))
  .or(_token('FilePath'))
  .or(_token('FileSize'))
  .or(_token('FileTime'))
  .or(_token('FindOneOf'))
  .or(_token('FINV'))
  .or(_token('FirstSortedValue'))
  .or(_token('FirstValue'))
  .or(_token('FirstWorkDate'))
  .or(_token('Floor'))
  .or(_token('fmod'))
  .or(_token('Frac'))
  .or(_token('Fractile'))
  .or(_token('FV'))
  .or(_token('GetExtendedProperty'))
  .or(_token('GetFolderPath'))
  .or(_token('GetObjectField'))
  .or(_token('GetRegistryString'))
  .or(_token('GMT'))
  .or(_token('Green'))
  .or(_token('Hash128'))
  .or(_token('Hash160'))
  .or(_token('Hash256'))
  .or(_token('Hour'))
  .or(_token('HSL'))
  .or(_token('InDay'))
  .or(_token('InDayToTime'))
  .or(_token('Index'))
  .or(_token('InLunarWeek'))
  .or(_token('InLunarWeekToDate'))
  .or(_token('InMonth'))
  .or(_token('InMonths'))
  .or(_token('InMonthsToDate'))
  .or(_token('InMonthToDate'))
  .or(_token('Input'))
  .or(_token('InputAvg'))
  .or(_token('InputSum'))
  .or(_token('InQuarter'))
  .or(_token('InQuarterToDate'))
  .or(_token('Interval'))
  .or(_token('Interval#'))
  .or(_token('InWeek'))
  .or(_token('InWeekToDate'))
  .or(_token('InYear'))
  .or(_token('InYearToDate'))
  .or(_token('IRR'))
  .or(_token('IsNull'))
  .or(_token('IsNum'))
  .or(_token('IsPartialReload'))
  .or(_token('IsText'))
  .or(_token('IterNo'))
  .or(_token('KeepChar'))
  .or(_token('Kurtosis'))
  .or(_token('LastValue'))
  .or(_token('LastWorkDate'))
  .or(_token('Len'))
  .or(_token('LightBlue'))
  .or(_token('LightCyan'))
  .or(_token('LightGray'))
  .or(_token('LightGreen'))
  .or(_token('LightMagenta'))
  .or(_token('LightRed'))
  .or(_token('LINEST_B'))
  .or(_token('LINEST_DF'))
  .or(_token('LINEST_F'))
  .or(_token('LINEST_M'))
  .or(_token('LINEST_R2'))
  .or(_token('LINEST_SEB'))
  .or(_token('LINEST_SEM'))
  .or(_token('LINEST_SEY'))
  .or(_token('LINEST_SSREG'))
  .or(_token('LINEST_SSRESID'))
  .or(_token('LocalTime'))
  .or(_token('log'))
  .or(_token('log10'))
  .or(_token('Lookup'))
  .or(_token('Lower'))
  .or(_token('LTrim'))
  .or(_token('LunarWeekEnd'))
  .or(_token('LunarWeekName'))
  .or(_token('LunarWeekStart'))
  .or(_token('Magenta'))
  .or(_token('MakeDate'))
  .or(_token('MakeTime'))
  .or(_token('MakeWeekDate'))
  .or(_token('MapSubString'))
  .or(_token('Match'))
  .or(_token('Max'))
  .or(_token('MaxString'))
  .or(_token('Median'))
  .or(_token('Mid'))
  .or(_token('Min'))
  .or(_token('MinString'))
  .or(_token('Minute'))
  .or(_token('MissingCount'))
  .or(_token('MixMatch'))
  .or(_token('Mod'))
  .or(_token('Mode'))
  .or(_token('Money'))
  .or(_token('Money#'))
  .or(_token('Month'))
  .or(_token('MonthEnd'))
  .or(_token('MonthName'))
  .or(_token('MonthsEnd'))
  .or(_token('MonthsName'))
  .or(_token('MonthsStart'))
  .or(_token('MonthStart'))
  .or(_token('MsgBox'))
  .or(_token('NetWorkDays'))
  .or(_token('NoOfFields'))
  .or(_token('NoOfReports'))
  .or(_token('NoOfRows'))
  .or(_token('NoOfTables'))
  .or(_token('NORMDIST'))
  .or(_token('NORMINV'))
  .or(_token('Now'))
  .or(_token('nPer'))
  .or(_token('NPV'))
  .or(_token('Null'))
  .or(_token('NullCount'))
  .or(_token('Num'))
  .or(_token('Num#'))
  .or(_token('NumAvg'))
  .or(_token('NumCount'))
  .or(_token('NumericCount'))
  .or(_token('NumMax'))
  .or(_token('NumMin'))
  .or(_token('NumSum'))
  .or(_token('Odd'))
  .or(_token('Only'))
  .or(_token('Ord'))
  .or(_token('OSUser'))
  .or(_token('Peek'))
  .or(_token('Permut'))
  .or(_token('Pi'))
  .or(_token('Pick'))
  .or(_token('Pmt'))
  .or(_token('pow'))
  .or(_token('Previous'))
  .or(_token('PurgeChar'))
  .or(_token('PV'))
  .or(_token('QlikTechBlue'))
  .or(_token('QlikTechGray'))
  .or(_token('QlikViewVersion'))
  .or(_token('QuarterEnd'))
  .or(_token('QuarterName'))
  .or(_token('QuarterStart'))
  .or(_token('QvdCreateTime'))
  .or(_token('QvdFieldName'))
  .or(_token('QvdNoOfFields'))
  .or(_token('QvdNoOfRecords'))
  .or(_token('QvdTableName'))
  .or(_token('QVUser'))
  .or(_token('Rand'))
  .or(_token('RangeAvg'))
  .or(_token('RangeCorrel'))
  .or(_token('RangeCount'))
  .or(_token('RangeFractile'))
  .or(_token('RangeIRR'))
  .or(_token('RangeKurtosis'))
  .or(_token('RangeMax'))
  .or(_token('RangeMaxString'))
  .or(_token('RangeMin'))
  .or(_token('RangeMinString'))
  .or(_token('RangeMissingCount'))
  .or(_token('RangeMode'))
  .or(_token('RangeNPV'))
  .or(_token('RangeNullCount'))
  .or(_token('RangeNumericCount'))
  .or(_token('RangeOnly'))
  .or(_token('RangeSkew'))
  .or(_token('RangeStdev'))
  .or(_token('RangeSum'))
  .or(_token('RangeTextCount'))
  .or(_token('RangeXIRR'))
  .or(_token('RangeXNPV'))
  .or(_token('Rate'))
  .or(_token('RecNo'))
  .or(_token('Red'))
  .or(_token('ReloadTime'))
  .or(_token('Repeat'))
  .or(_token('Replace'))
  .or(_token('ReportComment'))
  .or(_token('ReportId'))
  .or(_token('ReportName'))
  .or(_token('ReportNumber'))
  .or(_token('RGB'))
  .or(_token('Round'))
  .or(_token('RowNo'))
  .or(_token('RTrim'))
  .or(_token('Second'))
  .or(_token('SetDateYear'))
  .or(_token('SetDateYearMonth'))
  .or(_token('Sign'))
  .or(_token('sin'))
  .or(_token('sinh'))
  .or(_token('Skew'))
  .or(_token('sqr'))
  .or(_token('sqrt'))
  .or(_token('Stdev'))
  .or(_token('Sterr'))
  .or(_token('STEYX'))
  .or(_token('SubField'))
  .or(_token('SubStringCount'))
  .or(_token('Sum'))
  .or(_token('SysColor'))
  .or(_token('TableName'))
  .or(_token('TableNumber'))
  .or(_token('tan'))
  .or(_token('tanh'))
  .or(_token('TDIST'))
  .or(_token('Text'))
  .or(_token('TextBetween'))
  .or(_token('TextCount'))
  .or(_token('Time'))
  .or(_token('Time#'))
  .or(_token('Timestamp'))
  .or(_token('Timestamp#'))
  .or(_token('TimeZone'))
  .or(_token('TINV'))
  .or(_token('Today'))
  .or(_token('Trim'))
  .or(_token('True'))
  .or(_token('TTest1_conf'))
  .or(_token('TTest1_df'))
  .or(_token('TTest1_dif'))
  .or(_token('TTest1_lower'))
  .or(_token('TTest1_sig'))
  .or(_token('TTest1_sterr'))
  .or(_token('TTest1_t'))
  .or(_token('TTest1_upper'))
  .or(_token('TTest1w_conf'))
  .or(_token('TTest1w_df'))
  .or(_token('TTest1w_dif'))
  .or(_token('TTest1w_lower'))
  .or(_token('TTest1w_sig'))
  .or(_token('TTest1w_sterr'))
  .or(_token('TTest1w_t'))
  .or(_token('TTest1w_upper'))
  .or(_token('TTest_conf'))
  .or(_token('TTest_df'))
  .or(_token('TTest_dif'))
  .or(_token('TTest_lower'))
  .or(_token('TTest_sig'))
  .or(_token('TTest_sterr'))
  .or(_token('TTest_t'))
  .or(_token('TTest_upper'))
  .or(_token('TTestw_conf'))
  .or(_token('TTestw_df'))
  .or(_token('TTestw_dif'))
  .or(_token('TTestw_lower'))
  .or(_token('TTestw_sig'))
  .or(_token('TTestw_sterr'))
  .or(_token('TTestw_t'))
  .or(_token('TTestw_upper'))
  .or(_token('Upper'))
  .or(_token('UTC'))
  .or(_token('Week'))
  .or(_token('WeekDay'))
  .or(_token('WeekEnd'))
  .or(_token('WeekName'))
  .or(_token('WeekStart'))
  .or(_token('WeekYear'))
  .or(_token('White'))
  .or(_token('WildMatch'))
  .or(_token('WildMatch5'))
  .or(_token('XIRR'))
  .or(_token('XNPV'))
  .or(_token('Year'))
  .or(_token('Year2Date'))
  .or(_token('YearEnd'))
  .or(_token('YearName'))
  .or(_token('YearStart'))
  .or(_token('YearToDate'))
  .or(_token('Yellow'))
  .or(_token('ZTest_conf'))
  .or(_token('ZTest_dif'))
  .or(_token('ZTest_lower'))
  .or(_token('ZTest_sig'))
  .or(_token('ZTest_sterr'))
  .or(_token('ZTest_upper'))
  .or(_token('ZTest_z'))
  .or(_token('ZTestw_conf'))
  .or(_token('ZTestw_dif'))
  .or(_token('ZTestw_lower'))
  .or(_token('ZTestw_sig'))
  .or(_token('ZTestw_sterr'))
  .or(_token('ZTestw_upper'))
  .or(_token('ZTestw_z'))
  .flatten());
//
//    
//    def('builtInFunctionName',
//        pattern('(if|aggr|left|right|acos|addmonths|addyears|age|alt|applycodepage|applymap|argb|asin|atan|atan2|attribute|author|autonumber|autonumberhash128|autonumberhash256|avg|bitcount|black|blackandschole|blue|brown|capitalize|ceil|chi2test_chi2|chi2test_df|chi2test_p|chidist|chiinv|chr|class|clientplatform|color|colormaphue|colormapjet|colormix1|colormix2|combin|computername|concat|connectstring|converttolocaltime|correl|cos|cosh|count|cyan|darkgray|date|date#|day|dayend|daylightsaving|dayname|daynumberofquarter|daynumberofyear|daystart|div|DocumentName|DocumentPath|DocumentTitle|Dual|e|Evaluate|Even|Exists|exp|fabs|Fact|False|FDIST|FieldIndex|FieldName|FieldNumber|FieldValue|FieldValueCount|FileBaseName|FileDir|FileExtension|FileName|FilePath|FileSize|FileTime|FindOneOf|FINV|FirstSortedValue|FirstValue|FirstWorkDate|Floor|fmod|Frac|Fractile|FV|GetExtendedProperty|GetFolderPath|GetObjectField|GetRegistryString|GMT|Green|Hash128|Hash160|Hash256|Hour|HSL|InDay|InDayToTime|Index|InLunarWeek|InLunarWeekToDate|InMonth|InMonths|InMonthsToDate|InMonthToDate|Input|InputAvg|InputSum|InQuarter|InQuarterToDate|Interval|Interval#|InWeek|InWeekToDate|InYear|InYearToDate|IRR|IsNull|IsNum|IsPartialReload|IsText|IterNo|KeepChar|Kurtosis|LastValue|LastWorkDate|Len|LightBlue|LightCyan|LightGray|LightGreen|LightMagenta|LightRed|LINEST_B|LINEST_DF|LINEST_F|LINEST_M|LINEST_R2|LINEST_SEB|LINEST_SEM|LINEST_SEY|LINEST_SSREG|LINEST_SSRESID|LocalTime|log|log10|Lookup|Lower|LTrim|LunarWeekEnd|LunarWeekName|LunarWeekStart|Magenta|MakeDate|MakeTime|MakeWeekDate|MapSubString|Match|Max|MaxString|Median|Mid|Min|MinString|Minute|MissingCount|MixMatch|Mod|Mode|Money|Money#|Month|MonthEnd|MonthName|MonthsEnd|MonthsName|MonthsStart|MonthStart|MsgBox|NetWorkDays|NoOfFields|NoOfReports|NoOfRows|NoOfTables|NORMDIST|NORMINV|Now|nPer|NPV|Null|NullCount|Num|Num#|NumAvg|NumCount|NumericCount|NumMax|NumMin|NumSum|Odd|Only|Ord|OSUser|Peek|Permut|Pi|Pick|Pmt|pow|Previous|PurgeChar|PV|QlikTechBlue|QlikTechGray|QlikViewVersion|QuarterEnd|QuarterName|QuarterStart|QvdCreateTime|QvdFieldName|QvdNoOfFields|QvdNoOfRecords|QvdTableName|QVUser|Rand|RangeAvg|RangeCorrel|RangeCount|RangeFractile|RangeIRR|RangeKurtosis|RangeMax|RangeMaxString|RangeMin|RangeMinString|RangeMissingCount|RangeMode|RangeNPV|RangeNullCount|RangeNumericCount|RangeOnly|RangeSkew|RangeStdev|RangeSum|RangeTextCount|RangeXIRR|RangeXNPV|Rate|RecNo|Red|ReloadTime|Repeat|Replace|ReportComment|ReportId|ReportName|ReportNumber|RGB|Round|RowNo|RTrim|Second|SetDateYear|SetDateYearMonth|Sign|sin|sinh|Skew|sqr|sqrt|Stdev|Sterr|STEYX|SubField|SubStringCount|Sum|SysColor|TableName|TableNumber|tan|tanh|TDIST|Text|TextBetween|TextCount|Time|Time#|Timestamp|Timestamp#|TimeZone|TINV|Today|Trim|True|TTest1_conf|TTest1_df|TTest1_dif|TTest1_lower|TTest1_sig|TTest1_sterr|TTest1_t|TTest1_upper|TTest1w_conf|TTest1w_df|TTest1w_dif|TTest1w_lower|TTest1w_sig|TTest1w_sterr|TTest1w_t|TTest1w_upper|TTest_conf|TTest_df|TTest_dif|TTest_lower|TTest_sig|TTest_sterr|TTest_t|TTest_upper|TTestw_conf|TTestw_df|TTestw_dif|TTestw_lower|TTestw_sig|TTestw_sterr|TTestw_t|TTestw_upper|Upper|UTC|Week|WeekDay|WeekEnd|WeekName|WeekStart|WeekYear|White|WildMatch|WildMatch5|XIRR|XNPV|Year|Year2Date|YearEnd|YearName|YearStart|YearToDate|Yellow|ZTest_conf|ZTest_dif|ZTest_lower|ZTest_sig|ZTest_sterr|ZTest_upper|ZTest_z|ZTestw_conf|ZTestw_dif|ZTestw_lower|ZTestw_sig|ZTestw_sterr|ZTestw_upper|ZTestw_z)')
//        .flatten());
    
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
