extensions[gis test profiler nw]

__includes[
  "/Users/Juste/Documents/Complex Systems/Softwares/NetLogo/utils/EuclidianDistancesUtilities.nls" 
  "/Users/Juste/Documents/Complex Systems/Softwares/NetLogo/utils/StringUtilities.nls"
  "/Users/Juste/Documents/Complex Systems/Softwares/NetLogo/utils/SortingUtilities.nls"
  "/Users/Juste/Documents/Complex Systems/Softwares/NetLogo/utils/ListUtilities.nls"
  "/Users/Juste/Documents/Complex Systems/Softwares/NetLogo/utils/TypesUtilities.nls"
  "/Users/Juste/Documents/Complex Systems/Softwares/NetLogo/utils/FileUtilities.nls"
  "/Users/Juste/Documents/Complex Systems/Softwares/NetLogo/utils/LinkUtilities.nls"  
  "/Users/Juste/Documents/Complex Systems/Softwares/NetLogo/utils/NetworkUtilities.nls"    
  
]

globals [
  
  ;;utils variables
  building-layer-data
  transport-layer-data
  green-layer-data
  services-layer-data
  
  ;;network include vars
  paths-layer-data
  remaining-links
  remaining-vertexes
  cluster-treshold
  
  
  flats-list-by-rooms
  unemployment-diff  ;coefficient before the derivative in mean unemployment equa diff
  stop?
  tst
  
  ;;real variables
  ;unemployment-rate    ;considered as a macro variable, may evolve in long time series, according to external data?
  taxes-proportion     ;basically considered as linear function of income ; no taxes if get social help
  job-opportunities-per-year   ; very important : closely linked to the time scale, if small time step as 2 weeks, must be small ! to reproduce real situations with a lot of steps, such small step is needed
  unemployment-data            ;time-serie to match
  unemployment-data-time-scale
  
  
  ;social-help-rate     ;max proportion of population that can get social help - social help is attributed to the people with negative balance - first approx bring balance to zero
  ;;SAME VARIABLE as ...
  
  person-cost     ; approximate cost of a person per month (food etc) - children same as growth.
  
  ;time-interval        ;time for each tick, in years. Important if time serie for macrovars?
  
  ;social help
  ;social-help-treshold  ;treshold under which you can get social help - expressed in Kr/person (including children) -> allocs
  social-help-max-recipient-proportion  ;max fraction of the population which can get social help
  social-help-max-amount                ; max amount perceived from social help
  
  ;;rent update
  max-rent-per-square-meter     ;law regulation
  ;bnorm                         ; normalisation coef for the influence of balances on rents
  ;bref
  
  ;params for immigrants
  max-immigrant-number-per-year
  
  ;;globals for random config
  couple-proba
  children-mean
  ;income-mean
  ;income-sigma
  rent-mean
  rent-sigma
  
  
  ;;globals for extended aspects
  green-space-satisfaction-individual-norm-factor
  services-satisfaction-individual-norm-factor
]




;;Basic breeds
breed [flats flat]
breed [buildings building]
breed [households household]



;;new breeds
breed [services service]
breed [transports transport]
breed [green-spaces green-space]






;;;;;;;;;;;;;;;;;;;;;;;
;;network include breeds
;;;;;;;;;;;;;;;;;;;;;;;

breed [vertexes vertex]        
breed [abstract-gis-paths abstract-gis-path]

abstract-gis-paths-own [
   gis-feature
   vertexes-list
]

undirected-link-breed [paths path]

paths-own [path-length]


;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;
;; Owned variables
;;;;;;;;;;;;;;;;;;;;;;

buildings-own [
  gis-shape      ;corresponding gis VectorFeature
  in-flats       ;list of flats contained in the building
  
  rent-per-square-meter   ;numeric value of rents in the building. same for all flats?
]

households-own[
  incomes           ;list of incomes
  total-income      ;
  studies           ;for each people, level of studies in years. shows potentiality to find a job (children have 0 for example)
  experiences       ;years of experience in job, back to 0 if change?
  social-help?
  
  global-balance    ;economic bilan of the last period
  
  people-number     ;number of people in the household
  
  consumption-rate  ;quite constant, shows the tendancy to consum
  
  occupied-flat      ;pointer to the occuped flat
  
  ;;life quality aspects
  green-space-satisfaction
  services-satisfaction
  
]


