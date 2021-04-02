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

loki(myHandler, input):
  do_greet name:
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

```sh
$ ./cmd 
Welcome to my CLI!

(loki) greet
Hello there!

(loki) greet Beshr
Hello Beshr!

(loki) add
Provide two numbers to add them

(loki) add 1 2
Result is 3
```

### How it works?

Loki uses the powerful macro system in Nim. Macros in Nim are functions that
execute at compile-time and can transform a syntax tree into a different one.

The `loki` macro block in the example above would expand into something like this: 

```nim
proc do_greet(input: Line; name: Option[string] = none(string)): bool =
  if isSome(name):
    echo(["Hello ", get(name), "!"])
  else:
    echo(["Hello there!"])

proc do_add(input: Line; num1: Option[string] = none(string);
            num2: Option[string] = none(string)): bool =
  if isSome(num1) and isSome(num2):
    echo(["Result is ", parseInt(get(num1)) + parseInt(get(num2))])
  else:
    echo(["Provide two numbers to add them"])

proc do_EOF(input: Line): bool =
  write(stdout, "Bye!\n")
  return true

proc default(input: Line): bool =
  write(stdout, ["*** Unknown syntax: ", input.text, " ***\n"])


proc myHandler(input: Line): bool =
  case input.command
  of "greet":
    if isSome(input.args):
      return do_greet(input, pick(input.args, 0))
    else:
      return do_greet(input, none(string))
  of "add":
    if isSome(input.args):
      return do_add(input, pick(input.args, 0), pick(input.args, 1))
    else:
      return do_add(input, none(string), none(string))
  of "EOF":
    if isSome(input.args):
      return do_EOF(input)
    else:
      return do_EOF(input)
  else:
    return default(input)
```

Tip: The expanded code above (of the `loki` macro) can be printed using
[`expandMacros`](https://nim-lang.org/docs/macros.html#expandMacros.m%2Ctyped )
which can be helpful when debugging your code to see what's going on.
