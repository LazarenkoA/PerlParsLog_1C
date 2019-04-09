#!/usr/bin/perl
use strict;
use Encode;
#use encoding 'cp1251';
#use Encode::Locale;
#use autodie;  # automatic error handling  

#my $file_name;
#my $root_dir_name;
my $fileCall = "CALL.csv";
my $fileUsr = "USR.csv";
my $fileSCall = "SCALL.csv"; 

#binmode(STDOUT,':cp1251');
#binmode(STDOUT,':utf8');

#die "Ошибка открытия файла $fileCall" unless open my $FH_Call, ">:encoding(cp1251)", $fileCall; 
die "Ошибка открытия файла $fileCall" unless open my $FH_Call, ">", $fileCall; 
die "Ошибка открытия файла $fileUsr" unless open my $FH_Usr, ">:encoding(cp1251)", $fileUsr; 
die "Ошибка открытия файла $fileSCall" unless open my $FH_SCall, ">:encoding(cp1251)", $fileSCall; 


#while (defined(my $file = glob 'rmng*/*.log')) {
while (defined(my $file = glob 'rphost*/*.log')) {
    my ($file_name, $root_dir_name) = ($2, $1) if $file =~  /^(.+?)[\/](.*).log$/;
    
    die "Ошибка открытия файла $file" unless open my $FH, "<", $file; 
    while(<$FH>) {
        ParsLineCall($_, $file_name, $FH_Call) if (/^\d\d:\d\d\.\d+(.+?),CALL/);
        ParsLineSCall($_, $file_name, $root_dir_name, $FH_SCall) if (/^\d\d:\d\d\.\d+(.+?),SCALL/);
        ParsLineUsr($_, $root_dir_name, $FH_Usr) if (/^\d\d:\d\d\.\d+(.+?),CONN/);
    }

    close $FH;
    
}
  
close $FH_Call;
close $FH_SCall;
close $FH_Usr;  
  
sub ParsLineCall($) {
    my ($line, $file_name, $FH) = @_;
    
    my ($Duration, $CallID, $InBytes) = ($1, $2, $3) if $line =~ /\d\d:\d\d\.\d+[-](\d+)(?:.+?)CallID=([^,]+)(?:.+?)InBytes=([\d]+)/;
    print $FH "$file_name;$CallID;$InBytes\n" if $CallID and $InBytes > 0;
}   

sub ParsLineSCall($) {
    my ($line, $file_name, $root_dir_name, $FH) = @_;
    my($clientID, $CallID) = ($1, $2) if $line =~ /t:clientID=([\d]+)(?:.+?)CallID=([^,]+)/;

    print $FH decode("utf8", "$root_dir_name;$file_name;$clientID;$CallID\n") if $CallID;
}   

sub ParsLineUsr($) {
    my ($line, $root_dir_name, $FH) = @_; 
    
    my($clientID, $Usr) = ($1, $2) if $line =~ /(?:.+?)t:clientID=([\d]+)(?:.+?)Usr=([^,]+)/;
    print $FH decode("utf8", "$root_dir_name;$clientID;$Usr\n") if $Usr;
} 
