#!/usr/bin/perl


print "Content-type: text/plain; charset=iso-8859-1\n\n\n";

$cmd=@ARGV[0];
$vdb=@ARGV[1];
$type=@ARGV[2];

$load_points=$cmd || 1;
#$type=$type||2;

$TOPN=5;

if (length ($ENV{'DEBUG'}) > 0){
   $DEBUG=$ENV{'DEBUG'};
} else {
  $DEBUG=0;
}

if ( 1 == $DEBUG ) {
  $kyle=1;
}

my $MON_HOME="/var/delphix/server/log";
my $MON_HOME="/export/home/delphix/MONITOR";
my $MON_HOME="/var/www/cgi-bin/MONITOR";

$curr_date=`cat $MON_HOME/currrent_data.out`;
#print "cat $MON_HOME/currrent_data.out\n";
#print "curr_date=$cur_date\n";
chomp($curr_date);
$MON_DATA=$MON_HOME . "/" . $curr_date;


#print "MON_DATA=$MON_DATA\n";

chdir("$MON_DATA") or die "Can't chdir to $MON_DATA $!";


      #system("echo name value  >> /tmp/num ");
      #system("echo 'hello' > /tmp/ash_args.txt ");
      $foo=$ENV{'SHELL'};
      #print "foo $foo";
      #$foo="echo \'$foo\' > /tmp/ash_args1.txt ";
      #print "foo $foo" if defined($kyle);
      #system($foo);
if (length ($ENV{'QUERY_STRING'}) > 0){
      #$foo="echo \'$ENV{'QUERY_STRING'}\'  > /tmp/ash_args.txt";
      #system($foo);
      $buffer = $ENV{'QUERY_STRING'};
      @pairs = split(/&/, $buffer);
      foreach $pair (@pairs){
           ($name, $value) = split(/=/, $pair);
           $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
           $in{$name} = $value; 
           system("echo name $name value $value >> /tmp/num ");
           if ( $name =~ "points" ) { $load_points=$value; };
           if ( $name =~ "vdb" ) { $vdb=$value; };
           if ( $name =~ "end_epoch" ) { $end_epoch=$value; };
           if ( $name =~ "beg_epoch" ) { $beg_epoch=$value; };
           if ( $name =~ "get_details" ) { $get_details=$value; };
           if ( $name =~ "type" ) { $type=$value; };
      }
 }
           $vdb='192.168.1.140:o1123';

