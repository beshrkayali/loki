import unittest, options
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
      if isSome(num1) and isSome(num2):
        echo("Result is ", parseInt(num1.get) + parseInt(num2.get))
      else:
        echo("Provide two numbers to add them")
    do_EOF:
      quit()

  let cmd = newLoki(cmdHandler)
