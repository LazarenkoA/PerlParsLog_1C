#!/usr/bin/perl
use strict;
use warnings;
use Encode;
use 5.016;
use Time::Piece;
use Data::Dumper; 
#use DateTime::Format::Strptime;



my %Buff;
while(<STDIN>) {
    my @Split = split(";", $_);
    push(@{$Buff{$Split[8]}}, $Split[2]) if $Split[2] and $Split[8];
} continue {
    close ARGV if eof;  # Not eof()!
}

foreach (keys %Buff) {
    my $MinDate;
    my $MaxDate;
    say $_;
    foreach(sort {$a cmp $b} @{$Buff{$_}}) {
        #my ($date, $time) = split(" ", $_);
        my $dt = Time::Piece->strptime($_, '%d.%m.%Y %H:%M:%S-%N') if /[\d]{2}[\.][\d]{2}[\.][\d]{4}/;
       $MinDate = $dt if !$MinDate or $dt < $MinDate;
       $MaxDate = $dt if !$MaxDate or $dt > $MaxDate;
    }

    my $D = $MaxDate -  $MinDate;
    say  "MinDate = $MinDate";
    say  "MaxDate = $MaxDate";
    say "Diff = $D";

}

#say Dumper \%Buff;