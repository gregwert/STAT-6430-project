
/*Create a new dataset that includes weekday extracted from the date of every observation.
NOTE: In SAS 1 = Sunday, 2 = Monday, etc. */
data masterwkday;
set '/home/sg2zv0/finalproj/newmaster.sas7bdat';
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
