**** LEEBOUNDS ****

use "${DATA_CLEAN}tutoring_regression_dataset.dta", clear 

set varabbrev off
eststo clear
set scheme cleanplots

ren final_mark_maths_pa final_marks // too long


* Specs
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"
local spec0 "i.block_id"

local test_std_t1_cont "c.test_perc_std_gr_base i.mi_bl_test_p"
local good_math_cont " i.good_math_base i.mi_bl_good_m"
local good_language_cont "c.good_language_base i.mi_bl_good_l"
local wellbeing_index_cont  "c.wellbeing_index_base i.mi_bl_wellbe"
local school_satis_cont " c.school_satis_base i.mi_bl_school"
local loc_index_cont  "c.loc_index_base i.mi_bl_loc_in"
gen one =1

foreach var in final_marks final_marks_fu  pass_math  failed_course failed_course_fu after_eso2 after_eso2_fu college1  college1_pa_fu grit_score high_effort att_school_index likemath likespanish {
	local `var'_cont "one"
}


bys block_id: egen share_treated = mean(treat)
gen inv_p_weight = (treat / share_treated) + (1-treat)/(1-share_treated)


* Lee (2008) bounds: non-dummies and/or unbounded outcomes
			ren test_perc_std_gr_t1 test_std_t1

	foreach var in  final_marks      {
		reg `var' i.treat `spec2' ``var'_cont' if period==1, vce(robust)
		local b_`var' = _b[1.treat]
		local se_`var' = _se[1.treat]
		local N_`var' = e(N)
		
		leebounds `var' treat if period==1 , vce(analytic) cie 
		local lb_`var' = _b[lower]
		local ub_`var' = _b[upper]
		
		local cil_`var' = e(cilower)
		local ciu_`var' = e(ciupper)
	}

