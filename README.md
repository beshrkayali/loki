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
