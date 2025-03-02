# Markdown Guide

This comprehensive guide will help you master Markdown syntax for creating well-formatted documentation. Each section includes both the Markdown syntax and its rendered output.

## Basic Syntax

### 1. Headings

Markdown provides six levels of headings, using `#` symbols:

```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

The rendered output looks like this:

# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

### 2. Text Formatting

#### Bold Text
```markdown
**Bold text** or __Bold text__
```
**Bold text** or __Bold text__

#### Italic Text
```markdown
*Italic text* or _Italic text_
```
*Italic text* or _Italic text_

#### Bold and Italic
```markdown
***Bold and italic*** or ___Bold and italic___
```
***Bold and italic*** or ___Bold and italic___

#### Strikethrough
```markdown
~~Strikethrough text~~
```
~~Strikethrough text~~

### 3. Lists

#### Unordered Lists
```markdown
- First item
- Second item
    - Indented item
    - Another indented item
- Third item
```

- First item
- Second item
    - Indented item
    - Another indented item
- Third item

#### Ordered Lists
```markdown
1. First item
2. Second item
    1. Indented item
    2. Another indented item
3. Third item
```

1. First item
2. Second item
    1. Indented item
    2. Another indented item
3. Third item

### 4. Links

#### Basic Links
```markdown
[Visit GitHub](https://github.com)
```
[Visit GitHub](https://github.com)

#### Links with Titles
```markdown
[GitHub](https://github.com "GitHub's Homepage")
```
[GitHub](https://github.com "GitHub's Homepage")

#### Reference-style Links
```markdown
[GitHub][1]
[DevOps][2]

[1]: https://github.com
[2]: https://en.wikipedia.org/wiki/DevOps
```

[GitHub][1]
[DevOps][2]

[1]: https://github.com
[2]: https://en.wikipedia.org/wiki/DevOps

### 5. Images

#### Basic Image
```markdown
![Alt text](https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png)
```

#### Image with Title
```markdown
![GitHub Logo](https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png "GitHub Logo")
```

### 6. Code

#### Inline Code
```markdown
Use `git status` to list all changed files.
```
Use `git status` to list all changed files.

#### Code Blocks
````markdown
```python
def hello_world():
    print("Hello, World!")
```
````

```python
def hello_world():
    print("Hello, World!")
```

#### Syntax Highlighting
````markdown
```javascript
function greet(name) {
    console.log(`Hello, ${name}!`);
}
```
````

```javascript
function greet(name) {
    console.log(`Hello, ${name}!`);
}
```

### 7. Tables

```markdown
| Left-aligned | Center-aligned | Right-aligned |
|:-------------|:-------------:|-------------:|
| Content      | Content       | Content      |
| Left         | Center        | Right        |
```

| Left-aligned | Center-aligned | Right-aligned |
|:-------------|:-------------:|-------------:|
| Content      | Content       | Content      |
| Left         | Center        | Right        |

### 8. Blockquotes

#### Simple Blockquote
```markdown
> This is a blockquote
```

> This is a blockquote

#### Nested Blockquotes
```markdown
> First level
>> Second level
>>> Third level
```

> First level
>> Second level
>>> Third level

### 9. Task Lists

```markdown
- [x] Completed task
- [ ] Incomplete task
    - [x] Completed subtask
    - [ ] Incomplete subtask
```

- [x] Completed task
- [ ] Incomplete task
    - [x] Completed subtask
    - [ ] Incomplete subtask

### 10. Horizontal Rules

Any of these will create a horizontal rule:
```markdown
---
***
___
```

---

### 11. Escaping Characters

Use backslash to escape special characters:
```markdown
\* Not italic \*
\` Not code \`
\[ Not a link \]
```

\* Not italic \*
\` Not code \`
\[ Not a link \]

### 12. Extended Syntax (with Material for MkDocs)

#### Highlighting Text
```markdown
==Highlighted text==
```
==Highlighted text==

#### Footnotes
```markdown
Here's a sentence with a footnote[^1].

[^1]: This is the footnote.
```

Here's a sentence with a footnote[^1].

[^1]: This is the footnote.

#### Definition Lists
```markdown
term
: definition
```

term
: definition

#### Emoji
```markdown
:smile: :heart: :thumbsup:
```
:smile: :heart: :thumbsup:

## Best Practices

1. **Consistency**: Use consistent formatting throughout your document
2. **Spacing**: Add blank lines before and after headings
3. **Headers**: Use proper header hierarchy (don't skip levels)
4. **Lists**: Keep them simple and nested no more than three levels
5. **Code Blocks**: Always specify the language for syntax highlighting
6. **Links**: Use descriptive text rather than "click here"
7. **Images**: Always include alt text for accessibility

## Common Pitfalls to Avoid

1. Forgetting to add two spaces for line breaks
2. Incorrect nesting of lists
3. Missing blank lines before and after lists and code blocks
4. Improper escaping of special characters
5. Inconsistent heading hierarchy

## Tools and Resources

1. **Markdown Editors**:
    - Visual Studio Code with Markdown extensions
    - Typora
    - StackEdit (web-based)

2. **Online Validators**:
    - [MarkdownLint](https://dlaa.me/markdownlint/)
    - [Dillinger](https://dillinger.io/)

3. **Cheat Sheets**:
    - [GitHub Markdown Guide](https://guides.github.com/features/mastering-markdown/)
    - [Markdown Guide](https://www.markdownguide.org/)
