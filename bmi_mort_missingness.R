# Load necessary packages
library(haven)
library(dplyr)
library(survival)
library(survminer)
library(rms)
library(car)
library(ggplot2)
library(Hmisc)
library(mice)

# Read data
data <- read_dta("filepath/exam_data_2023A.dta")

# Codebook
summary(data)

# Generate BMI categories
data$bmicat <- cut(data$bmi, breaks = c(-Inf, 18.5, 24.9, 29.9, 34.9, Inf), labels = c("underweight", "normal", "overweight", "obese class I", "obese class II/III"))

# Correlations
rcorr(as.matrix(data[c("diuretics", "cancer", "bmi", "dementia", "sex", "age")]))
rcorr(as.matrix(data[c("diuretics", "cancer", "bmicat", "dementia", "sex", "age")]))

# Summaries and histograms
summary(data$age)
ggplot(data, aes(x = age)) + geom_histogram()

summary(data$bmi)
ggplot(data, aes(x = bmi)) + geom_histogram()

table(data$bmicat)

# Set up the survival object
data$date_end_fu <- as.Date(data$date_end_fu)
data$date_baseline <- as.Date(data$date_baseline)
surv_obj <- Surv(time = as.numeric(data$date_end_fu - data$date_baseline), event = data$died)

# Descriptive statistics
summary(surv_obj)
summary(surv_obj[data$died == 1])

# Incidence rate
sum(data$died) / sum(as.numeric(data$date_end_fu - data$date_baseline))

# Univariable Cox proportional hazards models
summary(coxph(surv_obj ~ factor(bmicat), data = data))
summary(coxph(surv_obj ~ factor(cancer), data = data))
summary(coxph(surv_obj ~ factor(dementia), data = data))
summary(coxph(surv_obj ~ factor(diuretics), data = data))
summary(coxph(surv_obj ~ factor(sex), data = data))
summary(coxph(surv_obj ~ factor(sm_status), data = data))

# Age linearity assumption
cox_model <- coxph(surv_obj ~ age + I(age^2), data = data)
anova(cox_model)

# BMI linearity assumption
cox_model <- coxph(surv_obj ~ bmi + I(bmi^2), data = data)
anova(cox_model)

# Proportional hazards assumption with Schoenfeld residuals
cox_model <- coxph(surv_obj ~ factor(sm_status) + factor(bmicat) + factor(cancer) + factor(dementia) + factor(diuretics) + factor(sex) + age, data = data)
cox.zph(cox_model)

# Recode BMI categories
data$bmicat <- cut(data$bmi, breaks = c(-Inf, 24.9, 29.9, 34.9, Inf), labels = c("normal", "overweight", "obese class I", "obese class II/III"))

# Proportional hazards assumption with Schoenfeld residuals
cox_model <- coxph(surv_obj ~ factor(sm_status) + factor(bmicat) + factor(cancer) + factor(dementia) + factor(diuretics) + factor(sex) + age, data = data)
cox.zph(cox_model)

# Kaplan-Meier plot
ggsurvplot(survfit(surv_obj ~ bmicat, data = data), risk.table = TRUE)

# Complete case analysis
summary(coxph(surv_obj ~ factor(bmicat) + factor(cancer) + factor(dementia) + factor(diuretics) + factor(sex) + factor(sm_status) + age, data = data))

# Missingness analysis
table(is.na(data$sm_status))
table(is.na(data$sm_status), data$sex)
table(is.na(data$sm_status), data$cancer)
table(is.na(data$sm_status), data$dementia)
table(is.na(data$sm_status), data$diuretics)
table(is.na(data$sm_status), data$died)
table(is.na(data$sm_status), data$bmicat)

summary(data$age[!is.na(data$sm_status)])
summary(data$age[is.na(data$sm_status)])
summary(data$bmi[!is.na(data$sm_status)])
summary(data$bmi[is.na(data$sm_status)])

# Reasons for missingness
summary(glm(is.na(sm_status) ~ factor(bmicat) + factor(cancer) + factor(diuretics) + factor(dementia) + factor(sex) + age, data = data, family = "binomial"))

# Create imputations
imp <- mice(data, method = "mlogit", predictorMatrix = model.matrix(~ age + sex + bmicat + cancer + dementia + diuretics), m = 10)
summary(imp)

# Imputed data analysis
fit <- with(data = imp, expr = coxph(surv_obj ~ factor(bmicat) + factor(cancer) + factor(dementia) + factor(diuretics) + factor(sex) + factor(sm_status) + age))
summary(pool(fit))