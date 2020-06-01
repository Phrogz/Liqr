local lib = {}

local function sortByScore(a, b) return a.score<b.score end
function lib.filter(strs, search)
    local results = {}
    for originalIndex,str in ipairs(strs) do
        local score, matches = lib.score(str, search)
        if score < 1/0 then
            results[#results+1] = {score=score, matches=matches, originalIndex=originalIndex, annotated=lib.annotatedString(str, matches)}
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
            bits[#bits+1] = {str=str:sub(start, piece.first-1), matched=false}
        end
        bits[#bits+1] = {str=str:sub(piece.first, piece.last), matched=true}
        start = piece.last + 1
    end
    if start<#str then
        bits[#bits+1] = {str=str:sub(start), matched=false}
    end
    return bits
end

function lib.score(str, search)
    local score = 0
    local stringStart, searchStart = 1, 1
    local matches = {}
    local done = false

    while not done do
        local foundAtThisStart = false
        for searchStop=#search,searchStart,-1 do
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
        done = searchStart > #search
    end

    return score, matches
end

function lib.asciiAnnotation(str, matches)
    local annotations = lib.annotatedString(str, matches)
    for i,bit in ipairs(annotations) do
        annotations[i] = string[bit.matched and 'upper' or 'lower'](bit.str)
    end
    return table.concat(annotations)
end

return lib