# Package

version       = "0.3.0"
author        = "Beshr Kayali Reinholdsson"
description   = "A small library for writing cli programs in Nim."
license       = "Zlib"
srcDir        = "src"


# Dependencies

requires "nim >= 1.0.0"


# Tasks

task test, "Run the unit tests":
  exec "nim r --hints:off tests/test.nim"
