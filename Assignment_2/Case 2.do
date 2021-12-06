//Prepare Workspace
clear all
ssc install outreg2
ssc install asdoc

//Change directory
cd "/Users/markdekwaasteniet/Documents/Master Finance/Empirical Finance/Case 2"

//Data structurizing
import excel "/Users/markdekwaasteniet/Documents/Master Finance/Empirical Finance/Case 2/data_case_II_group_56.xls", sheet("Data") firstrow

// Exercise 1a

// Create the variable: excess_ret
gen excess_ret = RETURN-RF
label var excess_ret "Return over the Risk Free rate"

// Creating the log volume variable using the natural log
gen ln_volume=ln(VOLUME)


//Test the normality of all variables except Date
sktest excess_ret VOLUME IDCODE MktRF SMB HML RMW CMA RF Unemp Inflation

mat sktest = r(Utest)

//Subtract the last column of the matrix including the p-values
matrix Pvalues = sktest[.,4...]

//Summarize all the variables except Date
//Sut the variables into a table and convert to matrix
tabstat excess_ret ln_volume IDCODE MktRF SMB HML RMW CMA RF Unemp Inflation, statistic(mean sd min max) columns(statistics) save
mat statistics = r(StatTotal)'

//Merge the two matrices together
mat table1 = statistics,Pvalues\Pvalues,statistics
mat table1 = table1[1..10,1...]

//Output the matrix
asdoc wmat, mat(table1) title(Summary Statistics Table 1) dec(3) replace
//Rename Myfile.doc name to Table 1.doc

//Set Panel Data
gen year_month = ym(StataYear,StataMonth) //Create own time variable that is easier to read
xtset IDCODE year_month, monthly

// Exercise 1b
// Model 1:
reg excess_ret MktRF SMB HML RMW CMA
outreg2 using "Table 2.tex", replace word addstat(R-adjusted, e(r2_a), F-stat, e(F)) ctitle(Model 1) title(FF and Economic Factors affecting the Excess Stock Return)

// Model 2:
reg excess_ret MktRF SMB HML RMW CMA Unemp Inflation ln_volume
outreg2 using "Table 2.tex", append word addstat(R-adjusted, e(r2_a), F-stat, e(F)) ctitle(Model 2 - Including Economic Factors) title(FF and Economic Factors affecting the Excess Stock Return)


// Exercise 1d
// Use clustered standard errors.
reg excess_ret MktRF SMB HML RMW CMA, vce(cluster IDCODE)
outreg2 using "Table 2.tex", append word addstat(R-adjusted, e(r2_a), F-stat, e(F)) ctitle(Model 1 - Clustered Std Errors) title(Factors affecting the Excess Stock Return)


// Exercise 1e
reg excess_ret MktRF SMB HML RMW CMA Unemp Inflation ln_volume
outreg2 using "Table 3.tex", replace word addstat(F-stat, e(F)) ctitle(Model 2) title(Factors affecting the Excess Stock Return (including industry effects))


//Create Industry fixed effects model using industry dummies:
reg excess_ret MktRF SMB HML RMW CMA Unemp Inflation ln_volume i.Industry
outreg2 using "Table 3.tex", append word addstat(F-stat, e(F)) ctitle(Model 2 - Industry Fixed Effects) title(Factors affecting the Excess Stock Return (including industry effects))


// Exercise 1f
// Per month Time FE model:
reg excess_ret ln_volume i.year_month
outreg2 using "Table 3.tex", append word addstat(F-stat, e(F)) ctitle(Model 2 - Time Fixed Effects) title(Factors affecting the Excess Stock Return (including industry effects))


// Exercise 1g
xi i.year_month, pre(Y)
xtreg excess_ret ln_volume Yyear_month*, fe
outreg2 using "Table 3.tex", append word addstat(F-stat, e(F)) ctitle(Model 2 - Time and Firm Fixed Effects) title(Factors affecting the Excess Stock Return (including industry effects))


// Exercise 1h
//Ftest for time fixed effects
reg excess_ret ln_volume i.time
testparm i.time

//Ftest for firm fixed effects on top of time fixed effects.
reg excess_ret ln_volume i.time i.IDCODE
testparm i.IDCODE

// Exercise 1i

// Create two new dummy variables. 1 is the before event. 1 is for the affected firms.
// January 2001 is equal to time = 181
gen after_law = 0
replace after_law = 1 if time >= 181

gen affect_industry = 0
replace affect_industry = 1 if (Industry == 2 | Industry == 6)

// then we also let the dummy variables interact with each other in the model.
reg excess_ret after_law affect_industry c.after_law#c.affect_industry ln_volume
outreg2 using "Table 4.tex", replace word addstat(F-stat, e(F)) ctitle(Model 3 ) title(Difference in Difference analysis)
