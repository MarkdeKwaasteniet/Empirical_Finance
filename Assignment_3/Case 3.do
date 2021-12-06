//Prepare Workspace
clear all
ssc install outreg2
ssc install asdoc
ssc install winsor

//Change directory
cd "/Users/markdekwaasteniet/Documents/Master Finance/Empirical Finance/Case 3"

//Data structurizing
import excel "/Users/markdekwaasteniet/Documents/Master Finance/Empirical Finance/Case 3/data_case_III_group_56.xls", sheet("Data") firstrow

//Exercise 1a
tsset Time

//Test the normality of all variables except Date
sktest Return RV

mat sktest = r(Utest)

//Subtract the last column of the matrix including the p-values
matrix Pvalues = sktest[.,4...]

//Summarize all the variables except Date
//Sut the variables into a table and convert to matrix
tabstat Return RV, statistic(mean sd min max) columns(statistics) save
mat statistics = r(StatTotal)'

//Merge the two matrices together
mat table1 = statistics,Pvalues\Pvalues,statistics
mat table1 = table1[1..2,1...]

//Output the matrix
asdoc wmat, mat(table1) title(Summary Statistics Table 1) dec(3) replace
//Rename Myfile.doc name to Table 1.doc

//Interpret the data in terms of outliers
summarize Return, detail
graph hbox Return
histogram Return, frequency

summarize RV, detail
graph hbox RV
histogram RV, frequency

//winsorizing the outliers with respect to the 0.1% of the data
winsor RV, p(.001) highonly gen(RV_w1)
graph hbox RV_w1

//Test the normality of all variables except Date
sktest Return RV_w1

mat sktest = r(Utest)

//Subtract the last column of the matrix including the p-values
matrix Pvalues = sktest[.,4...]

//Summarize all the variables except Date
//Sut the variables into a table and convert to matrix
tabstat Return RV_w1, statistic(mean sd min max) columns(statistics) save
mat statistics = r(StatTotal)'

//Merge the two matrices together
mat table1 = statistics,Pvalues\Pvalues,statistics
mat table1 = table1[1..2,1...]

//Output the matrix
asdoc wmat, mat(table1) title(Summary Statistics Table 1) dec(3) replace
//Rename Myfile.doc name to Table 1 - Adjusted.doc

//Exercise 1b
//Create an in-sample period (including or excluding 2010?)
gen dummy_insample = 0
replace dummy_insample = 1 if Time <= 2490

graph set window fontface "Times New Roman"
line RV_w1 Time, scheme(s2mono) graphregion(color(white)) bgcolor(white) ytitle("Realized Variance (%)", size(small)) xtitle("Time (Daily)", size(small)) legend(size(vsmall)) yla(, labsize(*0.5) nogrid) xla(, labsize(*0.5) nogrid) title("Time Series of RV on Time(daily)")

//create the partial autocorrelation function
ac RV_w1 if dummy_insample == 1, scheme(s1mono) graphregion(color(white)) bgcolor(white) ytitle("Autocorrelations of RV", size(small)) xtitle("Lag", size(small)) legend(size(vsmall)) yla(, labsize(*0.5) nogrid) xla(, labsize(*0.5) nogrid) name(ac_RV)
pac RV_w1 if dummy_insample == 1, scheme(s1mono) graphregion(color(white)) bgcolor(white) ytitle("Partial Autocorrelations of RV", size(small)) xtitle("Lag", size(small)) legend(size(vsmall)) yla(, labsize(*0.5) nogrid) xla(, labsize(*0.5) nogrid) name(pac_RV)
graph set window fontface "Times New Roman"
graph combine ac_RV pac_RV, scheme(s1mono) title("Autocorrelation Functions") graphregion(color(white))

//This looks like an ARMA model
// Using a lag of 2 or 3 because the PACF denotes an fast decline in the autocorrelation after 2 or 3 lags.


//Exercise 1c
arima RV_w1 if dummy_insample == 1, ar(1/3) ma(1)
outreg2 using "Table 2.tex", replace word addstat(ll, e(ll)) ctitle(RV Model 1 - ARMA(3.1)) title(ARMA estimation results)
estimates store arma31

arima RV_w1 if dummy_insample == 1, ar(1) ma(1/3)
outreg2 using "Table 2.tex", append word addstat(ll, e(ll)) ctitle(RV Model 2 - ARMA(1,3)) title(ARMA estimation results)
estimates store arma13


estimates table arma31 arma13, stats(aic, bic, ll)


// ARMA(1,3) is the best model


//Exercise 1d
arima RV_w1 if dummy_insample == 1, ar(1/3) ma(1)
predict res_RV_arma31 if dummy_insample == 1, residuals
ac res_RV_arma31, scheme(s1mono) graphregion(color(white)) bgcolor(white) ytitle("Autocorrelations of ARMA(3,1) Residuals", size(small)) xtitle("Lag", size(small)) legend(size(vsmall)) yla(, labsize(*0.5) nogrid) xla(, labsize(*0.5) nogrid) name(ac_res_ARMA31)
wntestq res_RV_arma31, lags(14)

arima RV_w1 if dummy_insample == 1, ar(1) ma(1/3)
predict res_RV_arma13 if dummy_insample == 1, residuals
ac res_RV_arma13, scheme(s1mono) graphregion(color(white)) bgcolor(white) ytitle("Autocorrelations of ARMA(1,3) Residuals", size(small)) xtitle("Lag", size(small)) legend(size(vsmall)) yla(, labsize(*0.5) nogrid) xla(, labsize(*0.5) nogrid) name(ac_res_ARMA13)
wntestq res_RV_arma13, lags(14)

