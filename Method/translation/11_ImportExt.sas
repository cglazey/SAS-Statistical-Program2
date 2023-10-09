proc import datafile="D:\Documents\SASsupport\China Submission\Datasets\Extdata_EN\PROST CORE LAB MASTER 28_7_22.xlsx" 
	out=ext.CORE_LAB_28JUL2022
	 dbms=xlsx replace;
	sheet="Sheet1";
run;

proc import datafile="D:\Documents\SASsupport\China Submission\Datasets\Extdata_EN\PROST Treatment Assignment.xlsx" 
	out=PROST_RANDOMIZATION_2AUG2022
	 dbms=xlsx replace;
	sheet="ValidatOracle Subject Data File";
run;


proc import datafile="D:\Documents\SASsupport\China Submission\Datasets\Extdata_EN\PROST Treatment Assignment.xlsx" 
	out=EXT.PROST_RANDOMIZATION_2AUG2022
	 dbms=xlsx replace;
	sheet="Sheet2";
run;
