SET BINDIR=c:\Programs\Sublime3\Data\Packages\Inqlik-Tools\bin\
dart --snapshot=%BINDIR%inqlik.snapshot c:\projects\inqlik_cli\bin\inqlik.dart
copy /Y /B c:\Programs\dart\dart-sdk\bin\dart.exe %BINDIR%dart.exe
SET BINDIR=c:\Programs\bin\
dart --snapshot=%BINDIR%inqlik.snapshot c:\projects\inqlik_cli\bin\inqlik.dart
copy /Y /B c:\Programs\dart\dart-sdk\bin\dart.exe %BINDIR%dart_inqlik.exe