* Behagel et al. (2009): bounded outcomes
	drop treat_real
	g treat_real = if_endline_survey*treat
	
	foreach var in pass_math failed_course  {
		preserve
			gen Y_MR=(`var'-1)*if_endline_survey /* lower bound*/
			replace Y_MR=0 if if_endline_survey==0
			gen Y_mR=(`var'-0)*if_endline_survey /* upper bound*/
			replace Y_mR=0 if if_endline_survey==0

			reg `var' i.treat `spec2' ``var'_cont' if period==1, vce(robust)
			local b_`var' = _b[1.treat]
			local se_`var' = _se[1.treat]
			local N_`var' = e(N)
			
			ivregress 2sls Y_MR (treat_real=treat) `spec2' if period==1, vce(robust)
			local lb_`var'=_b[treat_real] 
			local cil_`var' = _b[treat_real]-1.96*_se[treat_real]

			ivregress 2sls Y_mR (treat_real=treat) `spec2' if period==1, vce(robust)
			local ub_`var'=_b[treat_real] 
			local ciu_`var' = _b[treat_real]+1.96*_se[treat_real]
		restore
	}
	
/*
	foreach var in final_marks {
		preserve
			gen Y_MR=(`var'-10)*if_endline_survey /* lower bound*/
			replace Y_MR=0 if if_endline_survey==0
			gen Y_mR=(`var'-0)*if_endline_survey /* upper bound*/
			replace Y_mR=0 if if_endline_survey==0

			reg `var' i.treat `spec2' if period==1, vce(cl ID)
			local b_`var' = _b[1.treat]
			local se_`var' = _se[1.treat]
			local N_`var' = e(N)
			
			ivregress 2sls Y_MR (treat_real=treat) `spec2' if period==1, vce(robust)
			local lb_`var'=_b[treat_real] 
			local cil_`var' = _b[treat_real]-1.96*_se[treat_real]

			ivregress 2sls Y_mR (treat_real=treat) `spec2' if period==1, vce(robust)
			local ub_`var'=_b[treat_real] 
			local ciu_`var' = _b[treat_real]+1.96*_se[treat_real]
		restore
	}
	
*/
	* Table
		cap file close summary
		file open summary using "${OUTPUT}/revision/tableA3_leebounds_parentreported.tex", write replace	
		file write summary "{" _n
		file write summary "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n
		file write summary  "\begin{tabular}{l*{7}{c}} \hline" _n
		file write summary  "Outcome & N & ITT estimate & Bound type & Lower bound & Upper bound & Confidence Interval  \\ \hline " _n
		file write summary  "\quad \textbf{Parent-reported outcomes} \\" _n
		file write summary  " Final math grade & \MyNumBis{`N_final_marks'} & \MyNum{`b_final_marks'} (\MyNum{`se_final_marks'}) & \cite{lee2009} & \MyNum{`lb_final_marks'} & \MyNum{`ub_final_marks'} & [\MyNum{`cil_final_marks'}, \MyNum{`ciu_final_marks'}] \\  " _n
		file write summary  " Passed math & \MyNumBis{`N_pass_math'} & \MyNum{`b_pass_math'} (\MyNum{`se_pass_math'}) & \cite{behagel2009} & \MyNum{`lb_pass_math'} & \MyNum{`ub_pass_math'} & [\MyNum{`cil_pass_math'}, \MyNum{`ciu_pass_math'}] \\  " _n
		file write summary  " Repeated year & \MyNumBis{`N_failed_course'} & \MyNum{`b_failed_course'} (\MyNum{`se_failed_course'}) & \cite{behagel2009}  & \MyNum{`lb_failed_course'} & \MyNum{`ub_failed_course'} & [\MyNum{`cil_failed_course'}, \MyNum{`ciu_failed_course'}] \\  " _n


		file write summary "\hline" _n

		file write summary  "\end{tabular}" _n	
		file write summary "}" _n
		file close summary
		type  "${OUTPUT}/revision/tableA3_leebounds_parentreported.tex"
		
		ex
		
/*
	
	

		ren final_mark_maths_pa_fu final_marks_fu 
			ren failed_course_pa_fu failed_course_fu
			ren after_eso2_pa_fu after_eso2_fu
			foreach var in final_marks pass_math    failed_course  after_eso2  college1  {
				reg `var' i.treat `spec2'  if period==1, vce(robust)
				leebounds `var' treat if period==1, vce(analytic) cie tight(if_fail language_home_2 )
			}

			
**** Tighter Bounds when outcome binary - Example passed math (in math) 

*** 1 PASS MATH 
preserve
drop treat_real
g treat_real = if_endline_survey*treat

* estimated effect for passing maths : 
reg pass_math i.treat `spec2'  if period==1, vce(robust)
local treat=_b[1.treat] 

reg if_endline_survey i.treat `spec2'  if period==1, vce(robust)
local difference_response=_b[1.treat]

reg treat_real i.treat  `spec2'  if period==1, vce(robust)
local compliance_respondents=_b[1.treat]

local diffmanual = `difference_response'/`compliance_respondents'

gen Y_MR=(pass_math-1)*if_endline_survey /* lower bound*/
replace Y_MR=0 if if_endline_survey==0
gen Y_mR=(pass_math-0)*if_endline_survey /* upper bound*/
replace Y_mR=0 if if_endline_survey==0

ivregress 2sls Y_MR (treat_real=treat) `spec2' if period==1, vce(robust)
local lb=_b[treat_real] 
ivregress 2sls Y_mR (treat_real=treat) `spec2' if period==1, vce(robust)
local ub=_b[treat_real] 
display "length_interval `lb'-`ub'"
display "lower bound: "
display `lb'
display "upper bound:"
display `ub'
display `lb'-`ub'
display "The length computed manually is `diffmanual'"

leebounds pass_math treat if period==1, vce(analytic) cie 
*xi: leebounds pass_math treat if period==1, vce(analytic) cie tight(`spec2')
restore 

* 2 failed_course: bounded between 0 and 1
preserve 

replace if_endline_survey=0 if if_endline_survey==1 & failed_course==. /* there are some people for whom we have failed course missing, but who did respond to endline. therefore we had a difference in the number of observations between the manual calculations and the 2sls regressions */

reg failed_course i.treat `spec2'  if period==1, vce(robust)
local treat=_b[1.treat] 

reg if_endline_survey i.treat `spec2'  if period==1, vce(robust)
local difference_response=_b[1.treat]

reg treat_real i.treat  `spec2'  if period==1, vce(robust)
local compliance_respondents=_b[1.treat]

local diffmanual = `difference_response'/`compliance_respondents'


gen Y_MR=(failed_course-1)*if_endline_survey /* lower bound* - The outcome variable takes values -1 (for those who have responded and passed) and 0 (for everyone else).*/
replace Y_MR=0 if if_endline_survey==0 
gen Y_mR=(failed_course-0)*if_endline_survey /* upper bound - o	The outcome variable takes values 1 for those who responded and passed and 0 (for everyone else).*/
replace Y_mR=0 if if_endline_survey==0 

su Y_MR Y_mR

ivregress 2sls Y_MR (treat_real=treat) `spec2' if period==1, vce(robust)
local lb=_b[treat_real] 
ivregress 2sls Y_mR (treat_real=treat) `spec2' if period==1, vce(robust)
local ub=_b[treat_real] 
display "length_interval `lb'-`ub'"
display "lower bound: 
display `lb'
display "upper bound:"
display `ub'
display `lb'-`ub'
display "The length computed manually is `diffmanual'"

leebounds failed_course treat if period==1, vce(analytic) cie 

restore


*** now loop through outcomes
foreach var in  pass_math  failed_course  after_eso2  college1  {
				reg `var' i.treat `spec2'  if period==1, vce(robust)
				leebounds `var' treat if period==1, vce(analytic) cie tight(if_fail language_home_2 )
			}

