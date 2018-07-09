#!/usr/bin/perl
use strict;
#use Encode;
use Data::Dumper;   
#use encoding 'cp1251';
#use Encode::Locale;
#use autodie;  # automatic error handling  


my %Hash;
my $top;
my $SortByMem = 0;

InitializationParams();

#print $SortByMem;

#exit;

while (<STDIN>) {
    ParsLine($_) if (/^\d\d:\d\d\.\d+(.+?),CALL(.+?)Context/);
} continue {
    close ARGV if eof;  # Not eof()!
}

my $index = 1;
 # Выводим отсортированные (по убыванию) данные. Сортировка по значениею хеша
foreach my $Key (sort {$Hash{$b} <=> $Hash{$a}} keys %Hash) {
    last if $top eq $index;
    
    # duration для 8.3 это миллионные доли секунды
    if(not $SortByMem) {
        print "$Key" . " - ~". sprintf("%.2f", $Hash{$Key} / 1000000). " сек., ~" .sprintf("%.2f", $Hash{$Key} / 1000000 / 60) . " мин. \n";
    } else {
        print "$Key" . " - ~". sprintf("%.2f", $Hash{$Key} / 1024). " Kb., ~" .sprintf("%.2f", $Hash{$Key} / 1024**2) . " Mb. \n";
    }
    $index++;
}

sub ParsLine() {
    my ($line) = @_;
    
    my %tmp = GetHashFromLine($line);
    while(my($k, $v) = each(%tmp)) {
        $Hash{$k} += $v;
    }
  }

sub GetHashFromLine($) {
    my ($line) = @_;
    my $Context;
    my %Hash;

    $Context = $1 if $line =~ /Context='([^']+)/; 
    $Context = $1 if (not $Context) and $line =~ /Context=([^,]+)/;
    
    # Из контекста убираем пробелы и переносы строк.
    $Context =~ s/\n//g;
    $Context =~ s/\s//g;

    $Hash{$Context} += $1 if (not $SortByMem and $line =~ /^[\d]+:[\d]+\.[\d]+[-]([\d]+)/) or ($SortByMem and $line =~ /Memory=([\d]+)/);
    return %Hash;
  }

  sub InitializationParams() {
      foreach (@ARGV) {
        $top = $1 if /top([\d]+)/;
        $SortByMem = $_ eq "SortByMem" if not $SortByMem;
      }
  }