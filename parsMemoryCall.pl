#!/usr/bin/perl
use strict;
#use autodie;  # automatic error handling  

my $event;
my $count = 0;


while (defined(my $file = glob '*/rmng*/*.log')) {
    my $file_name;
    $file_name = $2 if $file =~ /^(.*)[\/](.*).log$/;

    die "Ошибка открытия файла" unless open my $FH, "<", $file; 
    while(<$FH>) {
        print ParsLineCall($_, $file_name);
    }
    
}
  
  
sub ParsLineCall($) {
    my ($line, $file_name) = @_;
    my $CallID;
    my $InBytes;

    $CallID = $2 if $line =~ /(.+?)CallID=([\d]+)/;
    $InBytes = $2 if $line =~ /(.+?)InBytes=([\d]+)/;

    return "$file_name;$CallID;$InBytes\r\n" if $InBytes > 0;
}   