

*! Inspirit of -winsor-(NJ Cox) and -winsorizeJ-(J Caskey)
*! Lian Yujun, arlionn@163.com, 2013-12-25
*! version 1.0

cap program drop winsor2
program def winsor2, sortpreserve 
        version 8
        *set trace on
        syntax varlist(min=1) [if] [in] /* 
	*/  [, Suffix(str) REPLACE TRim Cuts(numlist max=2 min=2 >=0 <=100) by(varlist)] 

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
		local low=1
		local high=99
	}
	else{
		tokenize "`cuts'"
		local low=`1'
		mac shift
		local high=`1'
		if `low'>`high' {
			tempname tmp
			local `tmp'=`low'
			local low=`high'
			local high=`tmp'
		}
		if `low'<1|`high'<1{
		   if "`trim'"!=""{
		      local CUT "trim"
		   }
		   else{
		      local CUT "winsor"
		   }
		    dis in y "Warning: " in g "cuts(1   99) means `CUT' at   1th percentile and 99th percentile,"
			dis in g "         " in g "cuts(0.1 90) means `CUT' at 0.1th percentile and 90th percentile,"
			dis in g "         " in g "make sure cuts(`low' `high') you specified is what you want. "
		}
	}

	* Validate suffix
	if "`replace'" == ""{
	  foreach k of varlist `varlist' {
		capture confirm variable `k'`suffix', exact
		if _rc == 0 {
			di as error "Suffix `suffix' is invalid for `k'"
			exit 111
		}
	  }
	}
	
	
	* Validate by list
	if "`by'" != "" {
		capture confirm variable `by'
		if _rc != 0 {
			di as error "by() list is invalid"
			exit 111
	    }
	}	
		
 
	* Winsorize or Trimming
	tempname if2
	if "`by'" == "" {   // no by()
		foreach k of varlist `varlist' {
			qui centile `k' `if' `in', centile(`low' `high')
			
			if "`if'"==""{
			  local `if2' "if ~missing(`k')"
			}
			else{
			  local `if2' "`if' & ~missing(`k')"
			}
			
			local vtype=`"`:type `k''"'
			
			if "`replace'"!=""{
			  if "`trim'"==""{  //winsorize
			    qui replace `k' = max(min(r(c_2),`k'),r(c_1)) ``if2'' `in'
				 local labk : variable label `k'
			     label variable `k' "`labk'-Winsorized(p`low',p`high')"					
			  }
			  else{             //trimming
				qui replace `k' = cond(`k'<r(c_1),.,`k') ``if2'' `in'
				qui replace `k' = cond(`k'>r(c_2),.,`k') ``if2'' `in'
			     local labk : variable label `k'
			     label variable `k' "`labk'-Trimmed(p`low',p`high')"				 
			  }
			}
			else{
			  if "`trim'"==""{  //winsorize
			    qui gen `vtype' `k'`suffix'=max(min(r(c_2),`k'),r(c_1)) ``if2'' `in'
				 local labk : variable label `k'
			     label variable `k'`suffix' "`labk'-Winsorized(p`low',p`high')"
			  }
			  else{             //Trimming
			    qui gen `vtype' `k'`suffix' = cond(`k'<r(c_1),.,`k') ``if2'' `in'
				qui replace     `k'`suffix' = cond(`k'>r(c_2),.,`k') ``if2'' `in'
			     local labk : variable label `k'
			     label variable `k'`suffix' "`labk'-Trimmed(p`low',p`high')"			    
			  }
			}
		}
	}
	else{   // with by()
		foreach k of varlist `varlist' {
		    tempvar pL pH tL
			
			if "`if'"==""{
			   local `if2' "if ~missing(`k')"
			}
			else{
			   local `if2' "`if' & ~missing(`k')"
			}  
			
			local vtype=`"`:type `k''"'
			
			qui egen `vtype' `pL'=pctile(`k') ``if2'' `in', p(`low')  by(`by')
			qui egen `vtype' `pH'=pctile(`k') ``if2'' `in', p(`high') by(`by')
			qui egen `vtype' `tL'=rowmax(`pL' `k') ``if2'' `in'
			
			if "`replace'"!=""{
			   if "`trim'"==""{   //winsorize
			     tempvar kwinsor
			     qui egen `vtype' `kwinsor'=rowmin(`pH' `tL') ``if2'' `in'
			     qui replace `k' = `kwinsor'
				 local labk : variable label `k'
			     label variable `k' "`labk'-Winsorized(p`low',p`high')"
			     qui drop `kwinsor'
			   }
			   else{              //Trimming
				 qui replace `k' = cond(`k'<`pL',.,`k') ``if2'' `in'
				 qui replace `k' = cond(`k'>`pH',.,`k') ``if2'' `in'
			     local labk : variable label `k'
			     label variable `k' "`labk'-Trimmed(p`low',p`high')"				 
			   }
			}
			
			else{
			   if "`trim'"==""{   //winsorize
			     qui egen `k'`suffix'=rowmin(`pH' `tL') ``if2'' `in'
			     qui drop `pL' `pH' `tL'
			     local labk : variable label `k'
			     label variable `k'`suffix' "`labk'-Winsorized(p`low',p`high')"
			   }
			   else{
			     qui gen `vtype' `k'`suffix' = cond(`k'<`pL',.,`k') ``if2'' `in'
				 qui replace     `k'`suffix' = cond(`k'>`pH',.,`k') ``if2'' `in'
			     local labk : variable label `k'
			     label variable `k'`suffix' "`labk'-Trimmed(p`low',p`high')"			     
			   }
			}
		    
		}
	} 
		
	

end
