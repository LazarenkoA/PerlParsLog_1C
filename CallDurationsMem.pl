#!/usr/bin/perl
use strict;
#use Encode;
use Data::Dumper;   
use Time::HiRes qw(gettimeofday tv_interval);
#use encoding 'cp1251';
#use Encode::Locale;
#use autodie;  # automatic error handling  
use Benchmark; # Для замера выполнения кода
use XML::Simple;
use 5.016;


my %Hash;
my $top;
my $SortByMem = 0;
my $GroupByDB = 0;
my $SortByOneCall = 0;
my $start_time = Benchmark->new;
InitializationParams();
#Time::HiRes::usleep(100000);

while (<STDIN>) {
    ParsLine($_) if (/^\d\d:\d\d\.\d+(.+?),CALL/);
} continue {
    close ARGV if eof;  # Not eof()!
}


my $index = 1;
 # Выводим отсортированные (по убыванию) данные. Сортировка по значениею хеша
foreach my $Key (sort sort_func keys %Hash) {
    last if $top eq $index;

    my $ValueKb = sprintf("%.2f", $Hash{$Key}{Value} / 1024);    
    my $ValueMb = sprintf("%.2f", $Hash{$Key}{Value} / 1024**2);   
    my $AvValueKb = sprintf("%.2f", ($Hash{$Key}{Value} / 1024) / $Hash{$Key}{Count});   
    my $ValueSec = sprintf("%.2f", $Hash{$Key}{Value} / 1000000);   
    my $AvValueSec = sprintf("%.2f", ($Hash{$Key}{Value} / 1000000) / $Hash{$Key}{Count});   
    my $ValueMin = sprintf("%.2f", $Hash{$Key}{Value} / 1000000 / 60);   

    # duration для 8.3 это миллионные доли секунды
    if(not $SortByMem) {
        print "$Key" . " - ~ $ValueSec сек., ~ $ValueMin мин. (вызов $Hash{$Key}{Count} раз, среднее значение за вызов $AvValueSec сек.)\n";
    } else {
        print "$Key" . " - ~ $ValueKb Kb., ~$ValueMb Mb. (вызов $Hash{$Key}{Count} раз, среднее значение за вызов $AvValueKb Kb.) \n";
    }
   $index++;
}

sub sort_func {
    ($SortByOneCall and ($Hash{$b}{Value} / $Hash{$b}{Count}) <=> ($Hash{$a}{Value} / $Hash{$a}{Count}))
    || (not $SortByOneCall and $Hash{$b}{Value} <=> $Hash{$a}{Value})
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

    my $matching = $line =~ /p:processName=(?<DB>[^,]+)(.+?)Context=(?<Context>[^,]+)/;
    my($DB, $Context) = ($+{DB}, $+{Context}) if $matching; 
    ($DB, $Context) = ($+{DB}, "$+{Module}.$+{Method}") if !$matching and $line =~ /p:processName=(?<DB>[^,]+)(.+?)Module=(?<Module>[^,]+)(?:.+?)Method=(?<Method>[^,]+)/; # Если контекста нет берем имя модуля и метода

    # Из контекста убираем пробелы и переносы строк + Context может быть обрамлен '', убираем и их
    $Context =~ s/\n//g;
    $Context =~ s/\s//g;
    $Context =~ s/[']//g;

    my $Key = "[$DB] $Context";
    $Key = $DB if $GroupByDB;
    return unless $Context; # Выходим если контекста нет, накой нам эти строки.

    my $Value = $+{Value} if (not $SortByMem and $line =~ /^[\d]+:[\d]+\.[\d]+[-](?<Value>[\d]+)/) or ($SortByMem and $line =~ /Memory=(?<Value>[-]?[\d]+)/); #MemoryPeak
    $Hash{$Key} = {
        Count => 1,
        Value => $Value
    };

    return %Hash;
  }

  sub InitializationParams() {
      foreach (@ARGV) {
        $top = $1 if /top([\d]+)/;
        $SortByMem = uc($_) eq uc("SortByMem") if not $SortByMem;
        $SortByOneCall = uc($_) eq uc("SortByOneCall") if not $SortByOneCall;
        $GroupByDB = uc($_) eq uc("GroupByDB") if not $GroupByDB;
      }
  }