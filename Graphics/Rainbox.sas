/*---------------------------------------------------------------------------------------------------------------
|Part 1 Rain Code
---------------------------------------------------------------------------------------------------------------*/
PROC FORMAT;
	INVALUE Species
	'Setosa'= 1
	'Versicolor'= 2
	'Virginica'= 3;
	
	VALUE Species_n
	1= 'Setosa'
	2= 'Versicolor'
	3= 'Virginica';
RUN;

DATA Iris;
	SET SASHELP.Iris;
	Species_n= input(Species, Species.);
	format Species_n Species_n.;
RUN;

proc template;
	define statgraph rainbox;
		begingraph;
		
			layout overlay;      
		        scatterplot x=Species_n y=SepalLength/jitter =auto;
		      endlayout;

		endgraph;
	end;
run;

proc sgrender data=Iris template=rainbox;run;

/*---------------------------------------------------------------------------------------------------------------
|Part 2 Half box plot 
---------------------------------------------------------------------------------------------------------------*/
/*计算箱型图线所需统计量*/
PROC MEANS DATA = Iris NOPRINT;
	BY Species_n Species;
	VAR SepalLength;
	OUTPUT OUT = BoxPlotStats MEAN = mean MEDIAN = median Q1 = q1
		Q3= q3 QRANGE = qrange MIN = min MAX = max;
RUN;

DATA GraphData;
	SET BoxPlotStats(IN =box)
		Iris (IN = iris);
	/*Roin code X asix skewing*/
	IF iris THEN DO ;
		Scatter_X = Species_n-0.375;
	END;
	
	IF box THEN DO;
		/*Box skewing*/
		XBoxLeft= Species_n-0.2;
		XBoxRight= Species_n-0.01;
		
		/*Whisker skewing*/
		XWhiskerLeft= Species_n-0.05;
		XWhiskerRight= Species_n-0.01;
		YWhiskerTop= (1.5*qrange ) +q3;
		YWhiskerBottom= q1-(1.5*qrange);
		
		IF max LE YWhiskerTop THEN YWhiskerTop =max;
		IF min GE YWhiskerBottom THEN YWhiskerBottom = min;
	END;
RUN;

DATA GraphData2;
	SET BoxPlotStats(IN =box)
		Iris (IN = iris);
	/*Roin code X asix skewing*/
	IF iris THEN DO ;
		Scatter_X = Species_n-0.375;
	END;
	
	IF box THEN DO;
		/*box series*/
		xbox=Species_n-0.1;ybox=q3;output;
		xbox=Species_n+0.1;ybox=q3;output;
		xbox=Species_n+0.1;ybox=q1;output;
		xbox=Species_n-0.1;ybox=q1;output;
		xbox=Species_n-0.1;ybox=q3;output;
		/*Whisker series*/
		xWhisker=Species_n;yWhisker=max((1.5*qrange ) +q3,max);output;
		xWhisker=Species_n;yWhisker=min(q1-(1.5*qrange),min);output;

	END;
	else do;
		output;
	end;
RUN;

proc template;
	define statgraph rainbox;
		begingraph;
		
			layout overlay;      
		        scatterplot x=Scatter_X y=SepalLength/jitter =auto group=Species_n;
		        seriesplot x=xbox y= ybox /group=Species_n;
		        seriesplot x=xWhisker y= yWhisker /group=Species_n;
		      endlayout;

		endgraph;
	end;
run;

proc sgrender data=GraphData2 template=rainbox;run;


/*---------------------------------------------------------------------------------------------------------------
|Part 3 KDE
---------------------------------------------------------------------------------------------------------------*/
/* Kernel Density Estimation */
PROC KDE DATA =Iris;
	BY Species_n;
	UNIVAR SepalLength / NGRID = 1000 UNISTATS PERCENTILES PLOTS= NONE 
		OUT = Density(RENAME = (value = SepalLength ) DROP = var);
RUN;

PROC SQL NOPRINT;
	create table maxdens as SELECT Species_n ,MAX(density) as max_dens
		FROM Density group by Species_n;
QUIT;

data Density2;
	merge Density maxdens BoxPlotStats;
	by Species_n;
	density = Density * 0.2/ max_dens;
	if SepalLength le max((1.5*qrange ) +q3,max) and SepalLength ge min(q1-(1.5*qrange),min);
run;

DATA GraphData3;
	SET Density2(in=dens)
		BoxPlotStats(IN =box)
		Iris (IN = iris);
	/*Roin code X asix skewing*/
	IF iris THEN DO ;
		Scatter_X = Species_n-0.375;
	END;
	
	IF box THEN DO;
		/*box series*/
		xbox=Species_n-0.1;ybox=q3;output;
		xbox=Species_n+0.1;ybox=q3;output;
		xbox=Species_n+0.1;ybox=q1;output;
		xbox=Species_n-0.1;ybox=q1;output;
		xbox=Species_n-0.1;ybox=q3;output;
		/*Whisker series*/
		xWhisker=Species_n;yWhisker=max((1.5*qrange ) +q3,max);output;
		xWhisker=Species_n;yWhisker=min(q1-(1.5*qrange),min);output;

	END;
	else if dens then do;
		ydens=SepalLength;
		highdens=Species_n+density;
		lowdens=Species_n-density;
		output;
	end;
	else if iris then do;
		output;
	end;
	format Species_n Species_n.;
RUN;

proc template;
	define statgraph rainbox;
		begingraph;
		
			layout overlay;      
		        scatterplot x=Scatter_X y=SepalLength/jitter =auto group=Species_n;
		        seriesplot x=xbox y= ybox /group=Species_n;
		        seriesplot x=xWhisker y= yWhisker /group=Species_n;
		        HIGHLOWPLOT Y =ydens HIGH = highdens LOW = lowdens /
					DISPLAY = (FILL)  TYPE =BAR BARWIDTH=1 INTERVALBARWIDTH =1 DATATRANSPARENCY = 0.5 fillattrs=(transparency=0.8);
		      endlayout;

		endgraph;
	end;
run;

proc sgrender data=GraphData3 template=rainbox;run;
