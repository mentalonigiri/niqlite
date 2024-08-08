
import unittest

import niqlite
import std/os


test "can create sqlite stmt":
  var db = niqlite.newSqliteDatabase("a.db")

  var stmt = niqlite.newSqliteStatement(db, """
CREATE TABLE contacts (
contact_id INTEGER PRIMARY KEY,
first_name TEXT NOT NULL,
last_name TEXT NOT NULL,
email TEXT NOT NULL UNIQUE,
phone TEXT NOT NULL UNIQUE
);""", 512)
  check 1 == 1
  discard os.tryRemoveFile("a.db")
