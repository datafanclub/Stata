*suestreg is suest
*Coder: Xu Lin
*Version: 1.0.2 (Mar. 27, 2016)
*Syntax: syntax varlist(min=2) [if] [in] [, Dummy(varlist) Groupvar(varlist min=1 max=1) Testvar(varlist min=1 max=1) Vce(str)]
*Example: suestreg lncompw $x,d(ind01 year) v(cl(dm)) g(hypo1) t(bi1w) 
*d中指定哑变量变量名
*v中指定方差调整的方法，有cl(dm)和r两种，可以混用
*g中指定分组的变量名，只能指定一个
*t中指定比较系数差异的变量名，可以指定多个

capture program drop suestreg
program define suestreg
version 12
syntax varlist(min=2) [if] [in] /* 
    */  [, Dummy(varlist) Groupvar(varlist min=1 max=1) Output(string) Testvar(varlist min=1) Vce(str)]
*set trace on
sort `groupvar'
tempvar gr
egen `gr'=group(`groupvar')
local groupname1=`groupvar' in 1
local _end1=_N
local groupname2=`groupvar' in `_end1'
qui sum `gr'
if r(max) > 2 {
    dis in red "More Than 2 Groups!"
    exit 198
}
else {
    if r(max)<2 {
        dis in red "Only 1 Group!"
        exit 198
    }
}
if "`vce'"=="" {
    local `vce'="r"
}
local d: word count `dummy'
tokenize "`dummy'"
local dum=""
forvalues i=1/`d' {
    local dum="`dum'"+" "+"i."+"``i''"
}
qui xi:reg `varlist' `dum' if `gr'==1
est store m1
local num1=e(N)
qui xi:reg `varlist' `dum' if `gr'==2
est store m2
local num2=e(N)
suest m1 m2, `vce'
local t: word count `testvar'
tokenize "`testvar'"

forvalues k=1/`t' {
qui suest m1 m2, `vce'
test [m1_mean]``k''=[m2_mean]``k''
tempname aa`k'
mat `aa`k'' = J(3,2,0) /*#指的是输出表格列的列数n，因为第一列后面生产*/
mat `aa`k''[1,1]=`num1'
mat `aa`k''[1,2]=`num2'
mat `aa`k''[2,1]=[m1_mean]``k''
mat `aa`k''[2,2]=[m2_mean]``k''
local chi2=r(chi2)
local pchi2=r(p)

qui {
    xi:reg `varlist' `dum' if `gr'==1
    tempvar end1
    local `end1' = e(df_m)
    vif
    forvalues i=1/``end1'' {
        local name=r(name_`i')
        if "`name'"=="``k''" {
            local vi=r(vif_`i')
            local vif1=`vi'
        }
    }
    xi:reg `varlist' `dum' if `gr'==2
    tempvar end2
    local `end2' = e(df_m)
    vif
    forvalues i=1/``end2'' {
        local name=r(name_`i')
        if "`name'"=="``k''" {
            local vi=r(vif_`i')
            local vif2=`vi'
        }
    }  

mat `aa`k''[3,1]=`vif1'
mat `aa`k''[3,2]=`vif2'
mat rownames `aa`k''= obs ``k'' vif
local grname1="`groupvar'=`groupname1'"
local grname2="`groupvar'=`groupname2'"
mat colnames `aa`k''= `grname1' `grname2' 
}
}
forvalues k=1/`t' {
dis _n in green _dup(10) "=" in yellow "比较系数结果" in green _dup(10) "="
mat list `aa`k'',noheader nodotz format(%10.3g)
disp
di as txt _col(8) "chi2 = " as res %8.2f `chi2'
di as txt _col(0) "Prob > chi2 = " as res %8.4f `pchi2'
}

if "`output'"!="" {
gettoken y x: varlist
qui xi:reg `varlist' `dum' if `gr'==1,`vce'
qui outreg2 `x' using "`output'.doc", replace adjr2 bdec(4) tdec(3) tstat ctitle("`groupvar'=0")
qui xi:reg `varlist' `dum' if `gr'==2,`vce'
outreg2 `x' using "`output'.doc", append adjr2 bdec(4) tdec(3) tstat ctitle("`groupvar'=1")
}
else {
gettoken y x: varlist
local output="_suestregresult"
qui xi:reg `varlist' `dum' if `gr'==1,`vce'
qui outreg2 `x' using "`output'.doc", replace adjr2 bdec(4) tdec(3) tstat ctitle("`groupvar'=0")
qui xi:reg `varlist' `dum' if `gr'==2,`vce'
outreg2 `x' using "`output'.doc", append adjr2 bdec(4) tdec(3) tstat ctitle("`groupvar'=1")
}
end
