clear all
global dir "C:\Users\achavda\Dropbo~1\Televi~1\Data\movied~1.24"
set more off

* problem with this IV is that many shows are off the network

import excel "C:\Users\achavda\Dropbox (MIT)\Television Project\Data\ActorDeaths.xlsm", sheet("Sheet1") firstrow clear
keep Show Dateofdeath
gen deathyear = regexs(0) if(regexm(Dateofdeath, "[0-9][0-9][0-9][0-9]"))
destring deathyear, replace
* assuming the death has impact in the next season
gen seasonyear = deathyear + 1
gen showname = subinstr(Show, char(34), "", .)
gen actordeath = 1
keep showname seasonyear actordeath
duplicates drop
compress
save $dir/dbs/actordeaths, replace

clear 
use $dir/dbs/midpoint_all, clear

drop titleid episodenumber
duplicates drop

bysort showname year: egen maxSeason = max(season)
drop season
* still some duplicates after this from shows that are listed on two or three different networks
duplicates drop
expand maxSeason
gen seasonyear = year
bysort showname year: replace seasonyear = seasonyear + _n - 1
drop maxSeason

* error in DB where show is listed twice
bysort showname seasonyear: egen keepyear = min(year)
keep if keepyear == year
drop keepyear

* adding season level rating data
merge 1:1 showname year seasonyear using $dir/dbs/ratings
drop if _merge == 2
drop _merge

merge 1:1 showname seasonyear using $dir/dbs/actordeaths
drop if _merge == 2
drop _merge
replace actordeath = 0 if missing(actordeath)
