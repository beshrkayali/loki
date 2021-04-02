Loki
----
[![](https://github.com/beshrkayali/loki/workflows/CI/badge.svg)](https://github.com/beshrkayali/loki/actions?query=workflow%3AC)


**loki**: line oriented (k)ommand interpreter

Loki is a small library for writing line-oriented
command interpreters (or cli programs) in Nim, that is inspired
by Python's cmd lib.

Example
=======

```nim
import loki, strutils, options
from sequtils import zip

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
nim c --threads:on cmd.nim
```

And an example run:

[![asciicast](https://asciinema.org/a/iMA7pIq2f7sy8X44pkCPhNmOt.svg)](https://asciinema.org/a/iMA7pIq2f7sy8X44pkCPhNmOt)


### How it works?

Loki uses the powerful macro system in Nim. Macros in Nim are functions that
execute at compile-time and can transform a syntax tree into a different one.

The `loki` macro block in the example above would expand into something like this: 

```nim
proc do_greet(line: Line; name: Option[string] = none(string)): bool =
  ## Get a nice greeting!
  if isSome(name):
    echo(["Hello ", get(name), "!"])
  else:
    echo(["Hello!"])
  
proc do_add(line: Line; num1: Option[string] = none(string);
            num2: Option[string] = none(string)): bool =
  if isSome(num1) and isSome(num2):
    echo(["Result is ", parseInt(get(num1)) + parseInt(get(num2))])
  else:
    echo(["Provide two numbers to add them"])

proc do_EOF(line: Line): bool =
  write(stdout, "Bye!\n")
  return true

proc default(line: Line): bool =
  write(stdout, ["*** Unknown syntax: ", line.text, " ***\n"])

proc help(input: Line): bool =
  var undocced: seq[string] = @["add"]
  var docced: seq[string] = @["greet"]
  var docs = @["d1", "d2"]
  if isSome(input.args):
    var cmdarg = pick(input.args, 0)
    if isSome(cmdarg):
      var cmd = get(cmdarg)
      if contains(undocced, cmd):
        write(stdout, "*** No help on for this")
      else:
        for pair in items(zip(docced, docs)):
          let (docced_cmd, doc) = pair
          if cmd == docced_cmd:
            write(stdout, doc)
            break
      return
  write(stdout, "\nDocumented commands (type help <topic>):\n")
  write(stdout, "========================================\n")
  write(stdout, join(docced, " \t "))
  write(stdout, "\n\nUndocumented commands:\n")
  write(stdout, "======================\n")
  write(stdout, join(undocced, " \t "))
  write(stdout, "\n")

proc cmdHandler(line: Line): bool =
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
    if isSome(line.args):
      return do_EOF(line)
    else:
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

### [0.2.1] Jun 2020
- Fix for handling extra args (thanks @hugosenari)

### [0.1.1] Feb 2020
- Run tests on GH actions
- Minor docs

### [0.1.0] Feb 2020
- Initial release
