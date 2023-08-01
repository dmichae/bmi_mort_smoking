# BMI, Mortality and Smoking Cessation Analysis Project

Project Overview
This project comprises two key investigations:

1. The examination of the relationship between Body Mass Index (BMI) levels and mortality over a 5-year period, while taking into account other measured risk factors.
2. The estimation of the relationship between smoking cessation and the 5-year percent change in BMI.

These investigations involve the processing of two datasets, each focusing on a specific question.

# Dataset 1: BMI and Mortality
The first dataset, exam_data_2023A.dta, is based on a sample of 50,000 individuals from Electronic Health Records. Each individual's data was collected from the date their BMI was first recorded, and they were followed up for 5 years. The dataset contains the following variables:

id: ID of the participant
sm_status: Smoking status (Never=0, Former=1, Current=2)
sex: Sex of the participant
age: Age at baseline
cancer: Prevalent cancer at baseline; No=0, Yes=1
dementia: Prevalent dementia at baseline; No=0, Yes=1
diuretics: Use of diuretics at baseline; No=0, Yes=1
bmi: Body mass index (in kg/m^2) - measured at baseline
died: Died during follow up; No=0, Yes=1
date_baseline: Date at baseline
date_end_fu: End of follow-up date

# Dataset 2: Smoking Cessation and BMI Change
The second dataset, exam_data_2023B.dta, is derived from Electronic Health Records of a sample of 10,000 individuals. The data includes the following variables:

id: Participant ID
sex: Participant sex
age: Age of the participant at baseline
education: Level of education; values range from 1 (low) to 5 (high)
n_cigarettes: Number of cigarettes smoked per day
CVD: Prevalent CVD at baseline; No=0, Yes=1
dementia: Prevalent dementia at baseline; No=0, Yes=1
diuretics: Use of diuretics at baseline; No=0, Yes=1
bmi: Body mass index (in kg/m^2) measured at baseline
smoking_cessation: Whether the participant quit smoking between baseline and the end of follow-up; No=0, Yes=1
bmi_ch_percent: Percent change in BMI
Analysis and Report Guidelines
Your analysis and report should include the following sections for each dataset:

# Dataset 1: BMI and Mortality
1. Variable Treatment: Describe how you treated each variable, including any decisions made to categorize continuous variables into clinically significant groups.
2. Model Building: Develop a model relating baseline BMI to the outcome (all-cause mortality), including a discussion of assumptions and modelling decisions made.
3. Missing Data Treatment: Describe how you handled missing data, the assumptions you made, and any sensitivity analyses conducted to assess the robustness of these assumptions.
4. Results Interpretation: Interpret the results and provide a conclusion about the overall study question.

# Dataset 2: Smoking Cessation and BMI Change
1. Descriptive Presentation: Overview of the dataset, including descriptive statistics and visualizations of the variables.
2. Outcome Regression Model: A simple linear regression model estimates the relationship between smoking cessation and BMI change after 5 years. This should be done with and without adjusting for other variables. Interpret the results.
3. Inverse Probability Weighting (IPW): Use IPW to adjust for baseline confounders and estimate the relationship between smoking cessation and BMI change.
4. G-Formula: Estimate the BMI change after 5 years if a) no one had quit smoking and b) all individuals had quit smoking. This will give the average causal effect of smoking cessation on BMI change after 5 years.
