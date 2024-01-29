**** LEEBOUNDS ****

use "${DATA_CLEAN}tutoring_regression_dataset.dta", clear 

set varabbrev off
eststo clear
set scheme cleanplots

* Specs
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"
local spec0 "i.block_id"
local spec1 " "
ren final_mark_maths_pa final_marks // too long

	foreach var in test_perc_std_gr final_marks pass_math failed_course likemath likespanish good_math good_language after_eso2 college1 grit_score high_effort att_school_index wellbeing_index school_satis loc_index {
	
		g mi_`var' = (`var'==.)
		
		reg mi_`var' i.treat `spec0' if period==1, vce(robust)
		su mi_`var' if treat==0 & period==1 & e(sample)==1
		local cm_`var' = `r(mean)'
		local b_`var' = _b[1.treat]
		local se_`var' = _se[1.treat]
		local N_`var' = e(N)
		
	}

	* Table
		cap file close summary
		file open summary using "${OUTPUT}/revision/tableA1_missingoutcomes.tex", write replace	
		file write summary "{" _n
		file write summary "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n
		file write summary  "\begin{tabular}{l*{2}{c}} \hline" _n 
		file write summary  " & (1) & (2) \\ " _n
		file write summary  "Outcome & Control mean & Treatment/Control \\ " _n
		file write summary  " &  & Difference \\ \hline " _n

		file write summary  "\quad \textbf{Academic} \\" _n
		file write summary  " Standardized math test & \MyNum{`cm_test_perc_std_gr'} & \MyNum{`b_test_perc_std_gr'} (\MyNum{`se_test_perc_std_gr'}) \\  " _n
		file write summary  " Final math grade (parent-survey) & \MyNum{`cm_final_marks'} & \MyNum{`b_final_marks'} (\MyNum{`se_final_marks'}) \\  " _n
		file write summary  " Passed math (parent-survey)  & \MyNum{`cm_pass_math'} & \MyNum{`b_pass_math'} (\MyNum{`se_pass_math'}) \\  " _n
		file write summary  " Repeated year (parent-survey)  & \MyNum{`cm_failed_course'} & \MyNum{`b_failed_course'} (\MyNum{`se_failed_course'}) \\  " _n
		file write summary  "\quad \textbf{Self-perceived ability and affinity} \\" _n
		file write summary  " Liked math & \MyNum{`cm_likemath'} & \MyNum{`b_likemath'} (\MyNum{`se_likemath'}) \\  " _n
		file write summary  " Liked Spanish & \MyNum{`cm_likespanish'} & \MyNum{`b_likespanish'} (\MyNum{`se_likespanish'}) \\  " _n
		file write summary  " Good at math & \MyNum{`cm_good_math'} & \MyNum{`b_good_math'} (\MyNum{`se_good_math'}) \\  " _n
		file write summary  " Good at Spanish  & \MyNum{`cm_good_language'} & \MyNum{`b_good_language'} (\MyNum{`se_good_language'}) \\  " _n
		file write summary  "\quad \textbf{Aspirations and motivation} \\" _n
		file write summary  " Bachillerato & \MyNum{`cm_after_eso2'} & \MyNum{`b_after_eso2'} (\MyNum{`se_after_eso2'}) \\  " _n
		file write summary  " College & \MyNum{`cm_college1'} & \MyNum{`b_college1'} (\MyNum{`se_college1'}) \\  " _n
		file write summary  " Grit score  & \MyNum{`cm_grit_score'} & \MyNum{`b_grit_score'} (\MyNum{`se_grit_score'}) \\  " _n
		file write summary  " High effort  & \MyNum{`cm_high_effort'} & \MyNum{`b_high_effort'} (\MyNum{`se_high_effort'}) \\  " _n
		file write summary  " Motivation school index  & \MyNum{`cm_att_school_index'} & \MyNum{`b_att_school_index'} (\MyNum{`se_att_school_index'}) \\  " _n
		file write summary  "\quad \textbf{Socio-emotional outcomes} \\" _n
		file write summary  " Wellbeing index  & \MyNum{`cm_wellbeing_index'} & \MyNum{`b_wellbeing_index'} (\MyNum{`se_wellbeing_index'}) \\  " _n
		file write summary  " School satisfaction  & \MyNum{`cm_school_satis'} & \MyNum{`b_school_satis'} (\MyNum{`se_school_satis'}) \\  " _n
		file write summary  "  Locus of control index  & \MyNum{`cm_loc_index'} & \MyNum{`b_loc_index'} (\MyNum{`se_loc_index'}) \\  " _n

		file write summary "\hline" _n

		file write summary  "\end{tabular}" _n	
		file write summary "}" _n
		file close summary
		type  "${OUTPUT}/revision/tableA1_missingoutcomes.tex"
		
		ex
	