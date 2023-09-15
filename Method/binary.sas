/* 运用二进制算法将分类信息汇总为单个数据值，应用于指标的复杂算法 */
data bin;
	int=1;output;
	int=2;output;
	int=3;output;
	int=4;output;
	int=7;output;
	int=8;output;
	int=16;output;
	int=25;output;
	int=32;output;
run;

data bin3;
	set bin;
	if int='1'b then put 'Binary 1';
	if int='1.'b then put 'Binary 2';
	if int='1..'b then put 'Binary 4';
	if int='1...'b then put 'Binary 8';
	if int='1....'b then put 'Binary 16';
	if int='1.....'b then put 'Binary 32';
run;
