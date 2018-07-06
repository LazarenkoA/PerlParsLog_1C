    #!/usr/bin/perl

    use strict;
	#use warnings;
	use Data::Dumper;     
	
    


    my %actions = (
        'CALL' => [
 
                    {

                        'action' => sub {
                                my ($event) = @_;
                                my $duration = $3 if $event =~ /^(\d\d:\d\d)\.(\d+)[-](\d+)/;
                                my $context = $1 if $event =~ /Context=([^,]+)/; 

                                $context =~ s/\s//g; # Удаляем пробелы
							    my $result = "$duration-$context" if $context;
                        }

                    }

        ],
        'DBMSSQL' => [ 

                    {

                        'action' => sub {
                                   my ($event) = @_;
								   my $duration = $3 if $event =~ /^(\d\d:\d\d)\.(\d+)[-](\d+)/;
                                   my $context = $1 if $event =~ /Context='([^']+)/; 

                                # убираем табуляцию, т.е. такой вид
                                # ОбщийМодуль.Вызов : ОбщийМодуль.СоединенияИБВызовСервера.Модуль.ПараметрыБлокировкиСеансов
                                #   ОбщийМодуль.СоединенияИБВызовСервера.Модуль : 70 : Возврат СоединенияИБ.ПараметрыБлокировкиСеансов(ПолучитьКоличествоСеансов);
                                #         ОбщийМодуль.СоединенияИБ.Модуль : 88 : ПараметрыБлокировки = СтруктураПараметровБлокировкиСеансов();
                                #                 ОбщийМодуль.СоединенияИБ.Модуль : 744 : ТекущийРежимОбластиДанных = ПолучитьБлокировкуСеансовОбластиДанных();
                                #                         ОбщийМодуль.СоединенияИБ.Модуль : 316 : НаборБлокировок.Прочитать();
                                # приводим к такому:
                                # ОбщийМодуль.Вызов:ОбщийМодуль.СоединенияИБВызовСервера.Модуль.ПараметрыБлокировкиСеансов
                                # ОбщийМодуль.СоединенияИБВызовСервера.Модуль:70:Возврат СоединенияИБ.ПараметрыБлокировкиСеансов(ПолучитьКоличествоСеансов);
                                # ОбщийМодуль.СоединенияИБ.Модуль:88:ПараметрыБлокировки=СтруктураПараметровБлокировкиСеансов();
                                # ОбщийМодуль.СоединенияИБ.Модуль:744:ТекущийРежимОбластиДанных=ПолучитьБлокировкуСеансовОбластиДанных();
                                # ОбщийМодуль.СоединенияИБ.Модуль:316:НаборБлокировок.Прочитать();

                                $context =~ s/\n/<end_line>/g;
                                $context =~ s/\s//g;
                                $context =~ s/<end_line>/\n/g;
                                #print "$context \n\n";
								my $result = "$duration-$context" if $context;
                                
                        }

                    }

        ]
    );


    print "\n";
	
    my $Block;
    my @Buffer;
    while (<>) {
		if (/^\d\d:\d\d\.\d+/) {
			my $line = process_event($Block);
            push(@Buffer, $line) if $line;
			$Block = "";
		}
		$Block .= $_;
    }

    
	my %resultHash;  
    my %value; 
    my $Condition = qr(CALL[-](.+));
    foreach(grep(/$Condition/s, @Buffer)) {
        $resultHash{$2} += $1 if /^[\D]+[-](\d+)-(.+)/s; 
        # $value{CommonD} += $1 if /^[\D]+[-](\d+)-(.+)/s; 
        # $resultHash{$2} = \%value;
    }


    # Пересобираем буфер, что бы в нем не было учтенных элементов
    @Buffer = grep(!/$Condition/s, @Buffer);

    # C DBMSSQL все сложнее, т.к. строк много, нам нужно знать по какой стоит мунусовать CALL, а по какой нет 
    foreach my $key (keys %resultHash) {
        my $Condition = qr(DBMSSQL[-]([\d]+)[-](.*?)$key(.*?));
        my @SelectRow = grep(/$Condition/s, @Buffer);
        foreach(@SelectRow) {
            $resultHash{$key} -= $1 if /^[\D]+[-](\d+)/; 
        } 
        # Пересобираем буфер, что бы в нем не было учтенных элементов
        @Buffer = grep(!/$Condition/s, @Buffer);  
    }
    
    # То что осталось в @Buffer это запросы к БД которые не были учтены в CALL
    # Для катих элементов, добавляем в хеш по последней строки стека
    {
        print "==== Остаток ====\n";
        $" = "\n";
        print @Buffer;
        print "=====================\n\n";
    }
    # foreach(@Buffer)  {
        
    #     my @break = split("\n", $_);
    #     $resultHash{pop @break} += $1 if /^[\D]+[-](\d+)/;
    # }

    # Выводим отсортированные (по убыванию) данные. Сортировка по значениею хеша
    foreach my $tmp (sort {$resultHash{$b} <=> $resultHash{$a}} keys %resultHash) {
        # duration для 8.3 это иллионные доли секунды
        print "$tmp - $resultHash{$tmp} (~". sprintf("%.2f", $resultHash{$tmp}/1000000). " сек.) \n";
	}

    sub process_event($) {
		my $result;
        my ($Block) = @_;

		if (!$Block) {
			return;
		}

        foreach my $event_type ( keys %actions ) {

		#print "$event_type - 1 \n";
                next if not $Block =~ /^[^,]+,$event_type,/; # /^[^,]+,DBMSSQL,/

                #print "$event_type - 2 \n";
                #print Dumper ( @{ $actions{$event_type} });
                
                foreach my $issue ( @{ $actions{$event_type} }) {
                    my $resultLine = &{$issue->{action}}($Block);
                    $result = "$event_type-$resultLine\n" if $resultLine;
                    last;
                }
        }
		
		return $result;
    }
