



use "${DATA_CLEAN}tutoring_regression_dataset.dta", clear 

cap log close 
log using "${TEMP}\heterogeneous_effects_1.log", replace

set varabbrev off
eststo clear

* Specs
local spec2 "i.grade i.age_student i.comunidad_1 i.gender  i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2 i.school_id i.block_id i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9"
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


	
* Het effects interactions
	g dummy4 = low_SES
	g dummy9 = same_baseline_p50
	
	g treat1 = treat_good
	g treat2 = treat_tablet
	g treat3 = treat_girl
	g treat4 = treat_sing
	g treat5 = treat_2ESO
	g treat6 = treat_immi
	g treat7 = treat_tutor_st_same_gender
	g treat8 = treat_same_gender
	g treat9 = treat_same_baseline
	g treat10 = treat_below_median
	
	g maineffect1=good_connection /* drops because only defined for treated*/
	g maineffect2=tablet_sessions /* drops because only defined for treated*/
	g maineffect3=1 /* should drop because we already control for gender- however for some reason it does not drop so i just include here a dummy equal to one*/
	g maineffect4=couple_2 /* should drop*/
	g maineffect5=curso_2 /* should drop*/
	g maineffect6=immi /* should drop*/
	g maineffect7=tutor_st_same_gender /* should drop as only defined for treated*/
	g maineffect8=same_gender /*should drop as only defined for treated*/
	g maineffect9=same_baseline_p50 /* should drop as only defined for treated*/
	g maineffect10=below_median /* should NOT drop*/

	
	g maineffectdid1=post*good_connection
	g maineffectdid2=post*tablet_sessions
	g maineffectdid3=post*girl
	g maineffectdid4=post*couple_2
	g maineffectdid5=post*curso_2
	g maineffectdid6=post*immi
	g maineffectdid7=post*tutor_st_same_gender
	g maineffectdid8=post*same_gender
	g maineffectdid9=post*same_baseline_p50
	g maineffectdid10=post*below_median
	
	g coef1did = treat_good
	g coef2did = treat_tablet
	g coef3did = treat_girl
	g coef4did = treat_sing
	g coef5did = treat_2ESO
	g coef6did = treat_immi
	g coef7did = treat_tutor_st_same_gender
	g coef8did = treat_same_gender
	g coef9did = treat_same_baseline
	g coef10did = treat_below_median
	
	g coef1didcon = treat_con_v2*(1-bad_connection)
	g coef2didcon = treat_con_v2*tablet_sessions
	g coef3didcon = treat_con_v2*girl
	g coef4didcon = treat_con_v2*couple_2
	g coef5didcon = treat_con_v2*curso_2
	g coef6didcon = treat_con_v2*(1-countr_origin_parent_9)
	g coef7didcon = treat_con_v2*tutor_st_same_gender
	g coef8didcon = treat_con_v2*same_gender
	g coef9didcon = treat_con_v2*same_baseline_p50
	g coef10didcon = treat_con_v2*below_median

	foreach var in "" {
		lab define coef1did`var' 0 "" 1 "Treat x Good connection", replace
		lab values coef1did`var' coef1did`var'
		lab var coef1did`var' "Treat x Good connection"
		
		lab define coef2did`var' 0 "" 1 "Treat x Tablet", replace
		lab values coef2did`var' coef2did`var'
		lab var coef2did`var' "Treat x Tablet"
				
		lab define coef3did`var' 0 "" 1 "Treat x Girl", replace
		lab values coef3did`var' coef3did`var'
		lab var coef3did`var' "Treat x Girl"
				
		lab define coef4did`var' 0 "" 1 "Treat x Single parent household", replace
		lab values coef4did`var' coef4did`var'
		lab var coef4did`var' "Treat x Low SES"
		
		lab define coef5did`var' 0 "" 1 "Treat x 2º ESO", replace
		lab values coef5did`var' coef5did`var'
		lab var coef5did`var' "Treat x 2º ESO"
		
		lab define coef6did`var' 0 "" 1 "Treat x Immigrant background", replace
		lab values coef6did`var' coef6did`var'
		lab var coef6did`var' "Treat x Immigrant background"
		
		lab define coef7did`var' 0 "" 1 "Treat x Tutor-student same gender", replace
		lab values coef7did`var' coef7did`var'
		lab var coef7did`var' "Treat x Female tutor"
		
		lab define coef8did`var' 0 "" 1 "Treat x Students same gender", replace
		lab values coef8did`var' coef8did`var'
		lab var coef8did`var' "Treat x Same gender"
		
		lab define coef9did`var' 0 "" 1 "Treat x Similar ability", replace
		lab values coef9did`var' coef9did`var'
		lab var coef9did`var' "Treat x Similar ability"
		
		label define coef10did`var'  0 "No" 1 "Treat x Bottom 50\% ability"
		label values coef10did`var' coef10did`var'
		label var coef10did`var'  "Treat x Bottom 50\% ability"

	}
	

	lab var coef1didcon "Treat x Nb. hours x Good connection"
	lab var coef2didcon "Treat x Nb. hours x Tablet"
	lab var coef3didcon "Treat x Nb. hours x Girl"
	lab var coef4didcon "Treat x Nb. hours x Single parent household"
	lab var coef5didcon "Treat x Nb. hours x 2º ESO"
	lab var coef6didcon "Treat x Nb. hours x Immigrant background"
	lab var coef7didcon "Treat x Nb. hours x Tutor-students same gender"
	lab var coef8didcon "Treat x Nb. hours x Students same gender"
	lab var coef9didcon "Treat x Nb. hours x Similar ability"
	lab var coef10didcon "Treat x Nb. hours x Bottom 50\% ability"

* Final adjustments
	ren final_mark_maths_pa final_marks // too long

* Test
	/*
	replace treat_v2 = post*treat
	replace coef1did = post*treat_good
	drop if Volun_men_Final == 1
	reg final_marks i.treat_v2 i.post i.treat i.coef1did i.treat_good `sp	ec2', vce(cl ID)
	*/

	/*
	reg final_marks  i.treat i.treat#i.same_gender i.grade i.age_student i.comunidad_1 i.gender  i.fsm i.math_grade i.lockdown_class i.device_available  i.refuerzo_2 i.school_id i.block_id i.language_home i.education i.income i.hh_persons_b18 i.couple i.countr_origin_parent_9 if period==1, vce(robust)
	*/

* Start loop
foreach sp in  2 {
	forv v=1/1 { // two versions for each spec: all mentors, and only professional mentors
		clear matrix 
		local count=1
		eststo clear 
		
		forv l=1/10  { 
		
			preserve
				replace treat_v2 = post*treat // relabelling tweak in order to have the same coefficient label for treat*post as in treat
				replace treat_con_v2 = post*treat_con_v2 
				
				replace coef1did = post*treat_good
				replace coef2did = post*treat_tablet
				replace coef3did = post*treat_girl
				replace coef4did = post*treat_SES_l
				replace coef5did = post*treat_2ESO
				replace coef6did = post*treat_immi
				replace coef7did = post*treat_tutor_st_same_gender
				replace coef8did = post*treat_same_gender	
				replace coef9did = post*treat_same_baseline	
				replace coef10did = post*treat_below_median

				
				forv x=1/10 {
					replace coef`x'didcon = post*coef`x'didcon
				}
				
				* Define sets of locals for defining file names for tables
				if `v' == 2 {
					drop if Volun_men_Final == 1
					local prof = "_prof"
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
				
				* DiD outcomes
				foreach var in test_perc_std_gr   {
					if `l' != 10 {
						reg `var' i.treat_v2 i.post i.treat i.coef`l'did i.maineffect`l' i.maineffectdid`l' `spec`sp'', vce(cl ID)
						est store `var'`prof'_`sp'
						
										
						if `l' == 6 { // last panel must have mdy, sdy, and obs
							reg `var' i.treat_v2 i.post i.treat i.coef`l'did i.maineffect`l' i.maineffectdid`l' `spec`sp'', vce(cl ID)
							est store `var'`prof'_`sp'
							su `var' if treat==0 & period==0 & e(sample)==1
							estadd scalar meany=r(mean) 
							estadd scalar sdy=r(sd) 
							su `var' if e(sample)==1
							estadd scalar Obs=r(N)
							
						
						}
					}
					else { // last panel must have mdy, sdy, and obs
						reg `var' i.treat_v2 i.post i.treat i.coef`l'did i.maineffect`l' i.maineffectdid`l'  `spec`sp'', vce(cl ID)
						est store `var'`prof'_`sp'
							su `var' if treat==0 & period==0 & e(sample)==1
							estadd scalar meany=r(mean) 
							estadd scalar sdy=r(sd) 
							su `var' if e(sample)==1
							estadd scalar Obs=r(N)
							
						
					}
				}
			restore
			
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
				
				* Non-DiD outcomes
				foreach var in final_marks pass_math failed_course after_eso2  {
					if `l' != 10 {
						reg `var' i.treat_v2 i.coef`l'did i.maineffect`l' `spec`sp''  if period==1, vce(robust)
						est store `var'`prof'_`sp'
						
	
						
						if `l' == 6 |  `l' == 10 { // last panel must have mdy, sdy, and obs
							reg `var' i.treat_v2  i.coef`l'did i.maineffect`l' `spec`sp'' if period==1, vce(robust)
							est store `var'`prof'_`sp'
							su `var' if treat==0 & period==1 & e(sample)==1
							estadd scalar meany=r(mean) 
							estadd scalar sdy=r(sd) 
							su `var' if e(sample)==1
							estadd scalar Obs=r(N)
							
							
						}
					}
					else { // last panel must have mdy, sdy, and obs
						reg `var' i.treat_v2 i.coef`l'did i.maineffect`l' `spec`sp''   if period==1, vce(robust)
						est store `var'`prof'_`sp'
							su `var' if treat==0 & period==1 & e(sample)==1
							estadd scalar meany=r(mean) 
							estadd scalar sdy=r(sd) 
							su `var' if e(sample)==1
							estadd scalar Obs=r(N)
							

					}
					
					
				}
				
				if `l' != 10 & `l' != 6 { // last panel must have mdy, sdy, and obs
					* Main tables ------------------------------------------------------
					
					esttab test_perc_std_gr`prof'_2 final_marks`prof'_2 pass_math`prof'_2 failed_course`prof'_2 after_eso2`prof'_2 using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
		replace cells(b(fmt(3) star) se(fmt(3)  par)) star(* 0.10 ** 0.05 *** 0.01) collabels(none) nonotes nogaps noobs label interaction(" x ") order(1.treat_v2 1.coef`l'did _cons)  keep(1.treat_v2 1.coef`l'did _cons) mtitles("\shortstack{Standardized\\test score}" "\shortstack{Final math\\grade}" "\shortstack{Passed\\math}" "\shortstack{Repeated\\year}" "\shortstack{Bachi\\llerato}" )   
		
				}
				
				else {
					* Main tables ------------------------------------------------------
					
					esttab test_perc_std_gr`prof'_2 final_marks`prof'_2 pass_math`prof'_2 failed_course`prof'_2 after_eso2`prof'_2  using "${TEMP}\PanelIE`count'.tex", style(tex)  ///
		replace cells(b(fmt(3) star) se(fmt(3)  par)) star(* 0.10 ** 0.05 *** 0.01) collabels(none) nonotes nogaps noobs label interaction(" x ") order(1.treat_v2 1.coef`l'did _cons)  keep(1.treat_v2 1.coef`l'did _cons) mtitles("\shortstack{Standardized\\test score}" "\shortstack{Final math\\grade}" "\shortstack{Passed\\math}" "\shortstack{Repeated\\year}" "\shortstack{Bachi\\llerato}") stats(meany sdy Obs, fmt(2 2 0) labels("Mean dep. var." "SD dep. var." "Obs.")) 
		
				}
				
				
		local ++count
		
		}
		
		do "$DO_FILES\programmes\make_panel_table_v2.do"
		
		* Main tables ------------------------------------------------------
		panelcombine2, use(${TEMP}\PanelIE7.tex ${TEMP}\PanelIE8.tex ${TEMP}\PanelIE9.tex ${TEMP}\PanelIE10.tex)  columncount(5) paneltitles("Tutor-student gender match" "Student gender composition" "Group ability composition" "Bottom 50\% baseline test") save("${OUTPUT}revision\table8`prof'`nocont'.tex") cleanup /* This is Table 8 */ 
		/* panelcombine2, use(${TEMP}\PanelIE3.tex ${TEMP}\PanelIE5.tex ${TEMP}\PanelIE4.tex  ${TEMP}\PanelIE6.tex)  columncount(5) paneltitles("Gender" "Grade" "Single parent household" "Immigrant background") save("${OUTPUT}tables\het_results`prof'`nocont'_final_2.tex") cleanup */

		

	}
}

set varabbrev on
cap log close 

ex