@vdb = split(/:/, $vdb);
$my_ip=@vdb[0];
$my_sid=@vdb[1];

  
  print "debugging\n" if defined($kyle);
  print "cmd=$cmd\n" if defined($kyle);
  print "load_points=$load_points\n" if defined($kyle);
  print "my_ip=$my_ip\n" if defined($kyle);
  print "my_sid=$my_sid\n" if defined($kyle);

  print "beg_epoch=$beg_epoch\n" if defined($kyle);
  print "end_epoch=$end_epoch\n" if defined($kyle);
  print "get_details=$get_details\n" if defined($kyle);
  print "type=$type\n" if defined($kyle);


   $WAIT_CLASSES=13;

   $wcn[0]="Idle";

   $wcn[1]="Administrative";
   $wcn[2]="Application";
   $wcn[3]="Cluster";
   $wcn[4]="Commit";
   $wcn[5]="Concurrency";
   $wcn[6]="Configuration";
   $wcn[7]="Network";
   $wcn[8]="Other";
  $wcn[9]="Queueing";
  $wcn[10]="Scheduler";
  $wcn[11]="System_I/O";
  $wcn[12]="User_I/O";
  $wcn[13]="CPU";

   $wcn_short[0]="idle";
   $wcn_short[1]="adm";
   $wcn_short[2]="app";
   $wcn_short[3]="clu";
   $wcn_short[4]="com";
   $wcn_short[5]="cnc";
   $wcn_short[6]="cnf";
   $wcn_short[7]="net";
   $wcn_short[8]="oth";
  $wcn_short[9]="que";
  $wcn_short[10]="sch";
  $wcn_short[11]="sio";
  $wcn_short[12]="uio";
  $wcn_short[13]="cpu";

   $bucket_size=5;
   $pts=0;

  $target= "$my_ip" . ":" . "$my_sid" ;
  $file="$MON_DATA" . "/" . "$target" .  ":ash.dat";

  print "file=$file\n" if defined($kyle);

 # get the last_epoch from the data file
 # last_epoch used as an end date if no end_date sent in 
   open(ASH," tail -qn 1 $file |");
   while ( $line=<ASH>  ) {
       ($hour_min, $last_epoch)=split(",",$line);
   }
   close(ASH);

  
   if ( $get_details==1 &&  $beg_epoch != 0 && $end_epoch != 0 ) {
      # change to seconds from milliseconds
        $end_epoch=int($end_epoch/1000);
        $beg_epoch=int($beg_epoch/1000);
      # round off to return bucket sizes
        $end_epoch=int($end_epoch/$bucket_size)*$bucket_size;
        $beg_epoch=int($beg_epoch/$bucket_size)*$bucket_size;
      # get delta in seconds for computing AAS
        $delta=$end_epoch-$beg_epoch+bucket_size;
        print "get_details delta=$delta;\n" if defined($kyle);
   } else {
      $end_epoch=int($last_epoch/$bucket_size)*$bucket_size;
      $beg_epoch=$end_epoch - (($load_points-1) * $bucket_size); 
      $delta=$end_epoch-$beg_epoch+bucket_size;
      print "all_data   delta1=$delta;\n" if defined($kyle);
   }

   $min_epoch=0; 
   $max_epoch=0; 

   print " beg_epoch:$beg_epoch:\n end_epoch:$end_epoch:\nlast_epoch:$last_epoch:\n" if defined($kyle);


   open(ASH,"$file");
   while ( $line=<ASH>  ) {
##  if (  $pts <= $load_points ) {
#     print "pts= $pts, load_points= $load_points\n";
     # print "$line \n";
     # get rid of return
       chomp($line);
     # get rid of white space, shouldn't be any
       $line=~ s/\s+//g;

       ($hour_min,
        $epoch,
        $sample_id,
        $session_id,
        $user_name,
        $sql_id,
        $sql_plan_id,
        $session_type,
        $event,
        $wait_class)=split(",",$line);

      # "==" only works for numbers, "eq" is for strings


      if ( $sql_id eq "" ) { $sql_id="no_sql_id" ;  }

      if ( $epoch <  $end_epoch && $epoch >= $beg_epoch ) { 
         print "line; $line \n" if defined($kyle);
         #print "sql-$sql_id,epoch-$epoch\n";
         # => set epoch  into buckets
           $cur_epoch=int($epoch/$bucket_size)*$bucket_size;
           
           if ( $min_epoch == 0 ) { $min_epoch=$cur_epoch; }
           if ( $cur_epoch > $max_epoch ) { $max_epoch=$cur_epoch; }
           if ( $cur_epoch < $min_epoch ) { $min_epoch=$cur_epoch; }

           $bar->{$cur_epoch,$wait_class}++;
   
           $total++;
           $topsql{$sql_id}++;
           $topevt{$event}++;
           $topses{$session_id}++;
           $topses_name{$session_id}=$user_name;

           $sql->{$sql_id,$wait_class}++;
           $ses->{$session_id,$wait_class}++;
           $evt->{$event,$wait_class}++;

           #print "xx sql->{$sql_id,$wait_class}=$sql->{$sql_id,$wait_class}\n" ;
           #print "xx sql->{$sql_id,$wait_class}=$sql->{$sql_id,$wait_class}\n" if defined($kyle);
           #print "$end_epoch, $wait_class, $bar->{$end_epoch,$wait_class} \n" if defined($kyle);
   
           $wc->{$wait_class}++;
        }
##   } else {
##     last;
##   }
    }
    close(ASH);

   $delta=$max_epoch-$min_epoch+bucket_size;
   print "delta2=$delta;\n" if defined($kyle);

