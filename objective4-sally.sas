
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

title 'Hours Worked by Each Consultant on Each Day of the Week';
