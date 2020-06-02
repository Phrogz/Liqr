local lib = {}

local function sortByScore(a, b) return a.score<b.score end
function lib.filter(values, search, key)
    local results = {}
    for originalIndex,value in ipairs(values) do
        local str = tostring(key and value[key] or value)
        local score, matches = lib.match(str, search)
        if score < 1/0 then
            results[#results+1] = {score=score, matches=matches, originalIndex=originalIndex, bits=lib.annotatedString(str, matches)}
        end
    end
    table.sort(results, sortByScore)
    return results
end

function lib.annotatedString(str, matches)
    local bits = {}
    local start = 1
    for _,piece in ipairs(matches) do
        if piece.first>start then
            bits[#bits+1] = {str=str:sub(start, piece.first-1), match=false}
        end
        bits[#bits+1] = {str=str:sub(piece.first, piece.last), match=true}
        start = piece.last + 1
    end
    if start<(#str+1) then
        bits[#bits+1] = {str=str:sub(start), match=false}
    end
    return bits
end

function lib.match(str, search)
    local score = 0
    local stringStart, searchStart = 1, 1
    local matches = {}
    local done = false

    local searchCharCount = #search
    while searchStart <= searchCharCount do
        local foundAtThisStart = false
        for searchStop=searchCharCount, searchStart, -1 do
            local caseInsensitive = {}
            local upperCaseFirst = {}
            local spaceFirst = {}
            for i=searchStart,searchStop do
                local char = search:sub(i, i)
                local idx = i-searchStart+1
                caseInsensitive[idx] = '['..char:upper()..char:lower()..']'
                if idx==1 then
                    upperCaseFirst[idx] = char:upper()
                    spaceFirst[idx] = ' '..caseInsensitive[idx]
                else
                    upperCaseFirst[idx] = caseInsensitive[idx]
                    spaceFirst[idx] = caseInsensitive[idx]
                end
            end
            caseInsensitive = table.concat(caseInsensitive)
            upperCaseFirst = table.concat(upperCaseFirst)
            spaceFirst = table.concat(spaceFirst)
            local at = str:find(caseInsensitive, stringStart)
            local insensitiveAt = at
            local pieceScore = 0
            if at~=stringStart then
                pieceScore = 0.1
                at = str:find(upperCaseFirst, stringStart)
                if not at then
                    at = str:find(spaceFirst, stringStart)
                    if at then at = at + 1 end
                end
                if not at then
                    at = insensitiveAt
                    pieceScore = 0.25
                end
            end
            if at then
                local charsFound = searchStop-searchStart+1
                foundAtThisStart = true
                matches[#matches+1] = {first=at, last=at+charsFound-1}
                stringStart = at + charsFound
                searchStart = searchStart + charsFound
                score = score + pieceScore
                break
            end
        end
        if not foundAtThisStart then
            return 1/0
        end
    end
    if matches[2] or matches[1] and (matches[1].first>1 or matches[1].last<#str) then
        score = score + 0.05
    end
    return score, matches
end

function lib.uppercaseMatches(bits)
    local annotations = {}
    for i,bit in ipairs(bits) do
        annotations[i] = string[bit.match and 'upper' or 'lower'](bit.str)
    end
    return table.concat(annotations)
end

return lib