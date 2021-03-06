library qvs_productions;

// Expression grammar productions
const String whitespace = 'whitespace';
const String singeLineComment = 'singeLineComment';
const String remComment = 'remComment';
const String multiLineComment = 'multiLineComment';
const String trimFromStart = 'trimFromStart';
const String number = 'number';
const String positiveNumber = 'positiveNumber';
const String parens = 'parens';
const String integer = 'integer';
const String decimalInteger = 'decimalInteger';
const String digits = 'digits';
const String radixInteger = 'radixInteger';
const String radixSpecifier = 'radixSpecifier';
const String radixDigits = 'radixDigits';
const String float = 'float';
const String mantissa = 'mantissa';
const String exponent = 'exponent';
const String exponentLetter = 'exponentLetter';
const String scaledDecimal = 'scaledDecimal';
const String scaledMantissa = 'scaledMantissa';
const String fractionalDigits = 'fractionalDigits';
const String expression = 'expression';
const String macroExpression = 'macroExpression';
const String primaryExpression = 'primaryExpression';
const String binaryExpression = 'binaryExpression';
const String binaryPart = 'binaryPart';
const String identifier = 'identifier';
const String alternateStateIdentifier = 'alternateStateIdentifier';
const String varName = 'varName';
const String fieldName = 'fieldName';
const String fieldrefInBrackets = 'fieldrefInBrackets';
const String str = 'str';
const String constant = 'constant';
const String function = 'function';
const String userFunction = 'userFunction';
const String macroFunction = 'macroFunction';
const String unaryExpression = 'unaryExpression';
const String binaryOperator = 'binaryOperator';
const String start = 'start';
const String params = 'params';
const String paramsOptional = 'paramsOptional';
const String setExpression = 'setExpression';
const String setEntity = 'setEntity';
const String setEntitySimple = 'setEntitySimple';
const String setEntityPrimary = 'setEntityPrimary';
const String setEntityInParens = 'setEntityInParens';
const String setIdentifier = 'setIdentifier';
const String setOperator = 'setOperator';
const String setModifier = 'setModifier';
const String setFieldSelection = 'setFieldSelection';
const String setElementSetExpression = 'setElementSetExpression';
const String setElementSet = 'setElementSet';
const String setElementList = 'setElementList';
const String setElementFunction = 'setElementFunction';
const String setElement = 'setElement';
const String setElementSetInParens = 'setElementSetInParens';
const String setElementSetPrimary = 'setElementSetPrimary';
const String totalClause = 'totalClause';
const String distinctClause = 'distinctClause';
const String totalModifier = 'totalModifier';
const String functionModifier = 'functionModifier';


/// QVS grammar productiond
const String includeDirective = 'includeDirective';
const String doWhile = 'doWhile';
const String fieldref = 'fieldref';
const String subDeclaration = 'subDeclaration';
const String command = 'command';
const String commandInternal = 'commandInternal';
const String renameTable = 'renameTable';
const String renameField = 'renameField';
const String load = 'load';
//const String precedingLoad = 'precedingLoad';
const String loadPerfix = 'loadPerfix';
const String sleep  = 'sleep';
const String bufferModifier = 'bufferModifier';
const String loadSource = 'loadSource';
const String loadSourceStandart = 'loadSourceStandart';
const String loadSourceInline = 'loadSourceInline';
const String loadSourceAutogenerate = 'loadSourceAutogenerate';
const String from = 'from';
const String dropFields = 'dropFields';
const String dropTable = 'dropTable';
const String storeTable = 'storeTable';
const String selectList = 'selectList';
const String commentWith = 'commentWith';
const String stringOrNotSemicolon = 'stringOrNotSemicolon';
const String join = 'join';
const String preloadFunc = 'preloadFunc';
const String whileClause = 'whileClause';
const String concatenate = 'concatenate';
const String tableInParens = 'tableInParens';
const String groupBy = 'groupBy';
const String orderBy = 'orderBy';
const String fieldrefs = 'fieldrefs';
const String fieldrefsOrderBy = 'fieldrefsOrderBy';
const String fieldrefOrderBy = 'fieldrefOrderBy';
const String tableDesignator = 'tableDesignator';
const String tableIdentifier = 'tableIdentifier';
const String macro = 'macro';
const String tableOrFilename = 'tableOrFilename';
const String whereClause = 'whereClause';
const String whenClause = 'whenClause';
const String letAssignment = 'letAssignment';
const String setAssignment = 'setAssignment';
const String assignment = 'assignment';
const String call = 'call';
const String simpleParens = 'simpleParens';
const String macroLine = 'macroLine';
const String fileModifierTokens = 'fileModifierTokens';
const String fileModifierElement = 'fileModifierElement';
const String fileModifierElements = 'fileModifierElements';
const String fileModifier = 'fileModifier';
const String tableSelectModifier = 'tableSelectModifier';
const String connect = 'connect';
const String controlStatement = 'controlStatement';
const String controlStatementFinish = 'controlStatementFinish';
const String subStart = 'subStart';
const String exitScript = 'exitScript';
const String forNextStart = 'forNextStart';
const String ifStart = 'ifStart';
const String forEachStart = 'forEachStart';
const String forEachFileMaskStart = 'forEachFileMaskStart';
const String qualify = 'qualify';
const String fieldrefOrStringList = 'fieldrefOrStringList';
const String fieldrefOrString = 'fieldrefOrString';
const String fieldrefAs = 'fieldrefAs';
const String fieldrefsAs = 'fieldrefsAs';
const String alias = 'alias';
const String binaryStatement = 'binaryStatement';
const String trace = 'trace';
const String execute = 'execute';
const String sqltables = 'sqltables';
const String directory = 'directory';
const String defaultStatement = 'defaultStatement';
const String switchStatement = 'switchStatement';
const String caseStatement = 'caseStatement';
const String disconnect = 'disconnect';
const String sqlTables = 'sqlTables';




