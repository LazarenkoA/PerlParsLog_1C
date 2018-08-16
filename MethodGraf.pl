#!/usr/bin/perl
use strict;
use Encode;
use File::Find;
use Cwd;
use Data::Dumper;   
use utf8;

my $CurrentDir = getcwd; # Текущая директория.
my $file_name; 
my @directories_to_search = ($CurrentDir);

binmode(STDOUT,':utf8');

find(\&wanted, @directories_to_search);
sub wanted {
    ParsFile($_) if /^(.*).bsl$/;
}

sub ParsFile() {
    my ($fileName) = @_;
    die "Ошибка открытия файла $fileName" unless open my $FH, "<:encoding(utf8)", $fileName;      

    my $txt;
    {
        local $/;
        $txt = <$FH>;
    }

    my @func = $txt =~ /^[\s]?функция[\s]+([\w]+)[(]/mgiu;
    my @proc = $txt =~ /^[\s]?процедура[\s]+([\w]+)[(]/mgiu;
    my @methods = ();
    push(@methods, @func);
    push(@methods, @proc);

    my @breakPath = split("/", $File::Find::dir);

    # Имя модуля второе с низу. 
    pop(@breakPath);
    my $moduleName = pop(@breakPath);
    foreach(@methods) {
        $_ = decode('Windows-1251', $moduleName).".".$_;
    }

    BuildCoupling(\@methods, $txt);
    #foreach(sort { $b cmp $a } @methods) {
    #    BuildCoupling($_, $txt);
    #}
   close $FH;
}

  
  sub BuildCoupling() {
    my ($methods, $txt) = @_;
    foreach(@$methods) {
        my @breakPath = split("[\.]", $_);
        my $methodName = pop(@breakPath);
        my $moduleName = pop(@breakPath);

        my $ConditionF = "функция[\\s]+".$methodName."[(][^)]+[)][\\s]+(Экспорт)?(.+?)конецфункции";
        my $ConditionP = "процедура[\\s]+".$methodName."[(][^)]+[)][\\s]+(Экспорт)?(.+?)конецпроцедуры";
        #print " \r\n $Condition\r\n ================ \r\n";

        my $MethodBody = $2 if $txt =~ /$ConditionF/msiu or $txt =~ /$ConditionP/msiu;
        my @calls = $MethodBody =~ /([\w]+[\.][\w]+)[(]/mgiu;
        push(@calls, &{ my @calls = $MethodBody =~ /([\w]+)[(]/mgiu; return @calls;});
        #my @calls = $MethodBody =~ /([\w]+[\.][\w]+)[(]/mgiu or $txt =~ /([\w]+)[(]/mgiu;

      

        foreach(@calls) {
          #  $_ = decode('Windows-1251', $moduleName).".".$_ if $#(split("[\.]", $_)) > 1;
          print "$_\r\n";
          my @CurrentMuduleCall = split("[\.]", $_);
          print $#CurrentMuduleCall;
         #   print "$_\r\n" if $#CurrentMuduleCall > 1;
        }
        
    }


  }