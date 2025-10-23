* ssc install rscript
clear 
cd "C:\Users\wb200957\OneDrive - WBG\DEC\SAE\Workshops\code"
import delimited using "./data/mosaikvars.csv"
tostring(ea_code), replace 
gen EA_CODE=ea_code
merge 1:1 EA_CODE using "./data/mwi_pop",keep(3) nogen 


gen ta_code=substr(ea_code,1,5)
save "./data/pop", replace 

import delimited using "./data/ihs5ea.csv", clear 
tostring(ea_code), replace 
merge 1:1 ea_code using "./data/pop", keep(3) nogen 
gen transformed_poor=asin(sqrt(poor))
set seed 123456 
lasso linear transformed_poor mosaik* [iw=total_weights], selection(cv) 
local selected_vars = e(allvars_sel)
drop transformed_poor 
save "./data/sample", replace 
Rpovmap poor `selected_vars', pop_data(./data/pop.dta) smp_data(./data/sample.dta) smp_domains("ta_code") pop_domains("ta_code") weights(total_weights) transformation("arcsin") l(0) mse(TRUE)  pop_weights("population") weights_type("nlme") saveobject("sae_output") savexls("sae_output.xlsx") 