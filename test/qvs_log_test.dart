library qvs_log_test;
import 'package:inqlik_cli/src/qvs_logfile.dart';
import 'package:test/test.dart';

main() {
  test('Dummy transform', (){
    String input = '''
     asdfasdfasdf
     asdfasdfasdf
     asdfa
     ''';
    var transformer = new QvsLogTransformer(null);
    String output = transformer.transformString(input);
    expect(output.trim(), input.trim());
  });

  test('Skip header', (){
    String input = '''
     Header1
     Header2
     Header3
           Body started
     line1
     line2
     line3''';
    var transformer = new QvsLogTransformer(null,skipUpTo: 'Body started');
    String output = transformer.transformString(input);
    var lines = output.split('\n');
    expect(lines.length, greaterThanOrEqualTo(4));
    expect(lines[0],contains(transformer.skipUpTo));
  });

  test('Skip up to bottom of file', (){
    String input = '''
     Header1
     Header2
     Header3
     line1
     line2
     line3''';
    var transformer = new QvsLogTransformer(null,skipUpTo: 'Body started');
    String output = transformer.transformString(input);
    expect(output,isEmpty);
  });


  test('Test on QDF project log output', (){
    String input = r'''
23.07.2015 7:00:19: 0111    SET vL.ContainerFolderName=
23.07.2015 7:00:19: 0112    SET vL.PhysicalFolderName=
23.07.2015 7:00:19: 0113    SET vL.VariablePrefix=
23.07.2015 7:00:19: 0114    SET vL.VariableLoop=
23.07.2015 7:00:19: 0115    SET vL.Path=
23.07.2015 7:00:19: 0116    set vL.VariableLoop=
23.07.2015 7:00:19: 0117    set vL.GetContainerStructure=
23.07.2015 7:00:19: 0118    SET vL.ContainerMapPath =
23.07.2015 7:00:19: 0119    SET vL.ContainerPathName=
23.07.2015 7:00:19: 0120    SET vL.RootPath=
23.07.2015 7:00:19: 0121    SET vL.FileExist=
23.07.2015 7:00:19: 0122    SET vL.ContanerName=
23.07.2015 7:00:19: 0123    SET vL.Comment =
23.07.2015 7:00:19:         SET vL.ContainerIdentification=
23.07.2015 7:00:19: 0125    SET vL.SingleFolder=
23.07.2015 7:00:19: 0126    SET vL.SubStringSplitt=
23.07.2015 7:00:19: 0127    SET vL.SubString=
23.07.2015 7:00:19: 0128  end sub
23.07.2015 7:00:19: 0008  LET vLoadStartTime = now()
23.07.2015 7:00:19: 0009  LET vScriptStartTime = replace(Num(now()),',','_')
07.07.2015 10:47:28: 0022        trace '### DF 2.GenericContainerLoader.qvs  Started'
07.07.2015 10:47:28: 0022        '### DF 2.GenericContainerLoader.qvs  Started'


     ''';
    var transformer = new QvsLogTransformer(null, skipUpTo: 'LET vLoadStartTime = now()');
    String output = transformer.transformString(input);
    var lines = output.split('\n');
    expect(lines[0],'LET vLoadStartTime = now()');
    expect(lines[2].trim(),startsWith('trace'));
    expect(lines[3].trim(),startsWith('//>>'));

  });


}

