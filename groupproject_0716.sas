*  SAS 6410 group project

Rohan Bapat
Sally Gao
Gregory Wert

;
/*
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
retain consultant_final projnum date hours2 stage2 complete type; /*this order doesn't seem to work!!*/
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
label projnum="Project Number" date="Date" complete="Complete" type="Type" consultant_final="Consultant" hours2="Hours"
		stage2="Stage" Correction_hours="Hours Corrected" Correction_stage="Stage Corrected";
run;

/* Output Master8 to NewMaster.csv */

filename outcsv "C:\Users\Rohan Bapat\Documents\Classes\STAT 6430\SAS Project\STAT-6430-project-master\NewMaster.csv";

data _Null_;
set Master8;
file outcsv dsd;
put (_ALL_)(~);
run;

/* Output to permanent SAS dataset*/

LIBNAME outsasdf "C:\Users\Rohan Bapat\Documents\Classes\STAT 6430\SAS Project\STAT-6430-project-master";

data outsasdf.NewMaster;
set Master8;
run;

proc print data=master8 label;
title 'Objective 1';
title2 'New Master Data'
run;

*OBJECTIVE 2

Create a report of ongoing projects as of last entry

1. Create a list of every projects most recent entry
2. Isolate the ongoing projects and create a list of them
3. remove all variables except projNum
4. Generate a report of the ongoing projects
;


*Filter out results except for last projnum entry. Due to sorting of NewMaster.csv by projnum
then date in Objective 1, data already sorted by date allowing last entry to be most most 
recent date of filing;
data temp;
set master8;
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
proc print data=ogProjects noobs;
title 'Objective 2';
title2 'Ongoing Projects';
run;

/*OBJECTIVE 3 --
1. Separate observations by consultant and create individual datasets Brown, Jones and Smith
2. Find start date and end date of each project
	a. Sort datasets by project number and date
	b. Use first.projnum and last.projnum to find the start and end date of each project, where applicable
	c. Output information on start dates and end dates to Brown2, Jones2, Smith2
	d. Update Brown2, Jones2 and Smith2 so start_date and end_date values appear in one observation per project.
	e. Output updated observations to Brownstartend, Jonesstartend, Smithstartend.
3. Calculate project hours
	a. Create a variable named projhours, summing the total number of works per project.
	b. Output only the observations with a final project hour total to datasets Brown3, Jones3, Smith 3.
4. Create final datasets with complete information on project hours and start and end dates
	a. Sort Brown3, Jones3, Smith3, Brownstartend, Jonesstartend, Smithstartend by project number.
	b. Merge each pair of datasets to create Brown_final, Jones_final, Smith_final.
*/

/*output separate data sets for Brown, Jones and Smith*/
data Brown Jones Smith;
set master8;
if consultant_final="Brown" then output Brown;
if consultant_final="Jones" then output Jones;
if consultant_final="Smith" then output Smith;
drop consultant_final;
run;

/*sort by project number, then date*/
proc sort data=Brown;
by projnum date;
run;

proc sort data=Jones;
by projnum date;
run;

proc sort data=Smith;
by projnum date;
run;

/*Find start dates and end dates for Brown. Projects still in stage 1,2 or 3 will not be given an end date.*/
data Brown2;
set Brown;
by projnum date;
if first.projnum then start_date = date;
	else start_date = .;
if last.projnum and complete=1 then end_date = date;
	else end_date = .;
format start_date mmddyy10. end_date mmddyy10.;
if start_date ^= . or end_date ^=. then output;
drop date type hours2 stage2 correction_hours correction_stage;
run;

/*Create Brownstartend, putting start date and end date in a single observation*/
data Brownstartend;
update Brown2(obs = 0) Brown2;
by projnum;
run;

/*Sum project hours and output only the last observation for each project*/
data Brown3;
set Brown;
by projnum;
retain projhours;
if first.projnum then projhours=0;
if hours2 ^= . then projhours = projhours + hours2;
if last.projnum then output;
drop hours2 stage2 Correction_hours Correction_stage date;
run;

/*merge Brown3 and Brownstartend to create Brown_final*/
proc sort data=Brown3;
by projnum;
run;

proc sort data=Brownstartend;
by projnum;
run;

data Brown_final;
retain projnum type projhours complete start_date end_date;
merge Brown3 Brownstartend;
by projnum;
label projnum = "Project Number" type="Type" projhours="Total Hours" complete="Complete" start_date="Start Date" end_date="End Date";
run;

/*Repeat the same steps for Jones.*/
data Jones2;
set Jones;
by projnum date;
if first.projnum then start_date = date;
	else start_date = .;
if last.projnum and complete=1 then end_date = date;
	else end_date = .;
format start_date mmddyy10. end_date mmddyy10.;
if start_date ^= . or end_date ^=. then output;
drop date type hours2 stage2 correction_hours correction_stage;
run;

