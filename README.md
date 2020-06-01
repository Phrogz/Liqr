# Liqr
Substring filtering for Lua.

In general, sequential matches and matches at word boundaries—including the boundaries
of capital letters appearing in camelCaseDescriptors—are prioritized over spread out,
mid-word matches.

## Matching a Single String

```lua
local liqr = require('liqr')

local score, matches = liqr.match('Fissile Pitched Birch Oxtail', 'ill')
print(score)
--> 0.55  Lower scores are better
-->       0.0 indicates an exact case-insensitive match

inspect(matches)
--> {
-->    {first=5, last=6},   "il" characters in "Fissile"
-->    {first=28, last=28}  "l" character in "Oxtail"
--> }

-- A failed match has a score of Infinity and no 'matches' result
local score, matches = liqr.match('dog', 'cat')
print(score, matches)
--> inf  nil 
```

## Filtering and Sorting a List of Results

```lua
local menu = {
    {id=1, label='Topside Betake Bejewel Mouth'},
    {id=2, label='Indigent Wapiti Mail'},
    {id=3, label='Fissile Pitched Birch Oxtail'},
    {id=4, label='Pithy Crumpet Monster'},
    {id=5, label='Britches Courier Small'},
    {id=6, label='Lagrange Exemplar Raisin Clang'},
    {id=7, label='Zoo Beam Diluvium Tourist'},
    {id=8, label='Taffy Town'},
    {id=9, label='Outwash Author Infer Flamingo'},
}

-- Simply finding the names of the matching items
-- The optional third parameter indicates that the items are tables, and matches against this key
-- With no third parameter `tostring()` is invoked on each list entry to find the string to match against
local results = liqr.filter(menu, 'cr', 'label')
for i,match in ipairs(results) do
    print(i, menu[match.originalIndex].label)
end
--> 1	Pithy Crumpet Monster
--> 2	Britches Courier Small List
--> 3	Fissile Pitched Birch Oxtail


-- Showing the data available in the results
local results = liqr.filter(menu, 'bea', 'label')
--> {
-->   {score=0.15, originalIndex=7, matches={{first=5, last=7}},
-->    bits={{match=false, str="Zoo "},
-->          {match=true,  str="Bea"},
-->          {match=false, str="m Diluvium Tourist"}}},
-->
-->   {score=0.4, originalIndex=1, matches={{first=9, last=10}, {first=12, last=12}},
-->    bits={{match=false, str="Topside "},
-->          {match=true,  str="Be"},
-->          {match=false, str="t"},
-->          {match=true,  str="a"},
-->          {match=false, str="ke Bejewel Mouth"}}},
-->
-->   {score=0.55, originalIndex=5, matches={{first=1, last=1}, {first=7, last=7}, {first=20, last=20}},
-->    bits={{match=true,  str="B"},
-->          {match=false, str="ritch"},
-->          {match=true,  str="e"},
-->          {match=false, str="s Courier Sm"},
-->          {match=true,  str="a"},
-->          {match=false, str="ll"}}}}
--> }


-- Showing how to concatenate the `bits` to construct a string that highlights the matches
local function showTop5(search)
    for i,result in ipairs(liqr.filter(menu, search, 'label')) do
        if i>5 then break end
        local uppercasedMatches = {}
        for i,bit in ipairs(result.bits) do
            uppercasedMatches[i] = bit.match and bit.str:upper() or bit.str:lower()
        end
        print(table.concat(uppercasedMatches))
    end
end

showTop5('t')
--> Topside betake bejewel mouth
--> Taffy town
--> zoo beam diluvium Tourist
--> briTches courier small list
--> piThy crumpet monster

showTop5('tt')
--> Taffy Town
--> Topside beTake bejewel mouth
--> zoo beam diluvium TourisT
--> briTches courier small lisT
--> piThy crumpeT monster

showTop5('ttown')
--> Taffy TOWN
```