flats-own[
  rooms             ;number of rooms
  surface           ;surface, directly linked to number of rooms. distributed in a "logic" way?
  rent
  
  occupant          ;pointer to the occuping household
  
  
  ;;living conditions variables
  living-standard ;;find a way to quantify it
  energetic-performance ;;% of total rent? easier that way
  
  ;;caches lists for distances - index corresponds to place in the sorted list of green by who (avoids a hashmap)
  distances-to-green-spaces
  distances-to-services
  
]


to draw-gis-layers
  ca
  
  output-print "Loading and Drawing GIS data..."
  
  let adresses import-adresses "/Users/Juste/Documents/Complex Systems/SustainableDistrict/Data/Langangen/GIS/adresses.txt"
  ask patches [set pcolor white]
  
  ;;load gis layers
  set building-layer-data gis:load-dataset "/Users/Juste/Documents/Complex Systems/SustainableDistrict/Data/Langangen/GIS/langangen_building/langangen_buildings_pol.shp";user-new-file
  set paths-layer-data gis:load-dataset "/Users/Juste/Documents/Complex Systems/SustainableDistrict/Data/Langangen/GIS/langangen_roads/langangen_roads.shp"
  set transport-layer-data gis:load-dataset "/Users/Juste/Documents/Complex Systems/SustainableDistrict/Data/Langangen/GIS/langangen_transport/langangen_transport.shp"
  set green-layer-data gis:load-dataset "/Users/Juste/Documents/Complex Systems/SustainableDistrict/Data/Langangen/GIS/langangen_green/langangen_green.shp"
  set services-layer-data gis:load-dataset "/Users/Juste/Documents/Complex Systems/SustainableDistrict/Data/Langangen/GIS/langangen_services/langangen_services.shp"
  
  ;;set enveloppes - these two layers enough?
  gis:set-world-envelope gis:envelope-union-of gis:envelope-of building-layer-data gis:envelope-of paths-layer-data
  
  ;;draw buildings
  gis:set-drawing-color black
  foreach gis:feature-list-of building-layer-data [
    ;if gis:property-value ? "ID" = target-id [gis:set-drawing-color red]
    foreach explode ";" gis:property-value ? "ADRESS" [if member? ? adresses [gis:set-drawing-color blue]]
    gis:fill ? 1 gis:set-drawing-color black
    let c gis:location-of gis:centroid-of ?
    ;create-turtles 1 [setxy item 0 c item 1 c set label-color red set size 0 set label gis:property-value ? "ADRESS"]
  ]
  gis:set-drawing-color white
  foreach gis:feature-list-of building-layer-data [let v ? foreach gis:feature-list-of building-layer-data [if v != ? and gis:contains? v ?[gis:fill ? 1]]]
  
  ;;draw roads
  gis:set-drawing-color brown
  gis:draw paths-layer-data 2
  
  ;;draw other layers
  if green? [gis:set-drawing-color green
  gis:draw green-layer-data 5]
  if services? [gis:set-drawing-color red
  gis:draw services-layer-data 5]
  if transport? [gis:set-drawing-color orange
  gis:draw transport-layer-data 3]
  
end

to load-csv-properies [filename property-name layer-data];load from csv file of the form ADRESS;PROPERTY
  let data but-first read-file filename
  foreach data [
    let value first but-first explode ";" ?
    foreach layer-data [
       ;gis:set-property-value 
    ]
  ]
end






;;set the static agent that are not supposed to change.
to set-static-agents
  output-print "Setting up static agents..."
  
  ;creation of buildings
  foreach gis:feature-list-of building-layer-data [create-buildings 1 [set gis-shape ? set in-flats [] set hidden? true]]
  
  
  
  ;;create abstract network -> BEFORE SETTING FLATS !!! (need network to calculate caches distances)
  ;;cluster treshold is fixed? Y, very small
  output-print "Extracting abstract network from GIS network..."
  set cluster-treshold 0.5
  create-network
  
  ;;set green spaces - Idem network (targets need to exist!)
  if green? [foreach gis:feature-list-of green-layer-data [foreach gis:vertex-lists-of ? [foreach ? [let loc gis:location-of ? create-green-spaces 1 [setxy first loc first but-first loc set color green set shape "circle"]]]]]
  
  ;;set services
  if services? [foreach gis:feature-list-of services-layer-data [foreach gis:vertex-lists-of ? [foreach ? [let loc gis:location-of ? create-services 1 [setxy first loc first but-first loc set color red set shape "circle"]]]]]
  
  ;;set transport stations
   
  
  ;;creation of flats
  set-flats  
  

  
  
  
  
  
