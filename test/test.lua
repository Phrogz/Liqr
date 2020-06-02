package.path = '../?.lua;?.lua'
_ENV = require('lunity')('Test Liqr')
local lunity = getmetatable(_ENV).__index

local liqr = require 'liqr'

local function dump(v,seen)
    seen = seen or {}
    local reserved = {["and"]=1,["break"]=1,["do"]=1,["else"]=1,["elseif"]=1,["end"]=1,["false"]=1,["for"]=1,["function"]=1,["goto"]=1,["if"]=1,["in"]=1,["local"]=1,["nil"]=1,["not"]=1,["or"]=1,["repeat"]=1,["return"]=1,["then"]=1,["true"]=1,["until"]=1,["while"]=1}
    local t=type(v)
    if t=='table' then
        if seen[v] then return '(...)' end
        seen[v] = true
        local s,r,a={},{},{}
        for i,v2 in ipairs(v) do s[i]=true table.insert(r,dump(v2)) end
        for k,v2 in pairs(v) do table.insert(a,k) end
        table.sort(a,function(a,b) return tostring(a)<tostring(b) end)
        for _,k in ipairs(a) do
            local v2 = v[k]
            if not s[k] then
                if type(k)=='string' and not reserved[k] and string.match(k,'^[%a_][%w_]*$') then
                    table.insert(r,k..'='..dump(v2,seen))
                else
                    table.insert(r,'['..dump(k,seen)..']='..dump(v2,seen))
                end
            end
        end
        return '{'..table.concat(r,', ')..'}'
    elseif t=='string' then
        return string.format('%q',v)
    elseif t=='function' then
        return "'"..tostring(v).."'"
    else
        return tostring(v)
    end
end

local function testNoMatch(str, search)
    lunity._lunityAssertsAttempted = lunity._lunityAssertsAttempted + 1
    local score = liqr.match(str, search)
    if score==1/0 then
        lunity._lunityAssertsPassed = lunity._lunityAssertsPassed + 1
    else
        error('Matching "'..search..'" against "'..str..'" failed.\nExpected: (no matches)\nActual:  '..dump(bits), 2)
    end
end

local function testMatches(str, search, expectedMatches)
    lunity._lunityAssertsAttempted = lunity._lunityAssertsAttempted + 1
    local score, bits = liqr.match(str, search)
    if bits then
        local ok = #bits==#expectedMatches
        if ok then
            for i,bit in ipairs(bits) do
                local expected = expectedMatches[i]
                ok = ok and bit.first==expected.first and bit.last==expected.last
                if not ok then break end
            end
        end
        if not ok then
            error('Matching "'..search..'" against "'..str..'" failed.\nExpected: '..dump(expectedMatches)..'\nActual:  '..dump(bits), 2)
        end
        lunity._lunityAssertsPassed = lunity._lunityAssertsPassed + 1
        io.write('.')
    else
        error('Expected a match, but got none', 2)
    end
end

function test.basicMatching()
    testNoMatch('foo bar', 'q')
    testMatches('foo bar', 'f',
        {{first=1, last=1}}
    )
    testMatches('foo bar', 'foo',
        {{first=1, last=3}}
    )
    testMatches('foo bar', 'fb',
        {{first=1, last=1},
         {first=5, last=5}}
    )
    testMatches('foo bar', 'fob',
        {{first=1, last=2},
         {first=5, last=5}}
    )
end

function test.prioritizeCamelCase()
    -- Ensure that case-insensitive searching works
    testMatches('foo bar', 'fob', {{first=1, last=2},{first=5, last=5}})
    testMatches('Foo Bar', 'fob', {{first=1, last=2},{first=5, last=5}})
    testMatches('FooBar',  'fob', {{first=1, last=2},{first=4, last=4}})

    -- Do not latch to word boundary if we're typing consecutive letters
    testMatches('abcd bar cat', 'ab', {{first=1, last=2}})
    testMatches('Abcd Bar Cat', 'ab', {{first=1, last=2}})
    testMatches('AbcdBarCat',   'ab', {{first=1, last=2}})

    testMatches('abcd bar cat', 'ac', {{first=1, last=1},{first=10, last=10}})
    testMatches('Abcd Bar Cat', 'ac', {{first=1, last=1},{first=10, last=10}})
    testMatches('AbcdBarCat',   'ac', {{first=1, last=1},{first=8,  last=8}})

    testMatches('abcd bar cat', 'aca', {{first=1, last=1},{first=10, last=11}})
    testMatches('Abcd Bar Cat', 'aca', {{first=1, last=1},{first=10, last=11}})
    testMatches('AbcdBarCat',   'aca', {{first=1, last=1},{first=8,  last=9}})

    -- Prefer sequences
    testMatches('generate colors from current', 'gecu', {{first=1, last=2},{first=22, last=23}})
    testMatches('Generate Colors from Current', 'gecu', {{first=1, last=2},{first=22, last=23}})
    testMatches('GenerateColorsfromCurrent',    'gecu', {{first=1, last=2},{first=19, last=20}})

    -- Prefer word boundaries over earlier characters
    testMatches('abcd bar cat', 'b', {{first=6, last=6}})
    testMatches('Abcd Bar Cat', 'b', {{first=6, last=6}})
    testMatches('AbcdBarCat',   'b', {{first=5, last=5}})

    testMatches('abcd bar cat', 'bc', {{first=6, last=6},{first=10, last=10}})
    testMatches('Abcd Bar Cat', 'bc', {{first=6, last=6},{first=10, last=10}})
    testMatches('AbcdBarCat',   'bc', {{first=5, last=5},{first=8,  last=8}})

    -- We do not expect backtracking after latching onto a word boundary
    -- This is unfortunate, but consistent with VS Code's filtering, e.g. "fld" failes to select "Fold Level 4"
    testNoMatch('abcd bar cat', 'acd')
    testNoMatch('Abcd Bar Cat', 'acd')
    testNoMatch('AbcdBarCat',   'acd')
    testNoMatch('abqd bar cat', 'bq')
    testNoMatch('Abqd Bar Cat', 'bq')
    testNoMatch('AbqdBarCat',   'bq')
