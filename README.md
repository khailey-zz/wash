
WASH
-----------------

Web ASH

WASH - collectes ASH like data without AWR
and enables HTTP access to the data
in interactive charts. The web access requires
that Apache be up and runnning.

Installing on LINUX Redhat
-------------------


	$ cd /var/www
	$ # copy the tar.gz file from github here
	$ gzip -d khailey-wash-155931c.tar.gz # name generated for github download
	$ tar xvf khailey-wash-155931c.tar
	$ mv  khailey-wash-155931c/* .

There are 3 basic files

1. ./cash.sh  - collect ASH like data from Oracle into a flat file, it  runs in a continual loop
2. ./html/ash.html - basic web page using Highcharts
3. ./cgi-bin/json_ash.sh - cgi to read ASH like data and give it to the web page via JSON

plus highchart javascript files in 
      
	htdocs/js/


Running
------------------------

Now you are almost ready to go. You just need to start the data collection with "cash.sh" (collect ASH)

	./cash.sh
	Usage: usage <username> <password> <host> [sid] [port]

The script "cash.sh" requires "sqlplus" be in the path and that is all. It's probably easiest to

* move/copy cash.sh to an ORACLE_HOME/bin
* su oracle
* kick it off as in:

	nohup cash.sh system change_on_install 172.16.100.250 orcl &

The script "cash.sh" will create a directory in /tmp/MONITOR/day_of_the_week for each day of the week, clearing out any old files, so there are only maximum 7 days of data. (to stop the  collection run "rm /tmp/MONITOR/clean/*end" )

To view the data go to your web server address and add "ash.html?q=machine:sid"
For example my web server is on 172.16.100.250
The database I am monitoring is on host 172.16.100.250 with Oracle SID "orcl"

	http://172.16.100.250/ash.html?q=172.16.100.250:orcl

 

