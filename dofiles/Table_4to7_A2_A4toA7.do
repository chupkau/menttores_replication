
cap log close 
log using "${TEMP}\main_results_revision3_Jan2024.log", replace



use "${DATA_CLEAN}tutoring_regression_dataset.dta", clear 

set varabbrev off
eststo clear
set scheme cleanplots

*CHECKS

ren final_mark_maths_pa final_marks // too long
			ren final_mark_maths_pa_fu final_marks_fu 
			ren failed_course_pa_fu failed_course_fu
			ren after_eso2_pa_fu after_eso2_fu

gen treat_post=treat*post 


* Specs
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"

local spec0 "i.block_id"




* Standard treatment
	gen treat_v2 = treat
	label define treat_v2 0 "Control" 1 "Treat"
	label values treat_v2 treat_v2

* Continuous treatment
	gen hours_tutoring = minutes/60 // put in hours
	gen treat_con = treat*hours_tutoring
	replace treat_con = 0 if treat == 0

	gen treat_con_v2 = treat_con
	lab var treat_con_v2 "Treat x Nb. hours"
	label define treat_con_v2 0 "Control" 1 "Treat x Nb. hours"
	label values treat_con_v2 treat_con_v2
	lab var treat_con "Treat"

* Start loop

forv v=1/2 { // two versions for each spec: all mentors, and only professional mentors
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
			
			* DiD outcomes
			foreach var in test_perc_std_gr good_math wellbeing_index school_satis loc_index good_language {
				reg `var' i.treat##i.post  `spec`sp'', vce(cl ID)
				est store `var'`prof'_`sp'
				su `var' if treat==0 & period==0 & e(sample)==1
				estadd scalar meany=r(mean) 
				estadd scalar sdy=r(sd) 
				su `var' if e(sample)==1
				estadd scalar Obs=r(N)
				distinct ID if e(sample)==1
				estadd scalar unique=r(ndistinct)
				
			}
			
			* Non-DiD outcomes
			
			foreach var in final_marks final_marks_fu pass_math failed_course failed_course_fu after_eso2 after_eso2_fu college1  college1_pa_fu grit_score high_effort time_schoolwork att_school_index likemath likespanish  {
				reg `var' i.treat `spec`sp''  if period==1, vce(robust)
				est store `var'`prof'_`sp'
				su `var' if treat==0 & period==1 & e(sample)==1
				estadd scalar meany=r(mean) 
				estadd scalar sdy=r(sd) 
				su `var' if e(sample)==1
				estadd scalar Obs=r(N)
				

			}
			
			* Main tables ------------------------------------------------------
			
/* This is Table 4 and Table A4*/			
esttab test_perc_std_gr`prof'_`sp' final_marks`prof'_`sp' pass_math`prof'_`sp' failed_course`prof'_`sp' using "${OUTPUT}revision\table4`nocont'`prof'_noRW.tex", style(tex)  ///
replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(meany sdy r2 Obs unique , fmt(2 2 2 0 0)  labels("Mean dep. var." "SD dep. var." "\$R^2\$" "Obs." "Unique ind.")) varwidth(25) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat 1.post 1.treat#1.post _cons)  keep(1.treat 1.post 1.treat#1.post _cons) mgroups("\shortstack{In-class\\test}" "Parent-reported", pattern(1 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mtitles("\shortstack{Standardized\\test score}" "\shortstack{Final math\\grade}" "\shortstack{Passed\\math}" "\shortstack{Repeated\\year}") 


/* This is table A2*/ 
esttab final_marks_fu`prof'_`sp' failed_course_fu`prof'_`sp' after_eso2_fu`prof'_`sp' college1_pa_fu`prof'_`sp' using "${OUTPUT}revision\tableA2`nocont'`prof'_noRW.tex", style(tex)  ///
replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(meany sdy r2 Obs  , fmt(2 2 2 0 )  labels("Mean dep. var." "SD dep. var." "\$R^2\$" "Obs." )) varwidth(25) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label  order(1.treat _cons)  keep(1.treat _cons) mgroups("Parent-reported", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  mtitles("\shortstack{Final math grade\\1 year later}"  "\shortstack{Repeated year\\1 year later}" "\shortstack{Bachillerato\\1 year later}" "\shortstack{College\\1 year later}") 

/* Table 7 and A7*/
			esttab wellbeing_index`prof'_`sp' school_satis`prof'_`sp' loc_index`prof'_`sp'  using "${OUTPUT}revision\table7`nocont'`prof'_noRW.tex", style(tex)  ///
replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(meany sdy r2 Obs unique , fmt(2 2 2 0 0) labels("Mean dep. var." "SD dep. var." "\$R^2\$" "Obs." "Unique ind." )) varwidth(25) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat 1.post 1.treat#1.post _cons)  keep(1.treat 1.post 1.treat#1.post _cons) mgroups("In-class test", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  mtitles("\shortstack{Wellbeing\\index}" "\shortstack{School\\satisfaction}" "\shortstack{Locus of\\control}") 


/* Table 6 and A6*/
			esttab after_eso2`prof'_`sp' college1`prof'_`sp' grit_score`prof'_`sp' high_effort`prof'_`sp' att_school_index`prof'_`sp'  using "${OUTPUT}revision\table6`nocont'`prof'_noRW.tex", style(tex)  ///
replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(meany sdy r2 Obs , fmt(2 2 2 0 0) labels("Mean dep. var." "SD dep. var." "\$R^2\$" "Obs." )) varwidth(25) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat _cons)  keep(1.treat _cons) mgroups("In-class test", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  mtitles("\shortstack{Bachi\\llerato}" "\shortstack{College\\\hspace{40 mm}}" "\shortstack{Grit\\\hspace{40 mm}}" "\shortstack{High\\effort}" "\shortstack{Motivation\\school}"  ) 

/* Table 5 and A5*/
			esttab good_math`prof'_`sp' good_language`prof'_`sp' likemath`prof'_`sp' likespanish`prof'_`sp' using "${OUTPUT}revision\table5`nocont'`prof'_noRW.tex", style(tex)  ///
replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(meany sdy r2 Obs unique , fmt(2 2 2 0 0) labels("Mean dep. var." "SD dep. var." "\$R^2\$" "Obs." "Unique ind."  )) varwidth(25) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat 1.post 1.treat#1.post 1.treat _cons)  keep(1.treat 1.post 1.treat#1.post _cons) mgroups("In-class test", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  mtitles("\shortstack{Good at\\math}" "\shortstack{Good at\\Spanish}"   "\shortstack{Likes\\math}"  "\shortstack{Likes\\Spanish}" ) 
		
			

		restore
	}
}


set varabbrev on
cap log close 
ex

cap log close 
log using "${TEMP}\log_RWolf_PVALS_Jan2024.log", replace


* Specs
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"
local spec0 "i.block_id"


* Group 1 - math achievment - table 4
	foreach sp in 2 { 

rwolf2 (reg test_perc_std_gr treat_post i.treat i.post `spec`sp'', vce(cl ID)) ///
 (reg final_marks treat `spec`sp''  if period==1, vce(robust)) ///
(reg pass_math treat `spec`sp''  if period==1, vce(robust)) ///
(reg failed_course treat `spec`sp''  if period==1, vce(robust)), ///
indepvars(treat_post, treat, treat, treat) ///
usevalid seed(123) reps(10000)
	}

* Group 2 - table 5
	foreach sp in 2 { 

rwolf2 (reg good_math treat_post i.treat i.post `spec`sp'', vce(cl ID)) ///
(reg good_language treat_post i.treat i.post `spec`sp'', vce(cl ID)) ///
(reg likemath treat `spec`sp''  if period==1, vce(robust)) ///
(reg likespanish treat `spec`sp''  if period==1, vce(robust)), ///
indepvars(treat_post, treat_post, treat, treat) ///
usevalid seed(123) reps(10000)
	}


	
* Group 3 - table 6 
	foreach sp in 2 { 

rwolf2 (reg after_eso2 treat `spec`sp''  if period==1, vce(robust)) ///
(reg college1 treat `spec`sp''  if period==1, vce(robust)), ///
indepvars(treat, treat) ///
usevalid seed(123) reps(10000)
}


* Group 4 - table 6 
	foreach sp in 2 { 

rwolf2 (reg grit_score treat `spec`sp''  if period==1, vce(robust)) ///
(reg high_effort treat `spec`sp''  if period==1, vce(robust)) ///
(reg att_school_index treat `spec`sp''  if period==1, vce(robust)), ///
indepvars(treat, treat, treat) ///
usevalid seed(123) reps(10000)
}
	
	
* Group 4 - table 7
  	foreach sp in 2 { 
rwolf2 (reg wellbeing_index treat_post i.treat i.post `spec`sp'', vce(cl ID)) ///
(reg school_satis treat_post i.treat i.post `spec`sp'', vce(cl ID)) ///
(reg loc_index treat_post i.treat i.post `spec`sp'', vce(cl ID)), ///
indepvars(treat_post, treat_post, treat_post) ///
usevalid seed(123) reps(10000)
}

cap log close 


