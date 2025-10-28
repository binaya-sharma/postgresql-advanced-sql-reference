# PostgreSQL Escape Sequences

## Overview

Escape sequences in PostgreSQL are special character combinations used inside string literals to represent non-printable characters, quotes, backslashes, or formatted text. They are particularly useful when dealing with file paths, JSON, Unicode, or procedural code.

By default, PostgreSQL treats backslashes (`\\`) as literal characters unless **escape string syntax** is used. To enable escape sequences, prefix a string with **E**.

---

## 1. Standard vs Escape Strings

### Standard string (default behavior)

```sql
SELECT 'C:\Users\Binaya';  -- Backslash is treated literally.
```

### Escape string (prefix with E)

```sql
SELECT E'C:\\Users\\Binaya';  -- Interprets \\ as a single backslash.
```

---

## 2. Common Escape Sequences

| Escape Sequence | Meaning         | Example            | Output                 |
| --------------- | --------------- | ------------------ | ---------------------- |
| `\\b`           | Backspace       | `E'abc\\b'`        | ab                    |
| `\\f`           | Form feed       | `E'page1\\fpage2'` | page1 (formfeed) page2 |
| `\\n`           | Newline         | `E'line1\\nline2'` | line1<br>line2         |
| `\\r`           | Carriage return | `E'hello\\rworld'` | world                  |
| `\\t`           | Tab             | `E'col1\\tcol2'`   | col1    col2           |
| `\\v`           | Vertical tab    | `E'hi\\vthere'`    | hi↕there               |
| `\\'`           | Single quote    | `E'It\\'s OK'`     | It's OK                |
| `\\\\`          | Backslash       | `E'C:\\\\path'`    | C:\path                |
| `\\0xx`         | Octal ASCII     | `E'\\072'`         | `:`                    |
| `\\uXXXX`       | 4-digit Unicode | `E'\\u20AC'`       | €                      |
| `\\UXXXXXXXX`   | 8-digit Unicode | `E'\\U0001F600'`   | 😀                     |

---

## 3. Single Quotes Handling

PostgreSQL uses single quotes to delimit text. To include a quote inside a string:

### Option 1 — Double it

```sql
SELECT 'It''s a good day';
```

### Option 2 — Use escape string

```sql
SELECT E'It\'s a good day';
```

Both return:

```
It's a good day
```

---

## 4. Unicode Escapes

You can insert Unicode characters directly using `U&'string'` syntax:

```sql
SELECT U&'Nepal: \\0928\\0947\\092A\\093E\\0932';
```

You can define your own escape character:

```sql
SELECT U&'Snowman: !2603' UESCAPE '!';
```

---

## 5. Dollar-Quoted Strings

Dollar-quoting removes the need for escapes entirely. It’s ideal for functions or long text blocks.

```sql
DO $$
BEGIN
    RAISE NOTICE 'No escaping needed here: It''s $ sign safe.';
END;
$$;
```

Custom tags can also be used:

```sql
$HTML$
<h1>Hello World</h1>
$HTML$
```

---

## 6. Practical Examples

### File Path

```sql
INSERT INTO logs(path) VALUES (E'C:\\Program Files\\Postgres\\logs.txt');
```

### Multi-line String

```sql
SELECT E'Hello\\nWorld\\nPostgreSQL';
```

### JSON Escaping

```sql
SELECT E'{\\"name\\": \\"Binaya\\", \\"role\\": \\"Data Engineer\\"}';
```

### Unicode Symbols

```sql
SELECT E'Unicode test: \\u2600 \\u2601 \\u2602';  -- ☀ ☁ ☂
```

---

## 7. Key Points

* Since PostgreSQL 9.1, **standard_conforming_strings = on** by default.
* Use **E''** when escape sequences are required.
* Prefer **dollar quoting** for readability in procedures.
* Escape sequences can also appear in regular expressions and LIKE patterns.

---

## 8. Summary

| Method          | Example       | Notes                               |
| --------------- | ------------- | ----------------------------------- |
| Standard String | `'C:\data'`   | Backslash is literal                |
| Escape String   | `E'C:\\data'` | Allows special escapes              |
| Dollar Quoting  | `$$ text $$`  | Best for long or multi-line strings |
| Unicode Escape  | `U&'\\0928'`  | Supports Unicode characters         |

---

**End of Document – PostgreSQL Escape Sequence Reference**
