#!/bin/ksh 

# ./collect.sh delphix delphix 172.16.100.250 orcl 1521 &


function usage
{
       echo "Usage: $(basename $0) <username> <password> <host> [sid] [port]"
       echo "  username        database username"
       echo "  username        database password"
       echo "  host            hostname or IP address"
       echo "  sid             optional database sid (default: orcl)"
       echo "  port            optional database port (default: 1521)"
       echo "  run time (secs) optional (default: 43200 , ie 12 hours) "
       exit 2
}

[[ $# -lt 3 ]] && usage
[[ $# -gt 5 ]] && usage

UN=delphix
PW=delphix
HOST=172.16.100.250
SID=orcl
PORT=1521
RUN_TIME=43200     # total run time, 12 hours default 43200
RUN_TIME=86400     # total run time, 24 hours default 86400
RUN_TIME=864000    # total run time, 10 days  default 864000
RUN_TIME=-1        #  run continuously

[[ $# -gt 0 ]] && UN=$1
[[ $# -gt 1 ]] && PW=$2
[[ $# -gt 2 ]] && HOST=$3
[[ $# -gt 3 ]] && SID=$4
[[ $# -gt 4 ]] && PORT=$5
[[ $# -gt 5 ]] && RUN_TIME=$6

# the dtrace will take an IP address as an argument and filter for just that IP 
# DTRACE_HOST=$HOST


    # seems to sample at sample rate +3 secs, ie 7 actual works out to 10 secs
    FAST_SAMPLE="avgreadsz avgreadms avgwritesz avgwritems throughput aas wts systat ash"     # list of stats to sample 
    FAST_SAMPLE="ash"     # list of stats to sample 
    DEBUG=${DEBUG:-0}            # 1 output debug, 2 include SQLplus output

    MON_HOME=${MON_HOME:-/tmp/MONITOR} 
    MON_HOME=${MON_HOME:-$HOME/MONITOR} 
    LOG=${LOG:-"$MON_HOME/log"}
    TMP=${TMP:-"$MON_HOME/tmp"}
    CLEAN=${CLEAN:-"$MON_HOME/clean"}

    mkdir $LOG > /dev/null 2>&1
    mkdir $TMP > /dev/null 2>&1
    mkdir $CLEAN > /dev/null 2>&1

    MACHINE=`uname -a | awk '{print $1}'`
    case $MACHINE  in
    Linux)
            MKNOD=/bin/mknod
            ;;
    AIX)
            MKNOD=/usr/sbin/mknod
            ;;
    SunOS)
            MKNOD=/etc/mknod
            ;;
    HP-UX)
            MKNOD=mknod
            ;;
    *)
            MKNOD=mknod
            ;;
    esac


  # create OUPUT directory
    if [ ! -f "$MON_HOME" ]; then
       mkdir $MON_HOME > /dev/null 2>&1
    fi

  # "collect.sh end" will end all running collect.sh's
    if test x$1 = xend ; then
       if [ -f $MON_HOME/*\.end ]; then
           rm $MON_HOME/*\.end
       fi
       if [ -f $MON_HOME/*/*\.end ]; then
           rm $MON_HOME/*/*\.end
       fi
       exit
    fi

  # setup OUTPUT file name template
  # CURR_DATE=`date "+%d%m_%H%M%S"`  
  # CURR_DATE=`date "+%m%d_%H"`  
    CURR_DATE=`date "+%u_%H"`  

  # MON_NODE="`hostname | sed -e 's/\..*//'`"

    TARGET=${HOST}:${SID}
    SUF=.dat


    OUTPUT=${LOG}/${TARGET}_connect.log
    CLEANUP=${CLEAN}/${TARGET}_cleanup.sh
    SQLTESTOUT=${TMP}/${TARGET}_collect.out
    OPEN=${TMP}/${TARGET}_collect.open
    PIPE=${TMP}/${TARGET}_collect.pipe
    EXIT=${CLEAN}/${TARGET}_collect.end

  # exit if removed
    touch $EXIT

  # printout setup
    for i in 1; do
    echo
    echo
    echo "SYS=$SYS" 
    echo "RUN_TIME=$RUN_TIME" 
    echo "FAST_SAMPLE=$FAST_SAMPLE" 
    echo "HOST=$HOST" 
    echo "DEBUG=$DEBUG" 
    echo
    done > $OUTPUT
    cat $OUTPUT

  # create a UNIX named pipe
  # in order to avoid disconnects when attaching sqlplus to the named pipe
  # create an empty file and "tail -f" this empty file into the pipe
  # this will prevent the pipe from closing on the sqlplus session
  # otherwise the sqlplus session would exit after every cat to the pipe
  # had finished

  # setup sqlplus connection reading off a pipe
    rm $OPEN $PIPE > /dev/null 2>&1
    touch  $OPEN
    cmd="$MKNOD $PIPE p"
    eval $cmd
    tail -f $OPEN >> $PIPE &
    OPENID="$!"


  # run SQLPLUS silent unless DEBUG is 2 or higher 
       SILENT=""
    if [ $DEBUG -lt 2 ]; then
       SILENT="-s"
    fi
    CONNECT="$UN/$PW@(DESCRIPTION= (ADDRESS_LIST= (ADDRESS= (PROTOCOL=TCP) (HOST=$HOST) (PORT=$PORT))) (CONNECT_DATA= (SERVER=DEDICATED) (SID=$SID)))"
    #CONNECT="$UN/$PW@(DESCRIPTION= (ADDRESS_LIST= (ADDRESS= (PROTOCOL=TCP) (HOST=$HOST) (PORT=$PORT))) (CONNECT_DATA= (SERVER=DEDICATED) (SERVICE_NAME=$SID)))"
    cmd="sqlplus $SILENT \"$CONNECT\" < $PIPE > /dev/null &" 
    echo "$cmd" >> ${OUTPUT}
    eval $cmd 
    SQLID="$!"

  # setup exit/cleanup stuff
    for i in 1; do
      echo "date" 
      echo "("
      echo "rm $PIPE $OPEN $EXIT"  
      echo "kill -9 $SQLID $OPENID $VMSTATID"
      echo ") > /dev/null 2>&1"
      echo "rm  $LOG/${HOST}:${SID}_connect.log"
    done > $CLEANUP
    chmod 755 $CLEANUP
    trap "echo $CLEANUP;sh $CLEANUP" 0 3 5 9 15 

    if [ ! -p $PIPE ]; then
       echo "error creating named pipe "
       echo "command was:"
       echo "             $cmd"
       eval $CMD
       exit
    fi

#   /******************************/
#   *                             *
#   * BEGIN FUNCTION DEFINITIONS  *
#   *                             *
#   /******************************/
#

function debug {
if [ $DEBUG -ge 1 ]; then
   #   echo "   ** beg debug **"
   var=$*
   nvar=$#
   if test x"$1" = xvar; then
     shift
     let nvar=nvar-1
     while (( $nvar > 0 ))
     do
        eval val='$'{$1} 1>&2
        echo "       :$1:$val:"  1>&2
        shift
        let nvar=nvar-1
     done
   else
     while (( $nvar > 0 ))
     do
        echo "       :$1:"  1>&2
        shift
        let nvar=nvar-1
     done
   fi
   #   echo "   ** end debug **"
fi
}                         

function check_exit {
        if [  ! -f $EXIT ]; then
           echo "exit file removed, exiting at `date`"
           cat $CLEANUP
           $CLEANUP 
           exit
        fi
}

function sqloutput  {
    cat << EOF >> $PIPE &
       set pagesize 0
       set feedback off
       spool $SQLTESTOUT
       select 1 from dual;
       spool off
EOF
}

function testconnect {
     rm $SQLTESTOUT 2> /dev/null
     if [ $CONNECTED -eq 0 ]; then
        limit=10
     else
        limit=60
     fi
     debug "before sqloutput"
     sqloutput
     debug "after sqloutput"
     count=0
     found=1
     debug "before while"
     while [ $count -lt $limit -a $found -eq 1 ]; do
        if [ -f $SQLTESTOUT ]; then
          grep '^ *1'  $SQLTESTOUT > /dev/null  2>&1
          found=$?
        else 
          debug  "sql output file: $SQLTESTOUT, not found"
        fi
          debug "found $found"
          debug "loop#   $count limit $limit "
          if [ $CONNECTED -eq 0 ]; then
             echo "Trying to connect"
          fi
          let TO_SLEEP=TO_SLEEP-count
          sleep $count
          count=`expr $count + 1`
          check_exit
     done
     debug "after while"
     if [ $count -ge $limit ]; then
       echo "output from sqlplus: "
       if [ -f $SQLTESTOUT ]; then
          cat $SQLTESTOUT 
       else
          echo "sqlplus output file: $SQLTESTOUT, not found"
          echo "check user name and password for sqlplus"
          echo "try 'export DEBUG=1' and rerun"
       fi
       echo "loop#  $count limit $limit " >> $OUTPUT
       echo "collect.sh : timeout waiting connection to sqlplus"
       echo "collect.sh : timeout waiting connection to sqlplus" >> $OUTPUT
       eval $CMD
       exit
     fi
     echo "count# $count limit $limit " >> $OUTPUT
}


# wait times - count, total time
function wts  {
     cat << EOF
     spool  ${TMP}/${TARGET}_wts.tmp
     Select 'waitstat'       ||','|| 
            total_waits      ||','|| 
            time_waited_micro||','|| 
            replace(event,' ','_')
     from v\$system_event
      where event in  (
          'db file sequential read',     -- single
          'db file parallel read',       -- multi 2-128 ?
          'db file scattered read',      -- multi 2-128 blocks ?
          'direct path read',            -- multi 1-128 blocks (8K-1M)
          'direct path write',           
          'direct path write temp',      
          'direct path read temp',       -- multi 1-128 ?? smaller
          'control file sequential read',-- multi 1-64 (blocks?)
          'log file sequential read',    -- multi 512 bytes - 4M
          'log file sync',               -- write
          'log file parallel write'      -- write
           ) ;
     spool off
EOF
}



function ash  {
     cat << EOF
     spool  ${TMP}/${TARGET}_ash.tmp
      select
      (cast(sysdate as date)-to_date('01-JAN-1970','DD-MON-YYYY'))*(86400) ||','||
         1  ||','||
         concat(s.sid,concat('_',s.serial#))  ||','||
         decode(type,'BACKGROUND',substr(program,-5,4),u.username)  ||','||
         s.sql_id ||','||
      --  sql_plan_hash_value is not in v$session but in x$ksusea KSUSESPH
         s.SQL_CHILD_NUMBER ||','||
         s.type ||','||
       decode(s.WAIT_TIME,0,replace(s.event,' ','_') , 'ON CPU') ||','||
       decode(s.WAIT_TIME,0,replace(s.wait_class,' ','_') , 'CPU' )
      from
             v\$session s,
             all_users u
      where
        u.user_id=s.user# and
        s.sid != ( select distinct sid from v\$mystat  where rownum < 2 ) and
            (  ( s.wait_time != 0  and  /* on CPU  */ s.status='ACTIVE'  /* ACTIVE */)
                 or
               s.wait_class  != 'Idle' 
            )
     ;
     spool off
EOF
}


function ash1  {
     cat << EOF
     spool  ${TMP}/${TARGET}_ash.tmp
     Select
 (cast(ash.SAMPLE_TIME as date)-to_date('01-JAN-1970','DD-MON-YYYY'))*(86400) ||','||
       ash.sample_id               ||','||
       ash.session_id              ||'_'|| session_serial# ||','||
       decode(ash.session_type,'BACKGROUND',substr(program,-5,4),u.username)  ||','||
       ash.sql_id                  ||','||
       ash.sql_plan_hash_value     ||','||
       ash.session_type            ||','||
       decode(session_state,'ON CPU','CPU',replace(ash.event,' ','_') ) ||','||
       decode(session_state,'ON CPU','CPU',replace(ash.wait_class,' ','_') ) 
     from v\$active_session_history ash, all_users u
     where
        ash.sample_id > $sample_id   and
        u.user_id=ash.user_id
     order by ash.sample_id 
     ;
     spool off
EOF
}

# reads, blocks, time
function systat  {
     cat << EOF
     spool  ${TMP}/${TARGET}_systat.tmp
     Select 'systat'  ||','|| 
            replace(name,' ','_') ||','|| 
             value   ||','|| 
	     stat_id    
       from v\$sysstat fs 
       where stat_id in (
          789768877,  -- physical read IO requests            
          3343375620, -- physical read total IO requests
          523531786,  -- physical read bytes                     
          2572010804, -- physical read total bytes
          2007302071, -- physical read total multi block requests
          2263124246, -- physical reads
          4171507801, -- physical reads cache
          2589616721, -- physical reads direct
          789768877 , -- physical read IO requests
          2663793346, -- physical reads direct temporary tablespace
          2564935310  -- physical reads direct (lob)
       );
     spool off
EOF
}

function aas  {
     cat << EOF
     spool  ${TMP}/${TARGET}_aas.tmp
with AASSTAT as (
           select
                 decode(n.wait_class,'User I/O','User I/O',
                                     'Commit','Commit',
                                     'Wait')                               CLASS,
                 sum(round(m.time_waited/m.INTSIZE_CSEC,3))                AAS
           from  v\$waitclassmetric  m,
                 v\$system_wait_class n
           where m.wait_class_id=n.wait_class_id
             and n.wait_class != 'Idle'
           group by  decode(n.wait_class,'User I/O','User I/O', 'Commit','Commit', 'Wait')
          union
             select 'CPU_ORA_CONSUMED'                                     CLASS,
                    round(value/100,3)                                     AAS
             from v\$sysmetric
             where metric_name='CPU Usage Per Sec'
               and group_id=2
          union
            select 'CPU_OS'                                                CLASS ,
                    round((prcnt.busy*parameter.cpu_count)/100,3)          AAS
            from
              ( select value busy from v\$sysmetric where metric_name='Host CPU Utilization (%)' and group_id=2 ) prcnt,
              ( select value cpu_count from v\$parameter where name='cpu_count' )  parameter
          union
             select
               'CPU_ORA_DEMAND'                                            CLASS,
               nvl(round( sum(decode(session_state,'ON CPU',1,0))/60,2),0) AAS
             from v\$active_session_history ash
             where SAMPLE_TIME > sysdate - (60/(24*60*60))
)
select
       decode(sign(CPU_OS-CPU_ORA_CONSUMED), -1, 0, (CPU_OS - CPU_ORA_CONSUMED )) ||','||
       CPU_ORA_CONSUMED ||','||
       decode(sign(CPU_ORA_DEMAND-CPU_ORA_CONSUMED), -1, 0, (CPU_ORA_DEMAND - CPU_ORA_CONSUMED )) ||','||
       COMMIT||','||
       READIO||','||
       WAIT
from (
select
       sum(decode(CLASS,'CPU_ORA_CONSUMED',AAS,0)) CPU_ORA_CONSUMED,
       sum(decode(CLASS,'CPU_ORA_DEMAND'  ,AAS,0)) CPU_ORA_DEMAND,
       sum(decode(CLASS,'CPU_OS'          ,AAS,0)) CPU_OS,
       sum(decode(CLASS,'Commit'          ,AAS,0)) COMMIT,
       sum(decode(CLASS,'User I/O'        ,AAS,0)) READIO,
       sum(decode(CLASS,'Wait'            ,AAS,0)) WAIT
from AASSTAT);
     spool off
EOF
}


#  
function throughput  {
     #  read_kb/s, write_kb/s, read_kb_total/s, write_kb_total/s
     cat << EOF
     spool  ${TMP}/${TARGET}_throughput.tmp
     select   
         round((sum(decode(metric_name, 'Physical Read Bytes Per Sec' , value,0)))/1024,0) ||','||
         round((sum(decode(metric_name, 'Physical Write Bytes Per Sec' , value,0 )))/1024,0)  ||','||
         round((sum(decode(metric_name, 'Physical Read Total Bytes Per Sec' , value,0)))/1024,0) ||','||
         round((sum(decode(metric_name, 'Physical Write Total Bytes Per Sec' , value,0 )))/1024,0) ||','||
         round((sum(decode(metric_name, 'Physical Write Total IO Requests Per Sec', value,0 ))),1) ||','||
         round((sum(decode(metric_name, 'Physical Read Total IO Requests Per Sec' , value,0 ))),1)
     from     v\$sysmetric
     where    metric_name in (
                    'Physical Read Total Bytes Per Sec' ,
                    'Physical Read Bytes Per Sec' , 
                    'Physical Write Bytes Per Sec' ,
                    'Physical Write Total Bytes Per Sec' ,
                    'Physical Write Total IO Requests Per Sec',
                    'Physical Read Total IO Requests Per Sec'
                    )
       and group_id=2;
     spool off
EOF
}


function avgwritems   {
     cat << EOF
     spool  ${TMP}/${TARGET}_avgwritems.tmp
     select 
       m.wait_count  ||','||
       10*m.time_waited ||','||
       nvl(round(10*m.time_waited/nullif(m.wait_count,0),3) ,0)
     from v\$eventmetric m,
          v\$event_name n
     where m.event_id=n.event_id
       and n.name in ( 'log file parallel write');
     spool off
EOF
}


#  
function avgwritesz  {
     # redo_KB/s, redo_writes/s , avg_redo_KB 
     cat << EOF
     spool  ${TMP}/${TARGET}_avgwritesz.tmp
     select
         round(sum(decode(metric_name,'Redo Generated Per Sec',value,0))/1024) ||','||
         round(sum(decode(metric_name,'Redo Writes Per Sec',value,0)),2) ||','||
         nvl(round(sum(decode(metric_name,'Redo Generated Per Sec',value,0)) /
         nullif(sum(decode(metric_name,'Redo Writes Per Sec',value,0)),0)/1024,0),0)
     from     v\$sysmetric
     where    metric_name in  (
                           'Redo Writes Per Sec',
                           'Redo Generated Per Sec'
         )
      and     group_id=2;
     spool off
EOF
}

function avgreadsz  {
     #  read_KB/s, reads/s, avg_read_KB
     cat << EOF
     spool  ${TMP}/${TARGET}_avgreadsz.tmp
        select 
          round(sum(decode(metric_name,'Physical Read Total Bytes Per Sec',value,0))/1024,2)  ||','||
          round(sum(decode(metric_name,'Physical Read Total IO Requests Per Sec',value,0)),2)  ||','||           
          round((nvl(sum(decode(metric_name,'Physical Read Total Bytes Per Sec',value))/
            nullif(sum(decode(metric_name,'Physical Read Total IO Requests Per Sec',value,0)),0),0))/1024 ,2)||','||
          round(sum(decode(metric_name,'Physical Read Bytes Per Sec',value,0))/1024,2)  ||','||
          round(sum(decode(metric_name,'Physical Read IO Requests Per Sec',value,0)),2)  ||','||           
          round((nvl(sum(decode(metric_name,'Physical Read Bytes Per Sec',value))/
            nullif(sum(decode(metric_name,'Physical Read IO Requests Per Sec',value,0)),0),0))/1024 ,2)
        from v\$sysmetric 
        where group_id = 2    -- 60 deltas, not the 15 second
        ;
     spool off
EOF
}
#           nvl(sum(decode(metric_name,'Physical Reads Per Sec',value))/

function avgreadms  {
     cat << EOF
     spool  ${TMP}/${TARGET}_avgreadms.tmp
            select 
                   wait_count    ||','||
                   10*time_waited  ||','||
                   round(10*time_waited/nullif(wait_count,0),2) avg_read_ms
            from   v\$waitclassmetric  m
                   where wait_class_id= 1740759767 --  User I/O
            ;
     spool off
EOF
}


function tight_loop {
   #
   # collect stats once a minute
   # every second see if the minute had changed
   # every second check EXIT file exists
   # if EXIT file has been deleted, then exit
   # 
   # change the directory day of the week 1-7
   # CURR_DATE=`date "+%u_%H"`  
   # day of the week 1-7
     check_exit
     SLEPTED=0
     SAMPLE_RATE=1
     debug var SLEPTED SAMPLE_RATE
     start_time=0  
     CURR_DATE=`date "+%u"`  
     echo $CURR_DATE > $MON_HOME/currrent_data.out
     LAST_DATE=-1
     while [  $SLEPTED -lt $RUN_TIME -o $RUN_TIME=-1 ]  && [ -f $EXIT ]; do
      # date = 1-7, day of the week

        CURR_DATE=`date "+%u"`  
        if [ $LAST_DATE -ne $CURR_DATE ]; then
          echo $CURR_DATE > $MON_HOME/currrent_data.out
          mkdir ${MON_HOME}/${CURR_DATE} > /dev/null 2>&1
          rm ${MON_HOME}/${CURR_DATE}/*.dat  > /dev/null 2>&1
          LAST_DATE=$CURR_DATE
        fi
        curr_time=`date "+%H%M%S" | sed -e 's/^0//' `  
       if [ $curr_time -gt  $start_time -o $curr_time -eq 0 ]; then
          if [  $curr_time -eq 0 ]; then
              start_time=1
          else 
              start_time=$curr_time
          fi
          debug "start_time $start_time curr_time $curr_time "
          for i in $FAST_SAMPLE; do
             ${i} >> $PIPE
          done
#          testconnect
           sleep .5 
          for i in  $FAST_SAMPLE; do
            # prepend each line with the current time hour concat minute ie 0-2359
            # then start over, but output directory will change to next day
            cat ${TMP}/${TARGET}_${i}.tmp  | sed -e "s/^/$curr_time,/" >> ${MON_HOME}/${CURR_DATE}/${TARGET}:${i}$SUF
          done
#          (sample_id_tmp=`tail -1 ${TMP}/${TARGET}_ash.tmp | awk -F, '{print $2}'`) > /dev/null 2>&1
#          if test x"$sample_id_tmp" = x ; then
#              sample_id_tmp=0
#          fi
#          #echo "sample_id_tmp:$sample_id_tmp:"
#          #echo "sample_id    :$sample_id:"
#          if [ $sample_id_tmp -gt $sample_id ] ; then
#            sample_id=$sample_id_tmp
#          fi
#          check_exit
       fi
        sleep .1
        debug "sleeping $SAMPLE_RATE"
     done
}


function setup_sql {
  cat << EOF
  set echo on
  set pause off
  set linesize 2500
  set verify off
  set feedback off
  set heading off
  set pagesize 0
  set trims on
  set trim on
  column start_day    new_value start_day 
  select  to_char(sysdate,'J')     start_day  from dual;
  column pt           new_value pt
  column seq          new_value seq
  column curr_time    new_value curr_time
  column elapsed      new_value elapsed     
  column timer        new_value timer       
  set echo off
EOF
}
#  alter session set sql_trace=false;
#  REM drop sequence orastat;
#  REM create sequence orastat;


#   /******************************/
#   *                             *
#   *   END FUNCTION DEFINITIONS  *
#   *                             *
#   /******************************/



#   /******************************/
#   *                             *
#   *      BEGIN PROGRAM          *
#   *                             *
#   /******************************/


  CURRENT=0
  TO_SLEEP=$SLOW_RATE

  CONNECTED=0
  setup_sql >> $PIPE
  testconnect
  echo "Connected, starting collect at `date`"
  CONNECTED=1
  setup_sql >> $PIPE

   echo "starting stats collecting "
 # BEGIN COLLECT LOOP
       sample_id=0
       tight_loop
 # END COLLECT LOOP

 # CLEANUP
   echo "run time expired, exiting at `date`"
   cat $CLEANUP
   $CLEANUP 


# aas
#   Total      CPU_OS    CPU_ORA CPU_ORA_WAIT     COMMIT     READIO       WAIT
#     --------- ---------- ------------ ---------- ---------- ----------
#          .387     13.753         .747          0          0       .023
# 
# throughput - v$sysmetric 
# 
#      READ_TBYTES_PER_SEC WRITE_TBYTES_PER_SEC READ_BYTES_PER_SEC WRITE_BYTES_PER_SEC
#      ------------------- -------------------- ------------------ -------------------
#                   751820                34866                  0                   0
# 
# avgwritems - v$eventmetric (with v$event_name), 'log file parallel write'
# 
#           WRITES WRITE_TIME_MS AVG_WRITE_MS
#        ---------- ------------- ------------
#                4          .028         .007
# 
# avgwritesz - v$sysmetric ,  Redo Writes Per Sec, Redo Generated Per Sec
# 
#        BYTES_PER_SEC WRITES_PER_SEC AVG_LOG_WRITE_KB
#        ------------- -------------- ----------------
#                  243     .116550117                2
# 
# avgreadsz -  v$sysmetic , Physical Read Bytes Per Sec, Physical Read IO Requests Per Sec
#        BYTES_READ_PER_SEC      READS AVG_KB_PER_READ
#        ------------------ ---------- ------------------
#                         0          0                  0
# 
# avgreadms  - v$waitclassmetric , User I/O
#        READ_COUNT    READ_MS AVG_READ_MS
#        ---------- ---------- -----------
#                 0          0
