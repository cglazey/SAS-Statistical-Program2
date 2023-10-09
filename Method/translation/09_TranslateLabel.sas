
dm "log; clear;";
dm "out; clear;";
run;
proc datasets nolist lib=work memtype=data kill;quit;
 
***********************************************************************************;
/*需要翻译的rawdata libname*/
%let rawnt=raw;
%let dmlib=raw;
%let salib=raw;

data rawmem;
	set sashelp.vcolumn(where=(libname=upcase("&rawnt.")));
	keep memname name type varnum length label format informat;
run;

/****************************************************************************************************
|导入XFDF标签翻译
****************************************************************************************************/
proc import datafile="&_wpath.\Documents\CRF\AnnoCRF.xlsx" out=label dbms=xlsx replace;
	sheet="XFDF标签翻译";
run;

proc import datafile="&_wpath.\Documents\CRF\AnnoCRF" out=&xfdf. dbms=xlsx replace;
	sheet="&xfdf.";
run;

data proc.labelverify;
	retain MEMBER_NAME ANNOTXT issue D ;
	set label(where=(ANNCAT='变量' and ^missing(D)));
	issue='Label';
	rename  MEMBER_NAME=memname ANNOTXT=name D=verify;
run;

data _null_;
     set sashelp.vtable(where=(libname=upcase("&rawnt.")));
	 call symputx('_sum',cats(_n_));
	 call symputx('_data'||cats(_n_),memname);
run;

option mprint;
%macro extract();
%do i=1 %to &_sum;
%let &&_data&i=;
/****************************************************************************************************************/
/*变量名与标签重置部分：Part 1*/
/*获得对应数据集的需要修改的变量名列表及修改原因和替换值*/
	%let _SUM_=0;
	data _null;
		set proc.labelverify(where=(memname="&&_data&i" and issue ne 'length'));
		call symput("varNm"||left(put(_n_,best.)),name);
		call symput("issue"||left(put(_n_,best.)),issue);
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

