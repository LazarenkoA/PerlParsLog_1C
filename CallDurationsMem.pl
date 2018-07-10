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

print localtime ."\n\n";

InitializationParams();

while (<STDIN>) {
    ParsLine($_) if (/^\d\d:\d\d\.\d+(.+?),CALL(.+?)Context/);
} continue {
    close ARGV if eof;  # Not eof()!
}

my $index = 1;
 # Выводим отсортированные (по убыванию) данные. Сортировка по значениею хеша
foreach my $Key (sort {$Hash{$b}{Value} <=> $Hash{$a}{Value}} keys %Hash) {
    last if $top eq $index;

    my $ValueKb = sprintf("%.2f", $Hash{$Key}{Value} / 1024);    
    my $ValueMb = sprintf("%.2f", $Hash{$Key}{Value} / 1024**2);   
    my $AvValueKb = sprintf("%.2f", ($Hash{$Key}{Value} / 1024) / $Hash{$Key}{Count});   
    my $ValueSec = sprintf("%.2f", $Hash{$Key}{Value} / 1000000);   
    my $ValueMin = sprintf("%.2f", $Hash{$Key}{Value} / 1000000 / 60);   

    # duration для 8.3 это миллионные доли секунды
    if(not $SortByMem) {
        print "$Key" . " - ~ $ValueSec сек., ~ $ValueMin мин. \n";
    } else {
        print "$Key" . " - ~ $ValueKb Kb., ~$ValueMb Mb. (вызов $Hash{$Key}{Count} раз, среднее значение за вызов $AvValueKb Kb.) \n";
    }
   $index++;
}

print "\n\n" . localtime;

sub ParsLine() {
    my ($line) = @_;
    
    #my %tmp = GetHashFromLine($line);
    my %tmp = GetHashFromLine($line);
    
    while(my($k, $v) = each(%tmp)) {
       $Hash{$k}{Count} += $$v{Count};
       $Hash{$k}{Value} += $$v{Value};

       #print "$$v{Value}\n";
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

    return unless $Context; # Выходим если контекста нет, накой нам эти строки.

    my $Value = $1 if (not $SortByMem and $line =~ /^[\d]+:[\d]+\.[\d]+[-]([\d]+)/) or ($SortByMem and $line =~ /Memory=([-]?[\d]+)/);
    $Hash{$Context} = {
        Count => 1,
        Value => $Value
    };

    return %Hash;
  }

  sub InitializationParams() {
      foreach (@ARGV) {
        $top = $1 if /top([\d]+)/;
        $SortByMem = $_ eq "SortByMem" if not $SortByMem;
      }
  }