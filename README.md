# Telco Churn Analysis Project

This repository contains a comprehensive analysis of customer churn using the Telco Churn dataset. The project involves data preprocessing, logistic regression modeling, decision tree analysis, and random forest classification. The outputs include performance metrics, confusion matrices, AUC calculations, and model predictions exported as CSV files for further visualization in tools like Power BI.

## Project Overview
The goal of this project is to predict customer churn using different machine learning models and evaluate their performance through confusion matrices and AUC scores. This project also exports key datasets to be used in external tools.

---

## Dataset Description
The Telco Churn dataset includes information about customers, their subscription details, and whether they churned. Key features include:
- **Contract**: The type of contract (Month-to-month, One year, Two year)
- **PaymentMethod**: Customer payment method
- **MonthlyCharges**: The monthly fee charged to the customer
- **Tenure**: The number of months the customer has stayed with the company
- **Churn**: Whether the customer churned (Yes/No)

---

## Project Workflow
1. **Data Import**: Import the Telco Churn dataset into SAS.
2. **Data Cleaning**: Handle missing values and convert the `Churn` variable to numeric.
3. **Exploratory Data Analysis (EDA)**: Analyze categorical and numerical variables using charts and correlation analysis.
4. **Modeling**:
   - Logistic Regression (with and without weights)
   - Decision Tree using `PROC HPSPLIT`
   - Random Forest using `PROC HPFOREST`
5. **Performance Evaluation**:
   - Generate confusion matrices for all models.
   - Compute AUC using logistic regression ROC curves.

---

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/telco-churn-dataset.git
   cd telco-churn-dataset
