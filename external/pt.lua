--
-- pt -- print table by Roberto Ierusalimschy
--

local function pt(x, id, visited)
    visited = visited or {}
    id = id or ""
    if type(x) == "string" then
        return "'" .. tostring(x) .. "'"
    elseif type(x) ~= "table" then
        return tostring(x)
    elseif visited[x] then
        return "..."
    else
        visited[x] = true
        local s = id .. "{\n"
        for k, v in pairs(x) do
            s = s .. id .. tostring(k) .. " = " .. pt(v, id .. "  ", visited) .. ";\n"
        end
        s = s .. id .. "}"
        return s
    end
end

return {pt = pt}
