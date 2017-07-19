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
set '/home/sg2zv0/finalproj/newmaster.sas7bdat';
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
