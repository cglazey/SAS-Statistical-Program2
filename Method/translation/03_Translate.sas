
dm "log; clear;";
dm "out; clear;";
run;
proc datasets nolist lib=work memtype=data kill;quit;
 
***********************************************************************************;
/*需要翻译的rawdata libname*/
%let rawnt=raw_en;

data rawmem;
	set sashelp.vcolumn(where=(libname=upcase("&rawnt.")));
	keep memname name type varnum length label format informat;
run;

data final;
	length Domain Var $20 cont $10000;
	call missing(of _all_);
	if ^missing(Var);
run;
/********************************************************/
/*输出所有rawdata的所有Domain的所有需要翻译的变量值*/
%macro opt(memname,name,type);
%if %upcase(&type) ne NUM %then %do;
	proc sql;
		create table _rst_ as select distinct "&memname." as Domain length=20,"&name." as Var length=20,
			&name. as cont length=10000 label='需要翻译内容' from &rawnt..&memname.(where=(^missing(&name.)));
	quit;
	data final;
		set  final _rst_;;
	run;
	proc sql;
		drop table _rst_;
	quit;
%end;
%mend opt;

data _null_;
	set rawmem;
	call execute('%opt('||memname||','||name||','||type||')');
run;
/****************************************************************************************************
|剔除部分不需要翻译的变量
****************************************************************************************************/
data final2;
	set final(where=((upcase(var) not in (
		'STUDYID','STUDYDES','CENTERID','SUBJID','BLORES','PRDTCC','AESDC1','AEEDC1','TDSIZE','DEPTI2','DEPTI3','S_INV_INV_BY'
		,'INSBY','CHGBY','AEDDC1','S_MON_MON_BY','MRIMTD7','CTAIMTD7','FORMID','VISITID'
		) and ^find(upcase(var),'TIM') and ^find(upcase(var),'BY')) or upcase(var) in ('ICSIBYD')));
/*	re=prxparse('/\d{4}\-\d{2}\-\d{2}/');*/
/*	if prxmatch(re,cont) then delete;*/
	re2=prxparse('/[\w\d\s\_]+R\b/i');
	if prxmatch(re2,var) and var not in ("IMGNAR","DEANAR") then do;	
		delete;
	end;
	drop re2;
	format _all_;
	informat _all_;
run;

data proc.DomainTranslate;
	set final2;
	length strcont $10000;
	cont=compress(strip(cont),'0a0d'x);
	strcont=compress(strip(cont),'0a0d'x);
run;

/****************************************************************************************************
|导入已经翻译的数据：包括CRF，人工翻译部分，不翻译数据
****************************************************************************************************/
/*CRF*/
proc import datafile="&_wpath.\Datasets\Translate\CRF Translate.xlsx" out=crf dbms=xlsx replace;
	sheet="CRF_Distinct";
run;
/*人工翻译version01*/
proc import datafile="&_wpath.\Datasets\Translate\Need Translate.xlsx" out=manu dbms=xlsx replace;
	sheet='翻译V0.1';
run;
/*不翻译数据*/
/*proc import datafile="&_wpath.\Datasets\Translate\Need Translate.xlsx" out=proc.non(where=(deletefl='Y') keep=strcont deletefl) dbms=xlsx replace;*/
/*	sheet='需要翻译的内容';*/
/*run;*/

data crf2;
	set crf ;
	length strcont $10000;
	strcont=strip(cont);
	drop cont;
run;

data Translated;
	length cn $10000;
	set crf2 manu;
run;
/*已经完成的翻译内容*/
proc sort data=Translated out=proc.Translated_Dis nodupkey;by strcont;run;

/****************************************************************************************************
|为final2拼接已经翻译的内容
****************************************************************************************************/
data proc.Havetranslated/*(drop=rc rc2)*/; 
	if _n_ = 0 then set proc.DomainTranslate proc.Translated_Dis;
	declare hash profee(dataset:'proc.Translated_Dis'); 
		profee.definekey ('strcont'); 
		profee.definedata('cn'); 
		profee.definedone();

	do until (eof_claims); 
		set proc.DomainTranslate end = eof_claims; 
		rc = profee.find(); 
		if rc ne 0 then cn= ''; 
		output;
	end; 
	stop; 
	format _all_;
	informat _all_;
run;
/****************************************************************************************************
|导出未翻译的内容Unique
****************************************************************************************************/
proc sort data=proc.Havetranslated(where=(missing(cn) and rc ne 0)) out=distin(keep=strcont) nodupkey;by cont;run;

proc export data=distin outfile="&_wpath.\Datasets\Translate\Need Translate.xlsx" dbms=xlsx replace;
	sheet='需要翻译的内容';
run;

/*proc sort data=raw.spss_ae out=cen(keep=CENTERID CENTRDES) nodupkey;by CENTERID;run;*/
/**/
/*proc export data=cen outfile="&_wpath.\Datasets\Translate\Need Translate.xlsx" dbms=xlsx replace;*/
/*	sheet='中心名称';*/
/*run;*/

