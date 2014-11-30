part of reader_tests;

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
definition: Sum(Amount)/Count(DISTINCT OrderID)
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
const FIELD_LIST = const [
r'$Field',
r'$Table',
r'$Rows',
r'$Fields',
r'$FieldNo',
r'$Info',
r'НоменклатураСсылка',
r'СкладСсылка',
r'_ДатаКлюч',
r'ТорговаяТочкаСсылка',
r'КлиентСсылка',
r'ТипДокумента',
r'СебестоимостьБезНДС',
r'КлючПодразНоменклатура',
r'Сумма',
r'Скидка',
r'ВП',
r'Себестоимость',
r'Количество',
r'ШкалаЛиквидностиИсторическая',
r'Клиент',
r'НоменклатураКод',
r'НоменклатураНаименование',
r'ВидТовара',
r'ТоварИндикатор',
r'_НоменклатураСчетчик',
r'НоменклатураНаименованиеУровня',
r'Направление',
r'Группа',
r'КатегорийныйМенеджер',
r'Производитель',
r'ЕдиницаИзмерения',
r'Категория',
r'Подкатегория',
r'ДатаПервойЗакупки',
r'Новинка',
r'Компания в целом',
r'Дата',
r'ТипПериода',
r'_ПоследнийДеньПериода',
r'Год',
r'Месяц',
r'МесяцНомер',
r'ГодМесяц',
r'Квартал',
r'Полугодие',
r'ГодПолугодие',
r'ГодКвартал',
r'ГодНеделя',
r'_Неделя',
r'День',
r'ДеньНедели',
r'_ДнейВМесяце',
r'_КонецНедели',
r'_КонецМесяца',
r'_МесяцПоПорядку',
r'_ДеньПоПорядку',
r'ДеньИНомерНедели',
r'_Последние30Дней',
r'_Последние60Дней',
r'_Последние90Дней',
r'_ФлагПоследнийДеньПериода',
r'_ДнейПрошлогоПериода',
r'_ФлагДействующаяДата',
r'_ФлагУникальнаяДата',
r'_МесяцПрогнозныйКоеффициент',
r'_ФлагМесяцТекущий',
r'_ФлагМесяцПредыдущий',
r'_ФлагНеделяТекущий',
r'_ФлагНеделяПредыдущий',
r'_ФлагКварталТекущий',
r'_ФлагКварталПредыдущий',
r'_ФлагГодТекущий',
r'_ФлагГодПредыдущий',
r'_ФлагПолугодиеТекущий',
r'_ФлагПолугодиеПредыдущий',
r'_ДнейПрошлогоПериодаВМесяце',
r'Склад1',
r'Склад2',
r'Склад3',
r'Склад',
r'ТоварнаяМатрицаСсылка',
r'СкладКод',
r'ОперационныйДиректор',
r'ПлощадьМагазина',
r'ШкалаЛиквидности',
r'МатричныйТовар',
r'ДатаВывода',
r'ДатаВвода',
r'ПродажиАБС',
r'ПродажиКоличествоАБС',
r'НаценкаАБС',
r'ТоварнаяМатрица',
r'ТорговыеТочки',
r'_ГруппаИзмерений',
r'_ГруппаИзмерений_Измерение',
r'_ГруппаИзмерений_План',
r'_ГруппаИзмерений_Код',
r'_ГруппаИзмерений_ФлагОстатки',
r'_ГруппаСклад',
r'_ГруппаСклад_Измерение',
r'_ГруппаСклад_План',
r'_ГруппаСклад_Код',
r'_ГруппаСклад_ФлагОстатки',
r'_ГруппаКлассификатор',
r'_ГруппаКлассификатор_Измерение',
r'_ГруппаКлассификатор_План',
r'_ГруппаКлассификатор_Код',
r'_ГруппаКлассификатор_ФлагОстатки',
r'_ГруппаКалендарь',
r'_ГруппаКалендарь_Измерение',
r'_ГруппаКалендарь3',
r'_ГруппаКалендарь3_Измерение',
r'_ГруппаФильтр',
r'_ГруппаФильтр_Измерение',
r'ГП_ПоказательАбс',
r'_ГП_ПоказательАбс',
r'_ГруппаПоказателей_ПоказательАбс',
r'_ГП_ПоказательАбс_ФлагОстатки',
r'_ГП_ПоказательАбс_ФорматТыс',
r'_ГП_ПоказательАбс_ФорматМлн',
r'_ГП_ПоказательАбс_ФорматМлрд',
r'_ГП_ПоказательАбс_КраснаяГраница',
r'_ГП_Ошибки_ПоказательАбс',
r'_ГП_Ошибки_ПоказательАбс_ГруппаИзмерений',
r'_ГП_Ошибки_ПоказательАбс_ФильтрВидДеятельности',
r'ГП_ПГ',
r'_ГП_ПГ',
r'_ГруппаПоказателей_ПГ',
r'_ГП_ПГ_ФлагОстатки',
r'_ГП_ПГ_ФорматТыс',
r'_ГП_ПГ_ФорматМлн',
r'_ГП_ПГ_ФорматМлрд',
r'_ГП_ПГ_КраснаяГраница',
r'ГП_План',
r'_ГП_План',
r'_ГруппаПоказателей_План',
r'_ГП_План_ФлагОстатки',
r'_ГП_План_ФорматТыс',
r'_ГП_План_ФорматМлн',
r'_ГП_План_ФорматМлрд',
r'_ГП_План_КраснаяГраница',
r'ГП_L4L',
r'_ГП_L4L',
r'_ГруппаПоказателей_L4L',
r'_ГП_L4L_ФлагОстатки',
r'_ГП_L4L_ФорматТыс',
r'_ГП_L4L_ФорматМлн',
r'_ГП_L4L_ФорматМлрд',
r'_ГП_L4L_КраснаяГраница',
r'ГП_L4L2',
r'_ГП_L4L2',
r'_ГруппаПоказателей_L4L2',
r'_ГП_L4L2_ФлагОстатки',
r'_ГП_L4L2_ФорматТыс',
r'_ГП_L4L2_ФорматМлн',
r'_ГП_L4L2_ФорматМлрд',
r'_ГП_L4L2_КраснаяГраница',
r'ГП_ПоказательАбсМ',
r'_ГП_ПоказательАбсМ',
r'_ГруппаПоказателей_ПоказательАбсМ',
r'_ГП_ПоказательАбсМ_ФлагОстатки',
r'_ГП_ПоказательАбсМ_ФорматТыс',
r'_ГП_ПоказательАбсМ_ФорматМлн',
r'_ГП_ПоказательАбсМ_ФорматМлрд',
r'_ГП_ПоказательАбсМ_КраснаяГраница',
r'_ГруппаМеню',
r'_ГруппаМеню_Измерение',
r'_ГруппаМеню_КодЛиста',
r'_ГруппаПодМеню_DynLFL',
r'_ГруппаПодМеню_Измерение_DynLFL',
r'_ГруппаПодМеню_КодЛиста_DynLFL',
r'_ГруппаПодМеню_Abc',
r'_ГруппаПодМеню_Измерение_Abc',
r'_ГруппаПодМеню_КодЛиста_Abc'];
