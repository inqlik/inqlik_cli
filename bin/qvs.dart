import 'package:petitparser/petitparser.dart';
import 'dart:io';
import 'qvs_grammar.dart';
var input = r'''
InventTrans:
LOAD Num(DayStart(Дата)) as Дата, 
     Номенклатура as НоменклатураСсылка,
     ХарактеристикаНоменклатуры as ХарактеристикаНоменклатурыСсылка,
 /*    Количество * If(ВидДвижения = 'Расход',-1,1) as */ ПроводкаКоличество, 
     Стоимость * If(ВидДвижения = 'Расход',-1,1) as ПроводкаСтоимость, 
//     Склад as СкладСсылка, 
     КодОперации,
     Регистратор,
     СерияНоменклатуры as СерияНоменклатурыСсылка, 
     ДокументДвижения,
     Dual('ПартииПоТовару',1) as ТипПроводки
FROM
[..\Data\Source\ПартииПоТовару.txt]
(txt, utf8, embedded labels, delimiter is '\t', no quotes);
''';

void main() {
  input = '';
  var options = new Options();
  for (var option in options.arguments) {
    if (option.startsWith('-')) {
      if (option == '-?') {
        print('${options.executable} qvs.dart [file]');
        exit(0);
      } else {
        print('Unknown option: $option');
        exit(1);
      }
    } else {
      var file = new File(option);
      if (file.existsSync())
      {
        if (input == '') {
          input = file.readAsStringSync(encoding: Encoding.SYSTEM);
        }  
      } else {
        print('File not found: $option');
        exit(2);
      }
    }
  }
  Parser qvs = new QvsGrammar().ref('start');;
  Result id1 = qvs.parse(input);
//  id1 = qvs.parse(r" $(invlude=QVD)");
  if (id1.isFailure) {
    print(id1.message);
    print(id1.position);
    var rowAndCol = Token.lineAndColumnOf(input, id1.position);
    print('Parse error on row:${rowAndCol[0]} col: ${rowAndCol[1]}.  ${id1.message}');
  } else {
    print(id1.value);
  }  
}
