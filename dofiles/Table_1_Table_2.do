*** TUTORING SUMMARY STATS - ENDLINE (for presentation)***

use "${DATA_CLEAN}tutoring_regression_dataset.dta", clear 
drop if_endline_survey

set varabbrev on
eststo clear
set scheme cleanplots

bys ID: gen test_score_percent_bl=test_score_percent if period==0
bys ID: egen test_score_percent_bl_ext=max(test_score_percent_bl)


replace test_score_percent_bl=test_score_percent_bl_ext
drop test_score_percent_bl_ext

label variable test_score_percent_bl "Test score (\%) at baseline"

gen mi_bl=(test_score_percent_bl==.)	
label var mi_bl "Missing baseline test score"

bys ID: egen partial_response_end_ext=max(partial_response_end)


keep if period==0
drop partial_response_end 
ren partial_response_end_ext  partial_response_end

forv v=1/2 {

preserve

	if `v' == 2 {
		drop if partial_response_end == 0
	}
	

global vars_child "age_student gender_1 countr_origin_child_7 curso_2 public comunidad_1  fsm_2  device_available_1 internet refuerzo_2    " 
global vars_hh "relation_ch_2 couple_1 countr_origin_parent_9 spanish_catalan education_below income_below hh_persons hh_persons_b18 age_youngest "
global math_grade "if_fail_math_2  if_fail_2 repeated_1plus  math_grade_2 math_grade_3 test_score_percent_bl"
global response "partial_response_incl_maths full_response" 

cap file close fh

	if `v' == 1 {
		file open fh using "${OUTPUT}revision/table_1.tex", write replace /* This is Table 1 */
	}
	
	if `v' == 2 {
		file open fh using "${OUTPUT}revision/table_2.tex", write replace /* This is Table 2*/
	}

	
	file write fh _n  "\begin{tabular}{@{}lccc@{}}"
	file write fh _n "\toprule" 
	su partial_response
	local N=r(N)
	file write fh _n "" "  " " & " "\multicolumn{3}{c}{\textit{N}=`N'}" "\\"
	file write fh _n  "" " " " & " " Control mean" " & " "Treatment/control" " & " "Normalized"  "\\"
		file write fh _n  "" "  " " & " "(SD)" " & " "difference (SE)"  " & "  "difference" "\\"
		file write fh _n"\midrule" 
		file write fh _n "\multicolumn{4}{l}{\textit{Child characteristics}}" "\\"
		foreach var in $vars_child  {
		reg `var' treat i.block_id , vce(robust)
		local treat=_b[treat]
		local treat_mean=_b[treat]+_b[_cons]
		local cons=_b[_cons]
		local se=_se[treat]
		if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.000000000,0.01) local star="***"
	else if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.01000000001,0.05) local star= "**"
	else if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.05000000001,0.10) local star= "*"
	else local star = " "
		su `var' if treat!=., det
		local m1 = r(mean)
		local s1 = r(sd)
		local N1 = r(N)
		su `var'  if treat==1, det
		local m2 = r(mean)
		local s2 = r(sd)
		local N2 = r(N)
		su `var'  if treat==0, det
		local m3 = r(mean)
		local s3 = r(sd)
		local N3 = r(N)
		local diff=`m2'-`m3'
		ttesti `N2' `m2' `s2' `N3' `m3' `s3'
		local pval = r(p)
		local normdiff=`treat'/`s3'
		file write fh _n `"`: var label `var''"'  " & " %9.2fc (`m3')  " " "(\MyNumthree{`s3'})"  " & " %9.3fc (`treat') "`star'" " " "(\MyNumtwo{`se'})" " & " %9.3fc (`normdiff')   " \\"
		}
		file write fh _n "\multicolumn{3}{l}{\textit{Baseline child survey outcome}}" "\\"

		foreach var in $response  {
		reg `var' treat i.block_id if period==0, vce(robust)
		if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.000000000,0.01) local star="***"
	else if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.01000000001,0.05) local star= "**"
	else if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.05000000001,0.10) local star= "*"
	else local star = " "
		local treat=_b[treat]
		local treat_mean=_b[treat]+_b[_cons]
		local cons=_b[_cons]
		local se=_se[treat]
		su `var' if treat!=., det
		local m1 = r(mean)
		local s1 = r(sd)
		local N1 = r(N)
		su `var'  if treat==1, det
		local m2 = r(mean)
		local s2 = r(sd)
		local N2 = r(N)
		su `var'  if treat==0, det
		local m3 = r(mean)
		local s3 = r(sd)
		local N3 = r(N)
		local diff=`m2'-`m3'
		ttesti `N2' `m2' `s2' `N3' `m3' `s3'
		local pval = r(p)
		local normdiff=`treat'/`s3'
		su `var' if treat==., det
		local m4 = r(mean)
		local s4 = r(sd)
		local N4 = r(N)
		file write fh _n `"`: var label `var''"'  " & " %9.2fc (`m3')  " " "(\MyNumthree{`s3'})"  " & " %9.3fc (`treat') "`star'" " " "(\MyNumtwo{`se'})" " & " %9.3fc (`normdiff')   " \\"
		}
		file write fh _n "\multicolumn{4}{l}{\textit{Baseline performance}}" "\\"

		foreach var in $math_grade  {
		reg `var' treat i.block_id , vce(robust)
		if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.000000000,0.01) local star="***"
	else if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.01000000001,0.05) local star= "**"
	else if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.05000000001,0.10) local star= "*"
	else local star = " "
		local treat=_b[treat]
		local treat_mean=_b[treat]+_b[_cons]
		local cons=_b[_cons]
		local se=_se[treat]
		su `var'  if treat==0, det
		local m3 = r(mean)
		local s3 = r(sd)
		local N3 = r(N)
		local normdiff=`treat'/`s3'
		file write fh _n `"`: var label `var''"'  " & " %9.2fc (`m3')  " " "(\MyNumthree{`s3'})"  " & " %9.3fc (`treat') "`star'" " " "(\MyNumtwo{`se'})" " & " %9.3fc (`normdiff')   " \\"
		}
		
		file write fh _n "\multicolumn{4}{l}{\textit{Parental/household characteristics}}" "\\"
		foreach var in $vars_hh  {
		reg `var' treat i.block_id , vce(robust)
		if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.000000000,0.01) local star="***"
	else if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.01000000001,0.05) local star= "**"
	else if inrange(2* ttail(e(df_r), abs(_b[treat]/_se[treat])),0.05000000001,0.10) local star= "*"
	else local star = " "
		local treat=_b[treat]
		local treat_mean=_b[treat]+_b[_cons]
		local cons=_b[_cons]
		local se=_se[treat]
		su `var' if treat!=., det
		local m1 = r(mean)
		local s1 = r(sd)
		local N1 = r(N)
		su `var'  if treat==1, det
		local m2 = r(mean)
		local s2 = r(sd)
		local N2 = r(N)
		su `var'  if treat==0, det
		local m3 = r(mean)
		local s3 = r(sd)
		local N3 = r(N)
		local diff=`m2'-`m3'
		ttesti `N2' `m2' `s2' `N3' `m3' `s3'
		local pval = r(p)
		local normdiff=`treat'/`s3'
		file write fh _n `"`: var label `var''"'  " & " %9.2fc (`m3')  " " "(\MyNumthree{`s3'})"  " & " %9.3fc (`treat') "`star'" " " "(\MyNumtwo{`se'})" " & " %9.3fc (`normdiff')   " \\"
		}
		file write fh _n "\bottomrule" 
		file write fh _n "\end{tabular}"

file close fh

restore

}


