Loki
----
[![](https://github.com/beshrkayali/loki/workflows/CI/badge.svg)](https://github.com/beshrkayali/loki/actions?query=workflow%3ACI)


**loki**: line oriented (k)ommand interpreter

Loki is a small library for writing line-oriented
command interpreters (or cli programs) in Nim, that is inspired
by Python's cmd lib.

Example
=======

```nim
import loki, strutils # `options` helpers (isSome/get/...) come from loki

loki(myHandler, input):
  do_greet name:
   ## Get a nice greeting!
   if isSome(name):
    echo("Hello ", name.get, "!")
   else:
    echo("Hello there!")
  do_add num1, num2:
    if isSome(num1) and isSome(num2):
      echo("Result is ", parseInt(num1.get) + parseInt(num2.get))
    else:
      echo("Provide two numbers to add them")
  do_EOF:
    write(stdout, "Bye!\n")
    return true
  default:
    write(stdout, "*** Unknown syntax: ", input.text , " ***\n")

let myCmd = newLoki(
  handler=myHandler,
  intro="Welcome to my CLI!\n",
)

myCmd.cmdLoop
```

Compile with something like:

```sh
nim c cmd.nim
```

And an example run:

[![asciicast](https://asciinema.org/a/iMA7pIq2f7sy8X44pkCPhNmOt.svg)](https://asciinema.org/a/iMA7pIq2f7sy8X44pkCPhNmOt)

A runnable version lives in [`examples/greeter.nim`](examples/greeter.nim):

```sh
nim r examples/greeter.nim
```

A session looks like this (commands typed at the `demo>` prompt):

```text
loki demo — type `help`, or `help <command>`. Ctrl-D to quit.
demo> greet Ada
Hello Ada!
demo> add 2 3
2 + 3 = 5
demo> shout hello
HELLO
demo> bogus cmd
*** unknown command: bogus cmd
demo> help

Documented commands (type help <topic>):
========================================
greet 	 add

Undocumented commands:
======================
shout
demo> help greet
greet someone by name (e.g. `greet Ada`)
demo> ^D
Bye!
```


### How it works?

Loki uses the powerful macro system in Nim. Macros in Nim are functions that
execute at compile-time and can transform a syntax tree into a different one.

The `loki` macro block in the example above would expand into something like this:

```nim
proc do_greet(line: Line; name: Option[string] = none(string)): bool =
  ## Get a nice greeting!
  if isSome(name):
    echo("Hello ", get(name), "!")
  else:
    echo("Hello there!")

proc do_add(line: Line; num1: Option[string] = none(string);
            num2: Option[string] = none(string)): bool =
  if isSome(num1) and isSome(num2):
    echo("Result is ", parseInt(get(num1)) + parseInt(get(num2)))
  else:
    echo("Provide two numbers to add them")

proc do_EOF(line: Line): bool =
  write(stdout, "Bye!\n")
  return true

proc default(line: Line): bool =
  write(stdout, "*** Unknown syntax: ", line.text, " ***\n")

# Auto-generated. The command lists and docs are known at compile time, so they
# are baked in as literals -- the generated code needs no extra imports.
proc help(input: Line): bool =
  if isSome(input.args):
    let cmdarg = pick(input.args, 0)
    if isSome(cmdarg):
      let cmd = get(cmdarg)
      let docced = @["greet"]
      let docs = @["Get a nice greeting!"]
      let undocced = @["add"]
      if cmd in undocced:
        writeLine(stdout, "*** No help for this command")
      else:
        for i in 0 ..< docced.len:
          if cmd == docced[i]:
            writeLine(stdout, docs[i])
            break
      return
  write(stdout, "\nDocumented commands (type help <topic>):\n")
  write(stdout, "========================================\n")
  write(stdout, "greet")
  write(stdout, "\n\nUndocumented commands:\n")
  write(stdout, "======================\n")
  write(stdout, "add")
  write(stdout, "\n")

proc myHandler(line: Line): bool =
  case line.command
  of "greet":
    if isSome(line.args):
      return do_greet(line, pick(line.args, 0))
    else:
      return do_greet(line, none(string))
  of "add":
    if isSome(line.args):
      return do_add(line, pick(line.args, 0), pick(line.args, 1))
    else:
      return do_add(line, none(string), none(string))
  of "EOF":
    return do_EOF(line)
  of "help":
    return help(line)
  else:
    return default(line)
```

Tip: The expanded code above (of the `loki` macro) can be printed using
[`expandMacros`](https://nim-lang.org/docs/macros.html#expandMacros.m%2Ctyped )
which can be helpful when debugging your code to see what's going on.


### Changelog

### [Unreleased]
- Remove deprecated `threadpool`; `cmdLoop` is now a plain blocking loop
  (fixes a busy-wait that spun the CPU while idle)
- No longer requires `--threads:on`
- `cmdLoop` no longer takes an unused `intro` argument (use `newLoki(intro=...)`)
- Hygienic macro: `import loki` is enough — it re-exports the Option helpers,
  and generated code no longer needs `sequtils`/`strutils` in scope
- `help <command>` output now ends with a newline
- Add `examples/greeter.nim`

### [0.3.0] Apr 2021
- Automatically generate TOC and help for handler commands

### [0.2.1] Jun 2020
- Fix for handling extra args (thanks @hugosenari)

### [0.1.1] Feb 2020
- Run tests on GH actions
- Minor docs

### [0.1.0] Feb 2020
- Initial release
