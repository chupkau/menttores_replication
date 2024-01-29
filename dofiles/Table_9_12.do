

use "${DATA_CLEAN}tutoring_regression_dataset.dta", clear 

set scheme cleanplots


cap log close 
log using "${TEMP}\robustness_revision3_Jan2024.log", replace

**** TReatment probability by block 
/*
preserve
collapse (mean) treat (count) study_participants if study_participants==1, by(block_id)
gen obs=sum(study_participants)
su treat, det 
hist treat , bin(10 )fraction 
su study_participants, det
su obs
restore 

preserve
keep nb_groups_men_Final Workspace_men_Final
duplicates drop
su nb_groups_men_Final, det
restore 
*/

*** Summary Tables 



* Specs
local spec0 "i.block_id"
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"
local spec1 "i.grade i.age_student i.comunidad_1 i.gender 		i.math_grade i.lockdown_class i.device_available i.refuerzo_2  i.block_id"



* Recode math grade variable
	tab math_grade

* Mentor FEs
	g mentor_fe = Nombre_men_Final
	replace mentor_fe = "control" if Nombre_men_Final == ""
	encode mentor_fe, gen(mentor_fe2)
	drop mentor_fe
	ren mentor_fe2 mentor_fe
	lab var mentor_fe "Mentor dummies"
	
* Define standalone treatment variable different than "treat" (for labels in tables)
	gen treat_v2 = treat
	label define treat_v2 0 "Control" 1 "Treat"
	label values treat_v2 treat_v2
		
************************************** LOOP ************************************
forv v=1/1 { // two versions for each spec: all mentors, and only professional mentors

preserve
	if `v' == 2 {
		drop if Volun_men_Final == 1
		local prof = "_appendix"
	}
	else {
		local prof = ""
	}
	

* Academic outcomes [NEW VERSION] - TABLE 9

local spec0 "i.block_id"
local spec1 "i.grade i.age_student i.comunidad_1 i.gender 		i.math_grade i.lockdown_class i.device_available i.refuerzo_2  i.block_id"
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"



	clear matrix 
	local count=1

	foreach var in test_perc_std_gr final_mark_maths_pa pass_math failed_course {
	eststo clear 


	if "`var'" == "test_perc_std_gr" {
		forval i = 0/2 {
		    * block FE only plus adding controls
			eststo: reg `var' i.post##i.treat  `spec`i'', vce(cl ID)
			su `var' if treat==0 & period==0 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
		}
		
			* IPW 
			eststo: reg `var' i.post##i.treat `spec2' [pweight=weight_p], vce(cl ID)
			su `var' if treat==0 & period==0 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			local label : variable label `var'
			
			
			* [NEW]: Back to clustering at the block level and main spec 
			eststo: reg `var' i.post##i.treat `spec2' , vce(cl block_id)
			su `var' if treat==0 & period==0 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			local label : variable label `var'
			
			esttab _all using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
	replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(r2 Obs, fmt(2 0) labels("\$R^2\$" "Obs.")) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.post#1.treat _cons)  keep(1.post#1.treat _cons) mtitles("+Block FEs" "+Demog" "+SES" "+IPW" "Block cl.")    
		}
		
	else {
		forval i = 0/2 {
			eststo: reg `var' i.treat_v2  `spec`i'' if period==1, vce(cl ID)
			su `var' if treat==0 & period==1 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			}
			
			eststo: reg `var' i.treat_v2 `spec2' [pweight=weight_p] if period==1, vce(cl ID)
			su `var' if treat==0 & period==1 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			local label : variable label `var'
			
			
			* [NEW]: Back to clustering at the block level
			eststo: reg `var' i.treat_v2 `spec2' if period==1  , vce(cl block_id)
			su `var' if treat==0 & period==1 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			local label : variable label `var'	
			
			esttab _all using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
	replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(r2 Obs, fmt(2 0) labels("\$R^2\$" "Obs.")) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat_v2 _cons)  keep(1.treat_v2 _cons) mtitles("+Block FEs" "+Demog" "+SES" "+IPW"  "Block cl.")     
		}
	

	local ++count
	}
	
	do "$DO_FILES\programmes\make_panel_table.do"
	panelcombine, use(${TEMP}\PanelIE1.tex ${TEMP}\PanelIE2.tex ${TEMP}\PanelIE3.tex ${TEMP}\PanelIE4.tex)  columncount(5) paneltitles("Standardized test score" "Final math grade" "Passed math" "Repeated year" ) save("${OUTPUT}revision\table9`prof'.tex") cleanup
	clear matrix 


* Self-perceived ability and affinity [NEW VERSION] - TABLE 10

