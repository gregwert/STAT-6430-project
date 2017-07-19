*OBJECTIVE 2

Create a report of ongoing projects as of last entry

1. Create a list of every projects most recent entry
2. Isolate the ongoing projects and create a list of them
3. remove all variables except projNum
4. Generate a report of the ongoing projects
;

*import master.csv from github repository;
filename nmstrcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/NewMaster.csv" 
 out=nmstrcsv 
;

*create data set for NewMaster;
data newMaster;
infile nmstrcsv dsd;
retain projnum date complete type consultant hours stage correction_hour correction_stage;
length date $10  type $18 consultant $5 correction_hour $3 correction_stage $3;
input projnum date $ complete type $ consultant $ hours stage correction_hour $ correction_stage $;
run;

*Filter out results except for last projnum entry. Due to sorting of NewMaster.csv by projnum
then date in Objective 1, data already sorted by date allowing last entry to be most most 
recent date of filing;
data temp;
set NewMaster;
by projnum; 
if last.projnum;
run;

*filter to only display if complete is zero (Incomplete). Keep Projnum as only variable;
data ogProjects;
set temp;
if complete = 0;
keep projnum;
run;

*print out contents of dataset;
proc print data=ogProjects;
run;
