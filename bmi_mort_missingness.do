********************************************
use "filepath\exam_data_2023A.dta", clear

**Question: "What is the relationship between body mass index levels and mortality, after accounting for other measured risk factors?"
**dependent: mortality
**independent: bmi 

codebook

********************************************
********************************************

* Missing

**id: 0/50,000
**sm_status: 17,206/50,000
**sex: 0/50,000
**age: 0/50,000
**cancer: 0/50,000
**dementia: 0/50,000
**diuretics: 0/50,000
**bmi: 0/50,000
**died: 0/50,000
**date_baseline: 0/50,000
**date_end_fu: 0/50,000

********************************************
********************************************

* Exploratory Data Analysis

**BMI Category Source: https://www.ncbi.nlm.nih.gov/books/NBK541070/
**BMI Classification Percentile And Cut Off Points: 
*Severely underweight - BMI less than 16.5kg/m^2
*Underweight - BMI under 18.5 kg/m^2
*Normal weight - BMI greater than or equal to 18.5 to 24.9 kg/m^2
*Overweight – BMI greater than or equal to 25 to 29.9 kg/m^2
*Obesity – BMI greater than or equal to 30 kg/m^2
*Obesity class I – BMI 30 to 34.9 kg/m^2
*Obesity class II – BMI 35 to 39.9 kg/m^2
*Obesity class III – BMI greater than or equal to 40 kg/m^2 (also referred to as severe, extreme, or massive obesity)

recode bmi (min/18.49999 = 1 "underweight") (18.5/24.99999 = 2 "normal") (25/29.99999 = 3 "overweight") (30/34.99999 = 4 "obese class I") (35/max = 5 "obese class II/III"), generate(bmicat)

corr diuretics cancer bmi dementia sex age
corr diuretics cancer bmicat dementia sex age
**no high correlations

summ age 
hist age //normal distribution, mean: 49.66844

summ bmi 
hist bmi //normal distribution, mean: 27.28

tab bmicat

********************************************
********************************************

* Cox Regression   

stset date_end_fu, id(id) origin(date_baseline) fail(died) scale(365.25) 

stdescribe
**failures: 4343
**mean time: 4.8 years

stdescribe if died ==1

stsum
**incidence rate:  .0180947 

********************************************
********************************************

* Univariable Analyses

stcox ib2.bmicat, base
stcox i.cancer, base
stcox i.dementia, base
stcox i.diuretics, base 
stcox i.sex, base 
stcox i.sm_status, base

gen age2 = age*age
stcox age age2 
est store a 
stcox age  
est store b 
lrtest a b 
**Age passes linearity assumption
stcox age

gen bmi2 = bmi*bmi 
stcox bmi bmi2
est store a 
stcox bmi 
est store b 
lrtest a b 
**BMI does not pass linearity assumption
**Use categorical 

********************************************
********************************************

* Proportional Hazards Assumption using Schoenfeld

stcox i.sm_status ib2.bmicat i.cancer i.dementia i.diuretics i.sex age, schoenfeld(sc_c*) scaledsch(ssc_c*)
estat phtest, log detail
**BMI underweight shows evidence of not meeting proportional hazards assumption

* Graph for Testing the proportional hazards assumption for this model: 
stphplot, strata(bmicat) adjust(i.sm_status i.cancer i.dementia i.diuretics i.sex age)
**BMI underweight does not follow proportional hazards

drop bmicat 
recode bmi (min/24.99999 = 1 "normal") (25/29.99999 = 1 "overweight") (30/34.99999 = 3 "obese class I") (35/max = 4 "obese class II/III"), generate(bmicat)
tab bmicat

* Graph for Testing the proportional hazards assumption for this model: 
stphplot, strata(bmicat) adjust(i.sm_status i.cancer i.dementia i.diuretics i.sex age)
stphplot, strata(sm_status) adjust(i.bmicat i.cancer i.dementia i.diuretics i.sex age) saving(sm_status)
stphplot, strata(cancer) adjust(i.sm_status i.bmicat i.dementia i.diuretics i.sex age) saving(cancer)
stphplot, strata(dementia) adjust(i.sm_status i.bmicat i.cancer i.diuretics i.sex age) saving(dementia)
stphplot, strata(diuretics) adjust(i.sm_status i.bmicat i.cancer i.dementia i.sex age) saving(diuretics)
stphplot, strata(sex) adjust(i.sm_status i.bmicat i.cancer i.dementia i.diuretics age) saving(sex)
gr combine sm_status.gph bmicat.gph cancer.gph dementia.gph diuretics.gph sex.gph 

********************************************
********************************************

* Kaplan Meier Plot: BMICAT
sts graph, by(bmicat) risktable(, size(vsmall)) xlabel(0(1)4.9) survival ytitle("Survival Proportion") title ("Kaplan Meier Prortional Hazards")

********************************************
********************************************

* Complete case 
stcox i.bmicat i.cancer i.dementia i.diuretics i.sex i.sm_status age, base

********************************************
********************************************


* Missingness

codebook sm_status 

tab sm_status

gen miss_smstatus = missing(sm_status)
tab miss_smstatus //34.41% missing 

tab miss_smstatus sex, r
tab miss_smstatus cancer, r 
tab miss_smstatus dementia, r 
tab miss_smstatus diuretics, r 
tab miss_smstatus died, r  
tab miss_smstatus bmicat, r 

summ age if miss_smstatus ==0
summ age if miss_smstatus ==1
summ bmi if miss_smstatus ==0
summ bmi if miss_smstatus ==1

* Reasons for missingness
logistic miss_smstatus i.bmicat i.cancer i.diuretics i.dementia i.sex age, base
** all have significant p value 


********************************************
********************************************
********************************************
*  Create Imputations  

* Nelson-Aalen
sts gen na = na

* MI settings
mi set wide
mi register imputed sm_status
mi register regular age sex bmicat cancer dementia diuretics na

* Imputations
mi impute mlogit sm_status = age sex bmicat cancer dementia diuretics na, add(10)
**17,206 imputed 

browse

summ _1_sm_status
summ _2_sm_status
summ _3_sm_status
summ _4_sm_status
summ _5_sm_status
summ _6_sm_status
summ _7_sm_status
summ _8_sm_status
summ _9_sm_status
summ _10_sm_status


********************************************
********************************************
********************************************
*  Imputed data analysis

mi estimate, eform base: stcox i.bmicat i.cancer i.dementia i.diuretics i.sex i.sm_status age

mi estimate, vartable base
