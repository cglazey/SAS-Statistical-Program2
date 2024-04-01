ODS PATH work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);
proc template;
	define statgraph celldefine;
		dynamic _byval_ _byval2_ _byval3_ XAXISLABEL YAXISLABEL 
			xtickvaluelist ytickvaluelist ytickvaluelistlog
			XTICKMIN XTICKMAX YTICKMIN YTICKMAX
			YVAR LOGYVAR XVAR GRPVAR LOWBAR UPBAR LENGEDTITLE ; 
		begingraph;
			if (exists(_byval_)) 
				entrytitle "剂量组：" _byval_;
			endif;
			if (exists(ytickvaluelistlog))
				layout lattice / columns=2 rows=1;
			        column2headers;
			          entry "线性药时曲线";
			          entry "半对数药时曲线";
			        endcolumn2headers;
					layout overlay/
						xaxisopts=(label=XAXISLABEL  offsetmin=0 offsetmax=0
							linearopts=(tickvaluelist=xtickvaluelist viewmin=XTICKMIN viewmax=XTICKMAX )
							tickvalueattrs=(size=7pt) labelattrs=(size=7pt))
			    		yaxisopts=(label=YAXISLABEL) walldisplay=none ;
						seriesplot y=YVAR x=XVAR / display=all group=GRPVAR name="scatter" YERRORLOWER=LOWBAR YERRORUPPER=UPBAR;
					endlayout;
					
					layout overlay/
						xaxisopts=(label=XAXISLABEL  offsetmin=0 offsetmax=0
							linearopts=(tickvaluelist=xtickvaluelist viewmin=XTICKMIN viewmax=XTICKMAX)
							tickvalueattrs=(size=7pt) labelattrs=(size=7pt))
			    		yaxisopts=(label=YAXISLABEL TYPE=LOG LOGOPTS=(base=10 tickvaluelist=ytickvaluelistlog viewmin=YTICKMIN viewmax=YTICKMAX)) walldisplay=none ;
						seriesplot y=LOGYVAR x=XVAR / display=all group=GRPVAR  YERRORLOWER=LOWBAR YERRORUPPER=UPBAR;
					endlayout;
					
					sidebar / align=bottom;
					    discretelegend "scatter"/title=LENGEDTITLE across=5 DISPLAYCLIPPED=TRUE BORDER=FALSE;
					endsidebar;
				endlayout;
			else
				layout lattice / columns=1 rows=1;
			        column2headers;
			          entry "线性药时曲线";
			        endcolumn2headers;
					layout overlay/
						xaxisopts=(label=XAXISLABEL  offsetmin=0 offsetmax=0
							linearopts=(tickvaluelist=xtickvaluelist viewmin=XTICKMIN viewmax=XTICKMAX )
							tickvalueattrs=(size=7pt) labelattrs=(size=7pt))
			    		yaxisopts=(label=YAXISLABEL) walldisplay=none ;
						seriesplot y=YVAR x=XVAR / display=all group=GRPVAR name="scatter" YERRORLOWER=LOWBAR YERRORUPPER=UPBAR;
					endlayout;
					
					sidebar / align=bottom;
					    discretelegend "scatter"/title=LENGEDTITLE across=5 DISPLAYCLIPPED=TRUE BORDER=FALSE;
					endsidebar;
				endlayout;
			endif;
		endgraph;
	end;
run;
