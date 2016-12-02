* using this site as a cross check
* http://reporter.blogs.com/pilotseason/200910-pilot-orders-abc.html

clear all
global dir "C:\Users\achavda\Dropbo~1\Televi~1\Data\"
set more off

use $dir/tvpilots
drop usrelease dvdrelease internationalreleasedate shootstartfeature shootwrapfeature
drop foreigntheatricaldistributor domestictheatricaldistributor financingcompany
drop estimatedbudget usboxofficecume technicalnotes mostrecent10 mostrecentawards

* very small number of these have dual networks
gen network = "FOX" if strpos(broadcastnetwork,"Fox")
replace network = "ABC" if strpos(broadcastnetwork, "ABC")
replace network = "CBS" if strpos(broadcastnetwork, "CBS")
replace network = "NBC" if strpos(broadcastnetwork, "NBC")
* very small number of scripts with broadcastnetwork also have cablenewtork
drop if missing(network)
drop broadcastnetwork cablenetwork

gen year = substr(seasonspan, 1,4)
drop if real(year) == .
destring year, replace
drop seasonspan

* only ~30 of these exist; maybe better to merge with synopsis?
drop logline

* this is from the production ownership spreadsheet
replace productioncompany = studio + " " + productioncompany
replace productioncompany = lower(productioncompany)
gen sisterstudio = 0
replace sisterstudio = 1 if network == "ABC" & strpos(productioncompany, "abc ")
replace sisterstudio = 1 if network == "ABC" & strpos(productioncompany, "disney") & year > 1995
replace sisterstudio = 1 if network == "ABC" & strpos(productioncompany, "touchstone") & year > 1995
replace sisterstudio = 1 if network == "ABC" & strpos(productioncompany, "dic ") & year > 1993 & year <= 2000
replace sisterstudio = 1 if network == "CBS" & strpos(productioncompany, "cbs ") 
replace sisterstudio = 1 if network == "CBS" & strpos(productioncompany, "paramount") & year > 2000 & year <= 2009
replace sisterstudio = 1 if network == "CBS" & strpos(productioncompany, "viacom") & year > 2000 & year <= 2009
replace sisterstudio = 1 if network == "CBS" & strpos(productioncompany, "tristar") & year > 1983 & year <= 1985
replace sisterstudio = 1 if network == "FOX" & strpos(productioncompany, "fox ") 
replace sisterstudio = 1 if network == "FOX" & strpos(productioncompany, "reveille") & year > 2008
replace sisterstudio = 1 if network == "FOX" & strpos(productioncompany, "new world") & year > 1997
replace sisterstudio = 1 if network == "FOX" & strpos(productioncompany, "regency") & year > 1998 & year <= 2008
replace sisterstudio = 1 if network == "NBC" & strpos(productioncompany, "nbc ")
replace sisterstudio = 1 if network == "NBC" & strpos(productioncompany, "universal") & year > 2004
replace sisterstudio = 1 if network == "NBC" & strpos(productioncompany, "revue") & year > 2004
drop productioncompany

gen jointnames = name + akas
drop akas

* seems like in the first stage getting to pilot is higher for things
* outside the studio
tab pilot sisterstudio, nofreq column
* verifying this is true across networks
* bysort network: regress pilot sisterstudio

* conditional on getting to pilot, sisterstudio has slightly positive effect
tab greenlit sisterstudio if pilot, nofreq column
* directionally true across networks, significant for CBS and FOX
* bysort network: regress greenlit sisterstudio if pilot

preserve
* data seems odd pre-2000
drop if year < 2000
drop if year > 2016
* keep if network == "ABC"
* keep if network == "CBS"
* keep if network == "NBC"
* keep if network == "FOX"
bysort year network: egen outcome = mean(pilot) if !sisterstudio
bysort year network: egen outcome2 = mean(pilot) if sisterstudio
replace outcome = outcome2 if missing(outcome)
encode network, gen(net)
keep outcome net sisterstudio year
duplicates drop
regress outcome sisterstudio i.net
restore

preserve
* data seems odd pre-2000
drop if year < 2000
drop if year > 2016
* keep if network == "ABC"
* keep if network == "CBS"
* keep if network == "NBC"
* keep if network == "FOX"
keep if pilot
bysort year network: egen outcome = mean(greenlit) if !sisterstudio
bysort year network: egen outcome2 = mean(greenlit) if sisterstudio
replace outcome = outcome2 if missing(outcome)
encode network, gen(net)
keep outcome net sisterstudio year network
duplicates drop
regress outcome sisterstudio i.net
drop net
egen id = group(year network)
reshape wide outcome, i(id) j(sisterstudio)
gen bias = outcome1 - outcome0
keep network year bias
save $dir/bias, replace
restore

