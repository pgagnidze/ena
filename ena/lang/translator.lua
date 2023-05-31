local module = {
    kwords = {longForm = {}, shortForm = {}},
    values = {longForm = {}, shortForm = {}},
    err = {},
    alphabet = {},
    success = {},
    toeng = {}
}

-- alphabet --
module.alphabet = "აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ"

-- custom language keywords --
module.kwords.longForm.keyIf = "თუ პირობა სრულდება"
module.kwords.shortForm.keyIf = "თუ"

module.kwords.longForm.keyElseIf = "სხვა შემთხვევაში შეამოწმე თუ"
module.kwords.shortForm.keyElseIf = "თუარადა"

module.kwords.longForm.keyElse = "სხვა შემთხვევაში"
module.kwords.shortForm.keyElse = "თუარა"

module.kwords.longForm.keyReturn = "დააბრუნე მნიშვნელობა"
module.kwords.shortForm.keyReturn = "დააბრუნე"

module.kwords.longForm.keyWhile = "სანამ პირობა სრულდება გაიმეორე"
module.kwords.shortForm.keyWhile = "სანამ"

module.kwords.longForm.keyPrint = "მაჩვენე მნიშვნელობა ეკრანზე"
module.kwords.shortForm.keyPrint = "მაჩვენე"

module.kwords.longForm.keyExec = "გაუშვი ბრძანება"
module.kwords.shortForm.keyExec = "ბრძანება"

module.kwords.longForm.keyNew = "ახალი"
module.kwords.shortForm.keyNew = "ახალი"

module.kwords.longForm.keyFunction = "ფუნქცია სახელად"
module.kwords.shortForm.keyFunction = "ფუნქცია"

module.kwords.longForm.keyLocal = "ლოკალური ცვლადი"
module.kwords.shortForm.keyLocal = "ლოკალური"

-- custom language boolean values --
module.values.longForm.valTrue = "ჭეშმარიტი მნიშვნელობა"
module.values.shortForm.valTrue = "ჭეშმარიტი"

module.values.longForm.valFalse = "მცდარი მნიშვნელობა"
module.values.shortForm.valFalse = "მცდარი"

-- custom language nil values --
module.values.longForm.valNil = "ცარიელი მნიშვნელობა"
module.values.shortForm.valNil = "ცარიელი"

-- error messages --
module.err.unknownArg = "უცნობი არგუმენტი"
module.err.noInputFile = "ფაილი ვერ მოიძებნა"
module.err.fileOpen = "ფაილი ვერ გაიხსნა"
module.err.codeError = "კოდი ვერ დაგენერირდა"
module.err.syntaxErrAfterLine = "სინტაქსური შეცდომა ამ ხაზის შემდეგ"
module.err.syntaxErrAtLine = "სინტაქსური შეცდომა ამ ხაზზე"

module.err.compileErrUndefinedVariable = "ცვლადი არაა განსაზღვრული"
module.err.compileErrUndefinedFunction = "ფუნქცია არაა განსაზღვრული"
module.err.compileErrWrongNumberOfArguments = "არასწორი არგუმენტების რაოდენობა ფუნქციისთვის"
module.err.compileErrVariableSameNameAsFunction = "ცვლადს აქვს იგივე სახელი რაც ფუნქციას"
module.err.compileErrVariableAlreadyDefined = "ცვლადი უკვე განსაზღვრულია"
module.err.compileErrDuplicateFunctionName = "ფუნქცია უკვე განსაზღვრულია"
module.err.compileErrDuplicateParamName = "პარამეტრის სახელი უკვე განსაზღვრულია"
module.err.compileErrNoEntryPointFound = "არ მოიძებნა მთავარი ფუნქცია"
module.err.compileErrEntryPointParams = "მთავარ ფუნქციას არ უნდა ჰქონდეს პარამეტრები"

module.err.runtimeErrOutOfRangeFirst = "მასივის ინდექსი რეინჯის გარეთაა. მასივის ზომაა"
module.err.runtimeErrOutOfRangeSecond = "მაგრამ მოვითხოვეთ"

-- success messages --
module.success.showAST = "აბსტრაქტული სინტაქსის ხე"
module.success.showCode = "დაგენერირებული კოდი"
module.success.showTrace = "ტრეისის ჩვენება"
module.success.showResult = "შედეგი"
module.success.showTranspile = "ტრანსპილირებული კოდი"

-- to english --
module.toeng = {
    ["ა"] = "a",
    ["ბ"] = "b",
    ["გ"] = "g",
    ["დ"] = "d",
    ["ე"] = "e",
    ["ვ"] = "v",
    ["ზ"] = "z",
    ["თ"] = "th",
    ["ი"] = "i",
    ["კ"] = "k",
    ["ლ"] = "l",
    ["მ"] = "m",
    ["ნ"] = "n",
    ["ო"] = "o",
    ["პ"] = "p",
    ["ჟ"] = "zh",
    ["რ"] = "r",
    ["ს"] = "s",
    ["ტ"] = "t",
    ["უ"] = "u",
    ["ფ"] = "f",
    ["ქ"] = "q",
    ["ღ"] = "gh",
    ["ყ"] = "qh",
    ["შ"] = "sh",
    ["ჩ"] = "ch",
    ["ც"] = "ts",
    ["ძ"] = "dz",
    ["წ"] = "ts",
    ["ჭ"] = "tch",
    ["ხ"] = "kh",
    ["ჯ"] = "j",
    ["ჰ"] = "h"
}

return module
