data ads;
	set sashelp.vcolumn(where=(libname=upcase("ADS_ST")) );
	keep memname name label type length ;
run;

proc export data=ads outfile="D:\Documents\SASsupport\China Submission\Documents\分析数据集说明" dbms=xlsx replace;
	sheet='Sheet1';
run;

data ads;
	set sashelp.vcolumn(where=(libname=upcase("ADS_RE")) );
	keep memname name label type length ;
run;

proc export data=ads outfile="D:\Documents\SASsupport\China Submission\Documents\分析数据集说明" dbms=xlsx replace;
	sheet='Sheet2';
run;
