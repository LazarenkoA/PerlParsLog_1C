#!/usr/bin/perl
use strict;
#use Encode;
use Data::Dumper;   
use Time::HiRes qw(gettimeofday tv_interval);
#use encoding 'cp1251';
#use Encode::Locale;
#use autodie;  # automatic error handling  
use Benchmark; # Для замера выполнения кода


my %Hash;
my $top;
my $GroupByDB = 0;
my $start_time = Benchmark->new;
InitializationParams();
#Time::HiRes::usleep(100000);


while (<STDIN>) {
    ParsLine($_) if (/^\d\d:\d\d\.\d+(.+?),DBMSSQL(.+?)Context/); # или SDBL
} continue {
    close ARGV if eof;  # Not eof()!
}

my $index = 1;
 # Выводим отсортированные (по убыванию) данные. Сортировка по значениею хеша
foreach my $Key (sort {$Hash{$b}{Value} <=> $Hash{$a}{Value}} keys %Hash) {
    last if $top eq $index;
 
    my $ValueSec = sprintf("%.2f", $Hash{$Key}{Value} / 1000000);   
    my $AvValueSec = sprintf("%.2f", ($Hash{$Key}{Value} / 1000000) / $Hash{$Key}{Count});   
    my $ValueMin = sprintf("%.2f", $Hash{$Key}{Value} / 1000000 / 60);   

    # duration для 8.3 это миллионные доли секунды
    print "$Key" . " - ~ $ValueSec сек., ~ $ValueMin мин. (вызов $Hash{$Key}{Count} раз, среднее значение за вызов $AvValueSec сек.)\n";
   
   $index++;
}

my $end_time = Benchmark->new;
my $delta = timediff($end_time, $start_time);
print "\n\nВремя выполнение скрипта:\n" . timestr($delta);

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
   # my $Context;
    my %Hash;

    my($DB, $Context) = ($1, $3) if $line =~ /p:processName=([^,]+)(.+?)Context=([^,]+)/; 

    #print $DB if $GroupByDB;

    # Из контекста убираем пробелы и переносы строк.
    # Context может быть орамлен '', убираем и их
    $Context =~ s/\n//g;
    $Context =~ s/\s//g;
    $Context =~ s/[']//g;

    my $Key = "[$DB] $Context";
    $Key = $DB if $GroupByDB;
    return unless $Context; # Выходим если контекста нет, накой нам эти строки.

    my $Value = $1 if $line =~ /^[\d]+:[\d]+\.[\d]+[-]([\d]+)/;
    $Hash{$Key} = {
        Count => 1,
        Value => $Value
    };

    return %Hash;
  }

  sub InitializationParams() {
      foreach (@ARGV) {
        $top = $1 if /top([\d]+)/;
        $GroupByDB = uc($_) eq uc("GroupByDB") if not $GroupByDB;
      }
  }