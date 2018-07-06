#!/usr/bin/perl
use strict;
#use autodie;  # automatic error handling  

my $file_name, 
my $root_dir_name;
my $fileCall = "CALL.csv";
my $fileUsr = "USR.csv";
my $fileSCall = "SCALL.csv"; 

die "Ошибка открытия файла $fileCall" unless open my $FH_Call, ">", $fileCall; 
die "Ошибка открытия файла $fileUsr" unless open my $FH_Usr, ">", $fileUsr; 
die "Ошибка открытия файла $fileSCall" unless open my $FH_SCall, ">", $fileSCall; 


#while (defined(my $file = glob '*/rmng*/*.log')) {
while (defined(my $file = glob '*/rphost*/*.log')) {
#while (defined(my $file = glob '*/*/*.log')) {
    ($file_name, $root_dir_name) = ($3, $2) if $file =~  /^(.*)[\/](.+?)[\/](.*).log$/;
    
    die "Ошибка открытия файла $file" unless open my $FH, "<", $file; 
    while(<$FH>) {
        ParsLineCall($_, $file_name, $FH_Call) if (/^\d\d:\d\d\.\d+(.+?),CALL/) ;
        ParsLineSCall($_, $file_name, $root_dir_name, $FH_SCall) if (/^\d\d:\d\d\.\d+(.+?),SCALL/) ;
        ParsLineUsr($_, $file_name, $FH_Usr); # if (/^\d\d:\d\d\.\d+(.+?),CALL/) ;
    }

    
}
  
close $FH_Call;
close $FH_SCall;
close $FH_Usr;  
  
sub ParsLineCall($) {
    my ($line, $file_name, $FH) = @_;
    my $CallID;
    my $InBytes;


    $CallID = $2 if $line =~ /(.+?)CallID=([\d]+)/;
    $InBytes = $2 if $line =~ /(.+?)InBytes=([\d]+)/;

    print $FH "$file_name;$CallID;$InBytes\n" if $CallID and $InBytes > 0;
}   

sub ParsLineSCall($) {
    my ($line, $file_name, $root_dir_name, $FH) = @_;
    my $CallID;
    my $clientID;

    $CallID = $2 if $line =~ /(.+?)CallID=([\d]+)/;
    $clientID = $2 if $line =~ /(.+?)t:clientID=([\d]+)/;

    print $FH "$root_dir_name;$file_name;$clientID;$CallID\n";
}   

sub ParsLineUsr($) {
    my ($line, $root_dir_name, $FH) = @_;
    my $clientID;
    my $Usr;

    $clientID = $2 if $line =~ /(.+?)t:clientID=([\d]+)/;
    $Usr = $2 if $line =~ /(.+?)Usr=([^,]+)/;

    print $FH "$root_dir_name;$clientID;$Usr\n" if $Usr;
} 