local spec0 "i.block_id"
local spec1 "i.grade i.age_student i.comunidad_1 i.gender 		i.math_grade i.lockdown_class i.device_available i.refuerzo_2  i.block_id"
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"


	clear matrix 
	local count=1

	foreach var in good_math good_language likemath likespanish {
	eststo clear 
	
	if ("`var'" == "good_math" | "`var'" == "good_language") {
		forval i = 0/2 {
			eststo: reg `var' i.post##i.treat  `spec`i'', vce(cl ID)
			su `var' if treat==0 & period==0 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			}
			eststo: reg `var' i.post##i.treat `spec2' [pweight=weight_p], vce(cl ID)
			su `var' if treat==0 & period==0 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			local label : variable label `var'
					
			* [NEW]: Back to clustering at the block level
			eststo: reg `var' i.post##i.treat `spec2'  , vce(cl block_id)
			su `var' if treat==0 & period==0 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			local label : variable label `var'
		
			esttab _all using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
	replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(r2 Obs, fmt(2 0) labels("\$R^2\$" "Obs.")) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.post#1.treat _cons)  keep(1.post#1.treat _cons) mtitles("+Block FEs" "+Demog" "+SES" "+IPW" "Block cl.")      
		}
		
	else {
		forval i = 0/2 {
			eststo: reg `var' i.treat_v2  `spec`i'' if period==1, vce(cl ID)
			su `var' if treat==0 & period==1 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			}
			
			eststo: reg `var' i.treat_v2 `spec2' [pweight=weight_p] if period==1, vce(cl ID)
			su `var' if treat==0 & period==1 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			local label : variable label `var'
			
			
			* [NEW]: Back to clustering at the block level
			eststo: reg `var' i.treat_v2 `spec2' if period==1 , vce(cl block_id)
			su `var' if treat==0 & period==1 & e(sample)==1
			estadd scalar meany=r(mean) 
			estadd scalar sdy=r(sd) 
			su `var' if e(sample)==1
			estadd scalar Obs=r(N)
			local label : variable label `var'	
		
			esttab _all using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
	replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(r2 Obs, fmt(2 0) labels("\$R^2\$" "Obs.")) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat_v2 _cons)  keep(1.treat_v2 _cons) mtitles("+Block FEs" "+Demog" "+SES" "+IPW"  "Block cl.")     
		}
	
	local ++count
	}
	
	
	do "$DO_FILES\programmes\make_panel_table.do"
	panelcombine, use(${TEMP}\PanelIE1.tex ${TEMP}\PanelIE2.tex ${TEMP}\PanelIE3.tex ${TEMP}\PanelIE4.tex  /* ${TEMP}\PanelIE5.tex  ${TEMP}\PanelIE6.tex  ${TEMP}\PanelIE7.tex ${TEMP}\PanelIE8.tex ${TEMP}\PanelIE9.tex */ )  columncount(5) paneltitles("Good at math" "Good at Spanish" "Likes math" "Likes Spanish" ) save("${OUTPUT}revision\table10`prof'.tex") cleanup
	clear matrix 


* Aspirations and motivations [NEW VERSION] - TABLE 11

local spec0 "i.block_id"
local spec1 "i.grade i.age_student i.comunidad_1 i.gender 		i.math_grade i.lockdown_class i.device_available i.refuerzo_2  i.block_id"
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"

		
	clear matrix 
	local count=1

	foreach var in after_eso2 college1 grit_score high_effort att_school_index {
	eststo clear 
	
	forval i = 0/2 {
		eststo: reg `var' i.treat_v2  `spec`i'' if period==1, vce(cl ID)
		su `var' if treat==0 & period==1 & e(sample)==1
		estadd scalar meany=r(mean) 
		estadd scalar sdy=r(sd) 
		su `var' if e(sample)==1
		estadd scalar Obs=r(N)
		}
		
		eststo: reg `var' i.treat_v2 `spec2' [pweight=weight_p] if period==1, vce(cl ID)
		su `var' if treat==0 & period==1 & e(sample)==1
		estadd scalar meany=r(mean) 
		estadd scalar sdy=r(sd) 
		su `var' if e(sample)==1
		estadd scalar Obs=r(N)
		local label : variable label `var'
		
	
		* [NEW]: Back to clustering at the block level
		eststo: reg `var' i.treat_v2 `spec2' if period==1, vce(cl block_id)
		su `var' if treat==0 & period==1 & e(sample)==1
		estadd scalar meany=r(mean) 
		estadd scalar sdy=r(sd) 
		su `var' if e(sample)==1
		estadd scalar Obs=r(N)
		local label : variable label `var'	
		
		esttab _all using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
	replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(r2 Obs, fmt(2 0) labels("\$R^2\$" "Obs.")) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat_v2 _cons)  keep(1.treat_v2 _cons) mtitles("+Block FEs" "+Demog" "+SES" "+IPW"  "Block cl.")   
		

	local ++count
	}
	
	do "$DO_FILES\programmes\make_panel_table.do"
	panelcombine, use(${TEMP}\PanelIE1.tex ${TEMP}\PanelIE2.tex ${TEMP}\PanelIE3.tex ${TEMP}\PanelIE4.tex  ${TEMP}\PanelIE5.tex /* ${TEMP}\PanelIE6.tex  ${TEMP}\PanelIE7.tex ${TEMP}\PanelIE8.tex ${TEMP}\PanelIE9.tex */ )  columncount(5) paneltitles("Bachillerato" "College" "Grit" "High effort" "Motivation school") save("${OUTPUT}revision\table11`prof'.tex") cleanup
	clear matrix 
	

* Socio-emotional outcomes [NEW VERSION] - TABLE 12

local spec0 "i.block_id"
local spec1 "i.grade i.age_student i.comunidad_1 i.gender 		i.math_grade i.lockdown_class i.device_available i.refuerzo_2  i.block_id"
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"
	
	clear matrix 
	local count=1

	foreach var in wellbeing_index school_satis loc_index  {
	eststo clear 
	
	forval i = 0/2 {
		eststo: reg `var' i.post##i.treat  `spec`i'', vce(cl ID)
		su `var' if treat==0 & period==0 & e(sample)==1
		estadd scalar meany=r(mean) 
		estadd scalar sdy=r(sd) 
		su `var' if e(sample)==1
		estadd scalar Obs=r(N)
	}
		
		eststo: reg `var' i.post##i.treat `spec2' [pweight=weight_p], vce(cl ID)
		su `var' if treat==0 & period==0 & e(sample)==1
		estadd scalar meany=r(mean) 
		estadd scalar sdy=r(sd) 
		su `var' if e(sample)==1
		estadd scalar Obs=r(N)
		local label : variable label `var'
		
		* [NEW]: Back to clustering at the block level
		eststo: reg `var' i.post##i.treat `spec2' , vce(cl block_id)
		su `var' if treat==0 & period==0 & e(sample)==1
		estadd scalar meany=r(mean) 
		estadd scalar sdy=r(sd) 
		su `var' if e(sample)==1
		estadd scalar Obs=r(N)
		local label : variable label `var'
		
		esttab _all using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
replace cells(b(fmt(3) star) se(fmt(3)  par)) stats(r2 Obs, fmt(2 0) labels("\$R^2\$" "Obs.")) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.post#1.treat _cons)  keep(1.post#1.treat _cons) mtitles("+Block FEs" "+Demog" "+SES" "+IPW"  "Block cl.")   
		
	local ++count
	}
	
	do "$DO_FILES\programmes\make_panel_table.do"
	panelcombine, use(${TEMP}\PanelIE1.tex ${TEMP}\PanelIE2.tex ${TEMP}\PanelIE3.tex   /* ${TEMP}\PanelIE5.tex  ${TEMP}\PanelIE6.tex  ${TEMP}\PanelIE7.tex ${TEMP}\PanelIE8.tex ${TEMP}\PanelIE9.tex */ )  columncount(5) paneltitles("Wellbeing index" "School satisfaction" "Locus of control") save("${OUTPUT}revision\table12`prof'.tex") cleanup
	clear matrix 

/*
*** Homework  
* Interval Regression 

local spec0 "i.block_id"
local spec1 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available i.refuerzo_2  i.block_id"
local spec2 "i.grade i.age_student i.comunidad_1 i.gender i.fsm i.math_grade i.lockdown_class i.device_available i.refuerzo_2  i.block_id  i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"

	clear matrix 
local count=1
	forval i = 0/2 {
	eststo: intreg homework_time_low homework_time_high i.treat `spec`i'' if  period==1, vce(cl ID)
	}
	esttab _all using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
	replace cells(b(fmt(3) star) se(fmt(3)  par)) star(* 0.10 ** 0.05 *** 0.01) collabels(none)   nonotes nogaps obslast label interaction(" x ") order(1.treat)  keep(1.treat _cons) mtitles("block FE" "+demog" "+SES" )    

	do "$DO_FILES\programmes\make_panel_table.do"
	panelcombine, use(${TEMP}\PanelIE1.tex)  columncount(3) paneltitles("All") save("${OUTPUT}tables\treat_homework_bygrade`prof'.tex") cleanup
	clear matrix 
	*/
restore
}	


log close 
ex
