dm "log; clear;";
dm "out; clear;";
proc datasets nolist lib=work memtype=data kill;quit;

OPTIONS notes nomprint;

/* 遍历文件夹下所有给定格式的文件 */
%macro drive(dir,ext); 
	%local cnt filrf rc did memcnt name;

	%let cnt=0;

	%let rc=%sysfunc(filename(filrf,&dir));
	%let did=%sysfunc(dopen(&filrf));

	%if &did ne 0 %then %do;
		%let memcnt=%sysfunc(dnum(&did));
		%do i=1 %to &memcnt;
			%let name=%qscan(%qsysfunc(dread(&did,&i)),-1,.);
			%if %qupcase(%qsysfunc(dread(&did,&i))) ne %qupcase(&name) %then %do;
				%if %superq(ext) = %superq(name) %then %do;
					%let cnt=%eval(&cnt+1);
					%let sasnm=%qsysfunc(dread(&did,&i));
					data rst;
						infile "&dir.\&sasnm." TRUNCOVER;
						input txt $10000.;
						txt=_infile_;
/*						修改3*/
						re4=prxparse('/(ADS\.)/i');
						if prxmatch(re4,txt) then do;
							txt=prxchange('s/ADS\./ADS_RE./',1,txt);
						end;
						re5=prxparse('/(EXT\.)/i');
						if prxmatch(re5,txt) then do;
							txt=prxchange('s/EXT\./EXT_RE./',1,txt);
						end;
						re6=prxparse('/(RAW\.)/i');
						if prxmatch(re6,txt) then do;
							txt=prxchange('s/RAW\./RAW_RE./',1,txt);
						end;
					run;
					data _null_;
						set rst;
						file "&dir.\&sasnm.";
						put txt;
					run;
				%end;
			%end;
		%end;
	%end;
	%else %put &dir cannot be opened.;

	%let rc=%sysfunc(dclose(&did));
%mend drive;

%drive(D:\Documents\SASsupport\China Submission\Programs\TLGprg,sas);

proc compare base=ADS_RE.ADSL_2AUG2022 compare=ADS.ADSL_2AUG2022 listall error;
run;
