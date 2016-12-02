clear all
global dir "C:\Users\achavda\Dropbo~1\Televi~1\Data\movied~1.24"
set more off

program chartbyyeariv

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
		tokenize `dependent'
		matrix result[`i',2] = c["b","`1'"]
		matrix result[`i',3] = c["ll","`1'"]
		matrix result[`i',4] = c["ul","`1'"]
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

* just keep ABC as a proof of concept for now
keep if isBigFour
* keep if distributor == "ABC"
drop isBigFour

preserve
clear
import delimited $dir/dbs/ratings.csv
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

replace season = 1 if missing(season)
* some seasons just have one episode rated; this creates a lot of noise in 
* the aggregate data.
bysort showname year season: gen drop_rating = (_N < 3)
bysort showname year season: egen mean = mean(rating)
drop if drop_rating
drop rating drop_rating
ren mean rating
duplicates drop

gen seasonyear = year + season - 1
drop season

* there is a small number of shows that have the same name and same showyears
duplicates tag showname seasonyear, gen(dup)
local oldcount = r(N)
drop if dup
quietly count
assert(`oldcount' - r(N) < 30)
drop dup

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

preserve
clear
import delimited $dir/dbs/business.csv
keep if type == "CP"
drop type
duplicates drop

compress
save $dir/dbs/business, replace
restore

merge 1:m titleid using $dir/dbs/business
* I think these are films but need to validate
drop if _merge == 2
drop _merge
gen sistercopyright = 0
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

* now reshaping seasons into years
* how does genre not get screwed up here? seems like genre is constant
* across the show itself; probably from the matlab script
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

* drop if showname == "Dancing with the Stars" & year == 2005

* adding season level rating data
merge 1:1 showname year seasonyear using $dir/dbs/ratings
drop if _merge == 2
drop _merge

* now adding marketing and nielson ratings
* favored_pre and treated_pre means the new show was before a hit show
* favored_post and treated_post means the new show was after a hit show
preserve
clear
import delimited $dir/dbs/favoredall.csv
encode dayofweek, gen(weekday)
drop dayofweek
ren weekday dayofweek
compress
save $dir/dbs/favoredall, replace
restore

merge 1:1 showname seasonyear using $dir/dbs/favoredall, keepusing(showname seasonyear) 

* _merge == 2 is a problem due to IMDB listing by calendar year
* of broadcast while neilson providing television year. Twin Peaks 
* was in the 1989-1990 season but didn't broadcast until CY 1990
bysort showname: egen minyear = min(seasonyear)
gen spring = minyear == _year - 1
drop if _merge == 2
replace _year = minyear if spring
replace seasonyear = seasonyear - 1 if spring
drop minyear spring _merge
* 6 show-seasons seem to cause errors either because of genre differences
* or network changes
quietly count
local oldcount = r(N)
bysort showname seasonyear: drop if _n > 1
quietly count
assert(`oldcount' - r(N) < 10)

* now redo the merge
merge 1:1 showname seasonyear using $dir/dbs/favoredall
keep if _merge == 3
drop _merge favoredset
merge 1:1 showname seasonyear using $dir/dbs/highlyrated
drop if _merge == 2
gen highlyrated = _merge == 3
drop _merge

* WARNING: Can't merge any IMDB data after this point since i've changed
* the show year to match season rather than calender year

* adding market share data
ren distributor network
merge m:1 network seasonyear using $dir/dbs/marketshare
count if _merge == 2
assert(r(N) == 0)
drop _merge
ren network distributor

encode distributor, gen(network)
drop distributor

gen treated = treated_pre | treated_post
gen favored = favored_pre | favored_post

* adding rating for adjacent shows
ren year _year
ren showname _showname
ren rating _rating
ren pre_showname showname
* need to fix why this needs to be m:1 rather than 1:1, could be the Korean 
* Friends collision problem
merge m:1 showname seasonyear using $dir/dbs/ratings, keepusing(rating year)
ren rating pre_rating
ren showname pre_showname
gen pre_firstyear = year == seasonyear
drop year
drop if _merge == 2
drop _merge
ren post_showname showname
merge m:1 showname seasonyear using $dir/dbs/ratings, keepusing(rating year)
ren rating post_rating
ren showname post_showname
gen post_firstyear = year == seasonyear
drop year
drop if _merge == 2
drop _merge
ren _showname showname
ren _rating rating
ren _year year

* setting up time series
egen id = group(showname year)
tsset id seasonyear
gen renewed = !missing(F.year)
gen season = seasonyear - year + 1
gen futuresuccess = F.highlyrated == 1
replace futuresuccess = . if missing(F.highlyrated)
gen futurefavored = F.favored_pre == 1 | F.favored_post == 1
replace futurefavored = . if missing(F.favored_pre) & missing(F.favored_post)

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
	bysort seasonyear: egen lag = max(ls`genre')
	bysort id: replace offpath = 1 if lag == 0 & `genre' == 1 & year == seasonyear
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
bysort genrecode: egen firstyear = min(year)
gen innovation = firstyear == year
drop firstyear genrecode

compress
save $dir/dbs/decisionmaking, replace
use $dir/dbs/decisionmaking, clear

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


