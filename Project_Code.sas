%let path = preplib.smartwatch_dataset; 
%let hr = 'Heart Rate (BPM)'n;
%let sd = 'Sleep Duration (hours)'n;
%let bo = 'Blood Oxygen Level (%)'n;
%let sl = 'Stress Level'n;
%let sc = 'Step Count'n;
%let al = 'Activity Level'n;
/*print 30 observation*/
proc print data=&path (obs=30);
run;

proc freq data=&path;
table 'User ID'n;
run;


/*print columns data type*/
proc contents data=&path;
run;


/*chick for duplicates*/
proc sort data =&path dupout=preplib.dups;
	 by _all_;
run;


/*summary statistics*/
proc means data=&path;
run;

/*number of missing values*/
proc means data=&path nmiss;
run;


proc univariate data=&path normal;
	 var 'Heart Rate (BPM)'n 'Sleep Duration (hours)'n 'Blood Oxygen Level (%)'n;
	 histogram 'Heart Rate (BPM)'n 'Sleep Duration (hours)'n 'Blood Oxygen Level (%)'n / normal;
run;


/*number of times each value appears*/
proc freq data=&path;
     tables 'Activity Level'n 'Stress Level'n;
run;


/*correcting typos */
data &path;
	 set &path;
	 if 'Activity Level'n = 'Actve'
	 then 'Activity Level'n = 'Active';
	 
	 else if 'Activity Level'n = 'Highly Active'
	 then 'Activity Level'n = 'Highly_Active';
	 
	 else if 'Activity Level'n = 'Seddentary'
	 then 'Activity Level'n = 'Sedentary';
run;


/*replace Very High with 10*/
data &path;
	 set &path;
	 
	 if 'Stress Level'n = 'Very High'
	 then 'Stress Level'n = 10;
	 
	 if 'Sleep Duration (hours)'n = 'ERROR'
     then 'Sleep Duration (hours)'n = '';
run;


/*conver Stress Level column type from char into num type*/
data &path;
	 set &path;
	Stress_level_Num = input('Stress Level'n, best12.);
	drop 'Stress Level'n;
	rename Stress_Level_Num = 'Stress Level'n;
	
	Sleep_Duration_hours_NUM = input('Sleep Duration (hours)'n, best12.);
    drop 'Sleep Duration (hours)'n;
	rename Sleep_Duration_hours_NUM = 'Sleep Duration (hours)'n;
run;	

/*detect Sleep Duration (hours) with <= 0 or >= 24*/
proc print data=&path;
	 where ('Sleep Duration (hours)'n is not missing and 'Sleep Duration (hours)'n <= 0)
	 or ('Sleep Duration (hours)'n is not missing and 'Sleep Duration (hours)'n >= 24);
run;


/*delete Sleep Duration (hours) with <= 0 or >= 24*/
data &path;
    set &path;
    
    if not missing('Sleep Duration (hours)'n) and
       ('Sleep Duration (hours)'n <= 0 or 'Sleep Duration (hours)'n >= 24)
    then delete;
run;


/*convert Step Count column values into int format*/
data &path;
	 set &path;
	 Step_Count_int = int('Step Count'n);
	 drop 'Step Count'n;
	rename Step_Count_int = 'Step Count'n;
run;


data &path;
	 set &path;
	 
	 if missing('User ID'n)
	 then delete;
run;


%macro IQR(var, out);

proc univariate data=&path noprint;
    var &var;
    output out=preplib.&out
        pctlpts=25 75
        pctlpre=Q_;
run;

data preplib.&out._final;
    set preplib.&out;
    IQR = Q_75 - Q_25;
    LB = Q_25 - 1.5*IQR;
    UB = Q_75 + 1.5*IQR;
run;

%mend;

%IQR(&hr, HR_iqr);
%IQR(&bo, BO_iqr);
%IQR(&sd, SD_iqr);


proc sql;
	select p.* 
	from &path as p, preplib.HR_IQR_FINAL as h
	where p.'Heart Rate (BPM)'n is not missing 
	and (p.'Heart Rate (BPM)'n < h.LB
	or p.'Heart Rate (BPM)'n > h.UB)
	order by p.'Heart Rate (BPM)'n desc;
