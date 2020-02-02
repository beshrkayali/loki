Loki
----

**loki**: line oriented (k)ommand interpreter

Loki is a small library for # writing line-oriented
command interpreters (or cli programs) that is inspired
by Python's cmdlib.

Example
=======

```nim
loki(myHandler, input):
  do_greet:
    write(stdout, "Hello!\n")
  do_EOF:
    write(stdout, "Bye!\n")
    return false
  default:
    write(stdout, "*** Unknown syntax: ", input.text , " ***\n")

let myCmd = newLoki(
  handler=myHandler,
  intro="Welcome to my CLI!\n",
)

myCmd.cmdLoop
```
