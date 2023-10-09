dm "log; clear;";
dm "out; clear;";
proc datasets nolist lib=work memtype=data kill;quit;

/*导出rawdata中的变量*/
data rst;
	set sashelp.vcolumn(where=(libname='RAW_EN'));
	if MEMNAME not in ("CODED_AES_2AUG2022");
/*	if name not in ("STUDYID","STUDYDES","CENTERID","CENTRDES","SUBJID","ENRDATE"*/
/*	,"VISITID","VISITDES","VISITOCC","FORMID","FORMDES","FORMOCC","PFORMID","PFORMDES"*/
/*	,"PFORMOCC","INSDAT","INSBY","CHGDAT","CHGBY","LCKDAT","LCKBY","FRZDAT","FRZBY");*/
	if VARNUM gt 38;
	re2=prxparse('/[\w\d\s\_]+R\b/i');
	if prxmatch(re2,name) and name ne 'PR' then do;	
		delete;
	end;
run;

/*导入crf page信息*/
proc import datafile="&_wpath.\Delivery\RawdataVisitFormInfoAndCRFPageInfo.xlsx" 
		out=crf(where=(^missing(page)) keep=domain Page Description) dbms=xlsx replace;
	sheet="RawdataVisitFormInfoCRF";
run;
proc sort data=crf out=crf2 nodupkey;by domain;run;
data crf2;
	length MEMNAME $32;
	set crf2;
	MEMNAME=upcase(cats(domain));
run;

data rst2(rename=(MEMNAME=domain));
	retain MEMNAME Page Annotext label;
	merge rst crf2(in=a);
	by MEMNAME;
	if a;
	AnnoText=cats(name);
	drop domain;
run;
proc sort data=rst2;by page domain;run;
/****************************************************************************************************
|导出注释表然后调整边框位置
****************************************************************************************************/
%let xfdf=XFDF;
%let crf=CRF PROST Study Rev 9_CN.pdf;
data pdf;
	retain page ANNOTXT ANNCAT RECT DomainNum;
	set rst2;
	by page domain;
	length ANNCAT COLOR FONTSIZE $20 SUBJECT DATE RECT style $200;
	ANNCAT='变量';
	FONTSIZE="12pt";
	SUBJECT="文本框";
	RECT="";
	ANNOTXT= Annotext;
	DATE="D:"||cats(put(input("&SYSDATE9",date9.),yymmddn8.))||"092816+08'00'";
	color="#BFFFFF";
	style='实线';

	if first.page then DomainNum=0;
	if first.domain then DomainNum+1;

	if DomainNum=1 then color="#BFFFFF";
	if DomainNum=2 then color="#FFFF96";
	if DomainNum=3 then color="#96FF96";
	if DomainNum=4 then color="#FFBE9B";
	
	output;
	if last.domain then do;
		ANNCAT='域名';
		FONTSIZE="12pt";
		Origin='指定';
		ANNOTXT=cats(domain,'(',Description,')');
		output;
	end;
run;

/*proc export data=pdf outfile="&_wpath.\Documents\CRF\AnnoCRF" dbms=xlsx label replace;*/
/*	sheet="&xfdf.";*/
/*run;*/

proc import datafile="&_wpath.\Documents\CRF\AnnoCRF" out=&xfdf. dbms=xlsx replace;
	sheet="&xfdf.";
run;

data pdf;
	set &xfdf. end=eof;
	page=page-1;
	length xml $30000;
	if _n_=1 then do;
		xml='<?xml version="1.0" encoding="UTF-8"?><xfdf xmlns="http://ns.adobe.com/xfdf/" xml:space="preserve"><annots>';
		output;
	end;
	if ANNCAT eq '域名' then 
		xml=cats('<freetext color="',COLOR,'" date="',DATE,'" page="',PAGE,'" rect="',RECT,'" subject="',SUBJECT,'" title="',"&SYSUSERID",'"><contents-richtext><body dir="ltr" style="font-size:',FONTSIZE,';text-align:left;color:#000000;font-weight:bold;font-style:normal;font-family:宋体;font-stretch:normal"><p><span>',ANNOTXT,"</span></p></body></contents-richtext><defaultappearance>0 0 0 rg /AdobeSongStd-Light 12 Tf</defaultappearance><defaultstyle>font: 'Adobe Song Std L' 12.0pt; text-align:left; color:#FF0000</defaultstyle></freetext>");
	else do;
		if style='虚线' then
			xml=cats('<freetext dashes="3.000000,3.000000" style="dash" color="',COLOR,'" date="',DATE,'" page="',PAGE,'" rect="',RECT,'" subject="',SUBJECT,'" title="',"&SYSUSERID",'"><contents-richtext><body dir="ltr" style="font-size:',FONTSIZE,';text-align:left;color:#000000;font-weight:normal;font-style:normal;font-family:宋体;font-stretch:normal"><p><span>',ANNOTXT,"</span></p></body></contents-richtext><defaultappearance>0 0 0 rg /AdobeSongStd-Light 12 Tf</defaultappearance><defaultstyle>font: 'Adobe Song Std L' 12.0pt; text-align:left; color:#FF0000</defaultstyle></freetext>");
		else
			xml=cats('<freetext color="',COLOR,'" date="',DATE,'" page="',PAGE,'" rect="',RECT,'" subject="',SUBJECT,'" title="',"&SYSUSERID",'"><contents-richtext><body dir="ltr" style="font-size:',FONTSIZE,';text-align:left;color:#000000;font-weight:normal;font-style:normal;font-family:宋体;font-stretch:normal"><p><span>',ANNOTXT,"</span></p></body></contents-richtext><defaultappearance>0 0 0 rg /AdobeSongStd-Light 12 Tf</defaultappearance><defaultstyle>font: 'Adobe Song Std L' 12.0pt; text-align:left; color:#FF0000</defaultstyle></freetext>");
	end;
	output;
	if eof then do;
		xml=cats('</annots><f href="',"&crf.",'"/></xfdf>');
		output;
	end;
run;
/*font-size:10.0pt;text-align:left;color:#000000;font-weight:normal;font-style:normal;font-family:宋体;font-stretch:normal*/

data _null_;
	set pdf;
	file "&_wpath.\Documents\CRF\anno.xfdf" lrecl=30000   encoding="utf-8";
	put xml;
run;