quit;



proc sql;
	select p.* 
	from &path as p, preplib.BO_IQR_FINAL as b
	where p.'Blood Oxygen Level (%)'n is not missing 
	and (p.'Blood Oxygen Level (%)'n < b.LB
	or p.'Blood Oxygen Level (%)'n > b.UB)
	order by p.'Blood Oxygen Level (%)'n desc;
quit;


proc sql;
	select p.* 
	from &path as p, preplib.SD_IQR_FINAL as s
	where p.'Sleep Duration (hours)'n is not missing 
	and (p.'Sleep Duration (hours)'n < s.LB
	or p.'Sleep Duration (hours)'n > s.UB)
	order by p.'Sleep Duration (hours)'n desc;
quit;

/*create temporary data*/
data preplib.temp;
    if _N_ = 1 then set preplib.sd_iqr_final;
    set &path;
run;

/*delete sleep duration if the value is less than lower bound*/
data preplib.no_outliers;
    set preplib.temp;

    if not missing('Sleep Duration (hours)'n)
       and 'Sleep Duration (hours)'n < LB
    then delete;
run;

/*delete Heart Rate if the value is less than 40 or greater than 210*/
data preplib.no_outliers;
	 set preplib.no_outliers;
	 if not missing('Heart Rate (BPM)'n) 
	 and ('Heart Rate (BPM)'n > 210 or 'Heart Rate (BPM)'n < 40)
	 then delete;
 
run;


proc contents data=preplib.imputed_missing_values_data;
run;

proc contents data=preplib.no_outliers;
run;

data preplib.no_outliers;
	 set preplib.no_outliers(drop = IQR LB Q_25 Q_75 UB);
run;
	 

proc univariate data=&path normal;
	 var &sd;
	 histogram &sd / normal;
run;

proc univariate data=&path normal;
	 var &hr;
	 histogram &hr / normal;
run;

proc univariate data=&path normal;
	 var &bo;
	 histogram &bo / normal;
run;

proc univariate data=&path normal;
	 var &sc;
	 histogram &sc / normal;
run;


proc means data=&path nmiss;
run;



proc mi data=preplib.no_outliers
		 seed=12345
         nimpute=1
         out=preplib.imputed_missing_values_data;

		 var 'Sleep Duration (hours)'n 
		 	 'Heart Rate (BPM)'n 
		 	 'Blood Oxygen Level (%)'n
		 	 'Step Count'n;
		 
		 fcs reg('Sleep Duration (hours)'n);
		 fcs regpmm('Heart Rate (BPM)'n);
		 fcs regpmm('Blood Oxygen Level (%)'n);
		 fcs regpmm('Step Count'n);
run;



data preplib.imputed_missing_values_datanonan;
	set preplib.imputed_missing_values_data;
	
	if &al = 'nan'
	then call missing(&al);
run;



proc univariate data=preplib.imputed_missing_values_data normal;
	 var &sd;
	 histogram &sd / normal;
run;

proc univariate data=preplib.imputed_missing_values_data normal;
	 var &hr;
	 histogram &hr / normal;
run;

proc univariate data=preplib.imputed_missing_values_data normal;
	 var &bo;
	 histogram &bo / normal;
run;

proc univariate data=preplib.imputed_missing_values_data normal;
	 var &sc;
	 histogram &sc / normal;
run;


proc sgplot data=preplib.imputed_missing_values_data;
	 vbox &sl / category= &al;
run;


proc means data=preplib.imputed_missing_values_data mode median;
	 var &sl;
run;


proc univariate data=preplib.no_outliers normal;
	 var &sd;
	 histogram &sd / normal;
run;

proc univariate data=preplib.no_outliers normal;
	 var &hr;
	 histogram &hr / normal;
run;

proc univariate data=preplib.no_outliers normal;
	 var &bo;
	 histogram &bo / normal;
run;

proc univariate data=preplib.no_outliers normal;
	 var &sc;
	 histogram &sc / normal;
run;


proc univariate data=preplib.no_outliers normal;
	 var &sl;
	 histogram &sl / normal;
run;


proc univariate data=preplib.imputed_missing_values_data normal;
	 var &sd;
	 histogram &sd / normal;
