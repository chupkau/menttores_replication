



use "${DATA_CLEAN}replication_dataset.dta", clear 

set varabbrev off
eststo clear
set scheme cleanplots

* Specs
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"
local spec0 "i.block_id"



gen test_perc_std_gr_base2=test_perc_std_gr_base^2
gen test_perc_std_gr_base3=test_perc_std_gr_base^3
gen test_perc_std_gr_base4=test_perc_std_gr_base^4    

local test_std_t1_cont "c.test_perc_std_gr_base i.mi_bl_test_p c.test_perc_std_gr_base2"
local good_math_cont " i.good_math_base i.mi_bl_good_m"
local good_language_cont "c.good_language_base i.mi_bl_good_l"
local wellb_cont  "c.wellbeing_index_base i.mi_bl_wellbe"
local school_satis_cont " c.school_satis_base i.mi_bl_school"
local loc_index_cont  "c.loc_index_base i.mi_bl_loc_in"
gen one =1

foreach var in final_marks final_marks_fu  pass_math  failed_course failed_course_fu after_eso2 after_eso2_fu college1  college1_pa_fu grit_score high_effort att_school_index likemath likespanish {
	local `var'_cont "one"
}

* Standard treatment
	gen treat_v2 = treat
	label define treat_v2 0 "Control" 1 "Treat"
	label values treat_v2 treat_v2

* Start loop

forv v=1/1 { // two versions for each spec: all mentors, and only professional mentors
	foreach sp in 2 { 
		preserve
			
			* Define sets of locals for defining file names for tables
			if `v' == 2 {
				drop if Volun_men_Final == 1
				local prof = "_appendix"
			}
			else {
				local prof = ""
			}
			
			if `sp' == 2 {
				local nocont = ""
			}
			else {
				local nocont = "_nocont"
			}
			
			
			eststo clear 
			
			* DiD outcomes - non DID 
			ren test_perc_std_gr_t1 test_std_t1
			ren wellbeing_index wellb
			foreach var in test_std_t1 good_math wellb school_satis loc_index good_language {
				reg `var' i.treat  `spec`sp'' ``var'_cont' if period==1, vce(robust)
				est store `var'`prof'_`sp'_noDID
				su `var' if treat==0 & period==1 & e(sample)==1
				estadd scalar meany=r(mean) 
				estadd scalar sdy=r(sd) 
				su `var' if e(sample)==1
				estadd scalar Obs=r(N)
				distinct ID if e(sample)==1
				estadd scalar unique=r(ndistinct)
				
				
			}
	* DiD outcomes - DID 
			foreach var in test_perc_std_gr good_math wellb school_satis loc_index good_language {
				reg `var' i.treat##i.post  `spec`sp'', vce(cl ID)
				est store `var'`prof'_`sp'_DID
				su `var' if treat==0 & period==0 & e(sample)==1
				estadd scalar meany=r(mean) 
				estadd scalar sdy=r(sd) 
				su `var' if e(sample)==1
				estadd scalar Obs=r(N)
				distinct ID if e(sample)==1
				estadd scalar unique=r(ndistinct)
				
			}
			
			* Main tables ------------------------------------------------------
			
			
esttab test_perc_std_gr`prof'_`sp'_DID test_std_t1`prof'_`sp'_noDID good_math`prof'_`sp'_DID good_math`prof'_`sp'_noDID good_language`prof'_`sp'_DID good_language`prof'_`sp'_noDID   wellb`prof'_`sp'_DID wellb`prof'_`sp'_noDID school_satis`prof'_`sp'_DID school_satis`prof'_`sp'_noDID loc_index`prof'_`sp'_DID loc_index`prof'_`sp'_noDID using "${OUTPUT}revision\table13.tex", style(tex)  ///
replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(meany sdy r2 Obs , fmt(2 2 2 0 0)  labels("Mean dep. var." "SD dep. var." "\$R^2\$" "Obs.")) varwidth(25) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat 1.post 1.treat#1.post _cons)  keep(1.treat 1.post 1.treat#1.post _cons) mgroups("\shortstack{Standardized\\test score}" "\shortstack{Good at\\math}" "\shortstack{Good at\\Spanish}" "\shortstack{Wellbeing\\index}" "\shortstack{School\\satisfaction}" "\shortstack{Locus of\\control}" , pattern(1 0 1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))    mtitles("\shortstack{DID}" "\shortstack{Lagged\\dep. var}" "\shortstack{DID}" "\shortstack{Lagged\\dep. var}" "\shortstack{DID}" "\shortstack{Lagged\\dep. var}" "\shortstack{DID}" "\shortstack{Lagged\\dep. var}" "\shortstack{DID}" "\shortstack{Lagged\\dep. var}" "\shortstack{DID}" "\shortstack{Lagged\\dep. var}") 

				
		restore
	}
}



set varabbrev on


* testing for equaliy of coefficients 

** STANDARDIZED TEST 
* non DID model
reg test_perc_std_gr_t1 i.treat c.test_perc_std_gr_base i.mi_bl_test_p c.test_perc_std_gr_base2 i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9  if period==1
est store m1
* DID model 
reg test_perc_std_gr i.post##i.treat i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9 
est store m2

suest m1 m2, vce(cluster ID)
*test [m1_mean=m2_mean], cons common
lincom _b[m1_mean:1.treat] - _b[m2_mean:1.treat#1.post]

****
* GOOD at MATH 
* non DID model 
reg good_math i.treat i.good_math_base i.mi_bl_good_m i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9  if period==1
est store m1
* DID model 
reg good_math i.post##i.treat i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9 
est store m2

suest m1 m2, vce(cluster ID)
*test [m1_mean=m2_mean], cons common
lincom _b[m1_mean:1.treat] - _b[m2_mean:1.treat#1.post]


****
* Good at Spanish 
reg good_language i.treat i.good_language_base i.mi_bl_good_l i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9  if period==1
est store m1
* DID model 
reg good_language i.post##i.treat i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9 
est store m2

suest m1 m2, vce(cluster ID)
*test [m1_mean=m2_mean], cons common
lincom _b[m1_mean:1.treat] - _b[m2_mean:1.treat#1.post]

***
* Wellbeing index 
* no DID 
reg  wellbeing_index i.treat  c.wellbeing_index_base i.mi_bl_wellbe i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9  if period==1
est store m1
* DID model 
reg wellbeing_index i.post##i.treat i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9 
est store m2

suest m1 m2, vce(cluster ID)
*test [m1_mean=m2_mean], cons common
lincom _b[m1_mean:1.treat] - _b[m2_mean:1.treat#1.post]



*** 
* School Satisfaction 
* no DID 
reg  school_satis i.treat  c.school_satis_base i.mi_bl_school i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9  if period==1
est store m1
* DID model 
reg school_satis i.post##i.treat i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9 
est store m2

suest m1 m2, vce(cluster ID)
*test [m1_mean=m2_mean], cons common
lincom _b[m1_mean:1.treat] - _b[m2_mean:1.treat#1.post]

*** 
* Locus of Contol  
* no DID 
reg  loc_index i.treat  c.loc_index_base i.mi_bl_loc_in i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9  if period==1
est store m1
* DID model 
reg loc_index i.post##i.treat i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9 
est store m2

suest m1 m2, vce(cluster ID)
*test [m1_mean=m2_mean], cons common
lincom _b[m1_mean:1.treat] - _b[m2_mean:1.treat#1.post]





** FIGURE 5 

reg test_perc_std_gr_t1 i.treat i.treat#c.test_perc_std_gr_base  c.test_perc_std_gr_base i.mi_bl_test_p i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9  if period==1, vce(robust)
margins, dydx(treat) at(test_perc_std_gr_base = (-2(0.25)2))
marginsplot, xlabel(-2(0.25)2) title("") level(90) ytitle(ITT effect)
graph export "${OUTPUT}figures\marginsplot_test_scores.pdf", as(pdf) replace  

reg wellbeing_index i.treat i.treat#c.wellbeing_index_base  c.wellbeing_index_base i.mi_bl_wellbe i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9  if period==1 , vce(robust)

margins treat, at(wellbeing_index_base=(1.5(2)16))
marginsplot, xlabel(1.5(2)16) 
