#!/usr/bin/perl
#convert Philips Rec-FilesExamcards to Text-files
# http://www.mr.ethz.ch/~rluchin/
#Special thanks goes to Sha Zhao form Manchester University. The Idea and some of the code comes from his Python Script!

$version="16.2.2021";
local $SIG{__DIE__} = \&DME::Application::mydie;
use XML::LibXML;
use XML::Parser;
use Data::Dumper;
use MIME::Base64;
use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
use utf8;
use Encode qw(from_to);
use File::Basename;
use FindBin;
use lib "$FindBin::Bin";
eval "use Image::Magick";
if ( $@ ) {
     $no_imagemagick = 1;
}
eval "use parameterPage";
if ( $@ ) {
    %goal_parameter=();
    print "Warning: The file parameterPage.pm is missing in the folder of the examcard2txt.pl folder. The C-variable names will not be translated to the human readable text\n\n";
} else {
    %goal_parameter=read_parameterpage();
}

#default values
$html=1;  #1 create a html file
$txt=1;   #1 create a text file
$data=1;  #1 convert the info from the scans
$nice_parameter=1;    #1 C-variable names, 0 nice names of parameters
$out_dir="";


while ($ARGV[0] =~ /^-/) {
    $_ = shift @ARGV;
    if (/^-h(elp)?$/) {
	&usage;
    } elsif (/^-out$/) {
	$out_dir = shift @ARGV;
    } elsif (/^-html$/) {
	$html = 1;
    } elsif (/^-nohtml$/) {
	$html = 0;
    } elsif (/^-txt$/) {
	$txt = 1;
    } elsif (/^-notxt$/) {
	$txt = 0;
    } elsif (/^-data$/) {
	$data = 1;
    } elsif (/^-nodata$/) {
	$data = 0;
    } elsif (/^-var$/) {
	$nice_parameter = 0;
    } else {
	print "Unknown Option: $_\n";
	&usage;
    }
}

if ($html==0){
    $data=0;
    $txt=1;
}

use bytes;

$file=$ARGV[0];
if ("$file" eq "") {
  print "No file given.\n";
  &usage;
}

# expand *.rec on Windows (standard on Unix)
if ($^O eq "MSWin32") {
    use File::DosGlob;
    @ARGV = map {
	my @g = File::DosGlob::glob($_) if /[*?]/;
	@g ? @g : $_;
    } @ARGV;
}

