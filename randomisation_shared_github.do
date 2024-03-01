************
*Code for performing Block Randomisation for two cohorts of participants in a drug trial
*
*March 2022

*S Soremekun
************


/*
NOTES
Randomisation for two cohorts
Cohort 1: regimen A - 60 placebo 120 vaccine
Cohort 2: regimen B - 60 placebo 120 vaccine
randomisation ratio 1:2 [placebo: vaccine]

randomisation within 6 strata of age and sex
sex groups male female x  age groups 5-9months, 10-12months, 13-17months

numbers to randomise per strata (actual sample size in brackets):
5 to 9 male		45	(36)
5 to 9 female	45	(36)
10 to 12 male	36	(21)
10 to 12 female	36	(21)
13 to 17 male	45	(36)
13 to 17 female	45	(36)

* prepare data in below format:
block_data.xlsx
*/


***************
*Part 1 load and prepare block data
clear all
local dir "G:\D\data_rh5_1"
local raw "G:\D\data_rh5_1\raw"
local dofile "G:\D\do files vac_rh5_1"
cd "`dir'"

import excel `raw'\block_data.xlsx, sheet("block_rh5_1")  firstrow

expand 10 if size==3
expand 2 if size==6

bysort size: gen tot_block_option=_N

label var blocktype "permuted blocks size 3 and 6"
label var size " size of block in 'blocks"
label var tot_block_option "total blocks by size"

count																				// 60 march 2023

label data
label data "permuted blocks for randomisation in randomised trial of two treatment regimens"
save block_data_prepped, replace





***************
*Part 2 random sorting and selection of blocks
clear all
local dir "G:\D\data_rh5_1"
local raw "G:\D\data_rh5_1\raw"
local dofile "G:\D\do files vac_rh5_1"
cd "`dir'"

use block_data_prepped, clear

/*
1st seed is cohort number 1 or 2, stratum number (replacing letter) 01-06, then second seed number 2203232
2nd seed is identical with number 2 on end (in case of duplicate random numbers)

Loop steps per stratum, per cohort:
0. Start with stratum A cohort 1
1. Randomly sort and select permuted blocks of 3 or 6 up to the number required for stratum
2. re-organise table in long form with a single allocation per row in identical order of chosen blocks
3. Label each allocation - randomisation ID and allocation number
4. Provide detail of each allocation (placebo or vaccine)
5. Move to next stratum

*/

*Randomisation Code


forvalues s=1/2  {
	forvalues i=1/6  {
	use block_data_prepped, clear
	preserve

		set seed `s'0`i'220323
		gen c`s'_`i'=runiform()
		set seed `s'0`i'2203232
		gen c`s'_`i'2=runiform()
		sort c`s'_`i' c`s'_`i'2
		gen cum_tot=sum(size)
			if `i'==4 | `i'==3 {
				gen samplesize=1 if cum_tot<=24 // actually 21 but to account for block sizes of 6
				replace samplesize=2 if samplesize==. & cum_tot<=39 
				}
			else {
				gen samplesize=1 if cum_tot<=36
				replace samplesize=2 if samplesize==. & cum_tot<=48 
				}
		keep if samplesize~=.
		drop tot_block c`s'_*
		gen block=_n
		save c`s'_`i'_wide, replace
		expand  size
		sort block
		bysort block: gen withinblock=_n
		gen arm=substr(blocktype, 1,1) if withinblock==1
		replace arm=substr(blocktype, 2,1) if withinblock==2
		replace arm=substr(blocktype, 3,1) if withinblock==3
		replace arm=substr(blocktype, 4,1) if withinblock==4
		replace arm=substr(blocktype, 5,1) if withinblock==5
		replace arm=substr(blocktype, 6,1) if withinblock==6
		drop cum_tot
		gen cum_tot=_n
		tostring cum_tot, gen(strcum_tot)
			if `i'==1 {
				gen randomisation_id="C`s'A"+"0"+strcum_tot if cum_tot<10
				replace randomisation_id="C`s'A"+strcum_tot if cum_tot>=10
				gen allocation_id="A"+"0"+strcum_tot if cum_tot<10
				replace allocation_id="A"+strcum_tot if cum_tot>=10
				gen age="5-9months"
				gen sex="male"
				}
			else if `i'==2 {
				gen randomisation_id="C`s'B"+"0"+strcum_tot if cum_tot<10
				replace randomisation_id="C`s'B"+strcum_tot if cum_tot>=10
				gen allocation_id="B"+"0"+strcum_tot if cum_tot<10
				replace allocation_id="B"+strcum_tot if cum_tot>=10
				gen age="5-9months"
				gen sex="female"
				}
			else if `i'==3 {
				gen randomisation_id="C`s'C"+"0"+strcum_tot if cum_tot<10
				replace randomisation_id="C`s'C"+strcum_tot if cum_tot>=10
				gen allocation_id="C"+"0"+strcum_tot if cum_tot<10
				replace allocation_id="C"+strcum_tot if cum_tot>=10
				gen age="10-12months"
				gen sex="male"
				}
			else if `i'==4 {
				gen randomisation_id="C`s'D"+"0"+strcum_tot if cum_tot<10
				replace randomisation_id="C`s'D"+strcum_tot if cum_tot>=10
				gen allocation_id="D"+"0"+strcum_tot if cum_tot<10
				replace allocation_id="D"+strcum_tot if cum_tot>=10
				gen age="10-12months"
				gen sex="female"
				}
			else if `i'==5 {
				gen randomisation_id="C`s'E"+"0"+strcum_tot if cum_tot<10
				replace randomisation_id="C`s'E"+strcum_tot if cum_tot>=10
				gen allocation_id="E"+"0"+strcum_tot if cum_tot<10
				replace allocation_id="E"+strcum_tot if cum_tot>=10
				gen age="13-17months"
				gen sex="male"
				}
			else {
				gen randomisation_id="C`s'F"+"0"+strcum_tot if cum_tot<10
				replace randomisation_id="C`s'F"+strcum_tot if cum_tot>=10
				gen allocation_id="F"+"0"+strcum_tot if cum_tot<10
				replace allocation_id="F"+strcum_tot if cum_tot>=10
				gen age="13-17months"
				gen sex="female"
				}
		drop strcum
		rename samplesize orig_extra
		label define orig_extra 1"original sample size" 2"additional codes"
		label values orig_extra orig_extra
			if `s'==1 {
				gen arm_detail="Cohort `s'  (A) Group 2: treatment" if arm=="b"
				replace arm_detail="Cohort `s'  (A) Group 1: control" if arm=="a"
			}
			else {
				gen arm_detail="Cohort `s'  (B) Group 2: treatment" if arm=="b"
				replace arm_detail="Cohort `s'  (B) Group 1: control" if arm=="a"
			}
		order allocation block withinbloc blocktype randomisation_id arm arm_detail age sex cum_tot
	
	save c`s'_`i'_long, replace
	restore
	}
}



/*
Post randomisation tidy in excel/csv - remove additional allocations above sample size required


*/