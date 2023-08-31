/* Nested GTL Template */
/* using the attribute map data set */

/* 1. 指定模拟数据 */
data test2;
   input ARMCD $10. ATPTN Mean Meanlow Meanhig;
datalines;
剂量组1   1   287.1   41.24   532.96
剂量组1   2   343.1   153.44   532.76
剂量组1   3   320.4   175.59   465.21
剂量组1   4   295.9   156.72   435.08
剂量组1   5   268.3   140.22   396.38
剂量组1   6   252.7   136.16   369.24
剂量组1   8   212   114.716   309.284
剂量组1   10   182.1   93.099   271.101
剂量组1   24   84.3   36.133   132.467
剂量组1   48   22.18   8.709   35.651
剂量组1   72   6.207   0.332   12.082
剂量组1   96   0.589   0.589   2.4516
剂量组2   1   388.3   166.36   610.24
剂量组2   2   655.6   390.45   920.75
剂量组2   3   647.4   350.52   944.28
剂量组2   4   608   289.94   926.06
剂量组2   5   548.1   246.31   849.89
剂量组2   6   502.7   222.03   783.37
剂量组2   8   407.7   161.17   654.23
剂量组2   10   346.7   152.92   540.48
剂量组2   24   172.9   76.032   269.768
剂量组2   48   47.56   13.489   81.631
剂量组2   72   13.48   1.219   25.741
剂量组2   96   2.37   2.37   6.5262
剂量组3   1   628.6   355.7   901.5
剂量组3   2   1047   539.45   1554.55
剂量组3   3   1060   585.8   1534.2
剂量组3   4   1008   536.09   1479.91
剂量组3   5   961.7   464.03   1459.37
剂量组3   6   891.4   409.51   1373.29
剂量组3   8   780.2   303.3   1257.1
剂量组3   10   643.9   240.93   1046.87
剂量组3   24   246.6   121.04   372.16
剂量组3   48   60.28   22.872   97.688
剂量组3   72   16.89   3.892   29.888
剂量组3   96   4.387   4.387   9.7029
剂量组4   1   457.3   272.71   641.89
剂量组4   2   924.5   735.7   1113.3
剂量组4   3   1283   818.99   1747.01
剂量组4   4   1550   329.8   2770.2
剂量组4   5   1435   331.3   2538.7
剂量组4   6   1353   365.57   2340.43
剂量组4   8   1101   333.82   1868.18
剂量组4   10   939.3   225.16   1653.44
剂量组4   24   404.8   75.29   734.31
剂量组4   48   103   25.219   180.781
剂量组4   72   24.52   9.958   39.082
剂量组4   96   6.153   1.6598   10.6462
剂量组5   1   1826   370.3   3281.7
剂量组5   2   2700   414.9   4985.1
剂量组5   3   2953   500.4   5405.6
剂量组5   4   2880   733.5   5026.5
剂量组5   5   2593   632.6   4553.4
剂量组5   6   2200   642.6   3757.4
剂量组5   8   1941   488.8   3393.2
剂量组5   10   1896   547.8   3244.2
剂量组5   24   1095   162.49   2027.51
剂量组5   48   421.4   100.4   742.4
剂量组5   72   145   16.36   273.64
剂量组5   96   69.63   9.012   130.248
;
run;

/* 2. 调整数据集 */
data test3;
	merge test2 test2(where=(ATPTN le 10) rename=(Mean=Mean2 Meanlow=Meanlow2 Meanhig=Meanhig2));
	by ARMCD ATPTN;
run;

/* 3. Create the attribute map data set */
data attrds;
   input ID	$1-7 Value $9-18 MarkerSymbol $20-33 MarkerSize MarkerColor $ MarkerTransparency LineColor $ LinePattern LineThickness;
datalines;
symbols 剂量组1 triangleFilled 10 blue      0.6 blue      4 1
symbols 剂量组2 circleFilled   10 green     0.6 green     4 1
symbols 剂量组3 squareFilled   10 firebrick 0.6 firebrick 4 1
symbols 剂量组4 HomeDownFilled 10 Purple    0.6 Purple    4 1
symbols 剂量组5 StarFilled     10 Orange    0.6 Orange    4 1
;
run;

/* 4. 创建GTL Template */
proc template;
	define statgraph tmp5;
		dynamic XAXISLABEL YVAR XVAR GRPVAR LENGEDTITLE TICKMIN TICKMAX TICKMAX2; 
		begingraph;
			discreteattrvar attrvar=groupmarkers var=GRPVAR attrmap="symbols";
			layout overlay/
				xaxisopts=(label=XAXISLABEL  offsetmin=0 offsetmax=0
					linearopts=(tickvaluelist=(1 4 8 10 24 48 72 96) viewmin=TICKMIN viewmax=TICKMAX TICKVALUEFITPOLICY=ROTATE)
					tickvalueattrs=(size=7pt) labelattrs=(size=7pt))
	    		yaxisopts=(label="Concentration (ng/mL)" TYPE=LINEAR) ;
				seriesplot y=YVAR x=XVAR / display=all group=groupmarkers name="scatter" YERRORLOWER=meanlow YERRORUPPER=meanhig;
				
				layout gridded / width=400px height=300px halign=right valign=top;
					layout overlay/
						xaxisopts=(label=XAXISLABEL  offsetmin=0 offsetmax=0
							linearopts=(tickvaluelist=(1 2 3 4 6 8 10) viewmin=TICKMIN viewmax=TICKMAX2 TICKVALUEFITPOLICY=ROTATE)
							tickvalueattrs=(size=7pt) labelattrs=(size=7pt))
			    		yaxisopts=(label="Concentration (ng/mL)" TYPE=LINEAR) ;
						seriesplot y=Mean2 x=XVAR / display=all group=groupmarkers YERRORLOWER=meanlow2 YERRORUPPER=meanhig2;
					endlayout;
			    endlayout;
			   discretelegend "scatter"/title=LENGEDTITLE across=5 DISPLAYCLIPPED=TRUE;
			endlayout;
		endgraph;
	end;
run;

ods graphics on /width=800px height=400px;

proc sgrender data=test3 dattrmap=attrds template=tmp5;
	dynamic XAXISLABEL='Time(h)' YVAR='Mean' XVAR='ATPTN' LENGEDTITLE='剂量组：' GRPVAR='ARMCD' TICKMIN='0.5' TICKMAX='100' TICKMAX2='12';
run;
