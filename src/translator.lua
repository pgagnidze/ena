local module = {kwords = {longForm = {}, shortForm = {}}, err = {}, alphabet = {}, success = {}}

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

-- error messages --
module.err.unknownArg = "უცნობი არგუმენტი"
module.err.noInputFile = "ფაილი ვერ მოიძებნა"
module.err.fileOpen = "ფაილი ვერ გაიხსნა"
module.err.syntaxErrAfterLine = "სინტაქსური შეცდომა ამ ხაზის შემდეგ"
module.err.syntaxErrAtLine = "სინტაქსური შეცდომა ამ ხაზზე"
module.err.compileErrUndefinedVariable = "ცვლადი არაა განსაზღვრული"
module.err.runtimeErrOutOfRangeFirst = "მასივის ინდექსი რეინჯის გარეთაა. მასივის ზომაა"
module.err.runtimeErrOutOfRangeSecond = "მაგრამ მოვითხოვეთ"
module.err.codeError = "კოდი ვერ დაგენერირდა"

-- success messages --
module.success.showAST = "აბსტრაქტული სინტაქსის ხე"
module.success.showCode = "დაგენერირებული კოდი"
module.success.showTrace = "ტრეისის ჩვენება"
module.success.showResult = "შედეგი"

return module
