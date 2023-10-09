dm "log; clear;";
dm "out; clear;";
run;
proc datasets nolist lib=work memtype=data kill;quit;
title;footnote;
*******************************************************************************************;

%let dmlib=raw;
%let salib=raw;

/*rawdata中不需要修改的数据集*/
%let droplist=/*FORMATS*/ SPSS_CONMED SPSS_AESCR SPSS_CONMEDPRO SPSS_AEPRO SPSS_AE24H SPSS_MED24H SPSS_CONMED2 SPSS_FUAE SPSS_MEDRACOD SPSS_AECECPREP;
%let verfy_path=&_wpath.\Datasets\Rawdata_ST\verify.xlsx;

data _null_;
	re=prxparse('/(([\_\w][\_\d\w]*)\s*)/');
	if prxmatch(re,"&droplist.") then do;
		_dplist=prxchange('s/(([\_\w][\_\d\w]*)\s*)/"$2"/',-1,"&droplist.");
		if prxmatch('""',_dplist) then do;
			dplist=prxchange('s/""/","/',-1,_dplist);
			call symputx('dplist',dplist);
		end;
	end;
run;

/*获取需要进行处理的数据集的列表*/
data _null_;
     set sashelp.vtable(where=(libname=upcase("&dmlib") & memname ^in (&dplist.)));
	 call symputx('_sum',cats(_n_));
	 call symputx('_data'||cats(_n_),memname);
run;

/*问题变量清单*/
data _problist _useless;
	set sashelp.vcolumn(where=(libname=upcase("&dmlib") & memname ^in (&dplist.) ) );
	length issue1 issue2 issue3 $200; 
    if lengthn(name)>8 then issue1='Var';
	if lengthn(label)>40 then issue2='Label';
    if length>200 then issue3='Length';
	re=prxparse('/(__)|(_YYYY)|(_MM)|(_DD)|(_YMD)|(_HH)|(_NN)/');
	if prxmatch(re,name) then output _useless;
		else output _problist;
run;

/*data _problist2;*/
/*	set sashelp.vcolumn(where=(libname=upcase("&dmlib") & memname ^in (&dplist.) ) );*/
/*	if varnum gt 38;*/
/*	issue='Label';*/
/*	findings='标签长度超过40';*/
/*run;*/
/*proc export data=_problist2 outfile="&verfy_path." DBMS=xlsx;*/
/*	sheet='GT38';*/
/*run;*/

data problist;
	length Key $100;
	set _problist(rename=(issue1=issue) where=(^missing(issue)))
		_problist(rename=(issue2=issue) /*where=(^missing(issue))*/)
		_problist(rename=(issue3=issue) where=(^missing(issue)));
	by memname varnum;
	if issue='Var' then findings='变量名长度超过8';
	if issue='Label' then findings='标签长度超过40';
	if issue='Length' then findings='长度超过200';
	length verify $200;
	call missing(verify);
	if issue='Var' then verify=name;
	if issue='Label' then verify=label;

	re=prxparse('/[\w\d\s\_]+R\b/i');
	if prxmatch(re,name) then do;
		key=reverse(substr(strip(reverse(name)),2));
	end;
	keep key libname memname name type length label issue findings verify;
run;
/****************************************************************************************************
|导出配对变量名
****************************************************************************************************/
data Dlabel;
	length Key $100;
	set proc.labelverify;
	re=prxparse('/[\w\d\s\_]+D\b/i');
	if prxmatch(re,name) then do;
		key=reverse(substr(strip(reverse(name)),2));
		output;
	end;
	keep memname key verify;
run;

proc sort data=problist out=problist2 ;by memname key ;run;
proc sort data=Dlabel out=Dlabel2 ;by memname key ;run;

data problist3;
	merge problist2(in=a) Dlabel2;
	by memname key ;
	if a;
run;

/*导出problist数据集*/
proc export data=problist3 outfile="&verfy_path." DBMS=xlsx;
	sheet='verify';
run;

/*修改problist数据集中不规范的命名等，导入修改后的数据集*/
proc import datafile="&verfy_path." 
		out=verify DBMS=xlsx replace;
	sheet='verify1.0';
	GETNAMES=YES;
run;
/*仅修改Raw的标签*/
data verify;
	set verify(where=(issue eq 'Label'));
run;

option mprint;
%macro extract();
%do i=1 %to &_sum;
%let &&_data&i=;
/****************************************************************************************************************/
/*变量名与标签重置部分：Part 1*/
/*获得对应数据集的需要修改的变量名列表及修改原因和替换值*/
	%let _SUM_=0;
	data _null_;
		set verify(where=(memname="&&_data&i" and issue ne 'Length'));
		call symput("varNm"||left(put(_n_,best.)),name);
		call symput("issue"||left(put(_n_,best.)),issue);
/* 		call symput("verify"||left(put(_n_,best.)),%nrstr("%nrstr(")||strip(verify)||%nrstr(")")); */
		call symput("verify"||left(put(_n_,best.)),strip(verify));
		call symput("_SUM_",strip(put(_n_,best.)));
	run;
	
/*	定义rename 和 label内容*/
	%let reNm=;
	%let reLal=;
/*	生成rename和label内容*/
	%if &_SUM_ ne 0 %then %do;
		%do j=1 %to &_SUM_;
			%if %upcase(&&issue&j)=%upcase(LABEL) %then %let reLal= &reLal %sysfunc(strip(&&varNm&j))="%superq(verify&j)";;
			%if %upcase(&&issue&j)=%upcase(VAR) %then %let reNm= &reNm %sysfunc(strip(&&varNm&j))=&&verify&j;;
		%end;
	%end;
	%put &reNm;
	%put &reLal;
/****************************************************************************************************************/
/*执行数据集变量和标签名重置*/
/*	无用变量列表：如EDC系统导出的非CRF收集信息的变量，__xxxx等*/
	%let drop_var=;
	data _dropvarfromdm;
		set sashelp.vcolumn(where=(libname=upcase("&dmlib.") and memname=upcase("&&_data&i") and find(upcase(name),'_R'))) end=eof;
		length dropvar $1000;
		retain dropvar;
		dropvar=catx(' ',dropvar,name);
		if eof then call symput('drop_var',strip(dropvar));
	run;
/*	修改raw_dm数据集，输出到raw中*/
	data &salib..&&_data&i;
        set &dmlib..&&_data&i;
/*		进行rename 和label修改数据集*/
		%if &reNm ne %then rename &reNm;;
		%if &reLal ne %then label &reLal;;
     run;
%end;

%mend;
%extract;

data rst(keep=libname memname name type label length finding);
  set sashelp.vcolumn(where=(libname=upcase("&salib") & memname ^in (&dplist.) ));
  re=prxparse('/(__)|(_YYYY)|(_MM)|(_DD)|(_YMD)|(_HH)|(_NN)/');
	if prxmatch(re,name) then delete;
  length finding $200;
       if lengthn(name)>8 then do;finding='变量名长度超过8位';output;end;
	   if lengthn(label)>40 then do;finding='标签长度超过40位';output;end;
       if length>200 then do;finding='变量超出200字符';output;end;
run;
