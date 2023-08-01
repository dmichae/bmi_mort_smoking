# Load necessary libraries
library(car)
library(Hmisc)
library(survey)
library(rms)
library(boot)

# Read data
data <- read.dta("filepath/exam_data_2023B.dta")

# Rename smoking_cessation column
colnames(data)[colnames(data) == "smoking_cessation"] <- "smoking_cess"

# Calculate correlation matrix
rcorr(as.matrix(data[c("sex", "education", "CVD", "dementia", "diuretics", "age", "n_cigarettes", "bmi_ch_percent", "bmi")]))

# Generate summary statistics
summary(data)

# Generate histograms
hist(data$age)
hist(data$bmi)

# Generate quadratic age and bmi
data$age2 <- data$age^2
data$bmi2 <- data$bmi^2

# Test linearity
mod1 <- lm(bmi_ch_percent ~ age, data = data)
mod2 <- lm(bmi_ch_percent ~ age + age2, data = data)
anova(mod1, mod2)

mod1 <- lm(bmi_ch_percent ~ bmi, data = data)
mod2 <- lm(bmi_ch_percent ~ bmi + bmi2, data = data)
anova(mod1, mod2)

mod1 <- lm(bmi_ch_percent ~ n_cigarettes, data = data)
mod2 <- lm(bmi_ch_percent ~ n_cigarettes + n_cigarettes^2, data = data)
anova(mod1, mod2)

# Summary statistics by smoking cessation status
summary(data[data$smoking_cess == 0, ])
summary(data[data$smoking_cess == 1, ])

# 1)
summary(data[data$smoking_cess == 0, c("age", "bmi", "bmi_ch_percent")])
summary(data[data$smoking_cess == 1, c("age", "bmi", "bmi_ch_percent")])

# Cross-tabulations by smoking cessation status
with(data[data$smoking_cess == 0, ], Table(sex, education, CVD, diuretics, dementia))
with(data[data$smoking_cess == 1, ], Table(sex, education, CVD, diuretics, dementia))

# Simple linear regression
# Crude
mod <- lm(bmi_ch_percent ~ smoking_cess, data = data)
summary(mod)

# Adjusted
mod1 <- lm(bmi_ch_percent ~ smoking_cess + factor(CVD) + factor(dementia) + factor(diuretics) + factor(education) + factor(sex) + age + age2 + bmi + n_cigarettes, data = data)
summary(mod1)

mod2 <- lm(bmi_ch_percent ~ smoking_cess + factor(CVD) + factor(dementia) + factor(diuretics) + factor(education) + factor(sex) + age + age2 + n_cigarettes, data = data)
anova(mod1, mod2)
summary(mod2)

# Inverse Probability Weighting
fit <- glm(smoking_cess ~ factor(CVD) + factor(dementia) + factor(diuretics) + factor(education) + factor(sex) + age + age2 + n_cigarettes, data = data, family = binomial())
data$p_smoking_cess <- predict(fit, type = "response")
data$IPW <- ifelse(data$smoking_cess == 1, 1/data$p_smoking_cess, 1/(1-data$p_smoking_cess))
summary(data$IPW)

# Weighted regression
svydesign(ids = ~1, data = data, weights = ~IPW) %>%
  svyglm(bmi_ch_percent ~ smoking_cess)

# G-Formula
data <- data[rep(seq_len(nrow(data)), each = 2), ]
data$interv[data$interv == 0] <- -1
data$interv[is.na(data$interv)] <- 0:1
data$bmi_ch_percent[data$interv != -1] <- NA
data$smoking_cess[data$interv == 0] <- 0
data$smoking_cess[data$interv == 1] <- 1
table(data$interv)

fit <- lm(bmi_ch_percent ~ smoking_cess + factor(CVD) + factor(diuretics) + factor(dementia) + factor(education) + factor(sex) + age + age2 + n_cigarettes, data = data)
data$predY <- predict(fit)

# Calculate expected values
expected <- tapply(data$predY, data$interv, mean)
diff_expected <- diff(expected)
c(expected, diff_expected)

# Bootstrapping
boot_function <- function(data, indices) {
  data <- data[indices, ]
  data <- data[rep(seq_len(nrow(data)), each = 2), ]
  data$interv_b <- c(-1, 0:1)
  data$bmi_ch_percent[data$interv_b != -1] <- NA
  data$smoking_cess[data$interv_b == 0] <- 0
  data$smoking_cess[data$interv_b == 1] <- 1
  
  fit <- lm(bmi_ch_percent ~ smoking_cess + factor(CVD) + factor(diuretics) + factor(dementia) + factor(education) + factor(sex) + age + age2 + n_cigarettes, data = data)
  predY_b <- predict(fit)
  
  expected <- tapply(predY_b, data$interv_b, mean)
  diff_expected <- diff(expected)
  c(expected, diff_expected)
}

boot_obj <- boot(data, boot_function, R = 500)
boot.ci(boot_obj, type = "perc", index = 3)  # For the difference