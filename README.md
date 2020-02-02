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
loki(myHandler, input):
  do_greet:
    write(stdout, "Hello!\n")
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
