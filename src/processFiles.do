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

*** ratings importing and creation of marketshare info
clear
forvalues year = 1950/2014 {
	clear
	import excel using $dir/../NielsonRatings.xlsx, sheet("`year'") firstrow
	keep _rank _showname _network _rating
	gen seasonyear = `year'
	ren _rank rank
	ren _rating viewership
	capture: replace viewership = subinstr(viewership, ",", ".",.)
	destring viewership, replace
	ren _showname showname 
	ren _network network
	tempfile `year'
	display "`year'"
	compress
	save "`year'", replace
}

clear
forvalues year = 1950/2014 {
	append using "`year'"
}

compress
outsheet showname network seasonyear using $dir/dbs/highlyrated.csv, comma replace

* get market share of each firm
bysort seasonyear: egen totalshows = count(showname)
bysort seasonyear network: egen networkshows = count(network)
gen marketshare = networkshows / totalshows
keep network seasonyear marketshare

duplicates drop
save $dir/dbs/marketshare, replace

clear
forvalues year = 1950/2014 {
	append using "`year'"
}
keep showname seasonyear rank viewership
save $dir/dbs/highlyrated, replace

*** not used anymore, tag for whether first season was next to a top show
clear
import delimited $dir/dbs/favored.csv
save $dir/dbs/favored, replace


*** loading genre data
clear
import delimited $dir/dbs/genres.csv

* Short    	 571976
* Drama    	 361560
* Comedy    	 264182
* Documentary    	 231806
* Adult    	 75580
* Action    	 70372
* Thriller    	 69896
* Romance    	 69432
* Animation    	 58410
* Family    	 55953
* Horror    	 53259
* Music    	 51033
* Crime    	 49374
* Adventure    	 43290
* Fantasy    	 38735
* Sci-Fi    	 35150
* Mystery    	 32870
* Biography    	 28039
* History    	 24222
* Sport    	 22956
* Musical    	 18649
* War    	 16764
* Western    	 15436
* Reality-TV    	 15269
* News    	 14320
* Talk-Show    	 10879
* Game-Show    	 5437
* Film-Noir    	 720
* Lifestyle    	 1
* Experimental    	 1
* Erotica    	 1
* Commercial    	 1

duplicates drop
bysort titleid: gen j = _n
reshape wide genre, i(titleid) j(j)
egen g = concat(genre*), punct("|")
drop genre*
ren g genre
compress
save $dir/dbs/genres, replace

*** whether rolling stone thought the show was groundbreaking
clear
import delimited $dir/lists/rollingstone.csv
compress
save $dir/dbs/rollingstone, replace

*** which networks owned which production companies
clear
import delimited $dir/lists/productionownership.csv
drop pcount
duplicates drop
compress
save $dir/dbs/productionownership, replace

*** data on which shows were attached to which production companies
clear
import delimited $dir/dbs/production-companies.csv
* not sure why this is necessary, need to investigate
duplicates drop
compress
save $dir/dbs/production-companies, replace

*** networks that aired the show (distributors)
clear
import delimited $dir/dbs/distributors.csv
drop contents
destring startyear, replace
destring endyear, replace
keep if media == "TV" & language == "us"
drop media language region
* Doesn't seem to do much for the big four
drop originalairing
compress
save $dir/dbs/distributors, replace
use $dir/dbs/distributors, clear
ren company distributor
replace distributor = "CBS" if strpos(distributor, "Columbia Broadcasting System (CBS")
replace distributor = "ABC" if strpos(distributor, "American Broadcasting Company (ABC")
replace distributor = "NBC" if strpos(distributor, "National Broadcasting Company (NBC")
replace distributor = "FOX" if strpos(distributor, "Fox Network")
keep distributor 
bysort distributor: egen distributorrank = count(distributor)
duplicates drop
compress
save $dir/dbs/distributorrank, replace


*** some limited copyright information located here
clear
import delimited $dir/dbs/business.csv
* 'AD'    Admissions
* 'BT'    Production Budget
* 'CP'    Copyright Holder
* 'GR'    Gross Receipts
* 'MV'    Title
* 'OW'    Opening Weekend Gross
* 'PD'    Production Dates
* 'RT'    Rental Income
* 'SD'    Filming / Shooting Dates
* 'ST'    Studio where filmed
* 'WG'    Weekend Gross
* keep if type == "SD" | type == "CP"
keep if type == "CP"
drop type
duplicates drop
compress
save $dir/dbs/business, replace

*** data on foreign content
clear
* this file can have the same title marked as domenstic (forign = 0) as well
* as foriegin (foreogin == 1). need to keep those marked as domestic, regardless
* of foreign term
import delimited $dir/dbs/country.csv
bysort titleid: egen min_foreign = min(foreign)
* drop foreign entries if show also had a domestic flag
drop if min_foreign == 0 & foreign == 1
* drop domestic data; don't need it
* actually need to keep this to move from episode to season level data
* drop if foreign == 0
* clean up
drop min_foreign
duplicates drop
save $dir/dbs/country, replace

* now do the same with language
clear
* this file can have the same title marked as domenstic (forign = 0) as well
* as foriegin (foreogin == 1). need to keep those marked as domestic, regardless
* of foreign term
import delimited $dir/dbs/language.csv
bysort titleid: egen min_foreign = min(foreign)
* drop foreign entries if show also had a domestic flag
drop if min_foreign == 0 & foreign == 1
* drop domestic data; don't need it
* drop if foreign == 0
* clean up
drop min_foreign
duplicates drop
save $dir/dbs/language, replace

*** using broadcast year to deal with mismatch between season and year scheduled
clear
import delimited $dir/dbs/broadcastyear.csv
duplicates drop
* this happens because my titleid's aren't currently unique if showname and 
* year had multiple shows in it. Original code ignored the /I after the year 
* in the movie database. Should fix at some point. 
quietly: count
local old_count = r(N)
sort titleid broadcastyear
by titleid: keep if _n == 1
quietly: count
assert(`old_count' - r(N) < 700)
save $dir/dbs/broadcastyear

*** for big four have data on schedule order
clear
import delimited $dir/dbs/favoredall.csv
encode dayofweek, gen(weekday)
drop dayofweek
ren weekday dayofweek
compress
* IMDB data has the long name for NCIS
* replace showname = "NCIS: Naval Criminal Investigative Service" if showname == "NCIS"
save $dir/dbs/favoredall, replace