# print "\n pts=$pts; load_points:$load_points \n\n";

 print "{";
 if ( $get_details!=1 ) {
  # AAS load chart
  # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  # for each WAIT_CLASS
    for ( $j=1; $j <= $WAIT_CLASSES ; $j++ ) {
       $pts=1; 
      print "\n" if defined($kyle);
       print "\"$wcn[$j]\":[";
     # for each EPOCH
       for ( $i = $beg_epoch; $i <  $end_epoch ; $i+=$bucket_size ) {
        # seems highcharts takes millsecs
          $tm=$i*1000;
          #print "[$tm,";
          $val=$bar->{$i,$wcn[$j]}||0;
          $val=int(($val/$bucket_size )*100)/100;
          #print "$val],";

        print "[$tm,$val],";
        $tm=$i*1000+$bucket_size*1000-1;
        print "[$tm,$val],";

          $pts++;
       }
     # $i has already been incremented from for loop, and loop skiped, so $i is read for new point
     # $i=$i+$bucket_size;
     # seems highcharts takes millsecs
       $tm=$i*1000;
     # value is    [epoch, wait_class#]  or 0 if doesn't exist
       if ($load_points == 1 ) { 
          print "$tm,";
          $val=$bar->{$i,$wcn[$j]}||0;
          $val=int(($val/$bucket_size )*100)/100;
          print "$tm,$val]";
          $tm=$tm+$bucket_size*1000-1;
          print "[$tm,$val],";
       } else {
          $val=$bar->{$i,$wcn[$j]}||0;
          $val=int(($val/$bucket_size )*100)/100;
          print "[$tm,$val],";
          $tm=$tm+$bucket_size*1000-1;
          print "[$tm,$val]]";
       }

      if ( $WAIT_CLASSES != $j ) {
     #    print "}\n" ;
     # } else {
         print "," ;
      }
    }
  # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 }

print "if ( 2  <= $type )\n" if defined($kyle);
if ( 0  <= $type ) {
 if ( $get_details!=1 ) {
    print "," ;
 }
   # top sql
   $i=1;
   # sort descending cmp b to a, ascending a to b 
   $nsql =keys( %topsql );
   foreach $sql_id (sort { $topsql{$b} <=> $topsql{$a} } keys %topsql) {
      if ( $i <= $TOPN ) {
        if ( $i < $TOPN && $i < $nsql ) { $sep = "," ; } else { $sep = "" }
        $sqlnames.="\"$sql_id\"$sep";
        for ( $j=1; $j <= $WAIT_CLASSES ; $j++ ) {
          $val=$sql->{$sql_id,$wcn[$j]}||0;
       #  AAS
       #  $val=int(($val/($end_epoch-$beg_epoch+bucket_size )*1000))/1000;
       #  percent of total
          $val=int(($val/($total )*1000))/10;
          $sqlnames{$j}.=$val.$sep;
        }
      } else { last; }
      $i++;
    }

  # top event
    $i=1;
    $nevt =keys( %topevt );
    foreach $evt_id (sort { $topevt{$b} <=> $topevt{$a} } keys %topevt) {
      if ( $i <= $TOPN ) {
         if ( $i < $TOPN && $i < $nevt ) { $sep = "," ; } else { $sep = "" }
       # print "\n$i < $TOPN && $i < $nevt \n";
         $evtnames.="\"$evt_id\"$sep";
         for ( $j=1; $j <= $WAIT_CLASSES ; $j++ ) {
           $val=$evt->{$evt_id,$wcn[$j]}||0;
       #  AAS
       #  $val=int(($val/($end_epoch-$beg_epoch+bucket_size )*1000))/1000;
       #  percent of total
          $val=int(($val/($total )*1000))/10;
           $evtnames{$j}.=$val.$sep;
         }
       } else { last; }
       $i++;
    }

  # top ses
    $i=1;
    $nses =keys( %topses );
    foreach $ses_id (sort { $topses{$b} <=> $topses{$a} } keys %topses) {
      if ( $i <= $TOPN ) {
         if ( $i < $TOPN && $i < $nses ) { $sep = "," ; } else { $sep = "" }

         #$topses_name{$session_id}=$user_name;
         $ses_name=$topses_name{$ses_id};
         #$sesnames.="\"$ses_id\"$sep";
         $sesnames.="\"$ses_name\"$sep";

         for ( $j=1; $j <= $WAIT_CLASSES ; $j++ ) {
           $val=$ses->{$ses_id,$wcn[$j]}||0;
       #  AAS
       #  $val=int(($val/($end_epoch-$beg_epoch+bucket_size )*1000))/100;
       #  percent of total
          $val=int(($val/($total )*1000))/10;
           $sesnames{$j}.=$val.$sep;
         }
       } else { last; }
       $i++;
    }

    print "\n" if defined($kyle);
    print "\"evtnames\":[$evtnames],";
    print "\n" if defined($kyle);
    for ( $j=1; $j <= $WAIT_CLASSES ; $j++ ) {
           print "\"evt_$wcn_short[$j]\":[$evtnames{$j}]";
           if ( $WAIT_CLASSES != $j ) { print "," ; } 
           print "\n" if defined($kyle);
    }
    print ",\"sqlnames\":[$sqlnames],";
    print "\n" if defined($kyle);
    for ( $j=1; $j <= $WAIT_CLASSES ; $j++ ) {
           print "\"sql_$wcn_short[$j]\":[$sqlnames{$j}]";
           if ( $WAIT_CLASSES != $j ) { print "," ; } 
           print "\n" if defined($kyle);
    }
    print ",\"sesnames\":[$sesnames],";
    print "\n" if defined($kyle);
    for ( $j=1; $j <= $WAIT_CLASSES ; $j++ ) {
           print "\"ses_$wcn_short[$j]\":[$sesnames{$j}]";
           if ( $WAIT_CLASSES != $j ) { print "," ; } 
           print "\n" if defined($kyle);
    }

    # {
    print "}\n" ;

 # while (($key, $val) = each %$wc) {
 #   print "$key=", $val, "\n";
 # }

 #if ( 1 == $DEBUG ) {
 #} # end DEBUG

} else {
        print "}\n" ;
}

