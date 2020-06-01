local lib = {}

local function sortByScore(a, b) return a.score<b.score end
function lib.filter(strs, search)
    local results = {}
    for _,str in ipairs(strs) do
        local score, pieces = lib.score(str, search)
        if score then
            results[#results+1] = {score=score, pieces=pieces}
        end
    end
    table.sort(results, sortByScore)
    return results
end

function lib.score(str, search)
    local score = 0
    local start = 1
    local pieces = {}
    for char in search:gmatch('.') do
        local anycase = '['..char:lower()..char:upper()..']'
        local at = str:find(anycase, start)
        if at~=start then
            at = str:find(char:upper(), start)
            if not at then
                at = str:find(' '..anycase, start-1)
                if at then at = at + 1 end
            end
            if not at then
                at = str:find(anycase, start)
            end
        end
        if not at then return 1/0 end
        local literal = str:sub(at,at)
        score = score + (at - start)^2
        if at==start and pieces[#pieces] then
            pieces[#pieces].last = at
        else
            pieces[#pieces+1] = {first=at, last=at}
        end
        start = at + 1
    end
    return score, pieces
end

return lib