foreach $file (@ARGV) {
    my $examcard_name="";
    my $examcard_description="";
    my $examcard_version="";
    my $seq_cnt=0;
    undef(@protocol_name);
    undef(@methodDescription);
    undef(@parameters);
    undef(@html_file);
    undef(@other_tags);
    undef(@images);
    undef(@duration);
    if (-f $file){
	my $base_dir=dirname($file);
	if ($out_dir ne ""){
	   if (-w $out_dir){
	      $base_dir=$out_dir;
           }
        }
	$base_filename=basename($file);
	$base_filename=~s/\.[Ee][Xx][Aa][Mm][Cc][Aa][Rr][Dd]//;
	$base_filename=~s/\W/_/g;
	$txt_filename=$base_filename.".txt";
	$html_filename=$base_filename.".html";
	$basedir_zip=$base_filename;
	my $parser = XML::LibXML->new();
	my $xmldoc = $parser->parse_file($file);
	chdir($base_dir);
	#Find Nodes under SOAP-ENV:Body
	for my $node ($xmldoc->findnodes('//SOAP-ENV:Body/*')){
	    if ($node->getName =~ /a\d+:ExamCard$/i){      #info about Examcard
		for my $result ($node->getElementsByTagName('*')){
		    if ($result->getName eq "name"){
			$examcard_name=$result->textContent;
		    } elsif ($result->getName eq "description"){
			$result =~ /href="#(\w+-\d+)"/;
			my $xpath= '//*[contains(@id,'."\"$1\"".')]';
			for my $exam_data ($xmldoc->findnodes($xpath)){
			    if (($exam_data =~ /dataBuffer href="#(\w+-\d+)"/i) and ($data)){
				if (!(-d $basedir_zip)){
				    mkdir($basedir_zip)||die "can't create outputdir ($basedir_zip) for Zip-files\n";
				}
				my $xpath= '//SOAP-ENC:Array[contains(@id,'."\"$1\"".')]';
				my $databuffer_base64=$node->findnodes($xpath);
				get_data_out_zipfile($databuffer_base64,$basedir_zip,0);
			    }
			}
		    } elsif ($result->textContent ne "") {
			$examcard_description=$examcard_description." ".substr($result->getName."                                   ",0,20)." :  ".$result->textContent."\n";
			
		    }
		}
	    } elsif ($node->getName =~ /a\d+:ExamCardData$/i){   #additional info about Examcard
		for my $result ($node->getElementsByTagName('*')){
		    if ($result->textContent ne "") {
			$examcard_description=$examcard_description." ".substr($result->getName."                                   ",0,20)." :  ".$result->textContent."\n";
		    }
		}
	    }  elsif ($node->getName =~ /a\d+:ExamCardsVersion$/i){   #Info about Softwarerelease which reated examcard
		for my $result ($node->getElementsByTagName('*')){
		    if ($result->textContent ne "") {
			$examcard_version=$examcard_version." ".substr($result->getName."                                   ",0,12)." :  ".$result->textContent."\n";
		    }
		}
	    } elsif ($node->getName =~ /a\d+:ExecutionStep$/i){        #Info about Protocols
		$seq_cnt++;
		for my $result ($node->findnodes('stepDuration')){
		    my $dur=$result->textContent;
		    if ($dur > 0){
			my $min=int($dur/60);
			my $sec=(int(10*($dur-$min*60)+0.5))/10;
			if ($sec<10){
			    $sec="0".$sec;
			}
			$duration[$seq_cnt]="$min:$sec";
		    } else {
			$duration[$seq_cnt]="";
		    }
		}
		for my $result ($node->findnodes('singleScan')){
		    $result =~ /href="#(\w+-\d+)"/;
		    my $xpath= '//*[contains(@id,'."\"$1\"".')]';
		    for my $single_scan ($xmldoc->findnodes($xpath)){
			if (($single_scan =~ /geometryName href="#(\w+-\d+)"/i)){
			    $geometry[$seq_cnt]="";
			    my $geo_xpath= '//item[contains(@id,'."\"$1\"".')]';
			    for my $geo_scan ($xmldoc->findnodes($geo_xpath)){
				$geometry[$seq_cnt]=$geo_scan->textContent;  
			    }
			}
			if (($single_scan =~ /scanProcedure href="#(\w+-\d+)"/i)){
			    my $scan_xpath= '//*[contains(@id,'."\"$1\"".')]';
			    for my $scan_scan ($xmldoc->findnodes($scan_xpath)){
				for my $temp_scan ($scan_scan->findnodes('./*')){
				    if ($temp_scan->getName eq "parameterData"){
					$temp_scan =~ /href="#(\w+-\d+)"/;
					my $para_xpath= '//SOAP-ENC:Array[contains(@id,'."\"$1\"".')]';
					my $parameter_base64=$xmldoc->findnodes($para_xpath);
					$parameters[$seq_cnt]=decode_base64($parameter_base64);
				    }  elsif ($temp_scan->getName eq "name"){
					if (($temp_scan->textContent ne "")){
					    $protocol_name[$seq_cnt]=$temp_scan->textContent;
					}
				    } elsif ($temp_scan->getName eq "methodDescription"){
					if (($temp_scan->textContent ne "")){
					    $methodDescription[$seq_cnt]=" ".$temp_scan->getName."  :  ".$temp_scan->textContent."\n\n";
					}
				    } elsif ($temp_scan->textContent ne""){
					$other_tags[$seq_cnt]=$other_tags[$seq_cnt]." ".$temp_scan->getName."  :  ".$temp_scan->textContent."\n";
				    }
				}
				
			    }
			}
			if (($single_scan =~ /detail href="#(\w+-\d+)"/i)){
			    my $data_xpath= '//*[contains(@id,'."\"$1\"".')]';
			    for my $data_scan ($xmldoc->findnodes($data_xpath)){
				if (($data_scan =~ /dataBuffer href="#(\w+-\d+)"/i) and ($data)){
				    if (!(-d $basedir_zip)){
					mkdir($basedir_zip)||die "can't create outputdir ($basedir_zip) for Zip-files\n";
				    }
				    my $xpath= '//SOAP-ENC:Array[contains(@id,'."\"$1\"".')]';
				    my $databuffer_base64=$node->findnodes($xpath);
				    get_data_out_zipfile($databuffer_base64,$basedir_zip,$seq_cnt);
				}
			    }
			}				
		    }
		}
	    }
	}

#create output
	
	if ($txt){ 
           open(TEXT,">$txt_filename");
        }
	if ($html){
           open(HTML,">$html_filename");
        }
	my $name_length=length($examcard_name);
	print "Examcard: $examcard_name\n";
	my $out_html="";
	if ($data){
	    $out_html=get_html_txt($html_file[0],0);
	}
	if ($txt){
	    print TEXT "ExamCard: $examcard_name\n";
	    print TEXT substr("==========================================================================================",0,$name_length+10)."\n";
	    print TEXT "Examcard Version:\n$examcard_version\n";
	    if ($examcard_description ne ""){
		print TEXT "Examcard description:\n";
		my @temp_arr=split("\n",$examcard_description);
		undef(%seen);
		foreach (@temp_arr) {
		    if (! defined($seen{$_})){
			$seen{$_}=1;
			print TEXT $_."\n";
		    }
		}
	    }
	    print TEXT "\n";
	}
	if ($html){
	    print HTML "<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">\n<title>ExamCard: $examcard_name</title>\n<style>\n#overflow { overflow-x: auto; font-size: medium;}\n@media print {\n #overflow {font-size: small;\n            overflow-x: auto;\n            white-space: pre-wrap;\n            white-space: -moz-pre-wrap;\n            white-space: -pre-wrap;\n            white-space: -o-pre-wrap;\n            word-wrap: break-word;}\n}\n</style>\n</head>\n<body>\n<h1>ExamCard: $examcard_name</h1><pre id=\"overflow\">$examcard_version</pre>\n";
	    print HTML "<pre id=\"overflow\">Examcard description:\n";
	    my @temp_arr=split("\n",$examcard_description);
	    undef(%seen);
	    foreach (@temp_arr) {
		if (! defined($seen{$_})){
		    $seen{$_}=1;
		    print HTML $_."\n";
		}
	    }
	    print HTML "</pre><h2>Protocols:</h2><table>\n";
	}
	if ($txt){
	    print TEXT "Protocols:\n==========\n";
	}
	$el_cnt=1;
	while ($el_cnt<=$seq_cnt){
	    if ($html){
		print HTML "<tr><td><a href=\"#prot_$el_cnt\">".$protocol_name[$el_cnt]."</a></td><td> &nbsp; &nbsp; &nbsp; </td><td>";
	    }
	    if ($txt){
		print TEXT substr($protocol_name[$el_cnt]."                                    ",0,30)."  ".substr($geometry[$el_cnt]."                      ",0,10)."  ".$duration[$el_cnt]."\n";
	    }
	    if ($html){
		if ($geometry[$el_cnt] ne ""){
		    print HTML "[".$geometry[$el_cnt]."]";
		}
		print HTML "</td><td> &nbsp; &nbsp; &nbsp; </td><td>";
		if ($duration[$el_cnt] ne ""){
		    print HTML $duration[$el_cnt];
		}
		print HTML "</td></tr>\n";
	    }
	    $el_cnt++;
	}
	
	if ($html){
	    print HTML "</table>\n";
	}
	if ($txt){
	    print "\n";
	}
    
	$el_cnt=1;
	while ($el_cnt<=$seq_cnt){
	    my $name_length=length($protocol_name[$el_cnt]);
	    print "Protocol Name:  ".$protocol_name[$el_cnt]."\n";
	    if ($txt){
		print TEXT "\nProtocol Name:  ".$protocol_name[$el_cnt]."\n";
		print TEXT substr("==========================================================================================",0,$name_length+16)."\n";

		my @temp_arr=split("\n",$methodDescription[$el_cnt]);
		undef(%seen);
		foreach (@temp_arr) {
		    if (! defined($seen{$_})){
			$seen{$_}=1;
			print TEXT $_."\n";
		    }
		}

		print TEXT "\nOther Tags:\n";
		my @temp_arr=split("\n",$other_tags[$el_cnt]);
		undef(%seen);
		foreach (@temp_arr) {
		    if (! defined($seen{$_})){
			$seen{$_}=1;
			print TEXT $_."\n";
		    }
		}
		print TEXT "\n";

	    }
	    my $out_html="";
	    if ($data){
		$out_html=get_html_txt($html_file[$el_cnt],$el_cnt);
	    }
	    if ($html){
		print HTML "<h2 id=\"prot_$el_cnt\">Protocol Name:  ".$protocol_name[$el_cnt]."</h2>\n$out_html";
		print HTML "<pre id=\"overflow\">";
		print HTML "Methodes Description:\n";
		my @temp_arr=split("\n",$methodDescription[$el_cnt]);
		undef(%seen);
		foreach (@temp_arr) {
		    if (! defined($seen{$_})){
			$seen{$_}=1;
			print HTML $_."\n";
		    }
		}
		print HTML "\n</pre><pre id=\"overflow\">Other Tags:\n";
	    my @temp_arr=split("\n",$other_tags[$el_cnt]);
	    undef(%seen);
	    foreach (@temp_arr) {
		if (! defined($seen{$_})){
		    $seen{$_}=1;
		    print HTML $_."\n";
		}
	    }
	    print HTML "</pre>\n<pre id=\"overflow\">\n";
	    }
	    $stacks=20;
	    $i=0;
	    while ($i<512){
		($para,$value)=get_a_param($parameters[$el_cnt],$i);
		if ($para eq "None"){
		    $i=520;
		} else {
		    if ($para =~ /EX_GEO_stacks$/){
			$stacks=$value;
			if ($stacks==0){
			    $stacks=20;
			}
		    }elsif ($para =~ /EX_GEO_stacks_/){
			my $count = () = $value =~ / /g;
			if ($count==20){
			    my @tmp_value=split(" ",$value,$stacks+1);
			    pop @tmp_value;
			    $value=join(" ",@tmp_value);
			}
		    } elsif ($para =~ /.+_([a-zA-Z0-9]+)_seperator$/){
			$para="=======".uc($1)."=======================================================================";
			$value="===================";
		    }
		    if (($nice_parameter) and (defined($goal_parameter{$para}))){
			$para_text=$goal_parameter{$para};
		    } else {
			$para_text=$para;
		    }
		    if ($txt){
			print TEXT "  ".substr("$para_text  :                                              ",0,34)."$value\n";
		    }
		    if ($html){
			print HTML "  ".substr("$para_text  :                                              ",0,34)."$value\n";
		    }
		    $i++;
		}
	    }
	    if ($html){
		print HTML "</pre><hr>";
	    }
	    $el_cnt++;
	}
    }
    print "Examcard converted to: ";
    if ($txt){
	print "$txt_filename ";
    }
    if ($html){
	print "$html_filename ";
    }
    print "\n";
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $min=substr("0$min",-2,2);
    if ($html){
	print HTML "<hr><address>examcard2txt.pl (version: $version) $mday.".($mon+1).".".($year+1900)." $hour:$min</address></body></html>";
	close(HTML);
    }
    if ($txt){
	print TEXT "\nConverted by examcard2txt.pl (version: $version) $mday.".($mon+1).".".($year+1900)." $hour:$min\n";
	close(TEXT);
    }
    
}    