/*Create Jonesstartend, putting start date and end date in a single observation*/
data Jonesstartend;
update Jones2(obs = 0) Jones2;
by projnum;
run;

/*Sum project hours and output only the last observation for each project*/
data Jones3;
set Jones;
by projnum;
retain projhours;
if first.projnum then projhours=0;
if hours2 ^= . then projhours = projhours + hours2;
if last.projnum then output;
drop hours2 stage2 Correction_hours Correction_stage date;
run;

/*merge Jones3 and Jonesstartend to create Jones_final*/
proc sort data=Jones3;
by projnum;
run;

proc sort data=Jonesstartend;
by projnum;
run;

data Jones_final;
retain projnum type projhours complete start_date end_date;
merge Jones3 Jonesstartend;
by projnum;
label projnum = "Project Number" type="Type" projhours="Total Hours" complete="Complete" start_date="Start Date" end_date="End Date";
run;

/*Repeat the same steps for Smith.*/
data Smith2;
set Smith;
by projnum date;
if first.projnum then start_date = date;
	else start_date = .;
if last.projnum and complete=1 then end_date = date;
	else end_date = .;
format start_date mmddyy10. end_date mmddyy10.;
if start_date ^= . or end_date ^=. then output;
drop date type hours2 stage2 correction_hours correction_stage;
run;

/*Create Smithstartend, putting start date and end date in a single observation*/
data Smithstartend;
update Smith2(obs = 0) Smith2;
by projnum;
run;

/*Sum project hours and output only the last observation for each project*/
data Smith3;
set Smith;
by projnum;
retain projhours;
if first.projnum then projhours=0;
if hours2 ^= . then projhours = projhours + hours2;
if last.projnum then output;
drop hours2 stage2 Correction_hours Correction_stage date;
run;

/*merge Smith3 and Smithstartend to create Smith_final*/
proc sort data=Smith3;
by projnum;
run;

proc sort data=Smithstartend;
by projnum;
run;

data Smith_final;
retain projnum type projhours complete start_date end_date;
merge Smith3 Smithstartend;
by projnum;
label projnum = "Project Number" type="Type" projhours="Total Hours" complete="Complete" start_date="Start Date" end_date="End Date";
run;

/*proc print table*/
title "Brown's Projects";

proc print data=Brown_final noobs label;
run;

title "Jones's Projects";
proc print data=Jones_final noobs label;
run;

title "Smith's Projects";
proc print data=Smith_final noobs label;
run;

title;

*Objective 4;
/*Sort Master8 by project number*/

proc sort data = Master8;
by projnum;
run;

/*Summarize projects by total hours spent*/

data projclasshours;
set Master8;
by projnum;
retain tothrs;

if first.projnum then tothrs = 0;
if hours2 ^= . then tothrs = tothrs + hours2;
if last.projnum then output;

run;


proc sql ;
	create table hoursnprojs as                             /*Get total hours, # projects by project type and consultant*/
	select consultant_final, type, sum(tothrs) as totalhours,  count(type) as projsdone 
	from projclasshours
	group by type, consultant_final;

	create table finalhoursnprojs as                       /*Get hours per project*/
	select consultant_final, type, totalhours, projsdone , totalhours/projsdone as hrsperproj
	from hoursnprojs;

run;

/*Create annotate variable for hours per project plot*/

DATA anno;
 LENGTH function $10 text $60;
 RETAIN xsys ysys '1';

 function='label'; x=50; y=80; text='Jones spent 25% more time on IT/Web Dev projects'; color='maroon';
angle=0; rotate=0; position='5'; style='centx'; size=1.2; output;
function='move'; x=63; y=72; output;
function='draw'; x=63; y=77; angle = 90; color='maroon'; arrow=2; size=1; output;
RUN;

/*Plot of number of hours*/

axis2 label=(angle=90 "Total Hours");  
proc gchart data = finalhoursnprojs;
title2 'Brown has spent most time (468 hours) working on consulting projects';
vbar consultant_final / subgroup = consultant_final group = type sumvar = totalhours sum space = 1 gspace = 6  cframe=ltgray raxis = axis2 nolegend;
run;

/*Plot of number of projects*/

axis2 label=(angle=90 "Total Projects");  
proc gchart data = finalhoursnprojs;
title2 'Analytical Consulting Lab has worked on nearly twice as many Advising projects(34) as Study Coordination projects(18)';
vbar consultant_final / subgroup = consultant_final group = type sumvar = projsdone sum space = 1 gspace = 6  cframe=ltgray raxis = axis2 nolegend ;
run;

/*Plot of hours per project*/

