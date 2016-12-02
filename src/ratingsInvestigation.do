clear all
global dir "C:\Users\achavda\Dropbo~1\Televi~1\Data\movied~1.24"
set more off

use $dir/dbs/decisionmaking, clear

bysort seasonyear network: egen network_rating = mean(rating)
bysort seasonyear: egen season_rating = mean(rating)

sort id seasonyear

regress D.rating L.rating pre_rating post_rating network_rating i.seasonyear i.network season_rating 
