function faqtoriali(n)
    n = n or 6
    if n ~= 0 then
        return n * faqtoriali(n - 1)
    else
        return 1
    end
end
function main()
    return faqtoriali()
end

main()