axis2 label=(angle=90 "Hours per project");  
proc gchart data = finalhoursnprojs;
title2 'Time taken to complete study co-ordination projects(~26 hours) is nearly 8 times that of Advising projects(~3 hours)';
vbar consultant_final / subgroup = consultant_final group = type sumvar = hrsperproj sum space = 1 gspace = 6  cframe=ltgray annotate = anno raxis = axis2 nolegend;
run;

*create a horizontal bar chart showing how much time is spent on each stage per project type;
data bars;
set master8;
if stage2^=. then output;
run;

axis1 value=none label=none;
axis2 minor=none;
axis3 label=none;

proc format;
value stages
	1 = "1 : Initial Consultation"
	2= "2 : Planning"
	3="3 : Implementation and Analysis"
	4="4 : Interpretation and Reporting"
	5="5 : Optional Followup";
run;

proc gchart data=bars;
   format stage2 stages.;
   hbar type / noframe type=pct subgroup=stage2
               g100 group=type
               nozero gaxis=axis1 
			   nostat
			   inside=percent
               raxis=axis2 maxis=axis3;
run;

/*Create a new dataset that includes weekday extracted from the date of every observation.
NOTE: In SAS 1 = Sunday, 2 = Monday, etc. */
data masterwkday;
set master8;
wkday = weekday(date);
keep consultant_final wkday hours2 complete;
run;

/*sort data and calculate the number of hours spent on each consultant on each weekday*/
proc sort data=masterwkday;
by wkday consultant_final;
run;

data wkday_hours;
set masterwkday;
by wkday consultant_final;
retain total_hours total_completed;
if first.wkday or first.consultant_final then do;
	total_hours = 0;
	total_completed=0;
	end;
if hours2 ^= . then total_hours=total_hours + hours2;
if complete ^= . then total_completed=total_completed+complete;
if last.consultant_final then output;
drop hours2 complete;
run;

/*transpose data so consultant_final is in output variables and data are split by weekday*/
proc transpose data=wkday_hours out=wkday_final(drop=_name_);
	ID consultant_final;
	var total_hours;
	by wkday;
run;

/*proc print table*/
title 'Hours Worked on Each Day of the Week';
title2 'by Consultant';

proc format;
value weekform
	2 = "Monday"
	3 = "Tuesday"
	4 = "Wednesday"
	5 = "Thursday"
	6 = "Friday";
run;

proc print data=wkday_final noobs label;
format wkday weekform.;
label wkday = "Weekday";
run;

/*Create chart of hours aggregated by weekday*/

title2 'Aggregated by Weekday';
axis1 label=("Weekday");
axis2 label=(angle=90 "Total Hours");

proc gchart data=wkday_hours;
format wkday weekform.;
vbar wkday / sumvar=total_hours raxis=axis2 maxis=axis1;
run;

/*Create chart of completed projects aggregated by weekday*/

title "Projects Completed by Weekday";
axis1 label=("Weekday");
axis2 label=(angle=90 "Projects Completed");
pattern1 color = lightblue;

proc gchart data=wkday_hours;
format wkday weekform.;
vbar wkday / sumvar=total_completed raxis=axis2 maxis=axis1;
run;

/*Create chart of hours worked by weekday, grouped by consultant*/

/* Formatting */
title 'Hours Worked on Each Day of the Week';
title2 "Hours Worked Per Consultant";
pattern1 color = navy;
pattern2 color = salmon;
pattern3 color = lightseagreen;

axis1 value=none label=none;
axis2 label=(angle=90 "Hours");
legend1 frame;

proc gchart data=wkday_hours;
format wkday weekform.;
   vbar consultant_final / subgroup=consultant_final group=wkday sumvar=total_hours sum
                  legend=legend1 space=0 gspace=4
                  maxis=axis1 raxis=axis2 gaxis=axis3;
   label consultant_final="Consultant" wkday="";
run;

/*Create scatter plot to emphasize that Monday is an anomaly*/
title1  "Scatter Plot of Hours Worked and Projects Completed on Each Day of the Week";

axis1 label=("Hours Worked") order=(40 to 140 by 20);
axis2 label=(angle=90 "Completed Projects") minor=(n=4);

/* Monday in red, all other days in Blue */
symbol1 interpol=none value=dot color=red;
symbol2 interpol=none value=dot color=navy;
symbol3 interpol=none value=dot color=navy;
symbol4 interpol=none value=dot color=navy;
symbol5 interpol=none value=dot color=navy;

/* Regression line */
symbol6 interpol=rl value=none color=black;

DATA anno;
LENGTH function $10 text $60;
RETAIN xsys ysys '1';

function='label'; x=80; y=80; text='Mondays'; color='red';
angle=0; rotate=0; position='5'; style='centx'; size=1.8; output;
run;

proc gplot data=wkday_hours;
   plot total_completed*total_hours=wkday / haxis=axis1 vaxis=axis2 nolegend annotate=anno;
   plot2 total_completed*total_hours / noaxis;
run;

quit;
