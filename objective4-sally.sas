
/*Create a new dataset that includes weekday extracted from the date of every observation.
NOTE: In SAS 1 = Sunday, 2 = Monday, etc. */
data masterwkday;
set '/home/sg2zv0/finalproj/newmaster.sas7bdat';
wkday = weekday(date);
keep consultant_final wkday hours2;
run;

/*sort data and calculate the number of hours spent on each consultant on each weekday*/
proc sort data=masterwkday;
by wkday consultant_final;
run;

data wkday_hours;
set masterwkday;
by wkday consultant_final;
retain total_hours;
if first.wkday or first.consultant_final then total_hours = 0;
if hours2 ^= . then total_hours=total_hours + hours2;
if last.consultant_final then output;
drop hours2;
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


title2 'Aggregated by Weekday';
proc gchart data=wkday_hours;
format wkday weekform.;
vbar wkday / sumvar=total_hours;
run;


/*grouped vertical bar chart*/

/* Set the graphics environment */
goptions border htitle=10pt htext=8pt;

/* Define the title */
title2 "By Consultant";

/* Define the axis characteristics */
axis1 value=none label=none;
axis2 label=(angle=90 "Hours");
axis3 label=none;

/* Define the legend options */
legend1 frame;

/* Generate the graph */
proc gchart data=wkday_hours;
format wkday weekform.;
   vbar consultant_final / subgroup=consultant_final group=wkday sumvar=total_hours
                  legend=legend1 space=0 gspace=4
                  maxis=axis1 raxis=axis2 gaxis=axis3;
run;
quit;
