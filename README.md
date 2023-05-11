# ენა - Ena
ქართული პროგრამული ენა

## მაგალითი

```ena
ფუნქცია ფაქტორიალი(ნ = 6) {
    თუ ნ != 0 {
        დააბრუნე ნ * ფაქტორიალი(ნ - 1)
    } თუარა {
        დააბრუნე 1
    }
}

ფუნქცია main() {
    დააბრუნე ფაქტორიალი()
}
```

## Todo
- transpiler to Lua (optionally, Python and JS)
- (optional) pass over the entire AST and find all functions before translating anything
- (optional) string literals

## ♥
- Final project for the Building a Programming Language course by Roberto Ierusalimschy
- Based on the Mab programming language by Mark W. Gabby-Li
