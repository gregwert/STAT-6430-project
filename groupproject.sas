/*read in Master.csv*/
filename mastrcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/Master.csv" 
 out=mastrcsv 
;
run;

data master;
infile mastrcsv dsd firstobs=2;
retain consultant projnum date hours stage complete;
length consultant $5 date $10;
input consultant $ projnum date $ hours stage complete;
run;

/*read in NewForms.csv*/
filename nwfrmcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/NewForms.csv" 
 out=nwfrmcsv 
;
run;

data newForms;
infile nwfrmcsv dsd firstobs=2;
retain projnum date hours stage complete;
length date $10;
input projnum date $ hours stage complete;
run;


/*read in ProjClass.csv*/
filename prjclcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/ProjClass.csv" 
 out=prjclcsv 
;
run;

data projClass;
infile prjclcsv dsd firstobs=2;
retain type projNum;
length type $ 18;
input type $ projNum;
run;

/*read in Assignments.csv*/
filename asmntcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/Assignments.csv" 
 out=asmntcsv 
;
run;

data assignments;
infile asmntcsv dsd firstobs=2;
length consultant $5;
input consultant $ projNum;
run;

/*read in Corrections.csv*/
filename crrctcsv "%sysfunc(getoption(work))/streaming.sas7bdat";
 
proc http method="get" 
 url="https://raw.githubusercontent.com/gregwert/STAT-6430-project/master/Corrections.csv" 
 out=crrctcsv 
;
run;
data corrections;
infile crrctcsv dsd firstobs=2;
retain projNum date hours stage;
length date $ 10;
input projNum date $ hours stage;
run;

/*stack Master and NewForms, output to Master2*/

data Master2;
set Master NewForms;
run;

/*merge Master2 with Corrections.
corrected hours are under newhours, corrected stage is under newstage.*/

data Master3;
retain consultant projnum date hours newhours stage newstage complete;
merge Master2 Corrections (rename=(hours=newhours stage=newstage));
run;

/*create Master4:
replace hours with newhours if newhours is not missing
replace stage with newstage if newstage is not missing*/

data Master4;
set Master3;
retain consultant projnum date hours2 stage2 complete; /*this order doesn't seem to work!!*/
if missing(newhours) then hours2=hours;
else hours2=newhours;
if missing(newstage) then stage2=stage;
else stage2=newstage;
drop hours newhours stage newstage;
run;