run;

proc univariate data=preplib.imputed_missing_values_data normal;
	 var &hr;
	 histogram &hr / normal;
run;

proc univariate data=preplib.imputed_missing_values_data normal;
	 var &bo;
	 histogram &bo / normal;
run;

proc univariate data=preplib.imputed_missing_values_data normal;
	 var &sc;
	 histogram &sc / normal;
run;


	 
/*calculate medians of each stress level by activity level class*/
proc means data=preplib.imputed_missing_values_data nway median noprint;
	 class &al;	
	 var &sl;
	 output out=preplib.medians
	 median = Median_Stress;
run;

data preplib.medians;
	 set preplib.medians; 
	 drop _TYPE_ _FREQ_;
run;

/*merge our data set with medians table*/
proc sql;
	create table preplib.imputed_sl_filled
	as select a.*,
	b.Median_Stress
	from preplib.imputed_missing_values_data as a
	left join preplib.medians as b 
	on a.'Activity Level'n = b.'Activity Level'n;
quit;

/*fill missing values*/
data preplib.imputed_sl_filled;
	 set preplib.imputed_sl_filled;
	 if missing('Stress Level'n)
	 then 'Stress Level'n = Median_Stress;
run;
/*drop Medians_Stress column*/
data preplib.imputed_sl_filled;
	 set preplib.imputed_sl_filled;
	 drop Median_Stress;
run;

	
proc univariate data=preplib.imputed_sl_filled normal;
	 var &sl;
	 histogram &sl / normal;
run;	

proc means data=preplib.imputed_sl_filled nmiss;
run;

data preplib.imputed_missing_values_datanona;
	set preplib.imputed_sl_filled;
	
	if &al = 'nan'
	then call missing(&al);
run;


proc freq data=preplib.imputed_missing_values_datanona;
	 table &al;
run;


proc surveyselect data=preplib.imputed_missing_values_datanona
	 out=preplib.spilited_data
	 seed=12345
	 samprate=0.7
	 outall;
run;

data preplib.train preplib.test;
	 set preplib.spilited_data;
	 
	 if Selected = 1
	 then output preplib.train;
	 
	 else 
	 output preplib.test;
run;


proc freq data=preplib.spilited_data;
	tables Selected;
run;


proc logistic data=preplib.train
	 outmodel=preplib.Activity_Level_model;
	 class 'Activity Level'n (ref='Sedentary') / param=ref;
	 
	 model 'Activity Level'n = 
	 		'Blood Oxygen Level (%)'n 
	 		'Heart Rate (BPM)'n 
	 		'Sleep Duration (hours)'n 
	 		'Step Count'n 
	 		'Stress Level'n
	 / link=glogit;
	 score data=preplib.test
	 	out=preplib.model_score;
run;



proc freq data=preplib.model_score;
	tables 'Activity Level'n * 'I_Activity Level'n;
run;


data preplib.model_score;
	set preplib.model_score;
	
	correct = ('Activity Level'n = 'I_Activity Level'n);
run;

proc means data=preplib.model_score mean;
	 var correct;
run;


proc freq data=preplib.smartwatch_dataset_cleaned;
	tables 'Activity Level'n;
run;
proc means data=preplib.smartwatch_dataset_cleaned nmiss;
run;

data preplib.smartwatch_dataset_cleaned;
	set preplib.imputed_missing_values_datanona;
	
	if missing('Activity Level'n)
	then 'Activity Level'n = 'Sedentary';
run;

data preplib.smartwatch_dataset_cleaned_final;
    set preplib.smartwatch_dataset_cleaned;

    'Sleep Duration (hours)'n = round('Sleep Duration (hours)'n, 1);
    'Heart Rate (BPM)'n = round('Heart Rate (BPM)'n, 0.01);
    'Blood Oxygen Level (%)'n = round('Blood Oxygen Level (%)'n, 0.01);
    'Step Count'n = round('Step Count'n, 0.01);
run;


proc export data=preplib.smartwatch_dataset_cleaned_final
	 outfile='/home/u64458616/Date_Prep_Project/smartwatc_dataset_cleaned.csv'
	 dbms=csv
	 replace;
run;