graph set window fontface "Times New Roman"
graph combine ac_res_ARMA31 ac_res_ARMA13, scheme(s1mono) title("Autocorrelation Functions") graphregion(color(white))

//Exercise 1e
varsoc RV_w1, maxlag(20)
dfuller RV_w1, regress lags(14)

//Exercise 1f
// gen Return_w1_2 = Return_w1^2
// ac Return_w1_2
// pac Return_w1_2

// reg Return_w1_2 L(1/8).Return_w1_2

arch Return if dummy_insample == 1, arch(1/1) garch(1/1)
estimates store GARCH11
outreg2 using "Table 3.tex", replace word addstat(ll, e(ll)) ctitle(Model 3 - GARCH) title(GARCH estimation results)
estimates table GARCH11, stats(aic, bic, ll)

// reg Return_w1_2 L(1/8).Return_w1_2
arch Return if dummy_insample == 1, earch(1/1) egarch(1/1)
estimates store EGARCH11
outreg2 using "Table 3.tex", append word addstat(ll, e(ll)) ctitle(Model 4 - EGARCH) title(GARCH and EGARCH estimation results)
estimates table EGARCH11, stats(aic, bic, ll)


//exercise 1g
//The gamma coefficient is in line with our expectations

//the aic and bic are not comparable, because the dependent variable in the models differ.

//Exercise 1h
arima RV_w1 if dummy_insample == 1, ar(1) ma(1/3)
predict sigma2arma13 if dummy_insample == 0, xb 

arch Return if dummy_insample == 1, arch(1) garch(1)
predict sigma2GARCH if dummy_insample == 0, variance 

gen ln_RV=ln(RV_w1)
gen ln_fcst_GARCH = ln(sigma2GARCH)
gen ln_fcst_arma = ln(sigma2arma13)

twoway (line ln_RV Time if dummy_insample == 0) (line ln_fcst_arma Time if dummy_insample == 0),  scheme(s1color) legend(label(1 "True Values") label(2 "Forecast ARMA")) ytitle("Natural Log of Variance", size(small)) xtitle("Time (Daily)", size(small)) legend(size(vsmall)) yla(, labsize(*0.5)) xla(, labsize(*0.5))
graph save "Forecast ARMA.gph",  replace
twoway (line ln_RV Time if dummy_insample == 0) (line ln_fcst_GARCH Time if dummy_insample == 0), scheme(s1color) legend(label(1 "True Values") label(2 "Forecast GARCH")) ytitle("Natural Log of Variance", size(small)) xtitle("Time (Daily)", size(small)) legend(size(vsmall)) yla(, labsize(*0.5)) xla(, labsize(*0.5))
graph save "Forecast GARCH.gph", replace

graph combine "Forecast ARMA.gph" "Forecast GARCH.gph", scheme(s1color) title("Plots of True Variance Values and Forecasted Variance Values", size(medium))  col(1) iscale(1)
graph save "Exercise 1h.png", replace

twoway (line ln_fcst_arma Time if dummy_insample == 0) (line ln_fcst_GARCH Time if dummy_insample == 0), scheme(s1color) legend(label(1 "Forecast ARMA") label(2 "Forecast GARCH"))


//Exercise 1i
//Create the forecast error -unbiasedness
gen ehat_ARMA = RV_w1 - sigma2arma13
gen ehat_ARMA_sq = ehat_ARMA^2
reg ehat_ARMA
ac ehat_ARMA
newey ehat_ARMA, lag(2)
//biased

gen ehat_GARCH = RV_w1 - sigma2GARCH
gen ehat_GARCH_sq = ehat_GARCH^2
reg ehat_GARCH
ac ehat_GARCH
newey ehat_GARCH, lag(3)
//Unbiased

//efficiency test
reg RV_w1 sigma2arma13 
test (sigma2arma13=1)(_cons=0)
scatter RV_w1 sigma2arma13 if dummy_insample == 0, scheme(s1color) ytitle("True Variance Values", size(small)) xtitle("ARMA(1,3) Forecasted Values", size(small)) legend(size(vsmall)) yla(, labsize(*0.5)) xla(, labsize(*0.5)) 
graph save "forecast scatter arma.gph" , replace
//inefficient

reg RV_w1 sigma2GARCH
test (sigma2GARCH=1)(_cons=0)
scatter RV_w1 sigma2GARCH if dummy_insample == 0, scheme(s1color) ytitle("True Variance Values", size(small)) xtitle("GARCH(1,1) Forecasted Values", size(small)) legend(size(vsmall)) yla(, labsize(*0.5)) xla(, labsize(*0.5)) 
graph save "forecast scatter garch.gph", replace
//inefficient
graph combine "forecast scatter arma.gph" "forecast scatter garch.gph", scheme(s1color) title("Scatter of True Variance Values against Forecasted Variance Values", size(medium)) iscale(1)
graph save "Exercise 1i.png", replace


//exercise 1j
//We disagree with the CEO. The traditional method in our opinion is still the best method to forecast the volatility of the assets.

//exercise 1k
summarize ehat_GARCH_sq ehat_ARMA_sq

gen dt = ehat_GARCH_sq - ehat_ARMA_sq
reg dt
ac dt
newey dt, lag(2)

//the coefficient of the dt is significant, meaning that arma model is significantly more accurate than the GARCH model.















