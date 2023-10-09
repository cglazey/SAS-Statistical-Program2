proc format ;
     value $ADEFF_2AUG2022_OB_TIME_CX (default=130 )
      	"Before stroke onset"="卒中前"
		"At screening"="筛选期"
		"At admission"="入院时"
		"Discharge"="出院"
		"24 hours post-procedure"="术后20h"
		"Day 30 evaluation"="第30天评估"
		"Day 90 evaluation"="第90天评估"
	 ;
	 value $ADSL_2AUG2022_OCC_SITE_CX
	 	"Other"="其他"
	 ;
	 value $ADSL_2AUG2022_YNX
	 	"Yes"="是"
		"No"="否"
	 ;
	 value $RNT
		"Clot migration"="血凝块转移"
		"Eligibiliy criteria violation identified"="确定违反资格标准"
		"Clot resolved"="血凝块已取出"
		"Wire perforation"="导丝穿刺"
		"SAH present. Subject died."="SAH，受试者死亡"
		"Vessel tortuosity; unable to reach clot"="血管曲折;无法到达血凝块"
		"Study device was not used"="研究器械未使用"
	 ;
run;


/*data EXT.Adat_pop_2aug2022;*/
/*	set EXT.Adat_pop_2aug2022;*/
/*	format AT_FLAG $ADSL_2AUG2022_YNX.;*/
/*run;*/
/**/
/*data EXT.Addprsae_2aug2022;*/
/*	set EXT.Addprsae_2aug2022;*/
/*	format CEC_REL_SER CADISTALEMBOLI DEATH_24H $ADSL_2AUG2022_YNX.;*/
/*run;*/
/**/
/*data EXT.Adhem_2aug2022;*/
/*	set EXT.Adhem_2aug2022;*/
/*	format HEM $ADSL_2AUG2022_YNX.;*/
/*run;*/
/**/
/*data EXT.Adpp_pop_2aug2022;*/
/*	set EXT.Adpp_pop_2aug2022;*/
/*	format PP_FLAG $ADSL_2AUG2022_YNX.;*/
/*run;*/
/**/
/*data EXT.Adrnt_20aug2022;*/
/*	set EXT.Adrnt_20aug2022;*/
/*	format RNT $RNT.;*/
/*run;*/