end

to set-flats
  output-print "Filling buildings with flats..."
  create-flats 1 [setxy 0 0 set shape "house" set size 0.5 set color yellow set occupant nobody]
  let current-flat one-of flats
  let previous-flat nobody
  let filled? false
  let previous-building nobody
  snapshot
  
  while [not filled?][
     ;;fix if in a building
     let fixed? false
     ask buildings [let b self ask current-flat [
         ifelse not fixed? [
           if gis:contains? [gis-shape] of myself self [
             hatch-flats 1 [
               set previous-flat current-flat set current-flat self
               ask b [
                 set in-flats lput previous-flat in-flats set previous-building self
               ]
             ] 
             set fixed? true
             
             ;;since current flat has been fixed in previous flat, able to calculate cache distances to activities
             set distances-to-green-spaces []
             foreach sort-on [who] green-spaces [set distances-to-green-spaces lput distance-through-network ? distances-to-green-spaces]
             set distances-to-services []
             foreach sort-on [who] services [set distances-to-services lput distance-through-network ? distances-to-services]
             
           ]
         ] 
         [ if gis:contains? [gis-shape] of myself self [ask previous-building [set in-flats remove previous-flat in-flats] ask previous-flat [die]]  ;;two and only two max containing shape?   
           ] ]]
     ask current-flat [ifelse ycor = world-height - 1 and xcor = world-width - 1 [set filled? true] [set ycor (ycor + 0.5 ) mod (world-height - 0.5) if ycor = 0 [set xcor (xcor + 0.5 ) mod (world-width - 0.5)]]]
     if filled? [ask current-flat[die]]
  ]
end




to set-static
  draw-gis-layers
  set-static-agents
end



to set-random-initial-configuration
  
  ;;when multiple iterations (ex calibration), don't do it each tick to gain time
  set-static
  
  output-print "Setting up dynamic agents..."
  
  
  ;;set "fixed" global vars
  set couple-proba 0.8
  set children-mean 1
  ;set income-mean 16000
  ;set income-sigma 3000
  set rent-mean 72.45
  set rent-sigma 6.9
  ;set time-interval 0.1 ;6month
  set social-help-max-recipient-proportion 25
  set taxes-proportion 0.1
  set person-cost 1500
  set social-help-max-amount 15000
  set job-opportunities-per-year 100
  set max-immigrant-number-per-year 10
  set max-rent-per-square-meter 200
  ;set bnorm 30000
  set stop? false
  
  let data read-file "unemployment.csv"
  set unemployment-data-time-scale read-from-string first but-first data
  set unemployment-data map read-from-string but-first but-first data
  
  ;;extended globals
  set green-space-satisfaction-individual-norm-factor 2.5
  set services-satisfaction-individual-norm-factor 2.5
  
  output-print "Variables"
  
  ;;fix rents
  ask buildings [
    set rent-per-square-meter random-normal rent-mean rent-sigma
    ;;set foreach flat rooms, surface and rent
    foreach in-flats [
      let r random-float 1
      ifelse r > couple-proba [ask ? [set rooms 2]]
      [ifelse r > couple-proba / 2 [ask ? [set rooms 3]][ask ? [set rooms 4]]]
      ask ? [set surface rooms * 20 set rent ([rent-per-square-meter] of myself) * surface]
    ]
  ]
  
  output-print "Rents"
  
  ;;populate the district
  
  set flats-list-by-rooms []
  set flats-list-by-rooms lput sort-by [lexcomp ?1 ?2 (list task [rent])] flats with [rooms = 2] flats-list-by-rooms
  set flats-list-by-rooms lput sort-by [lexcomp ?1 ?2 (list task [rent])] flats with [rooms = 3] flats-list-by-rooms
  set flats-list-by-rooms lput sort-by [lexcomp ?1 ?2 (list task [rent])] flats with [rooms = 4] flats-list-by-rooms
  repeat floor (count flats ) * initial-occupied-flats / 100 [
     
     create-households 1 [
       new-household income-mean
     ] 
  ]
  
  output-print "Households"
  
  reset-ticks
  
  update-drawing
  
  
  
  
