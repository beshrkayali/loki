## A tiny interactive CLI built with loki.
##
## Run it:
##   nim r examples/greeter.nim
##
## Then try:  greet Ada / add 2 3 / shout hello / help / help greet
## Press Ctrl-D (or type EOF) to quit.
##
## Note: only `loki` and `strutils` are imported -- the Option helpers
## (isSome/get/...) come from loki itself.
import loki, strutils

loki(handler, line):
  do_greet name:
    ## greet someone by name (e.g. `greet Ada`)
    if isSome(name):
      echo "Hello ", name.get, "!"
    else:
      echo "Hello there!"

  do_add a, b:
    ## add two numbers (e.g. `add 2 3`)
    if isSome(a) and isSome(b):
      try:
        echo a.get, " + ", b.get, " = ", parseInt(a.get) + parseInt(b.get)
      except ValueError:
        echo "both arguments must be numbers"
    else:
      echo "usage: add <a> <b>"

  do_shout text:
    # undocumented on purpose: it won't show a description under `help`
    if isSome(text):
      echo text.get.toUpperAscii
    else:
      echo "shout what?"

  do_EOF:
    echo "Bye!"
    return true

  default:
    echo "*** unknown command: ", line.text

let cli = newLoki(
  handler = handler,
  intro = "loki demo — type `help`, or `help <command>`. Ctrl-D to quit.",
  prompt = "demo> ",
)

cli.cmdLoop
