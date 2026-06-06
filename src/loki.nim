# Copyright (c) 2020 Beshr Kayali

# This software is provided 'as-is', without any express or implied
# warranty. In no event will the authors be held liable for any damages
# arising from the use of this software.

# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:

# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.

## **loki**: line oriented (k)ommand interpreter
##
## Loki is a small library for writing line-oriented
## command interpreters (or cli programs) that is inspired
## by Python's cmd lib.
##
## Example:
## --------
##
## ```nim
## import loki
##
## loki(myHandler, input):
##   do_greet name:
##     if isSome(name):
##       write(stdout, "Hello " & get(name) & "!")
##     else:
##       write(stdout, "Hey you!\n")
##   do_EOF:
##     write(stdout, "Bye!\n")
##     return true
##   default:
##     write(stdout, "*** Unknown syntax: ", input.text , " ***\n")
##
## let myCmd = newLoki(
##   handler=myHandler,
##   intro="Welcome to my CLI!\n",
## )
##
## myCmd.cmdLoop
## ```

import std/[macros, rdstdin, options, strutils]

# loki's public API is Option-based (Line.args, pick, handler params), so the
# Option helpers are re-exported: `import loki` is enough to work with them.
export options

const PROMPT = "(loki) "

type Line* = ref object
  command*: string
  args*: Option[seq[string]]
  text*: string

proc pick*[T](items: Option[seq[T]], idx: int): Option[T] =
  items.flatMap(
    proc(values: seq[T]): Option[T] =
      if idx < values.len:
        return some(values[idx])
  )

proc newLine(line_text: string): Line =
  let parts = line_text.splitWhitespace()
  let command =
    if parts.len > 0:
      parts[0]
    else:
      ""

  var args: Option[seq[string]]

  if parts.len > 1:
    args = some(parts[1 .. ^1])
  else:
    args = none(seq[string])

  Line(command: command, args: args, text: line_text)

proc `$`*(line: Line): string =
  if isSome(line.args):
    "Command: " & $line.command & " - Args: " & get(line.args).join(", ")
  else:
    "Command: " & $line.command

type Loki* = ref object
  prompt*: string
  lastcmd*: string
  intro*: string
  handler: proc(line: Line): bool

proc newLoki*(
    handler: proc(line: Line): bool, intro: string = "", prompt: string = PROMPT
): Loki =
  Loki(prompt: prompt, lastcmd: "", intro: intro & "\n", handler: handler)

# proc printTopics(loki: Loki) =
#   ## TODO
#   discard

# proc columnize(loki: Loki) =
#   ## TODO
#   discard

proc input(loki: Loki): string =
  try:
    readLineFromStdin(loki.prompt)
  except IOError: # Linenoise returns nil (and raises IOError) on EOF
    "EOF"

proc oneCmd(loki: Loki, line_text: string): bool =
  ## Interprets line_text as though it had been typed in response
  ## to the prompt.

  ## The return value is a flag indicating whether interpretation of
  ## commands by the interpreter should stop.

  if line_text == "" and loki.lastcmd != "":
    return loki.oneCmd(line_text = loki.lastcmd)

  loki.lastcmd = line_text

  return loki.handler(newLine(line_text))

proc cmdLoop*(loki: Loki) =
  write(stdout, loki.intro)

  var stop = false

  while not stop:
    # precmd / postcmd hooks would go here
    stop = loki.oneCmd(loki.input())

# Macros
# ======

proc createHandlerProcDef(
    ident: NimNode, lineVar: NimNode, statements: seq[NimNode]
): NimNode =
  result = newTree(
    nnkProcDef,
    newIdentNode(repr ident),
    newEmptyNode(),
    newEmptyNode(),
    newTree(
      nnkFormalParams,
      newIdentNode("bool"),
      newTree(
        nnkIdentDefs, newIdentNode(repr lineVar), newIdentNode("Line"), newEmptyNode()
      ),
    ),
    newEmptyNode(),
    newEmptyNode(),
    newStmtList(statements),
  )

proc strSeqLit(items: seq[string]): NimNode =
  ## Build a `@["a", "b", ...]` seq literal node from a seq of strings.
  result = nnkPrefix.newTree(ident"@", nnkBracket.newTree())
  for s in items:
    result[1].add newLit(s)

