#!/usr/bin/perl
use strict;
use Encode;
#use encoding 'cp1251';
#use Encode::Locale;
#use autodie;  # automatic error handling  

my $file_name, 
my $root_dir_name;
my $fileCall = "CALL.csv";
my $fileUsr = "USR.csv";
my $fileSCall = "SCALL.csv"; 

#binmode(STDOUT,':cp1251');
#binmode(STDOUT,':utf8');

#die "Ошибка открытия файла $fileCall" unless open my $FH_Call, ">:encoding(cp1251)", $fileCall; 
die "Ошибка открытия файла $fileCall" unless open my $FH_Call, ">", $fileCall; 
die "Ошибка открытия файла $fileUsr" unless open my $FH_Usr, ">:encoding(cp1251)", $fileUsr; 
die "Ошибка открытия файла $fileSCall" unless open my $FH_SCall, ">:encoding(cp1251)", $fileSCall; 


#while (defined(my $file = glob '*/rmng*/*.log')) {
while (defined(my $file = glob '*/rphost*/*.log')) {
#while (defined(my $file = glob '*/*/*.log')) {
    ($file_name, $root_dir_name) = ($3, $2) if $file =~  /^(.*)[\/](.+?)[\/](.*).log$/;
    
    die "Ошибка открытия файла $file" unless open my $FH, "<", $file; 
    while(<$FH>) {
        ParsLineCall($_, $file_name, $FH_Call) if (/^\d\d:\d\d\.\d+(.+?),CALL/) and not (/ISeanceContextStorage/);
        ParsLineSCall($_, $file_name, $root_dir_name, $FH_SCall) if (/^\d\d:\d\d\.\d+(.+?),SCALL/) and not (/ISeanceContextStorage/);
        ParsLineUsr($_, $file_name, $root_dir_name, $FH_Usr) if (/^\d\d:\d\d\.\d+(.+?),CONN/) ;
    }

    
}
  
close $FH_Call;
close $FH_SCall;
close $FH_Usr;  
  
sub ParsLineCall($) {
    my ($line, $file_name, $FH) = @_;
    my $CallID;
    my $Memory;
    my $Duration;
    #my $Module;
    #my $Method;

    ($Duration, $CallID, $Memory) = ($1, $3, $5) if $line =~ /\d\d:\d\d\.\d+[-](\d+)(.+?)CallID=([\d]+)(.+?)Memory=([\d]+)/;
    print $FH "$file_name;$CallID;$Memory;$Duration\n" if $CallID and $Memory > 0;
}   

sub ParsLineSCall($) {
    my ($line, $file_name, $root_dir_name, $FH) = @_;
    my $CallID;
    my $clientID;
    my $Context;

    $CallID = $1 if $line =~ /CallID=([\d]+)/;
    $clientID = $1 if $line =~ /t:clientID=([\d]+)/;
    $Context = $1 if $line =~ /Context=([^']+)/;
    
    # Из контекста убираем пробелы и переносы строк.
    $Context =~ s/\n//g;
    $Context =~ s/\s//g;

    print $FH decode("utf8", "$root_dir_name;$file_name;$clientID;$CallID\n") if $CallID;
}   

sub ParsLineUsr($) {
    my ($line, $file_name, $root_dir_name, $FH) = @_; 
    my $clientID;
    my $Usr;

    $clientID = $2 if $line =~ /(.+?)t:clientID=([\d]+)/;
    $Usr = $2 if $line =~ /(.+?)Usr=([^,]+)/;

    print $FH decode("utf8", "$root_dir_name;$clientID;$Usr;$file_name\n") if $Usr;
} 
