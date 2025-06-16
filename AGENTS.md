# AGENTS.md

## Coding Guidelines for Codex Agents

This document defines the minimum coding standards for implementing Agents in the Codex project.

### 1. Follow SwiftLint rules

All Swift code must comply with the SwiftLint rules defined in the project.

### 2. Avoid abbreviated variable names

Do not use unclear abbreviations such as `res`, `img`, or `btn`.  
Use descriptive and explicit names like `result`, `image`, or `button`.

### 3. Use `.init(...)` when the return type is explicitly known

In contexts where the return type is clear (e.g., function return values, computed properties), use `.init(...)` for initialization.

#### Examples

```swift
var user: User {
  .init(name: "Alice") // ✅ OK: return type is explicitly User
}

func makeUser() -> User {
  .init(name: "Bob") // ✅ OK
}

let user = User(name: "Carol") // ❌ Less preferred when type is not obvious
```

### 4. Follow markdownlint rules for Markdown files

All Markdown documents must conform to the rules defined at:  
https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md