sub get_a_param{
    $str_block=$_[0];
    $j=$_[1];
    # each parameter has: name, type, number, offset1, offset2
    $pos0 = 32;  # initial offset of the whole str_block base64 decoded
    if ( $pos0+($j+1)*50 > length($str_block) ){  
	return ("None",0);
    } 
    my $b_str1 = substr($str_block,$pos0+$j*50,50);   # each param has a length of 50 bytes
    # work out its name from the first 33 bytes   
    my $b = substr($b_str1,0,33);
    $pos_s = index($b,"\x0");   # end of string
    if ( $pos_s >= 0 ){
	$nm = substr($b,0,$pos_s);
    }
    if ( length($nm) < 5 ){
	return ("None",0);
    }
    if ((substr($nm,2,1) ne "_") and (substr($nm,3,1) ne "_")){  # name should be something like GEX_   EX_ or IF_
	return ("None",0);
    }

    # work out its data type
    $b = substr($b_str1,34,4);
    $tp = unpack("L<",$b);  #  data type of param as unsigned int

    if ( $tp > 4 ){
	return ("None",0);
    }
    # work out the numbers
    $b = substr($b_str1,38,4);
    $num = unpack("L<",$b); # number of params as unsigned int

    # work out its offset1
    $b = substr($b_str1,42,4);
    $off1 = unpack("L<",$b);   # offset1 as unsigned int, from current pos
    $off1 = $off1 + $pos0 + $j*50 + 42;  ## now offset1 from the beginning of whole str_block

    $b = substr($b_str1,46,4);
    $off2 = unpack("L<",$b);   # offset1 as unsigned int, from current pos
    $off2 = $off2 + $pos0 + $j*50 + 46;  ## now offset1 from the beginning of whole str_block

    # to get the param's values using tp, num, off1, off2 from the base64 decoded str_block
    $parm = get_param_value($tp, $num, $off1, $off2, $str_block);
    return ($nm,$parm); # successful
}

