
proc template;
	define statgraph celldefine;
		dynamic _byval1_ _byval2_ _byval3_ XAXISLABEL YAXISLABEL 
			xtickvaluelist ytickvaluelist ytickvaluelistlog
			XTICKMIN XTICKMAX YTICKMIN YTICKMAX
			YVAR XVAR GRPVAR ERRORLOW ERRORUP LENGEDTITLE ; 
		begingraph;
		/*
		|Mean Errorbar log
		*/
			if (_byval1_) 
				entrytitle "分析物:" _byval1_;
			endif;
				layout lattice / columns=2 rows=1;
			        column2headers;
			          entry "线性药时曲线";
			          entry "半对数药时曲线";
			        endcolumn2headers;
					layout overlay/
						xaxisopts=(label=XAXISLABEL  offsetmin=0 offsetmax=0
							linearopts=(tickvaluelist=xtickvaluelist viewmin=XTICKMIN viewmax=XTICKMAX TICKVALUEFITPOLICY=ROTATE)
							tickvalueattrs=(size=7pt) labelattrs=(size=7pt))
			    		yaxisopts=(label=YAXISLABEL) walldisplay=none ;
						seriesplot y=YVAR x=XVAR / display=all group=GRPVAR name="scatter" YERRORLOWER=ERRORLOW YERRORUPPER=ERRORUP;
					endlayout;
					
          layout overlay/
            xaxisopts=(label=XAXISLABEL  offsetmin=0 offsetmax=0
              linearopts=(tickvaluelist=xtickvaluelist viewmin=XTICKMIN viewmax=XTICKMAX TICKVALUEFITPOLICY=ROTATE)
              tickvalueattrs=(size=7pt) labelattrs=(size=7pt))
              yaxisopts=(label=YAXISLABEL TYPE=LOG LOGOPTS=(base=10 tickvaluelist=ytickvaluelistlog viewmin=YTICKMIN viewmax=YTICKMAX)) walldisplay=none ;
            seriesplot y=YVAR x=XVAR / display=all group=GRPVAR  YERRORLOWER=ERRORLOW YERRORUPPER=ERRORUP;
          endlayout;
					
					sidebar / align=bottom;
					    discretelegend "scatter"/title=LENGEDTITLE across=5 DISPLAYCLIPPED=TRUE;
					endsidebar;

			endlayout;
		endgraph;
	end;
run;

/*均值血药浓度*/
proc sgrender data=fig(where=(ADY=7)) template=celldefine ;
	by PARAMCD;
	dynamic XAXISLABEL='Time(h)' YAXISLABEL='Concentration (ng/mL)' 
	xtickvaluelist='0 1 2 3 4 6 7 8 12'
	ytickvaluelist =''
	ytickvaluelistlog='1 10 100 1000'
	XTICKMIN='-1' XTICKMAX='13' YTICKMIN='' YTICKMAX='1000'
	YVAR='Mean' XVAR='ATPTN' LENGEDTITLE='剂量组：' GRPVAR='ARMCD' ERRORLOW='Meanlow' ERRORUP='Meanhig';
run;
/*均值给药前浓度*/
proc sgrender data=fig(where=(ADY in (2,7,8) and ATPTN=0)) template=celldefine ;
	by PARAMCD;
	dynamic XAXISLABEL='Day(D)' YAXISLABEL='Concentration (ng/mL)' 
	xtickvaluelist='2 3 4 6 7 8'
	ytickvaluelist =''
	ytickvaluelistlog='1 10 100 1000'
	XTICKMIN='1' XTICKMAX='9' YTICKMIN='' YTICKMAX='1000'
	YVAR='Mean' XVAR='ADY' LENGEDTITLE='剂量组：' GRPVAR='ARMCD' ERRORLOW='Meanlow' ERRORUP='Meanhig';
run;

/*中位血药浓度*/
proc sgrender data=fig(where=(ADY=7)) template=celldefine ;
	by PARAMCD;
	dynamic XAXISLABEL='Time(h)' YAXISLABEL='Concentration (ng/mL)' 
	xtickvaluelist='0 1 2 3 4 6 7 8 12'
	ytickvaluelist =''
	ytickvaluelistlog='1 10 100 1000'
	XTICKMIN='-1' XTICKMAX='13' YTICKMIN='' YTICKMAX='1000'
	YVAR='Median' XVAR='ATPTN' LENGEDTITLE='剂量组：' GRPVAR='ARMCD' ERRORLOW='' ERRORUP='';
run;
