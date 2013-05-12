qvs_parser (v0.1.0)
================

Command line parser for QlikView load scripts.

Checks the syntacs of script. Optionally may reload QlikView document. 
By default if parser get error while parsing script reload does not start. 
To ovverride this behaviour use command line switch --forceReload.
By default parser expect QlikView executable on path C:\Program Files\QlikView\qv.exe
This may be changed by command line parameter --qlikview 

On syntax error parser output error in format

    Parse error. File: Department.qvs row:  col: 7 message: FROM expected 


####Installation and usage

Qvs_parser is written in Dart and requires Dart VM to run. Download dart-sdk from [Dartlang site](http://www.dartlang.org/tools/sdk/)
Then you may alternatively or add dart-sdk/bin directory in your PATH, or modify last line of /tool/qvsrun.cmd to point to dart.exe in dart-sdk/bin
Use command 

   qvsrun yourFileToCheck.qvs 

To reload QlikView document after successful parsing add full path do your QlikView document after commented sheband as first line of script
First 4 symbols of first line must be strictly `//#!` 
Example:

    //#!c:\QlikDocs\CurrentProject\EtlApps\DataModelDebug.qvw
 