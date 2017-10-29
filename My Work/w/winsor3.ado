*winsorize outliers
*Coder: Xu Lin
*Version：1.0.0 (Mar. 17, 2016)
*Update1：1.0.1 (Nov. 03, 2016)
*Syntax: winsor3 varlist [, REPLACE Suffix(string) Cuts(# #)]
*Example: winsor3 x1 x2, s(w) c(1 99)
*结果与stata官方的winsor一致。
*1.0.1版更新：添加当指定suffix的情况下，会自动生成全局宏变量_winsorx,将所有参与winsor的变量后加指定suffix


cap program drop winsor3
program def winsor3, sortpreserve 
        version 8
        syntax varlist(min=1) [if] [in] /* 
    */  [, Suffix(str) REPLACE Cuts(numlist max=2 min=2 >=0 <=100) by(varlist)] 
*set trace on
    if "`replace'"!="" & "`suffix'"!=""{
      dis in w "suffix() " in red "cannot be specified with" in w " replace" 
      exit 198
    }
    
    if "`suffix'"==""{
       if "`trim'" == ""{ 
         local suffix="_w"
       }
       else{
         local suffix="_tr"
       }
    }

    if "`cuts'"==""{
        local low=1/100
        local high=1/100
    }
    else{
        tokenize "`cuts'"
        if `2' > `1' {
          local low=`1'/100
          local high=1-`2'/100
        }
        else {
          local low=`2'/100
          local high=1-`1'/100
        }
        
        *noisily: disp "low=`low'    high=`high'"
    }

    if "`replace'" == ""{
      foreach k of varlist `varlist' {
        capture confirm variable `k'`suffix', exact
        if _rc == 0 {
            di as error "`k'`suffix' is existed, please try a new varname!"
            exit 111
        }
      }
	  global winsor_=""
      foreach v in `varlist' {
        tempvar nvar nvarh nvarl
        local newvar="`v'"+"`suffix'"
		global winsor_="$winsor_"+"`newvar'"+" "
        winsor `v',gen(`nvarl') p(`low')
        winsor `v',gen(`nvarh') p(`high')
        gen `nvar'=`nvarl'
        replace `nvar'=`nvarh' if `v'>`nvarh'
        rename `nvar' `newvar'
      }
    }
    else {
      foreach v in `varlist' {
        tempvar nvar nvarh nvarl
        winsor `v',gen(`nvarl') p(`low')
        winsor `v',gen(`nvarh') p(`high')
        gen `nvar'=`nvarl'
        replace `nvar'=`nvarh' if `v'>`nvarh'
        replace `v'=`nvar'
      }
    }
end
