dm "log; clear;";
dm "out; clear;";
run;
proc datasets nolist lib=work memtype=data kill;quit;
title;footnote;
*******************************************************************************************;

%let dmlib=RAW;
%let salib=raw_st;

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
     set sashelp.vtable(where=(libname in ("&dmlib","EXT","ADS") & memname ^in (&dplist.)));
	 call symputx('_sum',cats(_n_));
	 call symputx('_data'||cats(_n_),memname);
run;

/*问题变量清单*/
data _problist _useless;
	set sashelp.vcolumn(where=(libname in ("&dmlib","EXT","ADS") & memname ^in (&dplist.) ) );
	length issue1 issue2 issue3 $200; 
    if lengthn(name)>8 then issue1='Var';
	if lengthn(label)>40 then issue2='Label';
    if length>200 then issue3='Length';
	re=prxparse('/(__)|(_YYYY)|(_MM)|(_DD)|(_YMD)|(_HH)|(_NN)/');
	if prxmatch(re,name) then output _useless;
		else output _problist;
run;

data problist;
	length Key $100;
	set _problist(rename=(issue1=issue) where=(^missing(issue)))
		_problist(rename=(issue2=issue) where=(^missing(issue)))
		_problist(rename=(issue3=issue) where=(^missing(issue)));
	by libname memname varnum;
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
proc export data=problist3 outfile="&verfy_path." DBMS=xlsx replace;
	sheet='verify';
run;

/*修改problist数据集中不规范的命名等，导入修改后的数据集*/
proc import datafile="&verfy_path." 
		out=verify DBMS=xlsx replace;
	sheet='verify1.0';
	GETNAMES=YES;
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
		set verify(where=(memname="&&_data&i" and issue ne 'length'));
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
/****************************************************************************************************************/
/*变量长度超过200，拆分部分*/
/*变量长度超过200字符处理:直接从修改后的数据集进行变量拆分*/
	 %let _SUM_L=0;
     data length(keep=libname memname name type label length);
        set sashelp.vcolumn(where=(libname=upcase("&salib") and memname=upcase("&&_data&i") and length>200));
     run;
	 data _null_;
        set length;
		call symput("LnvarNm"||left(put(_n_,best.)),cats(name));
		call symput("LnvarLb"||left(put(_n_,best.)),cats(label));
		call symput("_SUM_L",strip(put(_n_,best.)));		
	run;

/*	如需要进行拆分，则获得变量列表*/
	%if &_SUM_L ne 0 %then %do;
	%do j=1 %to &_SUM_L;
		/*调整拆分变量的位置自动落在数据集末尾问题*/
		data _split_ds;
			set sashelp.vcolumn(where=(libname=upcase("&salib") and memname=upcase("&&_data&i")));
		run;
		/*	需要拆分成N_LEN个变量*/
		%let _ret_varlist=;/*拆分变量之前的所有变量列表*/
		%let _split_varlist=;/*拆分变量拆分出来的所有变量列表*/
		%let _all_varlist=;/*拆分前数据集所有变量的列表：用于判断拆分变量的名称与已有变量名冲突*/
		%let N_LEN=1;
		proc sql;
/*			获取数据集需拆分变量的值的最大长度可以拆分为N_LEN个200长度的变量*/
			select ceil(max(length(&&LnvarNm&j))/200) into: N_LEN  from &salib..&&_data&i;
/*			获得拆分变量在修改前的数据集中位置：varnum*/
			select varnum into:_split_varnum from _split_ds(where=(upcase(name)=upcase("&&LnvarNm&j.")));
/*			获得拆分变量之前的所有变量的列表*/
			select name into:_ret_varlist separated by ' ' from _split_ds(where=(varnum lt &_split_varnum.));
/*			获得拆分之前的所有变量的列表*/
			create table before_split as select name length=200 from _split_ds;
		quit;

/*		当N_LEN大于1时，即变量需要进行实质性拆分*/
		%if &N_LEN gt 1 %then %do;
/****************************************************************************************************************/
/*		将拆分变量的变量名验证部分拿出来*/
/*		创建拆分变量的数据集*/
/*			拆分变量后5位字符*/
			%let varlen=%length(&&LnvarNm&j.);
			%if &varlen. ge 5 %then %let varlen=5;;
			%if &varlen. eq 5 and &N_LEN ge 10 %then %let varlen=4;;
			%let pref=%sysfunc(reverse(%substr(%sysfunc(reverse(&&LnvarNm&j.)),1,&varlen.)));
			%let split_index=SP;
			data split_varlist;
				length name $200;
				%do k=1 %to &N_LEN;
					%let &pref.&k.=&pref.&split_index.&k;
					%let _split_varlist= &_split_varlist. &&&pref.&k;
					name="&&&pref.&k.";output;
				%end;
			run;
			%put &_split_varlist.;
/*			验证拆分后的变量名是否与已有变量名冲突*/
			%let conflict_num=0;
			proc sql;
				create table var_conflict as select s.name from split_varlist as s,before_split as u where s.name=u.name;
				select count(*) into: conflict_num  from var_conflict;
			quit;
			%if &conflict_num ne 0 %then %put '存在冲突变量名，查看数据集[var_conflict]';;
/****************************************************************************************************************/
			data &salib..&&_data&i;
				retain &_ret_varlist. &_split_varlist.;
	       		set &salib..&&_data&i;
				retain orgp;
				orgp=1;
				length &_split_varlist $200;
				%do k=1 %to &N_LEN;
					/*考虑单字节双字节或多字节情况*/
					&&&pref.&k=ksubstrb(&&LnvarNm&j,%eval((&k-1)*200)+orgp,%eval(&k*200));
					len=length(&&&pref.&k);
					if len=200 then orgp=1;else orgp=len+1-200;
					label &&&pref.&k="&&LnvarLb&j.-&k.";
				%end;
				drop &&LnvarNm&j len orgp;
	     	run;

			data _split_;
				length memname name label splitnm $40;
				memname="&&_data&i.";
				name="&&LnvarNm&j.";
				%do k=1 %to &N_LEN;
					splitnm="&&&pref.&k";
					label="&&LnvarLb&j.-&k.";
					output;
				%end;
			run;
		/*进行拆分的变量，拆分后的变量名标签信息总表*/
			data _split_allds;
				set %if %sysfunc(exist(_split,data)) %then _split_allds;_split_;
			run;

		%end;
/*		当N_LEN等于1，不需要进行拆分，直接修改对应变量的长度为200即可*/
		%if &N_LEN eq 1 %then %do;
			proc sql;
				alter table &salib..&&_data&i
					modify &&LnvarNm&j char(200) /*format=$200.*/ informat=$200.;
			quit;
		%end;
	%end;	
	%end;

%end;

%if %sysfunc(exist(_split_allds,data)) %then %do;
	proc export data=_split_allds outfile="&verfy_path." DBMS=xlsx replace;
		sheet='Split Var';
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
