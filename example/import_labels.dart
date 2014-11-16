library reader_tests;

import 'package:qvs/src/qv_exp_reader.dart';
import 'dart:io';

void main() {
  var source = TEST_FILE_CONTENTS;
  var reader = newReader()..readFile('test.qlikview-vars',source);
  var out = reader.importLabels(r'exp_files\EditedNames.csv');
  var file = new File(r'exp_files\Updated.test.qlikview-vars');
  file.writeAsStringSync(reader.printOut());
}



const TEST_FILE_CONTENTS = r"""
#define ABRACADABRA = 1

#SECTION :Chart expressions
---
set: DynamicDim
definition: $(=Only(DimField)) 
---
set: Продажи
definition: Sum(Amount)
label: Sales
comment: Продажи за
  выбранный период
backgroundColor: =LightGreen(96)
tag: Another tag
---
set: Sales1998
definition: Sum(If(Year(OrderDate)=1998,
   Amount))
label: 1998
comment: Sales 1998
---
set: Sales1997
definition: Sum(If(Year(OrderDate)=1997, Amount))
label: 1997
comment: Sales 1997
---
set: Sales1998to1997
definition: ($(Sales1998)/$(Sales1997))
label: Sales Index 98/97
comment: Ratio for sales 1998 to 1997 years
---
set: AvgOrder
definition: Sum(Amount)/
  Count(DISTINCT OrderID)
label: Avg order value
comment: Avg order value
---
set: NoOfOrders
definition: Count (Distinct OrderID)
label: No of orders
comment: Number of orders
---
set: Discount
definition: Sum(DiscAmount)
label: Discount
comment: Discount amount

#SECTION :Additional formulas
---
set: vG.ShowLangSelection
definition: 0 
---
set: LightGreen
definition: LightRed(96)
---
set:vL.Sum
definition:sum($(=Only(Field1)))
---
set: vL.Dim
definition:  $(=Only(Field1))
---
set: vL.Dummy
definition:  1
""";