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

/*using indicator variable to include observations from Master3 only*/

proc sort data = Master2 out = Master2sort;
by projnum date;
run;

proc sort data = corrections out = correctionssort;
by projnum date;
run;

data Master3;
retain consultant projnum date hours newhours stage newstage complete;
merge Master2sort(in = in1) correctionssort (rename=(hours=newhours stage=newstage));
if in1 then output;
run;

/* Merge Master3 with projclass to include add project classification */

/* First sort data in Master3 and projclass by projnum */

proc sort data = Master3 out = Master3sort;
by projnum;
run;

proc sort data = projclass out = projclasssort;
by projnum;
run;


/* Merge sorted data Master3sort with projclass */
data Master4;
merge Master3sort(in = in1) projclasssort;
by projnum;
if in1 then output;
run;


/* Merge Master4 with Assignments to fill blanks in Consultant column after Sep 1 */

/* Sort assignments data by projnum */

proc sort data = assignments out = assignmentssort;
by projnum;
run;

/* Merge Master 4 with assignmentssorted */

data Master5;
merge Master4(in = in1) assignmentssort(rename = (consultant = consultant_new));
by projnum;
if in1 then output;
run;

data Master6;
set Master5;
if missing(consultant) then consultant_final = consultant_new;
else consultant_final = consultant;
run;

/* Fill up missing values wihin consultant_final */

data Master7;
set Master6;
by projnum;
retain consult_msg;
if first.projnum then consult_msg = consultant_final;
if missing(consultant_final) then consultant_final = consult_msg;
drop consultant consultant_new consult_msg;
run;

/*create Master5:
replace hours with newhours if newhours is not missing
replace stage with newstage if newstage is not missing*/

data Master8;
set Master7;
retain consultant_final projnum date hours2 stage2 complete type; /*this order doesn't seem to work!!*/
if missing(newhours) then hours2=hours;
else hours2=newhours;
if missing(newstage) then stage2=stage;
else stage2=newstage;
drop hours newhours stage newstage;
run;
