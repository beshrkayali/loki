import unittest, options

import loki

test "loki macro generates valid code":
  loki(cmdHandler, line):
    do_greet name:
      if isSome(line.args):
        echo("Hello ", line.args.get[0], "!")
      else:
        echo("Hello!")
    do_EOF:
      quit()

  let cmd = newLoki(cmdHandler)