end

to new-household [income]
     ;;set people
     let r random-float 1 ifelse r >= couple-proba [set people-number 1];won't complicate with alone with children
     [set people-number 2 + (random 2 * children-mean)]
     
     ;;set studies !! BEFORE incomes, to be coherent with the following (self coherence of the implementation)
     let s1 floor (random-normal 3 2) let s2 floor (random-normal 3 2)
     ifelse people-number = 1 [set studies (list s1)]
     [set studies list s1 s2]
     
     ;;set incomes or unemployment
     set incomes []
     foreach studies [
       let i 0 let u random-float 100
       if u > unemployment-initial-rate [set i max list 10000 (random-normal ((income-mean - (income-sigma)) + (k-studies * ? * income-sigma)) income-sigma)]
       set incomes lput i incomes
     ]
     
     ;;set experiences
     set experiences list 0 0 foreach incomes [set experiences replace-item position ? incomes experiences (0.5 + (random 20 / 2))]
     ;;find flat
     find-flat
     ;;social help
     set social-help? false
     
     ;;default satisfactions
     set green-space-satisfaction 0
     set services-satisfaction 0  
     
end

;household procedure to find the best flat
to find-flat
  let i min list max list 0 (people-number - 2) 2
  let f nobody let d item i flats-list-by-rooms
  ifelse d != [] [set f first d set flats-list-by-rooms replace-item i flats-list-by-rooms but-first d][set f one-of flats with [occupant = nobody] foreach flats-list-by-rooms [set ? remove f ?]]
  set occupied-flat f ask f [set occupant myself]
  
end




to go
  output-print word "Going for tick " ticks
  
  set-data
  if not stop?[
  update-work-situations
  update-social-helps
  update-rents
  calculate-balances
  emigrate
  immigrate
  update-drawing
  
  ;;add new effects : integration on time step of "satisfaction" regarding to new aspects?
  ;;also influence of energy and living standard on rents
  
  
  
  update-life-quality-reporters
  
  tick
  
  output-print word "Total time : " (ticks * time-interval )
  ]
end

to test-run-duration
  profiler:reset
  profiler:start
  let time 0
  set-random-initial-configuration
  while [not stop?][
    go
    set time time + profiler:inclusive-time "go"
    show profiler:inclusive-time "go"
  ]
  show profiler:inclusive-time "go"
end

to calibrate
  let filename word word "calibration/cal_" timer ".sci"
  print-in-file filename "bref=[];bnorm=[];income-mean=[];rents=[];"
  set bref 5000
  set bnorm 10000
  set income-mean 10000
  let i 1
  
  repeat 10 [
    
    repeat 10 [
     
     repeat 10 [
      
       set-random-initial-configuration
       
       let out (list mean [rent / surface] of flats)
       let j 1
       
       while [not stop?][go if (ticks * time-interval) mod 1 = 0 [set out lput mean [rent / surface] of flats out]]  
       print-in-file filename word word word word "bref(" i ")=" bref ";"
       print-in-file filename word word word word "bnorm(" i ")=" bnorm ";"
       print-in-file filename word word word word "incomemean(" i ")=" income-mean ";"
       foreach out [print-in-file filename word word word word word word "rents(" i "," j ")=" ? ";" set j j + 1]
      
       set income-mean income-mean + 1000 
       set i i + 1

     ]
     
     set bnorm bnorm + 2000
     set income-mean 10000 
    ]
    
    set bref bref + 1000
    set bnorm 10000
    set income-mean 10000
  ]
  
  
end








to update-life-quality-reporters
  output-print "Calculating life quality reporters..."
  ;snapshot
  ask households [
    if green? [set green-space-satisfaction green-space-satisfaction-reporter]
    if services? [set services-satisfaction services-satisfaction-reporter]
  ]
end

to-report green-space-satisfaction-reporter
   report norm-p green-space-satisfaction-individual-norm-factor [distances-to-green-spaces] of occupied-flat
end

