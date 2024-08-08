
import unittest

import niqlite
import std/os


test "can open sqlite db":
  var db = niqlite.newSqliteDatabase("a.db")
  check 1 == 1
  discard os.tryRemoveFile("a.db")
