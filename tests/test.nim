import unittest, options
from sequtils import zip
import strutils
import loki

test "loki macro generates valid code":
  loki(cmdHandler, line):
    do_greet name:
      if isSome(name):
        echo("Hello ", name.get, "!")
      else:
        echo("Hello!")
    do_add num1, num2:
      ## Does addition
      if isSome(num1) and isSome(num2):
        echo("Result is ", parseInt(num1.get) + parseInt(num2.get))
      else:
        echo("Provide two numbers to add them")
    do_EOF:
      quit()

  let cmd = newLoki(cmdHandler)

test "loki macro genereted code shouldnt fail with less args":
  loki(shouldNotFailHandler, line):
    do_add num0, num1, num2:
      assert(num0.isSome)
      assert(num1.isNone)
      assert(num2.isNone)
  let cmd = newLoki(shouldNotFailHandler)
  let line = Line(
    command: "add",
    args: some(@["0"]),
    text: "add 0"
  )
  discard shouldNotFailHandler(line)
