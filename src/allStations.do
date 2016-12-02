clear all
global dir "C:\Users\achavda\Dropbo~1\Televi~1\Data\movied~1.24"
set more off

program chartbyyear

	args outcome dependent year conditional
	quietly: su `year'
	local yearstart = r(min)
	local yearend = r(max)
	local years = 1 + `yearend' - `yearstart'
	* columns are year, estimate, lower bound, upper bound
	matrix result = J(`years',4,0)
	matrix colnames result = year b ll ul
	forvalues i = 1/`years' {
		local currentyear = `i' + `yearstart' - 1
		if "`conditional'" == "" {
			quietly: regress `outcome' `dependent' if `year' == `currentyear'
		} 
		else {
			quietly: regress `outcome' `dependent' if `year' == `currentyear' & `conditional'
		}
		matrix c = r(table)
		matrix result[`i',1] = `currentyear'
		matrix result[`i',2] = c["b","`dependent'"]
		matrix result[`i',3] = c["ll","`dependent'"]
		matrix result[`i',4] = c["ul","`dependent'"]
		matrix drop c
	}
	
	preserve
	clear 
 	svmat result, names(col)
	graph twoway ///
		(rarea ul ll year, color(gs12) fintensity(inten50)) ///
		(line b year, lcolor(midblue) lpattern(dash)) ///
		(scatter b year, mcolor(midblue)) ///
		, title("Impact of `dependent' on `outcome' | `conditional'") ytitle("Magnitude of effect") yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) legend(order(1 3) label(3 "Point Estimate") label(1 "Confidence Interval") cols(1) size(small)) graphregion(fcolor(dimgray))	
	restore
	matrix drop result

end

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

* matlat script does some stuff
clear
import delimited $dir/dbs/favored.csv
save $dir/dbs/favored, replace

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

clear
import delimited $dir/lists/rollingstone.csv

compress
save $dir/dbs/rollingstone, replace

clear
import delimited $dir/lists/productionownership.csv
drop pcount
duplicates drop

compress
save $dir/dbs/productionownership, replace


clear
import delimited $dir/dbs/production-companies.csv

* not sure why this is necessary, need to investigate
duplicates drop

compress
save $dir/dbs/production-companies, replace

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

keep if type == "SD" | type == "CP"

compress
save $dir/dbs/business, replace

clear
import delimited $dir/dbs/titles.csv

* filter out titles known to be foreign
preserve
clear
* this file can have the same title marked as domenstic (forign = 0) as well
* as foriegin (foreogin == 1). need to keep those marked as domestic, regardless
* of foreign term
import delimited $dir/dbs/country.csv
bysort titleid: egen min_foreign = min(foreign)
* drop foreign entries if show also had a domestic flag
drop if min_foreign == 0 & foreign == 1
* drop domestic data; don't need it
drop if foreign == 0
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
drop if foreign == 0
* clean up
drop min_foreign
duplicates drop
save $dir/dbs/language, replace
restore

merge 1:1 titleid using $dir/dbs/country
drop if _merge != 1
drop _merge foreign

* filtering out anything not in english from my dataset. Will screw up 
* any analysis reliant on for example spanish language networks. 
merge 1:1 titleid using $dir/dbs/language
drop if _merge != 1
drop _merge foreign

merge 1:m titleid using $dir/dbs/distributors
ren company distributor
drop if _merge == 2
drop _merge

bysort showname year: egen maxseason = max(season)
gen success = 0
replace success = 1 if  maxseason > 1 & maxseason < .
replace success = 2 if maxseason > 4 & maxseason < .

* trying to get rid of things that are not TV shows
* later on we remove by genre as well
bysort showname year: egen maxepisode = max(episodenumber)
drop if maxepisode == . & maxseason == .
drop maxseason maxepisode

* looking for errors in distributors. Bones season 10 for example has 
* 2 episodes marked incorrectly as distributed by ABC rather than FOX
* Treasury Men in Action 1950 seems to be the only one where this noise 
* is legitimate
bysort showname year season distributor: egen episodebydistributor = count(episodenumber)
bysort showname year season: egen episodecount = count(episodenumber)
bysort showname year season: egen true_dist = mode(distributor)
replace distributor = true_dist if episodebydistributor / episodecount < 0.1
drop episodebydistributor episodecount true_dist

bysort showname year season: egen true_dist = mode(distributor)
replace distributor = true_dist if missing(distributor)
drop true_dist
bysort showname year: egen true_dist = mode(distributor)
replace distributor = true_dist if missing(distributor)
drop true_dist

* drop episodename issuspended endyear isBigFour
drop episodename issuspended endyear
duplicates drop

* we still have titleid duplicates for null season entries when the show
* switched between networks during its run, see Medium or Matlock
* coding the null season to be equal to the first season
* duplicates tag titleid, gen(dup)
* focus on whatever distributor was first run
sort titleid startyear
by titleid: keep if _n == 1
* drop if dup & year != startyear
drop startyear

* things that are left are when a show was broadcast across a conglomerate
* War & Peace on both A&E, History, and Lifetime in the same year

gen isBigFour = 0
replace isBigFour = 1 if strpos(distributor, "Columbia Broadcasting System (CBS")
replace distributor = "CBS" if strpos(distributor, "Columbia Broadcasting System (CBS")
replace isBigFour = 1 if strpos(distributor, "American Broadcasting Company (ABC")
replace distributor = "ABC" if strpos(distributor, "American Broadcasting Company (ABC")
replace isBigFour = 1 if strpos(distributor, "National Broadcasting Company (NBC")
replace distributor = "NBC" if strpos(distributor, "National Broadcasting Company (NBC")
replace isBigFour = 1 if strpos(distributor, "Fox Network")
replace distributor = "FOX" if strpos(distributor, "Fox Network")

compress

* one weird ones
drop if strpos(showname,"Kraft Television Theatre") & year == 1953 & season == . & strpos(distributor, "ABC")
drop if strpos(showname,"21 Beacon Street") & year == 1959 & season == . & strpos(distributor, "ABC")
drop if strpos(showname,"Black Saddle") & year == 1959 & season == . & strpos(distributor, "NBC")
drop if strpos(showname,"Dark Shadows") & year == 1991 & season == . & strpos(distributor, "ABC")
drop if strpos(showname,"Davis Rules") & year == 1991 & season == . & strpos(distributor, "CBS")
drop if strpos(showname,"Wuzzles") & year == 1985 & season == . & strpos(distributor, "ABC")
drop if strpos(showname,"Getting By") & year == 1993 & season == . & strpos(distributor, "NBC")
drop if strpos(showname,"Presidential Debates")

save $dir/dbs/midpoint_all, replace
use $dir/dbs/midpoint_all, clear

* basically shows that appeared on two different networks their first year
* duplicates report titleid
* creating a rank for distributors and then saving only the largest nework
bysort distributor: gen distSize = _N
replace distSize = 0 if missing(distributor)
sort titleid distSize
by titleid: keep if _n == _N
drop distSize
* should be cleared up now
* duplicates report titleid

merge 1:m titleid using $dir/dbs/genres
drop if _merge == 2
drop _merge
bysort showname year: egen g = mode(genre)
drop genre
ren g genre

merge 1:m titleid using $dir/dbs/production-companies
drop if _merge == 2
drop _merge

merge m:1 productioncompany using $dir/dbs/productionownership
drop if _merge == 2
drop _merge

drop countrycode

replace startdate = 0 if missing(startdate)
replace enddate = 9999 if missing(enddate)

bysort titleid: egen cooks = count(productioncompany)
drop productioncompany

****

gen sisterstudio = 0
replace sisterstudio = 1 if distributor == network & startdate < year & enddate > year & isBigFour

gen far = 0
replace far = 1 if sisterstudio & startfar < year & endfar > year
replace far = 1 if sisterstudio & startfar2 < year & endfar2 > year

gen competitorstudio = 0
replace competitorstudio = 1 if !missing(network) & distributor != network & startdate < year & enddate > year

gen farcompete = 0
replace farcompete = 1 if competitorstudio & startfar < year & endfar > year
replace farcompete = 1 if competitorstudio & startfar2 < year & endfar2 > year

drop startdate enddate
drop startfar startfar2 endfar endfar2
drop network

* this can get messy if there were some situations where a show
* had two studios, one of which had far while another did not
bysort showname year season: egen _sisterstudio = max(sisterstudio)
bysort showname year season: egen _competitorstudio = max(competitorstudio)
bysort showname year season: egen _cooks = max(cooks)
bysort showname year season: egen _far = max(far)
bysort showname year season: egen _farcompete = max(farcompete)
drop sisterstudio cooks far competitorstudio farcompete
ren _sisterstudio sisterstudio
ren _competitorstudio competitorstudio
ren _cooks cooks
ren _far far
ren _farcompete farcompete

drop titleid episodenumber
duplicates drop

* should also keep season == . if season == 1 is missing; loosing data here
* somthing like drop season and then drop duplicates might be a better way
keep if season == 1
drop season

* need to match year as well as name at some point
merge m:1 showname using $dir/dbs/rollingstone
drop if _merge == 2
drop _merge

gen innovation = !missing(rank)
drop rank
gen highsuccess = success == 2
gen lowsuccess = success == 1

gen scripted = 1
* getting rid of non-scripted stuff
replace scripted = 0 if strpos(genre, "Reality-TV")
replace scripted = 0 if strpos(genre, "Game-Show")
replace scripted = 0 if strpos(genre, "Talk-Show")
replace scripted = 0 if strpos(genre, "Documentary")
replace scripted = 0 if strpos(genre, "Music||") == 1
replace scripted = 0 if strpos(genre, "News||") == 1
replace scripted = 0 if strpos(genre, "Sport||") == 1

save $dir/dbs/done_all, replace
use $dir/dbs/done_all, clear

regress lowsuccess sisterstudio if isBigFour
regress highsuccess sisterstudio##far
regress highsuccess lowsuccess##sisterstudio sisterstudio##far lowsuccess##far
regress innovation sisterstudio##far

keep if isBigFour
bysort showname year: keep if _n == 1
merge 1:1 showname year using $dir/dbs/favored
drop _merge
keep if favoredset
tab favored sisterstudio, column
regress favored sisterstudio

tab lowsuccess favored, column
regress lowsuccess favored

tab highsuccess favored, column
regress highsuccess favored

regress lowsuccess sisterstudio

merge 1:1 showname year using $dir/dbs/highlyrated
drop if _merge == 2
gen highlyrated = _merge == 3
drop _merge

su year if highlyrated
* highly rated info won't exist for these yet
drop if year > r(max)
* don't have data going back farther than this
drop if year < r(min)

chartbyyear highlyrated sisterstudio year favored

/*
ren distributor network
merge m:1 network year using $dir/../bias
keep if _merge == 3
drop _merge
ren network distributor
*/

encode distributor, gen(network)

* things we do know

* regardless of network, there is a much higher likelihood of a show 
* getting on nielson's top 30 list if it was put in a spot next to an 
* existing highly rated show
bysort network: tab highlyrated favored, nofreq column
regress highlyrated favored i.network

* regardless of newtork, there is a higher shot of being renewed if highly
* rated
bysort network: tab lowsuccess highlyrated, nofreq column
regress lowsuccess highlyrated i.network

* sister studio doesn't help reorder conditional on the show being a hit
bysort network: tab lowsuccess sisterstudio if highlyrated , nofreq column
regress lowsuccess sisterstudio i.network if highlyrated

* nor does it help the show get to season five conditional on being an initial hit
bysort network: tab highsuccess sisterstudio if highlyrated , nofreq column
regress highsuccess sisterstudio i.network if highlyrated

* looks like ABC and CBS prefer sister studio shows on reorder if they were 
* not highly rated making this overall estimate significant
bysort network: tab lowsuccess sisterstudio if !highlyrated , nofreq column
regress lowsuccess sisterstudio i.network if !highlyrated

* but interestingly all networks have sister studios more likely to make
* it to season five than other shows
bysort network: tab highsuccess sisterstudio if !highlyrated , nofreq column
regress highsuccess sisterstudio i.network if !highlyrated

* all networks other than ABC favor sister productions over other productions
bysort network: tab favored sisterstudio, nofreq column

* even if sister shows do no better than other shows when favored 
bysort network: tab highlyrated sisterstudio if favored, nofreq column
regress highlyrated sisterstudio i.network if favored

* for ABC and CBS, sister shows do better when not favored
bysort network: tab highlyrated sisterstudio if !favored, nofreq column
regress highlyrated sisterstudio i.network if !favored & distributor != "NBC"
