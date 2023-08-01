********************************************

use "filepath\exam_data_2023B.dta", clear

**Question: "What is the effect of smoking cessation on BMI change?"
**dependent: bmi change
**independent: smoking cessation 

codebook

**no missing data

rename smoking_cessa~n smoking_cess

corr sex education CVD dementia diuretics age n_cigarettes bmi_ch_percent bmi 
**no high correlation values

summarize

tab sex
tab education	  
tab CVD
tab dementia
tab diuretics
tab smoking_cessa~n

summ age
hist age //normal distribution

gen age2 = age*age 
reg bmi_ch_percent age 
est store a 
reg bmi_ch_percent age age2
est store b 
lrtest a b 
**quadratic term needed 

summ bmi 
hist bmi //normal distribution 

gen bmi2 = bmi*bmi 
reg bmi_ch_percent bmi
est store a 
reg bmi_ch_percent bmi bmi2 
est store b 
lrtest a b 
**quadratic term not needed 

summ n_cigarettes
hist n_cigarettes //some peaks, normal distribution

gen n_cigarettes2 = n_cigarettes*n_cigarettes
reg bmi_ch_percent n_cigarettes
est store a 
reg bmi_ch_percent n_cigarettes n_cigarettes2
est store b 
lrtest a b 
**quadratic term not needed 


summ age if smoking_cess ==0, detail
summ age if smoking_cess ==1, detail 

summ bmi if smoking_cess ==0, detail 
summ bmi if smoking_cess ==1, detail 

summ n_cigarettes if smoking_cess ==0, detail 
summ n_cigarettes if smoking_cess ==1, detail 

summ bmi_ch_percent
summ bmi_ch_percent if smoking_cess ==0, detail 
summ bmi_ch_percent if smoking_cess ==1, detail 


* 1)
sum age bmi bmi_ch_percent if smoking_cess==0
sum age bmi bmi_ch_percent if smoking_cess==1

tab1 sex education CVD  diuretics dementia if smoking_cess==0
tab1 sex education CVD  diuretics dementia if smoking_cess==1


********************************************
********************************************

* Simple Linear Regression 


*crude
**regress dependent independent 
regress bmi_ch_percent smoking_cess 

**adjusted: multivariable linear regression 
regress bmi_ch_percent smoking_cess i.CVD i.dementia i.diuretics i.education i.sex age age2 bmi n_cigarettes
est store a 
regress bmi_ch_percent smoking_cess i.CVD i.dementia i.diuretics i.education i.sex age age2 n_cigarettes
est store b 
lrtest a b 
**BMI not significant, exclude, p-value = 0.85

**BMI not significant, excluded_
regress bmi_ch_percent smoking_cess i.CVD i.dementia i.diuretics i.education i.sex age age2 n_cigarettes


********************************************
********************************************

* Inverse Probability Weighting

capture drop p_smoking_cess
logit smoking_cess i.CVD i.dementia i.diuretics i.education i.sex age age2 n_cigarettes

predict p_smoking_cess, pr

gen IPW=1/p_smoking_cess if smoking_cess==1
replace IPW=1/(1-p_smoking_cess) if smoking_cess==0
**Check the mean of the weights; we expect it to be close to 2.0*/
summarize IPW
**Mean = 1.957

reg bmi_ch_percent smoking_cess [pw=IPW]

********************************************
********************************************

* G-Formula

expand 2, generate(interv)
expand 2 if interv == 0, generate(interv2)
replace interv = -1  if interv2 ==1
drop interv2 
tab interv
replace bmi_ch_percent = . if interv != -1
replace smoking_cess = 0 if interv == 0
replace smoking_cess = 1 if interv == 1
by interv, sort: summarize smoking_cess

reg bmi_ch_percent smoking_cess i.CVD i.diuretics i.dementia i.education i.sex age age2 n_cigarettes
predict predY, xb
by interv, sort: summarize 

by interv, sort: summarize predY


quietly summarize predY if(interv == -1)
matrix input observe = (-1,`r(mean)')
quietly summarize predY if(interv == 0)
matrix observe = (observe \0,`r(mean)')
quietly summarize predY if(interv == 1)
matrix observe = (observe \1,`r(mean)')
matrix observe = (observe \., observe[3,2]-observe[2,2]) 

matrix rownames observe = observed E(Y(x=0)) E(Y(x=1)) difference
matrix colnames observe = interv value
matrix list observe 

               interv      value
  observed         -1   1.651952
 E(Y(x=0))          0  .96492747
 E(Y(x=1))          1   3.591168
difference          .  2.6262406


********************************************
********************************************

* Confidence intervals


drop if interv != -1
gen meanY_b =.
capture program drop bootstdz
program define bootstdz, rclass
		preserve
		bsample 
		expand 2, generate(interv_b)
		expand 2 if interv_b == 0, generate(interv2_b)
		replace interv_b = -1  if interv2_b ==1
		drop interv2_b
		replace bmi_ch_percent = . if interv_b != -1
		replace smoking_cess = 0 if interv_b == 0
		replace smoking_cess = 1 if interv_b == 1
		reg bmi_ch_percent smoking_cess i.CVD i.diuretics i.dementia i.education i.sex age age2 n_cigarettes
		predict predY_b, xb
		summarize predY_b if interv_b == 0
		return scalar boot_0 = r(mean)
		summarize predY_b if interv_b == 1
		return scalar boot_1 = r(mean)
		return scalar boot_diff = return(boot_1) - return(boot_0)
	drop meanY_b
	restore
end


simulate EY_a0=r(boot_0) EY_a1 = r(boot_1) difference = r(boot_diff), reps(500) seed(1):bootstdz 

matrix pe = observe[2..4, 2]'
matrix list pe

bstat, stat(pe) n(10000) 

estat bootstrap, p

