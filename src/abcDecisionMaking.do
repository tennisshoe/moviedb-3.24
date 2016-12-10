clear all
global dir "C:\Users\achavda\Dropbo~1\Televi~1\Data\movied~1.24"
set more off

capture: program drop chartbyyeariv
program chartbyyeariv

	args outcome dependent year conditional
	quietly: su `year'
	local yearstart = r(min)
	local yearend = r(max)
	local years = 1 + `yearend' - `yearstart'
	* columns are year, estimate, lower bound, upper bound
	matrix result = J(`years',4,.)
	matrix colnames result = year b ll ul
	forvalues i = 1/`years' {
		local currentyear = `i' + `yearstart' - 1
		if "`conditional'" == "" {
			capture: ivregress 2sls `outcome' `dependent' if `year' == `currentyear'
			display "ivregress 2sls `outcome' `dependent' if `year' == `currentyear'"
		} 
		else {
			capture: ivregress 2sls `outcome' `dependent' if `year' == `currentyear' & `conditional'
		}
		matrix c = r(table)
		matrix result[`i',1] = `currentyear'
		tokenize `dependent'
		capture: matrix result[`i',2] = c["b","`1'"]
		capture: matrix result[`i',3] = c["ll","`1'"]
		capture: matrix result[`i',4] = c["ul","`1'"]
		matrix drop c
	}
	
	preserve
	clear 
 	svmat result, names(col)
	graph twoway ///
		(rarea ul ll year, color(gs12) fintensity(inten50)) ///
		(line b year, lcolor(midblue) lpattern(dash)) ///
		(scatter b year, mcolor(midblue)) ///
		, title("Impact of `1' on `outcome' | `conditional'") ytitle("Magnitude of effect") yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) legend(order(1 3) label(3 "Point Estimate") label(1 "Confidence Interval") cols(1) size(small)) graphregion(fcolor(dimgray))	
	restore
	matrix drop result

end

capture: program drop chartbyyear
program chartbyyear

	args outcome dependent year conditional
	quietly: su `year'
	local yearstart = r(min)
	local yearend = r(max)
	local years = 1 + `yearend' - `yearstart'
	* columns are year, estimate, lower bound, upper bound
	matrix result = J(`years',4,.)
	matrix colnames result = year b ll ul
	forvalues i = 1/`years' {
		local currentyear = `i' + `yearstart' - 1
		if "`conditional'" == "" {
			capture quietly: regress `outcome' `dependent' if `year' == `currentyear'
		} 
		else {
			capture quietly: regress `outcome' `dependent' if `year' == `currentyear' & `conditional'
		}
		matrix c = r(table)
		matrix result[`i',1] = `currentyear'
		tokenize `dependent'
		capture: matrix result[`i',2] = c["b","`1'"]
		capture: matrix result[`i',3] = c["ll","`1'"]
		capture: matrix result[`i',4] = c["ul","`1'"]
		matrix drop c
	}
	
	preserve
	clear 
 	svmat result, names(col)
	graph twoway ///
		(rarea ul ll year, color(gs12) fintensity(inten50)) ///
		(line b year, lcolor(midblue) lpattern(dash)) ///
		(scatter b year, mcolor(midblue)) ///
		, title("Impact of `1' on `outcome' | `conditional'") ytitle("Magnitude of effect") yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year) legend(order(1 3) label(3 "Point Estimate") label(1 "Confidence Interval") cols(1) size(small)) graphregion(fcolor(dimgray))	
	restore
	matrix drop result

end

* starting at the midpoint which includes all seasons of a show's run
use $dir/dbs/midpoint_all, clear

* keep if isBigFour
* drop isBigFour

preserve
clear
import delimited $dir/dbs/ratings.csv
*** should probably have a different variable for this but for now...
* replace rating = log(rating)

quietly count
local oldcount = r(N)
duplicates drop
quietly count
assert(`oldcount' - r(N) < 10)

sort titleid
by titleid: egen mean = mean(rating)
quietly count
local oldcount = r(N)
by titleid: keep if _n == 1
quietly count
assert(`oldcount' - r(N) < 200)
drop rating
ren mean rating

merge 1:m titleid using $dir/dbs/midpoint_all
keep if _merge == 3
drop _merge

keep rating showname year season
gen showrating = rating if missing(season)
replace rating = . if missing(season)

* some seasons just have one episode rated; this creates a lot of noise in 
* the aggregate data.
bysort showname year season: gen drop_rating = (_N < 3)
bysort showname year season: egen mean = mean(rating)
replace rating = . if drop_rating
drop rating drop_rating
ren mean rating
duplicates drop

* best number i have for the season is the overall show rating
* sucks for log because the mean of log episodes will be less than the log
* mean of epsiodes if that's what the showrating represents
bysort showname year season: replace rating = showrating if missing(rating)
drop showrating
bysort showname year: egen max_season = max(season)
replace season = 1 if missing(max_season) & missing(season)
drop max_season

gen seasonyear = year + season - 1
drop season

* there is a small number of shows that have the same name and same showyears
duplicates tag showname seasonyear, gen(dup)
local oldcount = r(N)
drop if dup
quietly count
assert(`oldcount' - r(N) < 300)
drop dup

* the IMDB data has the long title for this show
replace showname = "NCIS: Naval Criminal Investigative Service" if showname == "NCIS"

save $dir/dbs/ratings, replace
restore

* genre code

* make sure no other variables start with g
capture describe g*
assert(_rc != 0)

/*
preserve
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

sort titleid
by titleid: egen gShort = total(genre == "Short")
by titleid: egen gDrama = total(genre == "Drama")
by titleid: egen gComedy = total(genre == "Comedy")
by titleid: egen gDocumentary = total(genre == "Documentary")
by titleid: egen gAdult = total(genre == "Adult")
by titleid: egen gAction = total(genre == "Action")
by titleid: egen gThriller = total(genre == "Thriller")
by titleid: egen gRomance = total(genre == "Romance")
by titleid: egen gAnimation = total(genre == "Animation")
by titleid: egen gFamily = total(genre == "Family")
by titleid: egen gHorror = total(genre == "Horror")
by titleid: egen gMusic = total(genre == "Music")
by titleid: egen gCrime = total(genre == "Crime")
by titleid: egen gAdventure = total(genre == "Adventure")
by titleid: egen gFantasy = total(genre == "Fantasy")
by titleid: egen gSciFi = total(genre == "Sci-Fi")
by titleid: egen gMystery = total(genre == "Mystery")
by titleid: egen gBiography = total(genre == "Biography")
by titleid: egen gHistory = total(genre == "History")
by titleid: egen gSport = total(genre == "Sport")
by titleid: egen gMusical = total(genre == "Musical")
by titleid: egen gWar = total(genre == "War")
by titleid: egen gWestern = total(genre == "Western")
by titleid: egen gRealityTV = total(genre == "Reality-TV")
by titleid: egen gNews = total(genre == "News")
by titleid: egen gTalkShow = total(genre == "Talk-Show")
by titleid: egen gGameShow = total(genre == "Game-Show")
* none of these exist
* by titleid: egen gFilmNoir = total(genre == "Film-Noir")
* ignoring single lifestyle observation

drop genre
duplicates drop
compress
save $dir/dbs/genreswide, replace
restore
*/

merge 1:m titleid using $dir/dbs/genreswide
drop if _merge == 2
drop _merge
sort showname year
foreach genre of varlist g* { 
	replace `genre' = 0 if missing(`genre')
	by showname year: egen g = max(`genre')
	drop `genre'
	rename g `genre'
	su `genre'
	if(r(max) == 0) {
		drop `genre'
	}
}

merge 1:m titleid using $dir/dbs/business
* I think these are films but need to validate
gen sistercopyright = 0 if _merge == 3
drop if _merge == 2
drop _merge
replace content = lower(content)
replace sistercopyright = 1 if distributor == "ABC" & strpos(content, "abc ")
replace sistercopyright = 1 if distributor == "ABC" & strpos(content, "disney") & year > 1995
replace sistercopyright = 1 if distributor == "ABC" & strpos(content, "touchstone") & year > 1995
replace sistercopyright = 1 if distributor == "ABC" & strpos(content, "dic ") & year > 1993 & year <= 2000
replace sistercopyright = 1 if distributor == "CBS" & strpos(content, "cbs ")
replace sistercopyright = 1 if distributor == "CBS" & strpos(content, "paramount") & year > 2000 & year <= 2009
replace sistercopyright = 1 if distributor == "CBS" & strpos(content, "viacom") & year > 2000 & year <= 2009
replace sistercopyright = 1 if distributor == "CBS" & strpos(content, "tristar") & year > 1983 & year <= 1985
replace sistercopyright = 1 if distributor == "FOX" & strpos(content, "fox ") 
replace sistercopyright = 1 if distributor == "FOX" & strpos(content, "reveille") & year > 2008
replace sistercopyright = 1 if distributor == "FOX" & strpos(content, "new world") & year > 1997
replace sistercopyright = 1 if distributor == "FOX" & strpos(content, "regency") & year > 1998 & year <= 2008
replace sistercopyright = 1 if distributor == "NBC" & strpos(content, "nbc ")
replace sistercopyright = 1 if distributor == "NBC" & strpos(content, "universal") & year > 2004
replace sistercopyright = 1 if distributor == "NBC" & strpos(content, "revue") & year > 2004
drop content

bysort showname year: egen _sistercopyright = max(sistercopyright)
drop sistercopyright
ren _sistercopyright sistercopyright
duplicates drop

* sister studio code
merge 1:m titleid using $dir/dbs/production-companies
drop if _merge == 2
drop _merge

merge m:1 productioncompany using $dir/dbs/productionownership
drop if _merge == 2
drop _merge

drop countrycode

replace startdate = 0 if missing(startdate)
replace enddate = 9999 if missing(enddate)
drop productioncompany

* sister studio is on a show level since i'm looking at show launch year 
* rather than season production year. Can change this but i'm not sure i'll 
* have enough observations to be worth investigating
gen sisterstudio = 0
replace sisterstudio = 1 if distributor == network & startdate < year & enddate > year

drop startdate enddate
drop startfar endfar startfar2 endfar2
drop network
* drop distributor

* converting from episode to season level view
bysort showname year: egen _sisterstudio = max(sisterstudio)
drop sisterstudio
ren _sisterstudio sisterstudio
drop titleid episodenumber
duplicates drop

*** using seasonyear from the movies list instead
drop if missing(seasonyear)
drop season
duplicates drop
/*
* now reshaping seasons into years
* how does genre not get screwed up here? seems like genre is constant
* across the show itself; probably from the matlab script
bysort showname year: egen maxSeason = max(season)
drop season
* still some duplicates after this from shows that are listed on two or three different networks
duplicates drop
* duplicates cause problems with the expand so juse picking one
bysort showname year: keep if _n == 1
expand maxSeason
gen seasonyear = year
bysort showname year: replace seasonyear = seasonyear + _n - 1
drop maxSeason
*/

* dealing with when show has multiple distributors
merge m:1 distributor using $dir/dbs/distributorrank
drop if _merge == 2
drop _merge
bysort showname year seasonyear: egen max_rank = max(distributorrank)
keep if distributorrank == max_rank
drop max_rank distributorrank

* some left overs where low distributors have same rank
quietly: count
local old_count = r(N)
by showname year seasonyear: keep if _n == 1
quietly: count
assert(`old_count' - r(N) < 5)

* adding season level rating data
* should be doing this by titleid instead...
merge 1:1 showname year seasonyear using $dir/dbs/ratings
drop if _merge == 2
drop _merge

*** weird shows with overlap in seasonyears on the networks
* ABC had same show as NBC for one year
drop if showname=="Kraft Television Theatre" & year == 1953 & distributor  == "ABC"
* PB was a cartoon spin-off of original PB
drop if showname=="Punky Brewster" & year == 1985 & distributor  == "NBC"
* super friends was renamed / rebooted in 1980
drop if showname=="Super Friends" & year == 1973  & seasonyear == 1981 & distributor  == "ABC"
* who wants to be a millionaire should really always be on ABC, error in the way 
* i'm picking from multiple distributors
drop if showname=="Who Wants to Be a Millionaire" & year == 1999 & distributor  == "ABC" & seasonyear == 2009

* now adding marketing and nielson ratings
* favored_pre and treated_pre means the new show was before a hit show
* favored_post and treated_post means the new show was after a hit show

* favoredall only has big four in it for now. Can probably add others once I 
* figure out how to deal with the CW UPN merger
gen favoredset = isBigFour == 1

* a bunch of shows have colons in them from the IMDB data that needs to be sepecially 
* dealt with like the original NCIS
assert(0)


merge m:1 showname seasonyear favoredset using $dir/dbs/favoredall, keepusing(showname seasonyear)

* _merge == 2 is a problem due to IMDB listing by calendar year
* of broadcast while neilson providing television year. Twin Peaks 
* was in the 1989-1990 season but didn't broadcast until CY 1990
bysort showname: egen minyear = min(seasonyear) if favoredset == 1
gen spring = minyear == year - 1 if favoredset == 1
drop if _merge == 2
* may not need to do this for merging later data, could get away with just
* updating the seasonyear for the merge to work
replace year = minyear if spring == 1 & favoredset == 1
replace seasonyear = seasonyear - 1 if spring == 1 & favoredset == 1
drop minyear spring _merge

* 6 show-seasons seem to cause errors either because of genre differences
* or network changes
duplicates tag showname seasonyear if favoredset, gen(dup)
quietly count
local oldcount = r(N)
bysort showname seasonyear: gen dropme = _n > 1 & dup == 1
drop if dropme == 1
drop dropme dup
quietly count
assert(`oldcount' - r(N) < 10)

* for the things that are still dups, perfer to kill the ones that are not from
* the major networks
* duplicates tag showname seasonyear, gen(dup)
* drop if dup & !favoredset

* now redo the merge
merge m:1 showname seasonyear favoredset using $dir/dbs/favoredall
* this retricts our dataset to prime time shows on main networks
* keep if _merge == 3
drop if _merge == 2
replace pre_showname = "" if favoredset != 1
replace post_showname = "" if favoredset != 1
replace dayofweek = . if favoredset != 1
drop _merge favoredset

* WARNING: Can't merge any IMDB data after this point since i've changed
* the show year to match season rather than calender year

merge m:1 showname seasonyear using $dir/dbs/highlyrated
drop if _merge == 2
replace rank = . if isBigFour != 1
replace viewership = . if isBigFour != 1
gen highlyrated = _merge == 3 & isBigFour
drop _merge


* adding market share data
ren distributor network
merge m:1 network seasonyear using $dir/dbs/marketshare
count if _merge == 2
* no longer the case since we have other networks
* assert(r(N) == 0)
* networks that didn't make top 30 list that year
su seasonyear if _merge == 3
replace marketshare = 0 if _merge == 1 & seasonyear >= r(min) & seasonyear <= r(max) & isBigFour
drop _merge
ren network distributor
encode distributor, gen(network)
drop distributor

* think this is happening because the old show is tracked as a new name
count if year > seasonyear
* assert(r(N) == 0)
gen firstyear = year == seasonyear

sort seasonyear
by seasonyear: egen showcount = count(isBigFour)
gen rank2 = (showcount - 30) /2 + 30
replace rank2 = rank if !missing(rank) & isBigFour
* more intuitive for higher ranked show to be 'better'
replace rank2 = -rank2
drop showcount

drop if showname == "Black Box" & year == 2013 & seasonyear == 2013 & isBigFour != 1 

* setting up time series
egen id = group(showname year)
tsset id seasonyear
gen renewed = !missing(F.year)
gen lag_rating = L.rating
gen for_rating = F.rating
gen lag_rank = L.rank
gen for_rank = F.rank
gen lag_rank2 = L.rank2
gen for_rank2 = F.rank2
gen lag_viewership = L.viewership
gen for_viewership = F.viewership
gen lag_highlyrated = L.highlyrated
gen for_highlyrated = F.highlyrated
gen for_renewed = F.renewed

save $dir/dbs/tmp, replace
use $dir/dbs/tmp, clear

* adding pre and post data
* rating, rank, viewership, firstyear
preserve
keep showname seasonyear rating rank rank2 viewership firstyear highlyrated renewed lag_* for_*
duplicates drop
duplicates drop showname seasonyear, force
save $dir/dbs/pre, replace
restore

ren showname _showname
ren pre_showname showname

ren rating _rating
ren rank _rank
ren rank2 _rank2
ren viewership _viewership
ren firstyear _firstyear
ren highlyrated _highlyrated
drop lag_* for_*

* can't use 1:1 here because some pre shows were in front of multiple other shows
merge m:1 showname seasonyear using $dir/dbs/pre

ren rating pre_rating
ren rank pre_rank
ren rank2 pre_rank2
ren viewership pre_viewership
ren firstyear pre_firstyear
ren highlyrated pre_highlyrated
ren lag_* pre_lag_*
ren for_* pre_for_*
drop if _merge == 2
drop _merge

ren showname pre_showname
ren post_showname showname

merge m:1 showname seasonyear using $dir/dbs/pre

ren rating post_rating
ren rank post_rank
ren rank2 post_rank2
ren viewership post_viewership
ren firstyear post_firstyear
ren highlyrated post_highlyrated
ren lag_* post_lag_*
ren for_* post_for_*
drop if _merge == 2
drop _merge

ren showname post_showname
ren _showname showname
ren _rating rating
ren _rank rank
ren _rank2 rank2
ren _viewership viewership
ren _firstyear firstyear
ren _highlyrated highlyrated

gen season = seasonyear - year + 1

gen scripted = 1
* getting rid of non-scripted stuff
egen totalgenres = rowtotal(g*)
replace scripted = 0 if gRealityTV
replace scripted = 0 if gGameShow
replace scripted = 0 if gTalkShow
replace scripted = 0 if gDocumentary
replace scripted = 0 if gMusic & (totalgenres == 1)
replace scripted = 0 if gNews & (totalgenres == 1) 
replace scripted = 0 if gSport & (totalgenres == 1)
gen reality = gRealityTV
drop totalgenres



* by 1957 all genres had been 'invented'
* foreach genre of varlist g* { 
* 	capture: drop fy`genre'
* 	egen fy`genre' = min(seasonyear) if `genre' == 1
* 	tab fy`genre' if `genre'
* }

* shaping innovative flag
sort seasonyear
foreach genre of varlist g* { 
	by seasonyear: egen s`genre' = max(`genre')
} 

gen offpath = 0
foreach genre of varlist g* { 
	sort id seasonyear
	gen ls`genre' = L.s`genre'
	bysort seasonyear: egen lag = max(ls`genre') if isBigFour
	bysort id: replace offpath = 1 if lag == 0 & `genre' == 1 & year == seasonyear & isBigFour
	drop lag ls`genre'
} 
drop sg*

gen code = ""
foreach genre of varlist g* {
	display "`genre'"
	count if missing(`genre')
	replace code = code + string(`genre')
}
drop g*
encode code, gen(genrecode)
drop code
bysort genrecode: egen firstgenreyear = min(year)
gen innovation = firstgenreyear == year
drop firstgenreyear

replace innovation = 0 if firstyear == 0
* don't mark early stuff as innovation since genre set was still being worked out
replace innovation = 0 if year < 1960

gen treated_pre = pre_highlyrated == 1
gen treated_post = post_highlyrated == 1
gen treated = treated_pre | treated_post
gen favored_pre = pre_lag_highlyrated == 1
gen favored_post = post_lag_highlyrated == 1
gen favored = favored_pre | favored_post

sort id seasonyear

compress
save $dir/dbs/decisionmaking, replace
use $dir/dbs/decisionmaking, clear

assert(0)


preserve
keep if seasonyear == year
bysort year: egen scriptedcount = count(year) if scripted
bysort year: egen nonscriptedcount = count(year) if ~scripted
keep seasonyear scriptedcount nonscriptedcount
duplicates drop

lpoly  nonscriptedcount seasonyear, mcolor(gold) lpattern(dash) title("Effect of Writer's Strike on Non-Scripted Shows") ytitle("Number of New Non-Scripted Shows") yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year)
restore

preserve
keep if seasonyear == year
bysort seasonyear: egen avg_scripted = mean(log(rating)) if scripted
bysort seasonyear: egen avg_nonscripted = mean(log(rating)) if ~scripted
keep seasonyear avg_scripted avg_nonscripted
duplicates drop

lpoly  avg_nonscripted seasonyear, mcolor(gold) lpattern(dash) title("Effect of Writer's Strike on Non-Scripted Shows") ytitle("Number of New Non-Scripted Shows") yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year)
restore


preserve
keep if seasonyear == year
bysort seasonyear: egen avg_scripted = mean(innovation) if scripted
bysort seasonyear: egen avg_nonscripted = mean(innovation) if ~scripted
keep seasonyear avg_scripted avg_nonscripted
duplicates drop

lpoly  avg_scripted seasonyear, mcolor(gold) lpattern(dash) title("Effect of Writer's Strike on Non-Scripted Shows") ytitle("Share of Innovative Shows") yscale(titlegap(3)) ylabel(, labsize(small)) xtitle(Year)
restore

gen log_rating = log(rating)
gen lag_log_rating = L.log_rating
lpoly  log_rating lag_log_rating, mcolor(gold) lpattern(dash) title("IMDB Show Ratings") ytitle("Current Season Rating") yscale(titlegap(3)) ylabel(, labsize(small)) xtitle("Previous Season Rating")

gen iv = 0
replace iv = 1 if (!favored & treated)
replace iv = -1 if (favored & !treated)
gen error = iv != 0
gen error_pre = (treated_pre & !favored_pre) | (!treated_pre & favored_pre)
gen error_post = (treated_post & !favored_post) | (!treated_post & favored_post)

* gen iv = (treated & !favored) | (!treated & favored)
keep if seasonyear == year

replace iv = error

rename treated m
eststo first_stage: regress m iv
esttab first_stage using $dir/tmp/first_stage.tex, keep(iv _cons) order(iv _cons) cells(b(fmt(2)) se(par([ ]) fmt(2) star)) starlevels(* 0.05 ** 0.01) stats(N r2 F) replace

rename highlyrated s
rename innovation innovative
eststo innovative: ivregress 2sls s innovative (m=iv)
esttab innovative using $dir/tmp/innovation.tex, keep(innovative m _cons) order(innovative m _cons) cells(b(fmt(2)) se(par([ ]) fmt(2) star)) starlevels(* 0.05 ** 0.01) stats(N r2 F) replace

eststo clear
eststo hit_one: regress s m if favored
eststo hit_zero: regress s m if !favored
esttab hit_one hit_zero using $dir/tmp/ATTATU.tex, mtitles("H=1" "H=0") keep(m _cons) order(m _cons) cells(b(fmt(2)) se(par([ ]) fmt(2) star)) starlevels(* 0.05 ** 0.01) stats(N r2 F) replace

eststo clear
capture: drop vert_int inn_vert_int
gen vert_int = sisterstudio
gen inn_vert_int = innovative * vert_int
eststo hit_one: regress s m innovative vert_int inn_vert_int if favored
eststo hit_zero: regress s m innovative vert_int inn_vert_int if !favored
esttab hit_one hit_zero using $dir/tmp/ATTATUmi.tex, mtitles("H=1" "H=0") cells(b(fmt(2)) se(par([ ]) fmt(2) star)) starlevels(* 0.05 ** 0.01) stats(N r2 F) replace

eststo clear
capture: drop vert_int inn_vert_int
gen vert_int = sistercopyright
gen inn_vert_int = innovative * vert_int
eststo hit_one: regress s m innovative vert_int inn_vert_int if favored
eststo hit_zero: regress s m innovative vert_int inn_vert_int if !favored
esttab hit_one hit_zero using $dir/tmp/ATTATUmi.tex, mtitles("H=1" "H=0") cells(b(fmt(2)) se(par([ ]) fmt(2) star)) starlevels(* 0.05 ** 0.01) stats(N r2 F) replace

* interesting facts
* change of success increases greatly with marketshare, makes sense because
* marketshare = lots of good shows to put next to new show
lpoly s marketshare, ci noscatter
* when marketshare is high, innovation doesn't really help the shows succeed
tab s innovative if marketshare > 0.3, column nofreq
* its when marketshare is low that innovation is vital to success
tab s innovative if marketshare < 0.3, column nofreq
* but once we control for marketing innovation is always valuable
ivregress 2sls s innovative (m=error) if marketshare > 0.3
ivregress 2sls s innovative (m=error) if marketshare < 0.3
* behavior displays a u-shaped curve with low/high market share firms
* doing more innovation than the middle
lpoly innovative marketshare, ci noscatter


assert(0)

tsset, clear
keep genrecode year isBigFour rating renewed scripted 
duplicates drop
bysort genrecode year isBigFour scripted: egen mean_rating = mean(rating)
bysort genrecode year isBigFour scripted: egen min_rating = min(rating)
bysort genrecode year isBigFour scripted: egen max_rating = max(rating)
bysort genrecode year isBigFour scripted: egen mean_renewed = mean(renewed)
drop rating renewed
duplicates drop
bysort genrecode: egen t = rank(year), track
drop year
egen id = group(genrecode isBigFour)
tsset t 

assert(0)


use $dir/dbs/decisionmaking, clear
decode network, gen(strnetwork)
ren network _network
ren strnetwork network

replace network = "PBS" if strpos(network, "PBS")
replace network = "DISC" if strpos(network, "Discovery")
replace network = "AE" if strpos(network, "A&E")
replace network = "NIC" if strpos(network, "Nickelodeon")
replace network = "MTV" if strpos(network, "MTV")
replace network = "CC" if strpos(network, "Comedy Central")
replace network = "TOON" if strpos(network, "Cartoon Network")
replace network = "TOON" if strpos(network, "Adult Swim")
replace network = "HGTV" if strpos(network, "HGTV")
replace network = "WB" if strpos(network, "Warner Bros")
replace network = "DIS" if strpos(network, "Disney Channel")
replace network = "CW" if strpos(network, "CW Tele")
replace network = "LIF" if strpos(network, "Lifetime")
replace network = "UPN" if strpos(network, "UPN")
replace network = "SF" if strpos(network, "Syfy")
replace network = "TBS" if strpos(network, "TBS")
replace network = "AMC" if strpos(network, "AMC")
replace network = "IFC" if strpos(network, "IFC")
replace network = "FF" if strpos(network, "Freeform")
replace network = "FF" if strpos(network, "ABC Family")
replace network = "SF" if strpos(network, "Sci-Fi")
replace network = "BBC" if strpos(network, "BBC")

replace network = "TNT" if strpos(network, "TNT")
replace network = "STAR" if strpos(network, "Starz")
replace network = "SPIKE" if strpos(network, "Spike")

merge m:1 network year using $dir/dbs/networkpilots
keep if _merge == 3
drop _merge
keep if firstyear & scripted
gen scripts_greenlit = total_scripts / total_greenlit
gen scripts_pilot = total_scripts / total_pilot
gen pilot_greenlit = total_pilot / total_greenlit
keep if year > 2000 & year < 2016


regress rating scripts_greenlit, cluster(network)
regress rating pilot_greenlit, cluster(network)
regress rating scripts_pilot, cluster(network)


regress renewed scripts_greenlit, cluster(network)
regress renewed pilot_greenlit, cluster(network)
regress renewed scripts_pilot, cluster(network)

assert(0)
use $dir/dbs/decisionmaking, clear
keep if firstyear & isBigFour & scripted
decode network, gen(strnetwork)
drop network
label drop network
encode strnetwork, gen(network)
drop strnetwork
drop seasonyear isBigFour scripted firstyear

label variable year "Year"
label variable network "Network"
label variable rating "IMDB Rating"
label variable favored_post "Strongly Preferred"
label variable favored_pre "Weakly Preferred"
label variable sisterstudio "Vertically Integrated"
label variable sistercopyright "Vertically Integrated Copyright"

sutex year network rating favored_post favored_pre sisterstudio sistercopyright, labels digits(2) minmax file($dir/tmp/summary.tex) replace key("tab:sumstat") par

assert(0)

gen fyear2 = year - mod(year,2)
gen fyear3 = year - mod(year,3)
gen fyear4 = year - mod(year,4)
gen fyear5 = year - mod(year,5)
gen fyear10 = year - mod(year,10)

regress rating favored_pre i.network##i.fyear10##i.dayofweek, robust
estout, cells("b se p ci_l ci_u") keep(_cons f*) stats(N r2 F)
 