proc createdProcDefs(lineVar: NimNode, stmtList: NimNode): seq[NimNode] =
  expectKind(stmtList, nnkStmtList)

  result = @[]

  var undocced: seq[string]
  var docced: seq[string]
  var docs: seq[string]

  for child in stmtList:
    expectKind(child, {nnkCall, nnkCommand})

    let procName = repr child[0]
    let providedStmtList = child[child.len - 1]

    let cmd = replace(procName, "do_", "")

    case kind providedStmtList[0]
    of NimNodeKind.nnkCommentStmt:
      docced.add cmd
      docs.add strip replace(repr providedStmtList[0], "##", "")
    else:
      if count(cmd, "EOF") == 0 and count(cmd, "default") == 0:
        undocced.add cmd

    let args = child[1 .. child.len - 2]

    var identDefsStmtList = newSeq[NimNode]()

    identDefsStmtList.add(newIdentNode("bool"))

    identDefsStmtList.add(
      newTree(
        nnkIdentDefs, newIdentNode(repr lineVar), newIdentNode("Line"), newEmptyNode()
      )
    )

    for arg in args:
      identDefsStmtList.add(
        newIdentDefs(
          newIdentNode(repr arg),
          kind = newTree(nnkBracketExpr, newIdentNode("Option"), newIdentNode("string")),
          default = newCall(newIdentNode("none"), newIdentNode("string")),
        )
      )

    result.add(
      newTree(
        nnkProcDef,
        newIdentNode(procName),
        newEmptyNode(),
        newEmptyNode(),
        newTree(nnkFormalParams, identDefsStmtList),
        newEmptyNode(),
        newEmptyNode(),
        newStmtList(providedStmtList),
      )
    )

  # Generated help / table-of-contents proc. Everything it needs is known at
  # macro time: the command lists are baked in as literals and the table-of-
  # contents lines are pre-joined, so the generated proc pulls in no extra deps
  # (no zip/join) -- only the Option helpers re-exported above.
  let doccedLit = strSeqLit(docced)
  let docsLit = strSeqLit(docs)
  let undoccedLit = strSeqLit(undocced)
  let doccedToc = newLit(docced.join(" \t "))
  let undoccedToc = newLit(undocced.join(" \t "))

  result.add(
    quote do:
      proc help(input: Line): bool =
        if isSome(input.args):
          let cmdarg = pick(input.args, 0)
          if isSome(cmdarg):
            let cmd = cmdarg.get
            let docced: seq[string] = `doccedLit`
            let docs: seq[string] = `docsLit`
            let undocced: seq[string] = `undoccedLit`
            if cmd in undocced:
              writeLine(stdout, "*** No help for this command")
            else:
              for i in 0 ..< docced.len:
                if cmd == docced[i]:
                  writeLine(stdout, docs[i])
                  break
            return
        write(stdout, "\nDocumented commands (type help <topic>):\n")
        write(stdout, "========================================\n")
        write(stdout, `doccedToc`)
        write(stdout, "\n\nUndocumented commands:\n")
        write(stdout, "======================\n")
        write(stdout, `undoccedToc`)
        write(stdout, "\n")

  )

proc createHandlerCommandStatements(stmtList: NimNode, lineVar: NimNode): seq[NimNode] =
  expectKind(stmtList, nnkStmtList)

  result = @[]

  var cases = newSeq[NimNode]()

  cases.add(newDotExpr(newIdentNode(repr lineVar), newIdentNode("command")))

  for child in stmtList:
    expectKind(child, {nnkCall, nnkCommand})

    let procName = repr child[0]
    let cmd = replace(procName, "do_", "")

    var exprEqExprList = newSeq[NimNode]()

    exprEqExprList.add(newIdentNode(procName))

    exprEqExprList.add(
      newTree(nnkExprEqExpr, newIdentNode(repr lineVar), newIdentNode(repr lineVar))
    )

    if child.kind == nnkCommand:
      let args = child[1 .. child.len - 2]
      # var defsTree = newSeq[NimNode]()

      for idx, arg in args:
        # Proc call args
        exprEqExprList.add(
          newTree(
            nnkExprEqExpr,
            newIdentNode(repr arg),
            newCall(
              newIdentNode("pick"),
              newDotExpr(newIdentNode(repr lineVar), newIdentNode("args")),
              newIntLitNode(idx),
            ),
          )
        )

    var stmtList = newSeq[NimNode]()

    stmtList.add(
      newStmtList(
        newTree(
          nnkIfStmt,
          newTree(
            nnkElifBranch,
            newCall(
              newIdentNode("isSome"),
              newDotExpr(newIdentNode(repr lineVar), newIdentNode("args")),
            ),
            newStmtList(newTree(nnkReturnStmt, newTree(nnkCall, exprEqExprList))),
          ),
          newTree(
            nnkElse,
            newStmtList(
              newTree(
                nnkReturnStmt,
                newCall(newIdentNode(procName), newIdentNode(repr lineVar)),
              )
            ),
          ),
        )
      )
    )

    if cmd != "default":
      # cases of branches for case block
      cases.add(newTree(nnkOfBranch, newStrLitNode(cmd), newStmtList(stmtList)))
    else:
      # `help`/of branch for case block
      cases.add(
        newTree(
          nnkOfBranch,
          newStrLitNode("help"),
          newStmtList(
            newTree(
              nnkReturnStmt, newCall(newIdentNode("help"), newIdentNode(repr lineVar))
            )
          ),
        )
      )
      # `default`/else branch for case block
      cases.add(
        newTree(
          nnkElse,
          newStmtList(
            newTree(
              nnkReturnStmt,
              newCall(newIdentNode("default"), newIdentNode(repr lineVar)),
            )
          ),
        )
      )

  result.add(newTree(nnkCaseStmt, cases))

macro loki*(handlerName: untyped, lineVar: untyped, statements: untyped) =
  ## Can be used to generate a handler proc for
  ## a new Loki. A handler proc is run on parsed lines
  ## during the interpreter loop.

  runnableExamples:
    loki(cmdHandler, line):
      do_greet name:
        if isSome(name):
          write(stdout, "Hello " & get(name) & "!")
        else:
          write(stdout, "Hey you!\n")
      do_EOF:
        return true

  result = newStmtList()
  let handlerCasesProcDefs = createdProcDefs(lineVar, statements)

  result.add newStmtList handlerCasesProcDefs

  let statementNodes = createHandlerCommandStatements(statements, lineVar)
  result.add createHandlerProcDef(handlerName, lineVar, statementNodes)
