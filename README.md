QVS. Parser for QlikView load scripts
================

Command line tool to check syntax of QlikView load scripts

Can be used with [InQlik-Tools for Sublime Text](https://github.com/inqlik/inqlik-tools) as optional build system, or as standalone tool

![Inqlik-Tools](http://inqlik.github.io/images/qvs_error.png)

Built with Dart programming language, based on [Lukas Renggli's PetitParser library](https://github.com/renggli/dart-petitparser).


##Installation and usage

Easiest way is to download prepackaged qvs-dist archive (approximately 3.5Mb) from [qvs-dist](https://github.com/inqlik/qvs-dist/archive/master.zip) and extract files into some location.
Then run `dart.exe qvs.snapshot` from that directory to get command-line help.
To incomporate qvs into InQlik-Tools for Sublime Text, edit file `QlikView.sublime-build` change strings `c:\\qvs\\` to directory where you extracted qvs-dist (or just extract files into c:\qvs)
Then copy `QlikView.sublime-build` file into `User` package directory (in Sublime Text menu command `Preferences \ Browse Packages...` then directory `User`)

Alternatevely you can install DartEditor, clone main qvs repository and use sourcecode. 