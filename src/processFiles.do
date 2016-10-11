clear all
global dir "C:\Users\achavda\Dropbo~1\Televi~1\Data\movied~1.24"
set more off

import delimited $dir/dbs/distributors.csv
drop contents

gen isBigFour = 0
replace isBigFour = 1 if strpos(company, "Columbia Broadcasting System (CBS")
replace isBigFour = 1 if strpos(company, "American Broadcasting Company (ABC")
replace isBigFour = 1 if strpos(company, "National Broadcasting Company (NBC")
replace isBigFour = 1 if strpos(company, "Fox Network")

save $dir/dbs/distributors, replace

clear
import delimited $dir/dbs/titles.csv

merge 1:m titleid using $dir/dbs/distributors
ren company distributor

keep if isBigFour & media == "TV"
keep titleid showname year season episodenumber company language startyear endyear region originalairing

bysort showname year: egen maxseason = max(season)
gen success = 0
replace success = 1 if  maxseason > 1 & maxseason < .
replace success = 2 if maxseason > 4 & maxseason < .

bysort showname year: egen maxepisode = max(episodenumber)
drop if maxepisode == .

drop maxseason maxepisode

duplicates drop showname year distributor,force

tab distributor success, row
