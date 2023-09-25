
set path=D:\Documents\SASsupport\China Submission\Programs\TLGprg\

set start= D:\Sofeware\SASHome\SASFoundation\9.4\sas.exe -CONFIG "D:\Sofeware\SASHome\SASFoundation\9.4\nls\u8\sasv9.cfg" /nosplash /batch /autoexec "D:\Documents\SASsupport\China Submission\Programs\_Global\00_Setup.sas" /nolog  /NOPRINT

%start% /sysin '%path%L-16-01a-V1-20AUG2022-8SEP2022.sas' /log '%path%Outputs\'