sub get_param_value{
    $typ=$_[0];
    $num=$_[1];
    $off1=$_[2];
    $off2=$_[3];
    $b_str=$_[4];
    $res="";
    if ($typ == 0){   # floatbina
        $k = 0;
        while ( $k < $num ){
            $b = substr($b_str,$off2+$k*4,4);   # size of float == 4
	    $flt = unpack('f<', $b);
            $res = $res."".$flt." ";
	    $k++;
	}
    } elsif ( $typ == 1 ){   # int
        $k = 0;
        while ( $k < $num ){
            $b = substr($b_str,$off2+$k*4,4);   # size of int == 4
	    $intgr = unpack('i<', $b);
            $res = $res."".$intgr." ";
            $k++;
	}
    } elsif ($typ == 2 ){   # string
        $k = 0;
        while ( $k < $num ){
            $b = substr($b_str,$off2+$k*81,81);   # size of string == 81 here
            $pos_s = index($b,"\x0");   # end of string
            if ( $pos_s >= 0 ){
                $b = substr($b,0,$pos_s);
	    }
	    #$str1 = str($b, 'utf-8', errors = "ignore");
	    if ( length($b) > 0 ){
		$res = $res."".$b." , ";
	    }
	    $k++;
	}
	$res=substr($res,0,-2);
	
    } elsif ( $typ == 4 ){  # enum, only consider the case of num == 1
	$pos_s = index($b_str,"\x0", $off1);
        $b = substr($b_str,$off1,$pos_s-$off1);
	#str1 = str(b, 'utf-8', errors = "ignore")  ## the enum string separated by ','
	@list1 = split(',',$b);   ## the enum split out as a list
	$b = substr($b_str,$off2,4);   # size of int == 4
        $inx =  unpack('i<', $b);
        $res = $list1[$inx];
    }
    return $res;
}

