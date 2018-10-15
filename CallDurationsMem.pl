#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use Cwd;
use utf8;
use Data::Dumper;   
use Time::HiRes qw(gettimeofday tv_interval);
#use encoding 'cp1251';
use Encode;
#use autodie;  # automatic error handling  
use Benchmark; # Для замера выполнения кода
use XML::Simple;
use Digest::MD5 qw(md5 md5_hex);
use 5.016;

binmode(STDOUT,':utf8');

my %HashValue;
my %HashName;
my $top;
my $SortByMem = 0;
my $SortByCount = 0;
my $GroupByDB = 0;
my $SortByOneCall = 0;
my $start_time = Benchmark->new;
my @directories_to_search = (getcwd); # Текущая директория.  
InitializationParams();
#Time::HiRes::usleep(100000);

find(\&wanted, @directories_to_search);
sub wanted {
    ParsFile($_) if /^[\w]+.log$/i;
}

#while (<STDIN>) {
#    ParsLine($_);
#} continue {
#    close ARGV if eof;  # Not eof()!
#}

sub ParsFile() {
    my $fileName = shift;

    #my $pid = fork(); # or die "Не удалось форкнуть";
    #if ($pid) {
        # Родитель
    #    return;
    #} 

    open(my $FH, "<:encoding(utf8)", $fileName) or die "Ошибка открытия файла $fileName\n$!";

    my $txt;
    {
        local $/;
        $txt = <$FH>;
    } 
    close $FH;

    my @events = ("CALL", "DBMSSQL");

    local $" = "|";
    foreach($txt =~ /(^\d\d:\d\d\.\d+[-]\d+,(?|@events)(?:.*?)(?=\d\d:\d\d\.\d+))/gsm) {
       ParsLine($_);
    }
}

my $index = 0;
 # Выводим отсортированные (по убыванию) данные. Сортировка по значениею хеша
foreach my $Key (sort sort_func keys %HashValue) {
    last if defined($top) and $top eq $index;

    say "------------ (вызов $HashValue{$Key}{Count} раз) ------------";
    foreach(keys %{$HashValue{$Key}{Value}}) {
        my $ValueKb = sprintf("%.2f", $HashValue{$Key}{Value}{$_} / 1024);    
        my $ValueMb = sprintf("%.2f", $HashValue{$Key}{Value}{$_} / 1024**2);   
        my $AvValueKb = sprintf("%.2f", ($HashValue{$Key}{Value}{$_} / 1024) / $HashValue{$Key}{Count});   
        my $ValueSec = sprintf("%.2f", $HashValue{$Key}{Value}{$_} / 1000000);   
        my $AvValueSec = sprintf("%.2f", ($HashValue{$Key}{Value}{$_} / 1000000) / $HashValue{$Key}{Count});   
        my $ValueMin = sprintf("%.2f", $HashValue{$Key}{Value}{$_} / 1000000 / 60);   

        # duration для 8.3 это миллионные доли секунды
        if(not $SortByMem) {
            say "$_ [~ $ValueSec сек., ~ $ValueMin мин., среднее значение за вызов $AvValueSec сек.)]";
        } else {
            say "$_ [~ $ValueKb Kb., ~$ValueMb Mb., среднее значение за вызов $AvValueKb Kb.)]";
        }
    }

    say "$HashName{$Key}\n";
    
   $index++; 
}

sub sort_func {
    ($SortByOneCall and ($HashValue{$b}{Value}{Common} / $HashValue{$b}{Count}) <=> ($HashValue{$a}{Value}{Common} / $HashValue{$a}{Count}))
    || ($SortByCount and $HashValue{$b}{Count} <=> $HashValue{$a}{Count})
    || (not $SortByOneCall and not $SortByCount and $HashValue{$b}{Value}{Common} <=> $HashValue{$a}{Value}{Common}) # по дефолту
}

my $end_time = Benchmark->new;
my $delta = timediff($end_time, $start_time);
say "\n\nВремя выполнение скрипта:\n" . timestr($delta);

sub ParsLine() {
    my $line = shift;

    my %tmp = GetHashValueFromLine($line);
    
    while(my($k, $v) = each(%tmp)) {
       $HashValue{$k}{Count} += $$v{Count};
       map {
           $HashValue{$k}{Value}{$_} += $$v{Value}{$_};
           $HashValue{$k}{Value}{Common} += $$v{Value}{$_}
       } keys %{$$v{Value}};
       #$HashValue{$k}{Value} += $$v{Value};
    }
  }

sub GetHashValueFromLine($) {
    my ($line) = shift;
    return unless $line;

   # my $Context;
    my %HashValue;

# while($txt =~ /^\d\d:\d\d\.\d+[-]\d+,(?|@events)(?:.*?)(?|Method[^,]+|Context=([^'][^,]+)|Context='([^']+)).*?$/gm) {
    my $matching = $line =~ /p:processName=(?<DB>[^,]+)(.+?)(?|Context=(?<Context>[^,]+)|Context='(?<Context>[^']+))/s;
    my($DB, $Context) = ($+{DB}, $+{Context}) if $matching; 
    ($DB, $Context) = ($+{DB}, "$+{Module}.$+{Method}") if !$matching and $line =~ /p:processName=(?<DB>[^,]+)(.+?)Module=(?<Module>[^,]+)(?:.+?)Method=(?<Method>[^,]+)/; # Если контекста нет берем имя модуля и метода

    return unless $Context; # Выходим если контекста нет, накой нам эти строки.

    my $KeySource = "[$DB] $Context";
    $KeySource = $DB if $GroupByDB;
    my $Key = getHash($KeySource);
   
   $HashName{$Key} = $KeySource;

    my $Value = $+{Value} if (not $SortByMem and $line =~ /^[\d]+:[\d]+\.[\d]+[-](?<Value>[\d]+)[,](?<event>[^,]+)/) or ($SortByMem and $line =~ /^[\d]+:[\d]+\.[\d]+[-](?:[\d]+)[,](?<event>[^,]+).*?Memory=(?<Value>[-]?[\d]+)/); #MemoryPeak
    $HashValue{$Key} = {
        Count => 1,
        Value => {$+{event} => $Value}
    };

    return %HashValue;
  }

  sub InitializationParams {
      foreach (@ARGV) {
        $top = $1 if /top([\d]+)/;
        $SortByMem = uc($_) eq uc("SortByMem") if not $SortByMem;
        $SortByOneCall = uc($_) eq uc("SortByOneCall") if not $SortByOneCall;
        $GroupByDB = uc($_) eq uc("GroupByDB") if not $GroupByDB;
        $SortByCount = uc($_) eq uc("SortByCount") if not $SortByCount;
      }
  }

  sub getHash() {
      my $str = shift;

    # Из контекста убираем все лишние
    $str =~ s/[\n\s'\.;:\(\)\"\'\d]//g;
    return md5_hex(encode_utf8($str));
  }