*export excel, variables as firstrow, replace
*Coder: Xu Lin
*Version: 1.0.0 (Nar. 17, 2016)
*Syntax:saveexcel filename
*Example:saveexcel aaa.xls
*注意：需要在填写文件名时添加文件后缀，如xls或xlsx

capture program drop saveexcel
program define saveexcel
version 12
syntax [anything(name=extvarlist equalok)] 
    export excel using "`extvarlist'",firstrow(variables) replace
end