sub get_html_txt{
    my $html_text=$_[0];
    $html_text=~s/\r\n/\n/g;
    @html_text=split("\n",$html_text);
    shift(@html_text);
    shift(@html_text);
    my $cnt=$_[1];
    $start=0;
    $out_html="<hr>";
   foreach $line (@html_text) {
	if ($start==0){
	    if ($cnt==0){
		$start=1;
	    }else{
		if ($line =~ /<!-- General descr/i){
		    $start=1;
		}
	    }
	} else {
	    chomp($line);
	    $line =~ s/<\/body>//i;
	    $line =~ s/<\/html>//i;
	    $line =~ s/<!--.+-->//g;
	    $line =~ s/<\/a>//ig;
	    $line =~ s/<a\s.*?>//ig;
	    while ($line =~ /<img.* src=\"([\w\.]+)\"/i) {
		if (defined($images[$cnt]{$1})){
		    my $replace=$images[$cnt]{$1};
		    $line =~ s/$1/$replace/g;
		} else {
		    last;
		}
	    }
	    while ($line =~ /dynsrc=\"([0-9a-zA-Z_\-\.]+)\"/) {
		if (defined($images[$cnt]{$1})){
		    my $replace=$images[$cnt]{$1};
		    $line =~ s/$1/$replace/g;
		    if ($no_imagemagick==1){
			$line =~ s/ dynsrc=\"/ alt=\"Movie \($replace\) may only work in old IE.\" dynsrc=\"/i;
		    } else {
			$line =~ s/ dynsrc=\"/ src=\"/i;
		    }
		}
	    }
	    $out_html="$out_html$line\n";
	}
    }
    $out_html="$out_html<hr>";
    return $out_html;
}

