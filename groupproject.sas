
filename mastrcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/Master.csv" 
 out=mastrcsv 
;
run;

data master;
infile mastrcsv dsd;
retain consultant projnum date hours stage complete;
length projnum $3 date $10 stage $1 complete $1;
input consultant $ projnum date $ hours stage complete;
run;
*first row is displaying as column headers from file;

filename nwfrmcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/NewForms.csv" 
 out=nwfrmcsv 
;
run;

data newForms;
infile nwfrmcsv dsd;
retain consultant projnum date hours stage complete;
length projnum $3 date $10 stage $1 complete $1;
input consultant $ projnum date $ hours stage complete;
run;
*similar top row column issue that needs to be addressed;

filename prjclcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/ProjClass.csv" 
 out=prjclcsv 
;
run;

data projClass;
infile prjclcsv dsd;
retain type projNum;
length projNum $3;
input type $ projNum;
run;

filename asmntcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/Assignments.csv" 
 out=asmntcsv 
;
run;

data assignments;
infile asmntcsv dsd;
retain consultant projNum;
length projNum $3;
input consultant $ projNum;
run;

filename crrctcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/Corrections.csv" 
 out=crrctcsv 
;
run;
data corrections;
infile crrctcsv dsd;
retain projNum date hours stage;
length projNum $3 date $10 hours stage $1;
input projNum date $ hours stage;
run;


