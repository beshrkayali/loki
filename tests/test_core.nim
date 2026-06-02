import std/unittest

include "../src/loki.nim"

suite "newLoki":
  test "applies defaults":
    let l = newLoki(proc(line: Line): bool = false)
    check l.prompt == "(loki) "
    check l.intro == "\n" # "" & "\n"
    check l.lastcmd == ""
    check l.doc_header == "Documented commands (type help <topic>):"

  test "keeps a custom intro and prompt":
    let l = newLoki(proc(line: Line): bool = false, intro = "Welcome", prompt = "> ")
    check l.intro == "Welcome\n"
    check l.prompt == "> "

suite "newLine":
  test "takes the command from the first token and keeps the full text":
    check newLine("greet world foo").command == "greet"
    check newLine("greet world foo").text == "greet world foo"
    check newLine("solo").command == "solo"
    check newLine("").command == ""

var lastCalled: string

loki(testHandler, line):
  do_greet name:
    lastCalled = "greet"
  do_EOF:
    lastCalled = "eof"
    return true
  default:
    lastCalled = "default"

suite "oneCmd dispatch":
  test "routes a known command to its handler":
    let l = newLoki(testHandler)
    lastCalled = ""
    discard l.oneCmd("greet there")
    check lastCalled == "greet"

  test "routes an unknown command to default":
    let l = newLoki(testHandler)
    lastCalled = ""
    discard l.oneCmd("nope")
    check lastCalled == "default"

  test "EOF handler can stop the loop":
    let l = newLoki(testHandler)
    check l.oneCmd("EOF") == true

  test "an empty line repeats the last command":
    let l = newLoki(testHandler)
    discard l.oneCmd("greet there")
    lastCalled = ""
    discard l.oneCmd("") # repeats "greet there"
    check lastCalled == "greet"

  test "an empty line with no history runs the empty command":
    let l = newLoki(testHandler)
    lastCalled = ""
    discard l.oneCmd("") # lastcmd is "" -> no repeat -> falls to default
    check lastCalled == "default"
