
dm "log; clear;";
dm "out; clear;";
run;
proc datasets nolist lib=work memtype=data kill;quit;
 
proc sort data=proc.Havetranslated out=tran ;by Domain var;run;
/****************************************************************************************************
|拼接变量原始长度
****************************************************************************************************/
data column;
	length Domain var $200;
	set sashelp.vcolumn(where=(libname="RAW_EN") rename=(memname=domain name=var));
	keep Domain var length;
run;
proc sort data=column;by Domain var;run;

proc sort data=proc.Havetranslated  out=tran ;by Domain var;run;
data tran;
	length Domain var $200;
	merge tran(in=a ) column;
	by Domain var;
	if a;
run;

proc sort data=tran out=trandis nodupkey;by Domain var cont;run;
/****************************************************************************************************
|生产format，测试AE
****************************************************************************************************/
data _null_;
	set trandis(where=(/*Domain='SPSS_30DFU' and*/ ^missing(cn))) end=eof;
	by Domain var;
	length fmtname $100;
	fmtname=cats('$',Domain,'_',var,'X');
	file "&_wpath.\Programs\_Global\Format.sas";
	if _n_=1 then put 'proc format ;';
	if first.var then put '		value '  fmtname '(default=' length ')';
	if find(cont,"'") then 
		put '		"' cont '"="' cn '"';
	else
		put "		'" cont "'='" cn "'";
	if last.var then put '		;';
	if eof then put 'run;';
run;

data _NULL_;
	set trandis(where=(/*Domain='SPSS_30DFU' and*/ ^missing(cn))) end=eof;
	by Domain var;
	length fmtname $100;
	fmtname=cats('$',Domain,'_',var,'X');
	fmtname2=cats(fmtname,'.');
	file "&_wpath.\Programs\_Global\SetFormat.sas";
	if first.domain then do;put
'data raw.' domain ';
	set raw_en.' domain ';';
	end;
	if last.var then do;
		put 'format ' var fmtname2  ';';
	end;
	if last.domain then put 'run;';
run;