end

local function showFilter(phrases, search, key)
    local results = liqr.filter(phrases, search, key)
    print('\n-----------\n'..search)
    for _,match in ipairs(results) do
        print(match.score, liqr.highlightMatched(match.annotated))
    end
end

function test.relativeScoring()
    local phrases = {
        'Money Slate Outhouse Hutment',
        'Topside Betake Bejewel Mouth',
        'Indigent Wapiti Mail',
        'Fissile Pitched Smirch Oxtail',
        'Pithy Crumpet Ducktail Monster',
        'Britches Currier Smalto Listed',
        'Lagrange Exemplar Raisin Clang',
        'Zooist Beamy Diluvium Touristy',
        'Thither Sanative Stannic Nettle',
        'Edible Statued Devil Seepage',
        'Smithy Tenon Seaside Creepie',
        'Taffy Town',
        'Outwash Author Infer Flamingo',
        'Fool Oversize Tenement Amount',
        'Farrow Hood Infant',
        'Authored Triode Volt',
        'Stampede Multiped Gismo',
        'Humanoid Kale Ail',
        'Lesser Lipoid Salvia',
    }

    local results = liqr.filter(phrases, 'zzz')
    assertEqual(#results, 0)

    local results = liqr.filter(phrases, 'farrow hood infant')
    assertEqual(#results, 1)
    assertEqual(results[1].score, 0.0)
    assertEqual(phrases[results[1].originalIndex], 'Farrow Hood Infant')

    local results = liqr.filter(phrases, 'fa ho inf')
    assertEqual(#results, 1)
    assertTrue(results[1].score > 0, 'Imperfect matches should have non-zero scores')

    local results = liqr.filter(phrases, 'pit')
    assertEqual(phrases[results[1].originalIndex], 'Pithy Crumpet Ducktail Monster', 'Matches at the very beginning are better than start-of-word matches later')
    assertEqual(phrases[results[2].originalIndex], 'Fissile Pitched Smirch Oxtail',  'Matches at the very beginning are better than start-of-word matches later')
    assertEqual(phrases[results[3].originalIndex], 'Indigent Wapiti Mail',           'Matches at the very beginning are better than start-of-word matches later')
    assertEqual(phrases[results[4].originalIndex], 'Topside Betake Bejewel Mouth',   'Multiple matches score lower than a single substring')

    local results = liqr.filter(phrases, 'af')
    assertEqual(phrases[results[1].originalIndex], 'Outwash Author Infer Flamingo', 'Two matched word beginnings are better than a single two-character substring')
    assertEqual(phrases[results[2].originalIndex], 'Taffy Town', 'A single two-character substring is better than two substrings')
    assertEqual(phrases[results[3].originalIndex], 'Farrow Hood Infant', 'A single two-character substring is better than two substrings')
end

function test.filterAPI()
    local function stringable(str, id)
        return setmetatable({str=str, id=id}, {__tostring=function(t) return t.str end})
    end
    local strs = {'Abba', 'barn', 'cat'}
    local objs = {}
    for i,str in ipairs(strs) do objs[i] = stringable(str, 10+i) end

    -- matching pure strings
    local results = liqr.filter(strs, 'ba')
    assertEqual(strs[results[1].originalIndex], 'barn')
    assertEqual(strs[results[2].originalIndex], 'Abba')

    -- matching against properties
    local results = liqr.filter(objs, 'ba', 'str')
    assertEqual(strs[results[1].originalIndex], 'barn')
    assertEqual(strs[results[2].originalIndex], 'Abba')

    -- matching against tostring()
    local results = liqr.filter(objs, 'ba')
    assertEqual(strs[results[1].originalIndex], 'barn')
    assertEqual(strs[results[2].originalIndex], 'Abba')
end

test{useANSI=false}
