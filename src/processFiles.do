clear all
global dir "C:\Users\achavda\Dropbo~1\Televi~1\Data\"
set more off

clear
import delimited $dir/tvcomp~1.csv, varnames(1)
drop if missing(recordid)
compress
save $dir/tvcompany, replace

clear
import excel $dir/tvfina~1, firstrow case(lower)
ren l mostrecent10
drop if missing(recordid)
destring recordid,replace
compress
save $dir/tvfinancial, replace

clear 
import delimited $dir/tvover~1.csv, varnames(1)
keep if type == "TV Pilot" | type == "TV Series"
drop if real(recordid) == .
destring recordid, replace
merge 1:1 recordid using $dir/tvcompany
drop if _merge == 2
drop _merge
merge 1:1 recordid using $dir/tvfinancial
drop if _merge == 2
drop _merge

* looks like pilot information is only available for some type == pilot
replace pilotstartdate = "" if pilotstartdate == "No Pilot Start Date Available."
replace productionnotes = "" if productionnotes == "No Production Notes Available."
replace developmentnotes  = "" if developmentnotes  == "No Development Notes Available."
replace distributionnotes  = "" if distributionnotes  == "No Distribution Notes Available."
replace logline  = "" if logline  == "No Logline Available."

gen pilot = !missing(pilotstartdate)

foreach var of varlist *notes {
	display "`var'"
	count if strpos(lower(`var'), "pilot") > 0
	replace pilot = 1 if strpos(lower(`var'), "pilot") > 0
}
* need to filter out non-scripted shows since they won't have a pilot or script
gen scripted = 1
gen totalgenres = wordcount(genre)
replace scripted = 0 if strpos(genre, "Reality")
replace scripted = 0 if strpos(genre, "Game Show")
replace scripted = 0 if strpos(genre, "Talk")
replace scripted = 0 if strpos(genre, "Interview")
replace scripted = 0 if strpos(genre, "Documentary")
replace scripted = 0 if strpos(genre, "Variety")
replace scripted = 0 if strpos(genre, "Music") & (totalgenres == 1)
replace scripted = 0 if strpos(genre, "News") & (totalgenres == 1) 
replace scripted = 0 if strpos(genre, "Sports") & (totalgenres == 1)
drop if !scripted
drop scripted totalgenres

gen greenlit = type == "TV Series"
* question of whether skipping pilots is a good idea seems to be too 
* messy to answer in my dataset. assuming everything greenlit was actually piloted
replace pilot = 1 if greenlit
drop type

compress
save $dir/tvpilots, replace
