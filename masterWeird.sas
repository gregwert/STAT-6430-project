/*  SAS 6410 group project
OBJECTIVE 1 -
1. Read the input datafiles - 
    a. Master.csv
    b. NewForms.csv
    c. Projclass.csv
    d. Assignments.csv
    e. Corrections.csv
2. Stack, merge and clean - 
    a. Stack NewForms to Master to create Master2
    b. Merge corrections with Master2 on variables projnum and date to create Master3- 
    c. Clean corrections file to remove duplicates at projnum-date level
    d. Merge Projclass with Master3 to add project category against each project
    e. Merge Assignments with Master4 to get consultant names for projects entered after Sep 1
    f. Fill missing values remaining in the Master6 file 
    g. Update corrected hours and corrected stage, create new field Correction_hours and Correction_stage wherever update is made
3. Export to .csv and permanent SAS dataset (.sas7bdat)
*/
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
length consultant $5;
informat date mmddyy10.;
format date mmddyy10.;
input consultant $ projnum date hours stage complete;
/*input consultant $ projnum date hours stage complete;*/
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
informat date mmddyy10.;
format date mmddyy10.;
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
length type $18;
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
informat date mmddyy10.;
format date mmddyy10.;
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
data correctionssort2;
update correctionssort(obs = 0) correctionssort;
by projnum date;
run;
data Master3;
retain consultant projnum date hours newhours stage newstage complete;
merge Master2sort(in = in1) correctionssort2 (rename=(hours=newhours stage=newstage));
by projnum date;
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
/* Update consultants variable with name from assignments data*/
data Master6;
set Master5;
if missing(consultant) then consultant_final = consultant_new;
else consultant_final = consultant;
run;
/* Fill up missing values within consultant_final */
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
replace stage with newstage if newstage is not missing
Corre
*/
data Master8;
set Master7;
retain projnum date consultant_final complete type hours2 Correction_hours stage2 Correction_stage; /*this order doesn't seem to work!!*/
if missing(newhours) then hours2=hours;
else do;
hours2=newhours;
Correction_hours = "Yes";
end;
if missing(newstage) then stage2=stage;
else do;
stage2=newstage;
Correction_stage = "Yes";
end;
drop hours newhours stage newstage;
run;
/* Output Master8 to NewMaster.csv */
filename outcsv "C:\Users\researcher.ALD401-510.000\Desktop\NewMaster.csv";
data _Null_;
set Master8;
file outcsv dsd;
put (_ALL_)(~);
run;
/* Output to permanent SAS dataset*/
LIBNAME outsasdf "C:\Users\researcher.ALD401-510.000\Desktop\STAT-6430-project-master";
data outsasdf.NewMaster;
set Master8;
run;
/*OBJECTIVE 3*/
/*create 3 separate datasets for Brown, Jones and Smith*/
data Brown Jones Smith;
set Master8;
if consultant_final="Brown" then output Brown;
if consultant_final="Jones" then output Jones;
if consultant_final="Smith" then output Smith;
drop consultant_final;
run;
proc sort data=Brown;
by projnum date;
run;
data Brown2;
set Brown;
by projnum date;
retain start_date 0 end_date 0;
if first.projnum then start_date = 1;
start_date = 0;
if last.projnum then end_date = 1;
end_date = 0;
run;
proc sort data=Brown;
by projnum;
run;
data Brown3;
set Brown;
by projnum;
retain projhours;
if first.projnum then projhours=0;
projhours = projhours + hours2;
run;
/*test*/
data Brown4;
set Brown;
by projnum;
retain projhours;
if first.projnum then projhours=0;
projhours = projhours + hours2;
if last.projnum then output;
run;
