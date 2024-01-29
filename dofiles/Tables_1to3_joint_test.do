

use "${DATA_CLEAN}tutoring_regression_dataset.dta", clear 

bys ID: egen partial_response_end_ext=max(partial_response_end)


keep if period==0
drop if_endline_survey

drop partial_response_end 
ren partial_response_end_ext  partial_response_end


set varabbrev on
eststo clear
set scheme cleanplots

merge 1:1 ID using "${DATA_CLEAN}\endline_survey_parents_clean.dta", keepusing(if_endline_survey)
drop if _m==2
drop _m

bys ID: gen test_score_percent_bl=test_score_percent if period==0
bys ID: egen test_score_percent_bl_ext=max(test_score_percent_bl)

replace test_score_percent_bl=test_score_percent_bl_ext
drop test_score_percent_bl_ext

label variable test_score_percent_bl "Test score (\%) at baseline"

gen mi_bl=(test_score_percent_bl==.)	
label var mi_bl "Missing baseline test score"
replace test_score_percent_bl=0 if test_score_percent_bl==.

* Specs
local spec2 "curso_2 age_student public comunidad_1 gender_1  fsm_2 lockdown_class_little device_available_1 refuerzo_2 if_fail_math_2  if_fail_2 repeated_1plus math_grade_2 math_grade_3 test_score_percent_bl i.mi_bl spanish_catalan education_below income_below hh_persons_b18 couple_1 countr_origin_parent_9 i.block_id"
local spec0 "i.block_id"


global vars_child "age_student gender_1 countr_origin_child_7 curso_2 public comunidad_1  fsm_2 lockdown_class_little device_available_1 internet refuerzo_2    " 
global vars_hh "relation_ch_2 couple_1 countr_origin_parent_9 spanish_catalan education_below income_below hh_persons hh_persons_b18 age_youngest "
global math_grade "if_fail_math_2  if_fail_2 repeated_1plus  math_grade_2 math_grade_3 test_score_percent_bl"

forv v=1/3 { // two versions for each spec: baseline and endline, and only professional mentors
	foreach sp in 2 { 
		preserve
			
			* Define sets of locals for defining file names for tables
			if `v' == 2 {
				drop if if_endline_survey == 0
				local prof = "_endline_parent"
			}
			else if `v' == 3 {
				drop if partial_response_end == 0
				local prof = "_endline_child"
			}
			else if `v' == 1 {
				local prof = "_baseline"
			}
			
			if `sp' == 2 {
				local nocont = ""
			}
			else {
				local nocont = "_nocont"
			}
			
			di "`v' `prof'"
		
			
			eststo clear 

reg treat `spec`sp'' if period==0, vce(robust)
est store balance`prof'_`sp'
estadd scalar Obs=e(N)

testparm age_student gender_1 countr_origin_child_7 curso_2 public comunidad_1  fsm_2 lockdown_class_little device_available_1 internet refuerzo_2 if_fail_math_2  if_fail_2 repeated_1plus  math_grade_2 math_grade_3 test_score_percent_bl relation_ch_2 couple_1 countr_origin_parent_9 spanish_catalan education_below income_below hh_persons hh_persons_b18 age_youngest
estadd scalar Fstat=r(F)
estadd scalar pval=r(p)

	}
	
esttab balance`prof'_2 using "${OUTPUT}revision\joint_test_balance`nocont'`prof'.tex", style(tex) wide ///
replace stats(Fstat pval r2 Obs, fmt(3 3 2 0 0) labels("F-Stat." "p-value" "\$R^2\$" "Obs." "Unique ind.")) varwidth(25) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label  keep(curso_2 age_student public comunidad_1 gender_1  fsm_2 lockdown_class_little device_available_1 refuerzo_2 if_fail_math_2  if_fail_2 repeated_1plus  math_grade_2 math_grade_3 test_score_percent_bl spanish_catalan education_below income_below hh_persons_b18 couple_1 countr_origin_parent_9) order(curso_2 age_student public comunidad_1 gender_1  fsm_2 lockdown_class_little device_available_1 refuerzo_2 if_fail_math_2  if_fail_2 repeated_1plus  math_grade_2 math_grade_3 test_score_percent_bl spanish_catalan education_below income_below hh_persons_b18 couple_1 countr_origin_parent_9) mtitles("\shortstack{Treat}" ) refcat(curso_2 "\quad \textit{Child characteristics}"  if_fail_math_2 "\quad \textit{Baseline performance}" spanish_catalan "\quad \textit{Parental/household characteristics}" 1.couple "\quad \textit{Parental characteristics}", nolabel) b(3) p(3)
		
	
		restore
	}

set varabbrev on
ex


