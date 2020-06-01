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
    assertEqual(liqr.score(str, search), 1/0)
end

local function testMatches(str, search, expectedMatches)
    lunity._lunityAssertsAttempted = lunity._lunityAssertsAttempted + 1
    local score, bits = liqr.score(str, search)
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
    testMatches('Foo Bar', 'fob',
        {{first=1, last=2},
         {first=5, last=5}}
    )

    testMatches('Abcd Bar Cat', 'a',
        {{first=1, last=1}}
    )

    -- Prefer word boundaries over earlier characters
    testMatches('Abcd Bar Cat', 'b',
        {{first=6, last=6}}
    )
    testMatches('abcd bar cat', 'b',
        {{first=6, last=6}}
    )

    testMatches('Abcd Bar Cat', 'bc',
        {{first=6, last=6},
         {first=10, last=10}}
    )

    -- Do not latch to word boundary if we're typing consecutive letters
    testMatches('Abcd Bar Cat', 'ab',
        {{first=1, last=2}}
    )
    testMatches('Abcd Bar Cat', 'ac',
        {{first=1, last=1},
         {first=10, last=10}}
    )
    testMatches('Abcd Bar Cat', 'aca',
        {{first=1, last=1},
         {first=10, last=11}}
    )

    -- We do not expect backtracking after latching onto a word boundary
    -- This is unfortunate, but consistent with VS Code's filtering, e.g. "fld" failes to select "Fold Level 4"
    testNoMatch('Abcd Bar Cat', 'acd')
    testNoMatch('Abqd Bar Cat', 'bq')
    testNoMatch('abqd bar cat', 'bq')

    -- Prefer sequences
    testMatches('Generate Colors from Current', 'gecu',
        {{first=1, last=2},
         {first=22, last=23}}
    )
end

function test.scoring()
    local phrases = {
        'Money Slate Outhouse Hutment',
        'Topside Betake Bejewel Mouth',
        'Pithy Crumpet Ducktail Monster',
        'Fissile Pitched Smirch Oxtail',
        'Britches Currier Smalto Listed',
        'Lagrange Exemplar Raisin Clang',
        'Zooist Beamy Diluvium Touristy',
        'Thither Sanative Stannic Nettle',
        'Edible Statued Devil Seepage',
        'Smithy Tenon Seaside Creepie',
        'Outwash Author Infer Flamingo',
        'Fool Oversize Tenement Amount',
        'Farrow Hospodar Infant',
        'Indigent Wapiti Mail',
        'Authored Triode Volt',
        'Stampede Multiped Gismo',
        'Humanoid Kale Ail',
        'Lesser Lipoid Salvia',
    }
end

test{useANSI=false}
