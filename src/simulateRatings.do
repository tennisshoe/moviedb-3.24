clear all
set seed 2134561278

local showsperseason 10
local currentyear 1

* suppose we have 10 shows each season
set obs `showsperseason'

* name each show separately
gen showname = _n
* start in the first year
gen year = `currentyear'
* create an order of the shows
gen slot = _n
* each show gets a true quality measure
gen truequality = rnormal(0,1)
* observed quality is truequality plus some noise
gen rating = truequality + rnormal(0,0.5) if year == `currentyear'

while `currentyear' < 100 {

	* shift to the next year
	gen expandcount = 2 if year == `currentyear'
	expand expandcount, gen(newyear)
	local currentyear = `currentyear' + 1
	replace year = `currentyear' if newyear == 1
	drop newyear expandcount
	* if the rating is too low, get a new show
	gen cut = rating < 0 & year == `currentyear'
	* if the show is too old, get a new show
	bysort showname: egen seasons = count(showname)
	replace cut = seasons > 10 & year == `currentyear' & !cut
	replace showname = _N + slot if cut
	replace truequality = rnormal(0,1) if cut
	* add some bias based on preceived quality of existing show
	replace truequality = truequality + 0.1 if 
	drop cut seasons
	
	* now create the next round of ratings
	replace rating = truequality + rnormal(0,0.5) if year == `currentyear'
	
}

* now generate pre and post variables
tempfile prepost
sort year slot
save "`prepost'" 

ren rating _rating
ren slot _slot
gen slot = _slot + 1
sort year slot
merge 1:1 year slot using "`prepost'", keepusing(rating)
drop if _merge == 2
drop _merge
ren rating pre_rating
replace slot = _slot - 1
sort year slot
merge 1:1 year slot using "`prepost'", keepusing(rating)
drop if _merge == 2
drop _merge
ren rating post_rating
drop slot
ren _slot slot
ren _rating rating

tsset showname year

* should show strong positive since if current year is good, likely to 
* have higher epsilon draw this year than previous year
regress D.rating rating

* should show strong nagative since if last year was bad, likely to 
* have higher epsilon draw this year than previous year
regress D.rating L.rating

regress D.rating L.pre_rating pre_rating

regress D.rating L.post_rating post_rating