to-report services-satisfaction-reporter
   report norm-p services-satisfaction-individual-norm-factor [distances-to-services] of occupied-flat
end



to set-data
  if unemp-ext-data?[
    ifelse unemployment-data = [] [set stop? true]
    [if (ticks * time-interval) mod unemployment-data-time-scale = 0 [set unemployment-initial-rate first unemployment-data set unemployment-data but-first unemployment-data]]
  ]
end

to update-work-situations
  ;;add time experience for workers
  ask households [foreach incomes [if ? != 0 [let i position ? incomes set experiences replace-item i experiences (item i experiences + time-interval)]]]
  
  ;;some unemployed find jobs and others loose their jobs. Function of what? unemployment derivative? variable unemployment-growth
  let u unemployed-number
  let new-workers-number max list 0 min list u floor (random-normal (job-opportunities-per-year * time-interval) (u / 10)) ;
  let unemployed to-list households with [member? 0 incomes]
  repeat new-workers-number [;people finding a job
    if unemployed != [] [
    ask one-of unemployed [
      let w 1 - bool-to-int ((item 0 incomes) = 0)  ;index of unemployed guy
      ;gets job and new income!
      set incomes replace-item w incomes max list 10000 (random-normal ((income-mean - (income-sigma)) + (k-studies * (item w studies) * income-sigma)) income-sigma)
      if not member? 0 incomes [set unemployed remove self unemployed]
      ]
    ]
  ]
  
  ;;loose of jobs - ratio has to match unemployment-growth variable
  let job-loosers-number max list 0 min list (actives-number - u) floor (random-normal (new-workers-number + (actives-number * unemployment-initial-rate / 100) - u) (u / 10))
  set unemployment-diff job-loosers-number - new-workers-number
  let employed to-list households with [sum incomes > 0]
  repeat job-loosers-number [;people loosing their job
    if employed != [][
    ask one-of employed [
      let w bool-to-int (item 0 incomes = 0)
      ;;looses income and experience
      set incomes replace-item w incomes 0
      set experiences replace-item w experiences 0
      if sum incomes = 0 [set employed remove self employed]
    ]
    ]
  ]
  
  
  ;;promotion for experienced workers
  if with-promotions? [
    ask households [
      foreach experiences [let i position ? experiences if ? > 0 and ? mod 5 = 0 [set incomes replace-item i incomes (item i incomes + 500)]]
    ]
  ]
  
  
  
end



to update-social-helps
  ask households [set social-help? false]
  ;;calculate provisory balance to see if could get the social help
  let eligibles households with [prov-balance < social-help-treshold]
  ask min-n-of min list count eligibles floor (social-help-max-recipient-proportion * count households / 100 ) eligibles [prov-balance]
    [set social-help? true]
end

;aux function to report prov balance
to-report prov-balance
  report (sum incomes - ([rent] of occupied-flat)) / people-number
end




to update-rents
  ;;rents adapt themsleves according to ? -> neighborhood value (existing model) and people wealth
  ;;external control (law), also externalities as unemployment? -> could be a way to calibrate..
  ;;one time per year only? -> can change it
  
  if ticks * time-interval mod 1 = 0 and rent-updates? [ ;; update rents
     let r mean [rent] of flats
     let b mean [global-balance] of households
     ask flats [let max-rent surface * max-rent-per-square-meter set rent min list max-rent ((rent * ((1 + (b - bref)/ bnorm))) )];+ (rent-coef * (r - rent)))]
  ]
  
end

to calculate-balances
  ask households [set global-balance balance if social-help? [set global-balance min list (global-balance + social-help-max-amount) 500]]
end

to-report balance
  ;;basic balance, linear taxes.
    report (sum incomes - ([rent] of occupied-flat)) - (taxes-proportion * sum incomes) - (person-cost * people-number)
end


to emigrate
  ;;test with drastic rule : if balance < treshold, die (elictive district) - activate only when stable?
  if drastic? [ ask households with [global-balance < die-treshold] [ask occupied-flat [set occupant nobody] die]]
  
  
  ;;ADD RANDOM DEPARTURES ASSOCIATED WITH ARRIVALS
  ;;CHILDREN?
  
  
end

to immigrate
  if new-inhabitants? [ let i workers-mean-income repeat min list (count flats with [occupant = nobody]) floor (max-immigrant-number-per-year * time-interval) [create-households 1 [new-household i]] ]
