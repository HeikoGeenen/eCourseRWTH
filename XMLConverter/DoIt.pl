#!/usr/bin/perl -w
use strict;
use Term::ReadLine;
use Math::Trig;
use Config::IniFiles;
#use List::Uniq ':all';
use List::MoreUtils 'uniq';
use Getopt::Long;

my $defaultNumberOfDatasets=2;
my $defaultPunkte=10;
my $defaultAbzug=0.1;
my $defaultToleranz=0.1;
my $defaultToleranzTyp=2;
my $filename;
my $Kategorie;
if (defined $ARGV[0]){
    $filename=$ARGV[0];
    ($Kategorie = $filename) =~ s/\.[^.]+$//;
    print "K:$Kategorie \n";
}else{
    print "Da fehlt die ini Datei! Syntax: perl DoIt.pl Filename.ini \n";
    exit;
}
my $xmlfile = "$Kategorie.xml";

sub ReadConfig();
sub DefFileName;
sub DefPublishName;
sub DefRemoteDir;
{
    ReadConfig();
}

sub ReadConfig(){
    
#    if(-e $1){print "$1\n";}
#    my $filename="./Aufgabe1.ini";
    my $myconfig;
    $myconfig =  new Config::IniFiles(-file => $filename ) or 
	die "\n\n *** Error *** reading configuration file $filename \n\n";
    print " Reading configuration (\"$filename\"):\n"; 
    print " Ausgabe xml-File: $xmlfile\n";
    open XMLFILE, ">$xmlfile";
    print XMLFILE "<quiz>\n";
    print XMLFILE "<question type=\"category\">\n";
    print XMLFILE "\t<category><text>\$course\$/$Kategorie</text></category>\n";
    print XMLFILE "</question>\n\n";
    foreach my $dataset ($myconfig->Sections()){
	print "Lege Aufgabe $dataset an.\n";
	print XMLFILE '<question type="calculated">',"\n";
	
	print XMLFILE "\t<name><text>",$dataset,"</text></name>\n";
	if ($myconfig->val($dataset,'Text')){
	    print XMLFILE "\t",'<questiontext format="html"><text><![CDATA[<p>',
	    $myconfig->val($dataset,'Text'),
	    "</p>]]></text></questiontext>\n";
	}else{
	    print "In Aufgabe $dataset fehlt der Text\n"; exit;
	}	       
	if ($myconfig->val($dataset,'Feedback0')){
	    print XMLFILE "\t",'<generalfeedback format="html"><text><![CDATA[<p>',
	    $myconfig->val($dataset,'Feedback0'),
	    "</p>]]></text></generalfeedback>\n";
	}	       

	my $currentPunkte=$defaultPunkte;
	if ($myconfig->val($dataset,'Punkte')){
	    $currentPunkte=$myconfig->val($dataset,'Punkte');
	}else{print "Verwende default Punkte $currentPunkte.\n";}
	print XMLFILE "\t<defaultgrade>$currentPunkte</defaultgrade>\n";

	my $currentAbzug=$defaultAbzug;
	if ($myconfig->val($dataset,'Abzug')){
	    $currentAbzug=$myconfig->val($dataset,'Abzug');
	}else{print "Verwende default Abzug $currentAbzug\n"}	    
	print XMLFILE "\t<penalty>$currentAbzug</penalty>\n";

	print XMLFILE "\t<hidden>0</hidden>\n";    # Feedback hidden?
	print XMLFILE "\t<synchronize>0</synchronize>\n";    
	print XMLFILE "\t<single>0</single>\n";    # single try?
	print XMLFILE "\t<answernumbering>abc</answernumbering>\n";    
	print XMLFILE "\t<shuffleanswers>0</shuffleanswers>\n";    
	if ($myconfig->val($dataset,'Antwort')){
	    print XMLFILE "\t",'<answer fraction="100">',"\n";    
   	    print XMLFILE "\t\t<text>",$myconfig->val($dataset,'Antwort'),"</text>\n";

	    my $currentToleranz=$defaultToleranz;
	    if ($myconfig->val($dataset,'Toleranz')){
		$currentToleranz=$myconfig->val($dataset,'Toleranz');
	    }else{print "Verwende default Toleranz: $currentToleranz \n";}	    
	    print XMLFILE "\t\t<tolerance>$currentToleranz</tolerance>\n";

	    my $currentToleranzTyp=$defaultToleranzTyp;
	    if ($myconfig->val($dataset,'Toleranztyp')){
		$currentToleranzTyp=$defaultToleranzTyp;
	    }else{print "Verwende default Toleranztyp $currentToleranzTyp.\n"}
	    print XMLFILE "\t\t<tolerancetype>$currentToleranzTyp</tolerancetype>\n";	    

   	    print XMLFILE "\t\t<correctanswerformat>1</correctanswerformat>\n";
	    print XMLFILE "\t\t<correctanswerlength>2</correctanswerlength>\n";
	    if ($myconfig->val($dataset,'Feedback1')){
		print XMLFILE "\t\t",'<feedback format="html"><text><![CDATA[<p>',$myconfig->val($dataset,'Feedback1'),"</p>]]></text></feedback>\n";
	    }else{
		print XMLFILE "\t\t",'<feedback format="html"><text><![CDATA[<p>Schön</p>]]></text></feedback>',"\n";		
	    }
	    print XMLFILE "\t</answer>\n";    
	}
	print XMLFILE "\t<unitgradingtype>0</unitgradingtype>\n"; 
	print XMLFILE "\t<unitpenalty>0.1000000</unitpenalty>\n"; 
	print XMLFILE "\t<showunits>3</showunits>\n"; 
	print XMLFILE "\t<unitsleft>0</unitsleft>\n"; 
	#### Erstellung der Datensaetze
	print "Antwort",$myconfig->val($dataset,'Antwort'),"\n";

	my @words = uniq($myconfig->val($dataset,'Antwort') =~ /\{(\w+)\}/g);
	my $variablen=@words;
	print "Variablen:",@words,"\n";
	my @wertebereiche = $myconfig->val($dataset,'Wertebereich') =~ /(\w+?=\(\S+?\))/g;
	print "Wertebereiche:",@wertebereiche,"\n";
	if(scalar(@wertebereiche) != $variablen ){
	    print "Zahl der Variablen:",$variablen,"\n";
	    print "Zahl der Wertebereiche:",scalar(@wertebereiche),"\n";
	    print "Da stimmt was nicht!\n";
	    exit;
	}
	print XMLFILE "\t<dataset_definitions>\n";
	while (my $element = shift(@wertebereiche)){
	    $element =~ /(\w+)=\((\S+?),(\S+?)\)/g;
	    my $varname=$1;
	    my $lowbound=$2;
	    my $upbound=$3;
	    my $cycles=$defaultNumberOfDatasets;
	    if ($myconfig->val($dataset,'Datensatz')){
		$cycles=$myconfig->val($dataset,'Datensatz');
	    }else{
		print "Generiere per default: $defaultNumberOfDatasets Datensätze\n"
	    }

	    print "Variablenname $varname von $lowbound bis $upbound \n";
	    print XMLFILE "\t<dataset_definition>\n";
	    print XMLFILE "\t\t<status><text>private</text></status>\n";
	    print XMLFILE "\t\t<name><text>$varname</text></name>\n";
	    print XMLFILE "\t\t<type>calculated</type>\n";
	    print XMLFILE "\t\t<distribution><text>uniform</text></distribution>\n";
	    print XMLFILE "\t\t<minimum><text>$lowbound</text></minimum>\n";
	    print XMLFILE "\t\t<maximum><text>$upbound</text></maximum>\n";
	    print XMLFILE "\t\t<decimals><text>1</text></decimals>\n";
	    print XMLFILE "\t\t<itemcount>$cycles</itemcount>\n";
	    print XMLFILE "\t\t<dataset_items>\n";
	    for (my $i=1;$i<=$cycles;$i++){ 
		my $rannumber=$lowbound+rand($upbound-$lowbound);
		printf XMLFILE "\t\t\t<dataset_item><number>$i</number><value>%1.1f</value></dataset_item>\n",$rannumber;
	    }
	    print XMLFILE "\t\t</dataset_items>\n";
	    print XMLFILE "\t\t<number_of_items>$cycles</number_of_items>\n";
	    print XMLFILE "\t\t </dataset_definition>\n";
	}
	    print XMLFILE "\t\t </dataset_definitions>\n";

#Hints einfügen
	my @hints=$myconfig->val($dataset,'Hint');
	while (my $hint = shift(@hints)){
	    print XMLFILE "\t<hint format=\"html\"><text><![CDATA[<p>$hint</p>]]> </text></hint>\n"
	}
	print XMLFILE "</question>\n\n";
    }
    print XMLFILE "</quiz>\n";
    close XMLFILE;
}

