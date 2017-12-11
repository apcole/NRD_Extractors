# delimit; 
cd "/Users/Putnam_Cole/Dropbox/1_ResearchProjects/1_HarvardProjects/NRD_RC_Predictors/Data";
use "NRD_2014_Core_Readmit_Narrow_Costs_Hosp_Severity.dta", replace; 

/* Create variable CASELOD for HOSP_NRD */
keep if INDEX_DX==1;
gen CASELOAD=1;
collapse (sum) CASELOAD, by (HOSP_NRD);
xtile CASELOAD_QUART=CASELOAD, nquantiles(4);
label define CASELOAD_QUART 
	1 "1st quartile" 
	2 "2nd quartile" 
	3 "3rd quartile" 
	4 "4th quartile";
label values CASELOAD_QUART CASELOAD_QUART;
la var CASELOAD "Caseload at HOSP_NRD per year"; 
la var CASELOAD_QUART "Quartile of volume of HOSP_NRD";
keep CASELOAD CASELOAD_QUART HOSP_NRD;
save "Caseload.dta", replace;
use "NRD_2014_Core_Readmit_Narrow_Costs_Hosp_Severity.dta", clear;
merge m:1 HOSP_NRD using "Caseload.dta";
drop _merge; 
save "NRD_2014_Core_Readmit_Narrow_Costs_Hosp_Severity_C.dta", replace; 
rm "Caseload.dta";
describe;

/* Create "READMIT_NUMBER" variable for HOSP_NRD */
collapse (sum) READMIT, by (HOSP_NRD);
rename READMIT READMIT_NUMBER;
la var READMIT_NUMBER "Number of readmissions in year at HOSP_NRD";
keep READMIT_NUMBER HOSP_NRD;
save "Readmissions.dta", replace;
use "NRD_2014_Core_Readmit_Narrow_Costs_Hosp_Severity_C.dta", clear;
merge m:1 HOSP_NRD using "Readmissions.dta";
rm "Readmissions.dta";
rm "NRD_2014_Core_Readmit_Narrow_Costs_Hosp_Severity_C.dta";
drop _merge; 
describe;

/* Create variable READMIT_RATE, CCI_CAT, CASELOAD_QART and drop if non-resident */
#delimit;
gen READMIT_RATE=READMIT_NUMBER/CASELOAD;

recode CHARLSON
	(4=4 "CCI 4")
	(5=5 "CCI 5")
	(6=6 "CCI 6")
	(7=7 "CCI 7")
	(8=8 "CCI 8")
	(9/14=9 "CCI 9+")
	(else=.),
	gen(CCI_CAT);
xtile CASELOAD_20=CASELOAD, nquantiles(20);
	
drop if RESIDENT==0;

/* */


/* National estimates based on NRD design */ /* Specify the sampling design with sampling weights DISCWT, */ /* hospital clusters HOSP_NRD, and stratification NRD_STRATUM */ svyset HOSP_NRD [ pw=DISCWT ], strata( NRD_STRATUM ) ;
# delimit;
svyset HOSP_NRD [pw=DISCWT], singleunit(cen) strata(NRD_STRATUM);

/* Subset on index events */
svy: total READMIT, subpop(INDEX_EVENT);
svy: mean READMIT, subpop(INDEX_EVENT);

/* Patient-level demographics */
/* "linearized*: Taylor-linearized variance estimation, see http://www.stata.com/manuals13/svysvy.pdf */
svy linearized: tab AGE_CAT  READMIT, col pearson;

svy linearized: tab SEX READMIT, col pearson;

svy linearized: tab PAYOR READMIT, col pearson;

svy linearized: tab ZIPINC_QRTL READMIT, col pearson;

svy linearized: tab HOSP_URCAT4 READMIT, col pearson;

svy linearized: tab CCI_CAT READMIT, col pearson;

svy linearized: tab CASELOAD_QUART READMIT, col pearson;

#delimit cr

xtmelogit READMIT, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART i.MINIMALLY_INVASIVE , or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART i.MINIMALLY_INVASIVE i.PAYOR, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART i.MINIMALLY_INVASIVE i.PAYOR i.H_CONTROL, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART i.MINIMALLY_INVASIVE i.PAYOR i.H_CONTROL i.ZIPINC_QRTL i.DMONTH, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART i.MINIMALLY_INVASIVE i.PAYOR i.H_CONTROL i.ZIPINC_QRTL i.HOSP_BEDSIZE i.DMONTH, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART i.MINIMALLY_INVASIVE i.PAYOR i.H_CONTROL i.ZIPINC_QRTL i.HOSP_BEDSIZE i.DMONTH c.LOS, or || HOSP_NRD: , intpoints(10) 
xtmelogit READMIT c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART i.MINIMALLY_INVASIVE i.PAYOR i.H_CONTROL i.ZIPINC_QRTL i.HOSP_BEDSIZE  i.DMONTH c.LOS c.INDEX_COSTS, or || HOSP_NRD: , intpoints(10) 

/***> Calculation of chi square values for partial R-square calculations (To calculate R-square use Excel-Calculator)*/
/* Patient-level socioeconomic demographics// combined patient level variables*/
testparm c.AGE i.SEX i.CCI_CAT i.CASELOAD_QUART i.MINIMALLY_INVASIVE i.PAYOR i.H_CONTROL i.ZIPINC_QRTL i.HOSP_BEDSIZE i.DMONTH c.LOS c.INDEX_COSTS 
/* Single patient-level variables*/
testparm c.AGE
testparm i.SEX 
testparm i.CCI_CAT 
testparm i.PAYOR
testparm i.ZIPINC_QRTL 
testparm i.MINIMALLY_INVASIVE 
/* Combined hospital level variables**/
testparm i.H_CONTROL i.HOSP_BEDSIZE i.CASELOAD_QUART 
/** Single hospital level variables**/
testparm i.H_CONTROL
testparm i.HOSP_BEDSIZE
testparm i.CASELOAD_QUART



/*BELOW HERE JUST PLAYING AROUND*/

logit READMIT i.ROBOT_ASSISTED i.CCI_CAT, or

tab ORPROC


logit READMIT c.CASELOAD



#delimit;
recode CHARLSON
	(4=4 "CCI 4")
	(5=5 "CCI 5")
	(6=6 "CCI 6")
	(7=7 "CCI 7")
	(8=8 "CCI 8")
	(9/14=9 "CCI 9+")
	(else=.),
	gen(CCI_CAT);

logit READMIT i.CCI_CAT, or	
	
logit READMIT i.PAY1, or	

logit READMIT c.CASELOAD

anova READMIT_RATE CASELOAD, o

logit READMIT c.CASELOAD

logit READMIT i.AGE_CAT i.CCI_CAT i.PAYOR  i.ROBOT_ASSISTED i.H_CONTROL i.HOSP_BEDSIZE i.CASELOAD_QUART c.LOS, or
logit READMIT i.AGE_CAT i.CHARLSON i.PAY1 i.RESIDENT i.H_CONTROL i.HOSP_BEDSIZE i.CASELOAD_QUART c.READMIT_RATE c.LOS, or;

graph box READMIT_RATE, by(READMIT);

twoway (scatter READMIT READMIT_RATE ) ;




separate READMIT_RATE, by(HOSP_UR_TEACH)
twoway (scatter READMIT_RATE0 CASELOAD) (scatter READMIT_RATE1 CASELOAD) 


  ytitle(Writing Score) legend(order(1 "Males" 2 "Females"))