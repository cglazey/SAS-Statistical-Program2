
%global _wPath;

%let _wpath=D:\Documents\SASsupport\China Submission;


libname raw_en "&_wpath.\Datasets\Rawdata_EN";
libname raw "&_wpath.\Datasets\Rawdata";
libname raw_st "&_wpath.\Datasets\Rawdata_ST";
libname raw_RE "&_wpath.\Datasets\Rawdata_RE";

libname ads_en "&_wpath.\Datasets\Anadata_EN";
libname ads "&_wpath.\Datasets\Anadata";
libname ads_st "&_wpath.\Datasets\Anadata_ST";
libname ads_re "&_wpath.\Datasets\Anadata_re";

libname ext_en "&_wpath.\Datasets\Extdata_EN";
libname ext "&_wpath.\Datasets\Extdata";
libname ext_st "&_wpath.\Datasets\Extdata_ST";
libname ext_re "&_wpath.\Datasets\Extdata_RE";

libname Proc "&_wpath.\Datasets\ProcData";

libname tlg "&_wpath.\Datasets\TLGdata";
libname tlg_en "&_wpath.\Datasets\TLGdata_EN";
%let _orgAds=&_wpath.\Programs\ANAprg;
%let _orgTlg=&_wpath.\Programs\TLGprg;

%inc "&_wpath.\Programs\_Global\Format-RAW.sas";
/*%inc "&_wpath.\Programs\_Global\Format.sas";*/
%inc "&_wpath.\Programs\_Global\Format_ADS.sas";

/*%inc "&_wpath.\Programs\_Global\setFormat.sas";*/
/*%inc "&_wpath.\Programs\_Global\09_TranslateLabel.sas";*/
/*%inc "&_wpath.\Programs\_Global\10_Standard_label.sas";*/
/*%inc "&_wpath.\Programs\_Global\10_Standard_var length.sas";*/

proc format CNTLOUT=RAW.formats LIBRARY=work.formats;run;

data EXT.Prost_randomization_2aug2022;
	set EXT.Prost_randomization_2aug2022;
	if SUBJID in ('DE-22-005','DE-23-046','DE-24-004','DE-24-011',
		'US-01-030','US-02-016','US-03-024','US-04-006',
		'US-04-010','US-07-003','US-08-013','US-08-017','US-09-005','US-11-016') then RANDOM_AGE='< 65';
	if SUBJID in ('US-02-011') then RANDOM_AGE='>= 65';
run;
