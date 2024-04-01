ODS PATH work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);
proc template;
	define statgraph doselinearity;
		dynamic _byval_ _byval2_ _byval3_ _byval4_ _byval5_ XAXISLABEL YAXISLABEL 
			xtickvaluelist ytickvaluelist 
			XTICKMIN XTICKMAX YTICKMIN YTICKMAX
			YVAR XVAR GRPVAR LOWBAR UPBAR LENGEDTITLE ; 
		begingraph;
			layout lattice / columns=1 rows=1;
				rowheaders;
					if (_byval_="C^{sub max}(ug/mL)")
						entry 'Ln(C' {sub "max"} '(ug/mL))'/rotate=90;
					endif;
					if (_byval_="AUC^{sub last}(h*ug/mL)")
						entry 'Ln(AUC' {sub "last"} '(h*ug/mL))'/rotate=90;
					endif;
					if (_byval_="AUC^{sub inf}(h*ug/mL)")
						entry 'Ln(AUC' {sub "inf"} '(h*ug/mL))'/rotate=90;
					endif;
					if (_byval_="C^{sub max,ss}(ug/mL)")
						entry 'Ln(C' {sub "max,ss"} '(h*ug/mL))'/rotate=90;
					endif;
					if (_byval_="AUC^{sub tau}(h*ug/mL)")
						entry 'Ln(AUC' {sub "tau"} '(h*ug/mL))'/rotate=90;
					endif;
				endrowheaders;
				column2headers;
					entry "Rsq=" _byval2_ ", Intercept=" _byval3_ ", Slope=" _byval4_ ', 90%CI=' _byval5_;
				endcolumn2headers;
				layout overlay/
					xaxisopts=(label=XAXISLABEL  offsetmin=0.1 offsetmax=0.1
						linearopts=(tickvaluelist=xtickvaluelist viewmin=XTICKMIN viewmax=XTICKMAX )
						tickvalueattrs=(size=7pt) labelattrs=(size=7pt))
		    		yaxisopts=(display=(ticks tickvalues line)) walldisplay=none ;
					seriesplot y=YVAR x=XVAR / display=all group=GRPVAR name="scatter" ;
					regressionplot y=YVAR x=XVAR /alpha=0.1 clm="clm";
				endlayout;
				
				sidebar / align=bottom;
				    discretelegend "scatter"/title=LENGEDTITLE across=5 DISPLAYCLIPPED=TRUE BORDER=FALSE;
				endsidebar;
			endlayout;
		endgraph;
	end;
run;

/************************************************************************************************************************/
proc sgrender data=final template=doselinearity;
	by descending col1 Rsq Intcept Slope ci;
	dynamic XAXISLABEL='Ln(Dose)'
	YVAR='logaval' XVAR='logdose' LENGEDTITLE='剂量组：' GRPVAR='dose' LOWBAR='' UPBAR='';
run;
