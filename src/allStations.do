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
import delimited $dir/dbs/titles.csv

* not sure what to do with this
drop issuspended

* filter out titles known to be foreign
merge 1:1 titleid using $dir/dbs/country
drop if _merge == 2
bysort showname year: egen min_foreign = min(foreign)
drop if min_foreign == 1
drop _merge foreign min_foreign

* filtering out anything not in english from my dataset. Will screw up 
* any analysis reliant on for example spanish language networks. 
merge 1:1 titleid using $dir/dbs/language
drop if _merge == 2
bysort showname year: egen min_foreign = min(foreign)
drop if min_foreign == 1
drop _merge foreign min_foreign

merge 1:1 titleid using $dir/dbs/broadcastyear
drop if _merge == 2
drop _merge
bysort showname year season: egen mean_broadcastyear = mode(broadcastyear), maxmode
replace mean_broadcastyear = . if missing(season)
drop broadcastyear
rename mean_broadcastyear seasonyear

* if we don't have enough information about seasonyear then drop the show, no
* good way of matching season to year that works genericlly. most of these 
* shows just have one episode. Seinfeld 1990 is a weird entry that seems to be 
* an error of Seinfeld 1989
drop if !missing(season) & missing(seasonyear)

/*
* need to adjust season to broadcast year since sometimes multiple seasons
* are broadcast in the same year
* need m:1 here becease distributors is multiple
merge 1:1 titleid using $dir/dbs/broadcastyear
drop if _merge == 2
drop _merge
bysort showname year season: egen mean_broadcastyear = mode(broadcastyear)
replace mean_broadcastyear = . if missing(season)
gen true_season = mean_broadcastyear - year + 1
bysort showname year: egen min_true_season = min(true_season)
replace true_season = true_season - min_true_season + 1
count if true_season != season & showname == "The Office" & year == 2005
assert(r(N) == 0)
count if true_season != season & showname == "Band of Brothers" & year == 2001
assert(r(N) == 0)
count if true_season != season & showname == "Rick and Morty" & year == 2013
assert(r(N) == 0)
count if true_season != season & showname == "Breaking Bad" & year == 2008
assert(r(N) == 0)
count if true_season != season & showname == "Game of Thrones" & year == 2011
assert(r(N) == 0)
count if true_season != season & showname == "The Wire" & year == 2002
assert(r(N) == 0)
count if true_season != season & showname == "The Sopranos" & year == 1999
assert(r(N) == 0)
count if true_season != season & showname == "Sherlock" & year == 2010
assert(r(N) == 0)
count if true_season != season & showname == "Seinfeld" & year == 1989
assert(r(N) == 0)
count if true_season != season & showname == "Friends" & year == 1994
assert(r(N) == 0)
count if true_season != season & showname == "Simpsons" & year == 1989
assert(r(N) == 0)
count if true_season != season & showname == "Oz" & year == 1997
assert(r(N) == 0)
count if true_season != season & showname == "South Park" & year == 1997
assert(r(N) == 0)
count if true_season != season & showname == "Archer" & year == 2009
assert(r(N) == 0)
count if true_season != season & showname == "The West Wing" & year == 1999
assert(r(N) == 0)
count if true_season != season & showname == "Dexter" & year == 2006
assert(r(N) == 0)
count if true_season != season & showname == "The X-Files" & year == 1993
assert(r(N) == 0)
count if true_season == 16 & season == 21 & showname == "The Bachelor" & year == 2002
assert(r(N) > 0)
count if true_season == 12 & season == 17 & showname == "The Biggest Loser" & year == 2004
assert(r(N) > 0)
drop season broadcastyear mean_broadcastyear min_true_season
ren true_season season

* manually making changes for shows on main networks

* adjusting season for some shows that have multiple seasons per year
* survivor had two per season starting with season 3
replace season = floor((season - 3) / 2) + 3 if showname == "Survivor" & year == 2000 & season > 2 
drop if season == 102 & showname == "America's Funniest Home Videos" & year == 1989
replace season = floor((season - 1) / 2) + 1 if showname == "Dancing with the Stars" & year == 2005
* this is the australian and other foreign versions; not sure why it didn't get filtered above
drop if showname == "Dancing with the Stars" & year != 2005
* disneyland 1954 seems to be a problem in the final data but not sure what is wrong yet
drop if season == 111 & showname == "Entertainment Tonight" & year == 1981
replace season = 1 if showname == "Talking Pictures" & year == 2012 & season == 12
replace season = 3 if showname == "Talking Pictures" & year == 2012 & season == 7
replace season = floor((season - 2) / 2) + 2 if showname == "The Amazing Race" & year == 2001
* UK version
drop if showname == "The Bachelor" & year == 2003
* Bachelor is a bit of a mess, needing to hand code
replace season = 2 if showname == "The Bachelor" & year == 2002 & season == 3
replace season = 3 if showname == "The Bachelor" & year == 2002 & season == 4
replace season = 3 if showname == "The Bachelor" & year == 2002 & season == 5
replace season = 4 if showname == "The Bachelor" & year == 2002 & season == 6
replace season = 4 if showname == "The Bachelor" & year == 2002 & season == 7
replace season = 5 if showname == "The Bachelor" & year == 2002 & season == 8
replace season = 6 if showname == "The Bachelor" & year == 2002 & season == 9
replace season = 6 if showname == "The Bachelor" & year == 2002 & season == 10
replace season = 7 if showname == "The Bachelor" & year == 2002 & season == 11
replace season = 7 if showname == "The Bachelor" & year == 2002 & season == 12
replace season = 8 if showname == "The Bachelor" & year == 2002 & season == 13
replace season = 9 if showname == "The Bachelor" & year == 2002 & season == 14
replace season = 10 if showname == "The Bachelor" & year == 2002 & season == 15
replace season = 11 if showname == "The Bachelor" & year == 2002 & season == 16
replace season = 12 if showname == "The Bachelor" & year == 2002 & season == 17
replace season = 13 if showname == "The Bachelor" & year == 2002 & season == 18
replace season = 14 if showname == "The Bachelor" & year == 2002 & season == 19
replace season = 15 if showname == "The Bachelor" & year == 2002 & season == 20
replace season = 16 if showname == "The Bachelor" & year == 2002 & season == 21
* German version
drop if showname == "The Biggest Loser" & year == 2009
replace season = 4 if showname == "The Biggest Loser" & year == 2004 & season == 5
replace season = 5 if showname == "The Biggest Loser" & year == 2004 & season == 6
replace season = 5 if showname == "The Biggest Loser" & year == 2004 & season == 7
replace season = 6 if showname == "The Biggest Loser" & year == 2004 & season == 8
replace season = 6 if showname == "The Biggest Loser" & year == 2004 & season == 9
replace season = 7 if showname == "The Biggest Loser" & year == 2004 & season == 10
replace season = 7 if showname == "The Biggest Loser" & year == 2004 & season == 11
replace season = 8 if showname == "The Biggest Loser" & year == 2004 & season == 12
replace season = 8 if showname == "The Biggest Loser" & year == 2004 & season == 13
replace season = 9 if showname == "The Biggest Loser" & year == 2004 & season == 14
replace season = 10 if showname == "The Biggest Loser" & year == 2004 & season == 15
replace season = 11 if showname == "The Biggest Loser" & year == 2004 & season == 16
replace season = 12 if showname == "The Biggest Loser" & year == 2004 & season == 17
replace season = 1 if showname == "The Dee Armstrong Show" & year == 2015 & season == 7
* austrailian version
drop if showname == "The Voice" & year == 2012
replace season = floor((season - 1) / 2) + 1 if showname == "The Voice" & year == 2011
drop if showname == "Who Wants to Be a Millionaire" & year == 2002 & season == 29

* trying a more generic approach to shows off network
* first get rid of weird data
replace season = . if season > 1000
* what i really care about is the first two season's ratings and renewal
* so topcoding everthing at 5 and then will drop season 5+ after ratings are 
* calculated
*/

/*
bysort showname year: egen max_season = max(season)
su max_season
local overall_max = r(max)
gen error = 0
local i = `overall_max'
tab season, matrow(A)
local A_size = r(r)
sort showname year
local `i' = `A_size'
while  `i' > 0 {
	local A_season = matrix A[`i']
	disp "Season `A_season': Row `i'"
	by showname year: egen season_count = sum(season == `A_season')
	replace error = 0 if season == `A_season' & max_season >= `A_season' & !missing(max_season)
	drop season_count
	local i = `i' - 1
}
*/

* trying to get rid of things that are not TV shows
* later on we remove by genre as well
bysort showname year: egen maxepisode = max(episodenumber)
bysort showname year: egen maxseason = max(season)
drop if maxepisode == . & maxseason == .
drop maxseason maxepisode

merge 1:m titleid using $dir/dbs/distributors
ren company distributor
drop if _merge == 2
drop _merge

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
drop episodename endyear
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
* dont' need to go past this for the decision making script
assert(0)
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
