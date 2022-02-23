Examcard2text.pl
================

Special thanks goes to Sha Zhao form Manchester University. The Idea and some of the code comes from his Python Script!

Versions:
---------
17.2.2021: Option for out-folder for the results added. 
           Movies will be converted to animgif, to be visible in the html-files (works only if image::magick is installed)
           online converter available: https://www.mr.ethz.ch/examcard2txt/

31.1.2021: New version which takes the xml-structure better into account. Solves some of the errors from the old version.

22.1.2021: Correct order added

19.1.2021: Initial version

Installation:
-------------
Files: 
examcard2txt.pl      Main file
parameterPage.pm     Contains the conversion C-vaiable names to Text in Frontend
                     (if this file is missing the C-variable names will be used.)

The scrips use XML::LibXML which may not per default be installed.
If ppm is install run as Admin: "ppm install XML::LibXML"
ubuntu: "sudo apt install libxml-libxml-perl"

If you don't have perl installed under Windows, you can download a siutable configured package from:
https://platform.activestate.com/rluchin/Perl-5.28.1-with-xml-libxml
(The default Active State package has no xml::libxml included and with current versions ppm does no longer work.) 

Usage:
------

  examcard2txt.pl -html -txt -data -var filename(n)
e.g: examcard2txt.pl  test1.ExamCard test2.examcard

Version: 22.1.2021

-(no)html : HTML Page as output  (-nohtml disable html output)
-(no)txt  : Text File as output  (-notxt disable txt output)
-(no)data : Info text of Examcard will also converted (only with html)
-var      : The C Variable names will be shown (not the nice from the
           Scannerfrontend)
-h        : Help
 The default output can be changed in the perlscript in the four lines
 after #default values
 If no output is selected, a text-file will be created

Limitations:
------------
More testing is needed. It should work also with older Examcards, but there may be still some limitations.

If the info-page includes Movies (avi/wmv) they will not be shown in the html-file, since those formats are only supported in the outdated IE.

Errors:
-------
Please report errors (best together with the Examcard) to rluchin@ethz.ch