sub get_data_out_zipfile{
    my $databuffer_base64=$_[0];
    my $basedir_zip=$_[1];
    my $cnt=$_[2];
    my $tmp_html="";
    my $zip_file=decode_base64($databuffer_base64);
    my $unzip = new IO::Uncompress::Unzip \$zip_file or die "Cannot open $zipfile: $UnzipError";
    if (defined $unzip->getHeaderInfo){
	for (my $status = 1; $status > 0; $status = $unzip->nextStream) {
	    my $name = $unzip->getHeaderInfo->{Name};
	    if ($name =~ /\/$/) {
		mkdir $name;
	    }
	    else {
		my $out_zipfile_name="./$basedir_zip/$cnt"."_$name";
		if ($name =~ /htm$/){
		    unzip \$zip_file => \$tmp_html, Name => $name or die "unzip failed: $UnzipError\n";
		    my $test1=substr($tmp_html,0,1);
		    my $test2=substr($tmp_html,1,1);
		    if ((unpack ('C*',pack ('H*',$test1))==240) and (unpack ('C*',pack ('H*',$test2))==224)){
			from_to($tmp_html, 'UTF-16le', 'UTF-8');
		    }
		    $html_file[$cnt] =$tmp_html;
		} elsif ($name =~ /rtf$/){
		    #rtf-files are also in index.htm
		} else {
		    #images
		    unzip \$zip_file => $out_zipfile_name, Name => $name or die "unzip failed: $UnzipError\n";
		    $images[$cnt]{$name}=$out_zipfile_name;
		    if ($no_imagemagick!=1){
			if ($out_zipfile_name=~/\.avi|\.wmv/i){
			    my($conv_image, $conv_x);
			    $conv_image = Image::Magick->new;
			    $conv_x = $conv_image->Read($out_zipfile_name);
			    warn "$conv_x" if "$conv_x";
			    $out_zipfile_name=~s/\.avi|\.wmv/\.gif/i;
			    $conv_x = $conv_image->Write($out_zipfile_name);
			    warn "$conv_x" if "$conv_x";
			    $images[$cnt]{$name}=$out_zipfile_name;
			}
		    }
		}
	    }
	}
    } else {
	print "Warning: Zipfile has no members\n";
    }
}		    
		
    

sub usage{
	
  @command=split(/\//,$0);
  $command=$command[-1];
  print "Usage:\n  $command -html -txt -data -var filename(n)\n";
  print "e.g: $command  test1.ExamCard test2.examcard\n\n";
  print "Version: $version\n\n";
  print "-(no)html : HTML Page as output  (-nohtml disable html output)\n";
  print "-(no)txt  : Text File as output  (-notxt disable txt output)\n";
  print "-(no)data : Info text of Examcard will also converted (only with html)\n";
  print "-var      : The C Variable names will be shown (not the nice from the\n           Scannerfrontend)\n";
  print "out outfolder: Folder where the files will be stored. Default a folder\n           will be made in the current directory\n";
  print "-h        : Help\n";
  print " The default output can be changed in the perlscript in the four lines\n after #default values\n If no output is given, a text-file will be created\n";
  my $eingabe;
  print "Press enter to exit";
  chomp($eingabe=<STDIN>);
  exit;
}

sub mydie{
  my $why=shift;
  chomp $why;
  print "\n\n\n\ !!! Program stopped due to an error.\nPlease verify output and if needed report errors.\n\n$why\n\n";
  my $eingabe;
  print "Press enter to exit";
  chomp($eingabe=<STDIN>);
  exit 1;
}


