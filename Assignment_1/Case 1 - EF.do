//Prepare Workspace
clear all
ssc install outreg2
ssc install asdoc

//Change directory
cd "/Users/markdekwaasteniet/Documents/Master Finance/Empirical Finance/Case 1"

//Data structurizing
import excel "/Users/markdekwaasteniet/Documents/Master Finance/Empirical Finance/Case 1/data_case_I_group_56.xls", sheet("Data") firstrow


// Exercise 1a

//Test the normality of all variables except Date
sktest DEF sic2 mv ebitta wkta reta 

mat sktest = r(Utest)

//Subtract the last column of the matrix including the p-values
matrix Pvalues = sktest[.,4...]

//Summarize all the variables except Date
//Sut the variables into a table and convert to matrix
tabstat DEF sic2 mv ebitta wkta reta, statistic(mean sd min max) columns(statistics) save
mat statistics = r(StatTotal)'

//Merge the two matrices together
mat table1 = statistics,Pvalues\Pvalues,statistics
mat table1 = table1[1..6,1...]

//Output the matrix
asdoc wmat, mat(table1) title(Summary Statistics Table 1) dec(3) replace
//Rename Myfile.doc name to Table 1.doc

//Count Missing values in DEF.
egen number_missing = total(missing(DEF))
summarize number_missin




// Exercise 1b 

// Regress the two models. Using outreg2 to create output.
regres DEF ebitta mv
outreg2 using "Table 2.tex", replace word addstat(F-stat, e(F), R-adjusted, e(r2_a)) ctitle(Model 1) title(Ratios affecting the default probability)

regres DEF ebitta mv wkta reta
outreg2 using "Table 2.tex", append word addstat(F-stat, e(F), R-adjusted, e(r2_a)) ctitle(Model 2)

// Exercise 1e 

// regress model 2, incorporating dummy variables for SIC code with i.sic2.
regres DEF ebitta mv wkta reta i.sic2




// Exercise 1f

// Generate dummy variable. Siclower is 1 if the SIC code is below 40
gen lowSic = 0
replace lowSic = 1 if sic2 < 40


// Regress with the new dummy variable including interaction variables.
regress DEF ebitta mv wkta reta c.wkta#c.lowSic c.reta#c.lowSic 
test c.wkta#c.lowSic c.reta#c.lowSic 
outreg2 using "Table 2.tex", append word addstat(F-stat, e(F), R-adjusted, e(r2_a)) ctitle(Model 4) title(Ratios affecting the default probability (Including SIC dummy))




// Exercise 2b

//Create logit model.
logit DEF ebitta mv
outreg2 using "Table 4.tex", replace addstat(Pseudo R-squared, `e(r2_p)') ctitle(Model 5)

//Standardize wkta
egen wkta_s = std(wkta)
sum wkta_s

//Logit model including standardized wkta and normal reta
logit DEF ebitta mv wkta_s reta 
outreg2 using "Table 4.tex", append addstat(Pseudo R-squared, `e(r2_p)') ctitle(Model 6)




// Exercise 2c

// estimate the marginal effects.
logit DEF ebitta mv //model 5
margins, dydx(*) post //average effect of all the x's observations
outreg2 using "Table 5.tex", word replace noaster sideway noparen stats(coef) ctitle(Model 5 - Marginal Effects overall average)
logit DEF ebitta mv //model 5
margins, dydx(*) atmeans post //the effect at the average x observation.
outreg2 using "Table 5.tex", word append noaster sideway noparen stats(coef) ctitle(Model 5 - Marginal Effects atmeans)

logit DEF ebitta mv wkta_s reta  //model 6
margins, dydx(*) post //average effect of all the x's observations
outreg2 using "Table 5.tex", word append noaster sideway noparen stats(coef) ctitle(Model 6 - Marginal Effects overall average)
logit DEF ebitta mv wkta_s reta  //model 6
margins, dydx(*) atmeans post //the effect at the average x observation.
outreg2 using "Table 5.tex", word append noaster sideway noparen stats(coef) ctitle(Model 6 - Marginal Effects atmeans)




//Exercise 2d

// Making the graphs using lroc and saving them in the CD.
logit DEF ebitta mv if lowSic == 1
lroc if lowSic == 1, title("Model 5 in-sample")
graph save "Graph_model5_insample.gph", replace
lroc if lowSic == 0, title("Model 5 out-sample")
graph save "Graph_model5_outsample.gph", replace
graph combine Graph_model5_insample.gph Graph_model5_outsample.gph
graph save "Graph_model5.gph", replace

logit DEF ebitta mv wkta_s reta if lowSic == 1
lroc if lowSic == 1, title("Model 5 in-sample")
graph save "Graph_model6_insample.gph", replace
lroc if lowSic == 0, title("Model 5 out-sample")
graph save "Graph_model6_outsample.gph", replace
graph combine Graph_model6_insample.gph Graph_model6_outsample.gph
graph save "Graph_model6.gph", replace

graph combine Graph_model5.gph Graph_model6.gph, scheme(s1mono)









