end

















;;Utilities functions





to-report unemployed-number
  let res 0 ask households [foreach incomes [if ? = 0 [set res res + 1]]] report res
end

to-report actives-number
  report sum [length incomes] of households
end

to-report workers-mean-income
  let res 0 let c 0
  ask households [foreach incomes [ if ? != 0 [set res res + ? set c c + 1]]]
  report res / c
end

to-report unemployment-coef
  report unemployment-diff
end



to update-drawing
  ;;try to show something
  output-print "Drawing..."
  
  clear-drawing
  gis:set-drawing-color brown gis:draw paths-layer-data 2
  gis:set-drawing-color grey gis:draw building-layer-data 1
  
  if green? [gis:set-drawing-color green
  gis:draw green-layer-data 5]
  if services? [gis:set-drawing-color red
  gis:draw services-layer-data 5]
  if transport? [gis:set-drawing-color orange
  gis:draw transport-layer-data 3]
  
  
  ask turtles [set hidden? true]
  let mir min [rent] of flats
  let mar max [rent] of flats
  ask patches with [count flats-on self > 0][
    set pcolor scale-color red (mean ([rent] of flats-on self)) (mir - 50) (mar + 50) 
  ]
  let mii min [(sum incomes) / people-number] of households
  let mai max [(sum incomes) / people-number] of households
  ask households [
    setxy [xcor] of occupied-flat [ycor] of occupied-flat set shape "person" set size people-number / 2 set hidden? false
    set color scale-color green ((sum incomes) / people-number) (mii - 50) (mai + 50)
    if member? 0 incomes [set color pink] 
    if social-help? [set color yellow]
    ]
end






to-report import-adresses [file]
  let res []
  file-open file
  while [not file-at-end?][
     set res lput file-read-line res
  ]
  file-close
  report res
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
935
444
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
54
0
30
0
0
1
ticks
30.0

SLIDER
15
16
187
49
target-id
target-id
1
50
42
1
1
NIL
HORIZONTAL

SLIDER
3
164
187
197
initial-occupied-flats
initial-occupied-flats
0
100
91
1
1
NIL
HORIZONTAL

BUTTON
15
60
132
93
set-random
set-random-initial-configuration
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
253
595
332
640
NIL
count flats
17
1
11

MONITOR
184
642
270
687
unoccupied
count flats with [occupant = nobody]
17
1
11

MONITOR
278
643
328
688
hshlds
count households
17
1
11

MONITOR
187
692
282
737
mean income
workers-mean-income
17
1
11

MONITOR
501
693
593
738
mean people
mean [people-number] of households
17
1
11

MONITOR
342
593
422
638
population
sum [people-number] of households
17
1
11

MONITOR
289
691
384
736
mean studies
mean [mean studies] of households
17
1
11

SLIDER
-5
234
212
267
unemployment-initial-rate
unemployment-initial-rate
0
100
7.7
1
1
NIL
HORIZONTAL

SLIDER
6
273
202
306
unemployment-growth
unemployment-growth
-100
100
-4
1
1
NIL
HORIZONTAL

MONITOR
185
545
274
590
unemployed
unemployed-number
17
1
11

PLOT
518
448
678
568
unemployment
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 100 * unemployed-number / actives-number"

BUTTON
948
18
1011
51
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
390
690
495
735
unemployment
100 * unemployed-number / actives-number
17
1
11

SLIDER
6
309
178
342
time-interval
time-interval
0
1
0.1
0.05
1
NIL
HORIZONTAL

MONITOR
280
545
337
590
K
(job-opportunities-per-year * time-interval) - floor (actives-number * unemployment-growth / 100)
17
1
11

MONITOR
184
594
247
639
workers
actives-number - unemployed-number
17
1
11

SWITCH
5
353
172
386
with-promotions?
with-promotions?
0
1
-1000

PLOT
516
572
676
692
mean income
NIL
NIL
0.0
10.0
15000.0
17000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot workers-mean-income"
"pen-1" 1.0 0 -7500403 true "" ""

SLIDER
6
388
187
421
social-help-treshold
social-help-treshold
0
1500
50
10
1
NIL
HORIZONTAL

