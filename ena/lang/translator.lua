local module = {
    kwords = {longForm = {}, shortForm = {}},
    values = {longForm = {}, shortForm = {}},
    err = {},
    alphabet = {},
    success = {}
}

-- alphabet --
module.alphabet = "აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ"

-- custom language keywords --
module.kwords.longForm.keyIf = "თუ"
module.kwords.shortForm.keyIf = "თუ"

module.kwords.longForm.keyElseIf = "თუარადა"
module.kwords.shortForm.keyElseIf = "თად"

module.kwords.longForm.keyElse = "თუარა"
module.kwords.shortForm.keyElse = "თარ"

module.kwords.longForm.keyReturn = "დააბრუნე"
module.kwords.shortForm.keyReturn = "დაბ"

module.kwords.longForm.keyWhile = "სანამ"
module.kwords.shortForm.keyWhile = "სნ"

module.kwords.longForm.keyPrint = "მაჩვენე"
module.kwords.shortForm.keyPrint = "მჩ"

module.kwords.longForm.keyNew = "ახალი"
module.kwords.shortForm.keyNew = "ახ"

module.kwords.longForm.keyFunction = "ფუნქცია"
module.kwords.shortForm.keyFunction = "ფუნ"

module.kwords.longForm.keyLocal = "ლოკალური"
module.kwords.shortForm.keyLocal = "ლოკ"

-- custom language boolean values --
module.values.longForm.valTrue = "ჭეშმარიტი"
module.values.shortForm.valTrue = "ჭეშ"

module.values.longForm.valFalse = "მცდარი"
module.values.shortForm.valFalse = "მც"

-- custom language nil values --
module.values.longForm.valNil = "ცარიელი"
module.values.shortForm.valNil = "ცარ"

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

return module
