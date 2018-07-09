#!/usr/bin/perl
use strict;
#use Encode;
use Data::Dumper;   
#use encoding 'cp1251';
#use Encode::Locale;
#use autodie;  # automatic error handling  


my %Hash;

while (<>) {
    ParsLine($_) if (/^\d\d:\d\d\.\d+(.+?),CALL(.+?)Context/);
}

 # Выводим отсортированные (по убыванию) данные. Сортировка по значениею хеша
foreach my $Key (sort {$Hash{$b} <=> $Hash{$a}} keys %Hash) {
    # duration для 8.3 это миллионные доли секунды
    print "$Key - $Hash{$Key} (~". sprintf("%.2f", $Hash{$Key} / 1000000). " сек.) \n";
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

    $Hash{$Context} += $1 if ($line =~ /^[\d]+:[\d]+\.[\d]+[-]([\d]+)/);
    return %Hash;
  }