PLOT
680
572
840
692
balances
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [prov-balance] of households"
"pen-1" 1.0 0 -7500403 true "" "plot min [prov-balance] of households"
"pen-2" 1.0 0 -2674135 true "" "plot max [prov-balance] of households"
"pen-3" 1.0 0 -955883 true "" "plot mean [global-balance] of households"
"pen-4" 1.0 0 -6459832 true "" "plot max [global-balance] of households"
"pen-5" 1.0 0 -1184463 true "" "plot min [global-balance] of households"

MONITOR
415
642
488
687
deficients
count households with [global-balance < 0]
17
1
11

MONITOR
426
591
508
636
social-help
count households with [social-help?]
17
1
11

SWITCH
7
428
112
461
drastic?
drastic?
0
1
-1000

SLIDER
7
468
179
501
die-treshold
die-treshold
-10000
1000
160
10
1
NIL
HORIZONTAL

PLOT
358
448
518
568
population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [people-number] of households"

SWITCH
7
506
170
539
new-inhabitants?
new-inhabitants?
1
1
-1000

PLOT
681
447
841
567
rents
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [rent / surface] of flats"
"pen-1" 1.0 0 -7500403 true "" "plot max [rent / surface] of flats"
"pen-2" 1.0 0 -2674135 true "" "plot min [rent / surface] of flats"

SWITCH
6
541
150
574
rent-updates?
rent-updates?
0
1
-1000

SLIDER
6
580
178
613
rent-coef
rent-coef
0
1
0
0.1
1
NIL
HORIZONTAL

SLIDER
7
617
179
650
bref
bref
-10000
20000
9300
10
1
NIL
HORIZONTAL

SLIDER
3
664
175
697
income-sigma
income-sigma
0
5000
3087
1
1
NIL
HORIZONTAL

SWITCH
2
202
167
235
unemp-ext-data?
unemp-ext-data?
0
1
-1000

PLOT
1243
24
1403
144
happiness
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [max list 0 (global-balance / income-mean)] of households"
"pen-1" 1.0 0 -7500403 true "" "plot min [max list 0 (global-balance / income-mean)] of households"
"pen-2" 1.0 0 -2674135 true "" "plot max [max list 0 (global-balance / income-mean)] of households"

SLIDER
10
701
182
734
k-studies
k-studies
0
5
0.3
0.1
1
NIL
HORIZONTAL

MONITOR
334
643
409
688
mean rent
mean [rent] of flats
17
1
11

SLIDER
186
467
358
500
income-mean
income-mean
5000
25000
18250
10
1
NIL
HORIZONTAL

SLIDER
186
506
358
539
bnorm
bnorm
10000
30000
30000
10
1
NIL
HORIZONTAL

BUTTON
14
99
104
132
set-static
draw-gis-layers\nset-static-agents
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
907
481
1375
727
8

TEXTBOX
906
461
1056
479
Console
11
0.0
1

TEXTBOX
945
164
1095
184
Options and parameters\nfor life aspects
8
0.0
1

SWITCH
937
185
1027
218
green?
green?
0
1
-1000

SWITCH
938
222
1028
255
transport?
transport?
1
1
-1000

SWITCH
939
259
1029
292
services?
services?
0
1
-1000

SWITCH
939
297
1029
330
energy?
energy?
1
1
-1000

SWITCH
939
335
1029
368
standard?
standard?
1
1
-1000

PLOT
1242
183
1402
303
green satisf
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot norm-p 1 [green-space-satisfaction] of households"

PLOT
1242
307
1402
427
services satisf
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot norm-p 1 [services-satisfaction] of households"

BUTTON
1013
98
1076
131
test
ask paths [set color blue set thickness 0.3 let e1 end1 let d 0 ask end2 [set d distance e1] set path-length d]\nnw:set-snapshot vertexes paths\nask one-of vertexes [\n   ask one-of other vertexes [\n     let l nw:weighted-path-to myself \"path-length\"\n     if l != false [foreach l [ask ? [set thickness 0.5 set color green]]]\n   ]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

Extension of the basic Agent-based Model on small space and time scales for district Långängen.
We add "socio-cultural" aspects, in facts living conditions, inside flats and outside.

## HOW IT WORKS

New agents : green-spaces, services, transport
New owned variables for flats : energy perf and standard


## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
