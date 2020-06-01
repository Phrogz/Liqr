package.path = '../?.lua;?.lua'
local liqr = require 'liqr'
_ENV = require('lunity')()

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
    else
        error('Expected a match, but got none', 2)
    end
end

function test.all()
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
    testMatches('Foo Bar', 'fob',
        {{first=1, last=2},
         {first=5, last=5}}
    )
    
    testMatches('Abcd Bar Cat', 'a',
        {{first=1, last=1}}
    )
    testMatches('Abcd Bar Cat', 'b',
        {{first=6, last=6}}
    )
    testMatches('Abcd Bar Cat', 'bc',
        {{first=6, last=6},
         {first=10, last=10}}
    )
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
    testMatches('Abcd Bar Cat', 'acd',
        {{first=1, last=1},
         {first=3, last=4}}
    )

    testMatches('Abqd Bar Cat', 'bq',
        {{first=2, last=3}}
    )
end

test()