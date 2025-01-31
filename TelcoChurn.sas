* Import the Telco Churn dataset;
proc import datafile="/home/u64146862/TelcoChurn.csv"
    out=telco_data
    dbms=csv
    replace;
    getnames=yes;
run;

* Explore the dataset;
proc contents data=telco_data; 
run;

proc means data=telco_data n nmiss min max mean stddev;
run;

proc freq data=telco_data;
    tables Churn Contract PaymentMethod InternetService / nocum;
run;

* Calculate the mean of MonthlyCharges to fill missing values;
proc means data=telco_data noprint;
    var MonthlyCharges;
    output out=mean_charges mean=mean_monthlycharges;
run;

* Fill missing MonthlyCharges using the calculated mean and convert Churn to numeric;
data telco_clean;
    set telco_data;
    if MonthlyCharges = . then MonthlyCharges = mean_monthlycharges;

    * Convert Churn to numeric: Yes = 1, No = 0;
    if Churn = 'Yes' then ChurnNum = 1;
    else if Churn = 'No' then ChurnNum = 0;
run;

* Export the cleaned Telco Churn dataset as CSV;
proc export data=telco_clean
    outfile="/home/u64146862/telco_cleaned_data.csv"
    dbms=csv
    replace;
run;

* Bar chart for categorical variables;
proc sgplot data=telco_clean;
    vbar Contract / group=ChurnNum;
run;

* Box plot for MonthlyCharges categorized by ChurnNum;
proc sgplot data=telco_clean;
    vbox MonthlyCharges / category=ChurnNum;
run;

* Correlation analysis between numeric variables;
proc corr data=telco_clean;
    var Tenure MonthlyCharges TotalCharges;
run;

* Logistic Regression for churn prediction;
proc logistic data=telco_clean descending;
    class Contract PaymentMethod;
    model ChurnNum = MonthlyCharges Tenure Contract PaymentMethod / selection=stepwise;
    output out=predicted_data p=predicted_prob;
run;

* Split the data into 70% training and 30% testing sets;
proc surveyselect data=telco_clean out=train_test seed=12345 samprate=0.7 outall;
run;

* Evaluate the logistic regression model using the training dataset;
proc logistic data=train_test descending;
    class Contract PaymentMethod;
    model ChurnNum = MonthlyCharges Tenure Contract PaymentMethod;
    roc;
run;

* Create a weight variable (higher weight for churners);
data telco_clean_weighted;
    set telco_clean;
    if ChurnNum = 1 then weight = 3;  /* Assign higher weight to churners */
    else weight = 1;  /* Non-churners get a weight of 1 */
run;

* Logistic Regression WITHOUT weights;
proc logistic data=telco_clean descending;
    class Contract PaymentMethod;
    model ChurnNum = MonthlyCharges Tenure Contract PaymentMethod / selection=stepwise;
    output out=logistic_no_weights p=predicted_prob;
run;

* Logistic Regression WITH weights;
proc logistic data=telco_clean_weighted descending;
    class Contract PaymentMethod;
    model ChurnNum = MonthlyCharges Tenure Contract PaymentMethod / selection=stepwise;
    weight weight;
    output out=logistic_with_weights p=predicted_prob_weighted;
run;

* Evaluate the logistic regression WITHOUT weights;
data evaluation_no_weights;
    set logistic_no_weights;
    predicted = (predicted_prob >= 0.5);  /* Threshold at 0.5 */
run;

proc freq data=evaluation_no_weights;
    tables ChurnNum*predicted / nopercent norow nocol;
run;

* Evaluate the logistic regression WITH weights;
data evaluation_with_weights;
    set logistic_with_weights;
    predicted = (predicted_prob_weighted >= 0.5);  /* Threshold at 0.5 */
run;

proc freq data=evaluation_with_weights;
    tables ChurnNum*predicted / nopercent norow nocol;
run;

* ROC Curve and AUC WITHOUT weights;
ods output ROCCurve=roc_no_weights;
proc logistic data=telco_clean descending;
    class Contract PaymentMethod;
    model ChurnNum = MonthlyCharges Tenure Contract PaymentMethod / selection=stepwise;
    roc 'Logistic Regression Without Weights';
run;
ods output close;

* ROC Curve and AUC WITH weights;
ods output ROCCurve=roc_with_weights;
proc logistic data=telco_clean_weighted descending;
    class Contract PaymentMethod;
    model ChurnNum = MonthlyCharges Tenure Contract PaymentMethod / selection=stepwise;
    weight weight;
    roc 'Logistic Regression With Weights';
run;
ods output close;

* Decision Tree using PROC HPSPLIT;
proc hpsplit data=telco_clean;
    class ChurnNum Contract PaymentMethod;
    model ChurnNum = MonthlyCharges Tenure Contract PaymentMethod;
    score out=tree_predictions;
run;

* Assign predicted variable for decision tree evaluation;
data tree_predictions;
    set tree_predictions;
    predicted_tree = (P_ChurnNum1 >= 0.5);  /* Threshold at 0.5 */
run;

* Generate confusion matrix for decision tree model;
proc freq data=tree_predictions;
    tables ChurnNum*predicted_tree / nopercent norow nocol;
    title "Confusion Matrix for Decision Tree Model";
run;

* Train the Random Forest model using PROC HPFOREST;
proc hpforest data=telco_clean maxtrees=100;
    target ChurnNum;
    input MonthlyCharges Tenure Contract PaymentMethod;
    score out=rf_predictions;
run;

* Assign predicted variable for random forest evaluation;
data rf_predictions;
    set rf_predictions;
    predicted_rf = (P_ChurnNum1 >= 0.5);  /* Threshold at 0.5 */
run;

* Generate confusion matrix for random forest model;
proc freq data=rf_predictions;
    tables ChurnNum*predicted_rf / nopercent norow nocol;
    title "Confusion Matrix for Random Forest Model";
run;

* Compute AUC using a DATA step instead of PROC SQL;
data auc_no_weights;
    set roc_no_weights;
    retain lag_sensit lag_1mspec;
    auc_segment = (_sensit_ + lag(_sensit_)) * (1 - lag(_1mspec_)) / 2;
run;

proc means data=auc_no_weights sum;
    var auc_segment;
    output out=final_auc_no_weights sum=auc_value;
run;

data auc_with_weights;
    set roc_with_weights;
    retain lag_sensit lag_1mspec;
    auc_segment = (_sensit_ + lag(_sensit_)) * (1 - lag(_1mspec_)) / 2;
run;

proc means data=auc_with_weights sum;
    var auc_segment;
    output out=final_auc_with_weights sum=auc_value;
run;

* Print AUC values;
proc print data=final_auc_no_weights;
    title "AUC for Logistic Regression Without Weights";
run;

proc print data=final_auc_with_weights;
    title "AUC for Logistic Regression With Weights";
run;

* Export the final dataset with predictions;
proc export data=predicted_data
    outfile="/home/u64146862/predicted_churn.csv"
    dbms=csv
    replace;
run;

* Export final decision tree and random forest predictions;
proc export data=tree_predictions
    outfile="/home/u64146862/decision_tree_predictions.csv"
    dbms=csv
    replace;
run;

proc export data=rf_predictions
    outfile="/home/u64146862/random_forest_predictions.csv"
    dbms=csv
    replace;
run;
