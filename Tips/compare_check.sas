/* 将下面代码加在compare过程步后，将比对结果输出到日志中 */
/* reference document: https://documentation.sas.com/doc/zh-CN/pgmsascdc/9.4_3.5/proc/n1jbbrf1tztya8n1tju77t35dej9.htm */
/* PROC COMPARE stores a return code in the automatic macro variable SYSINFO. The value of the return code provides information about the result of the comparison. */

%if &sysinfo ne 0 %then %do;
	%put ERROR: Compare Results Exist Errors.;
%end;
%else %do;
	%put NOTE: Compare Results No Errors.;
%end;
