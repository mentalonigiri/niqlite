import unittest
import niqlite
import std/os

test "can write and read various data types from sqlite db":
  var db = niqlite.newSqliteDatabase("test.db")

  db.exec("""
  CREATE TABLE test_data (
    id INTEGER PRIMARY KEY,
    int_val INTEGER,
    real_val REAL,
    text_val TEXT,
    blob_val BLOB,
    date_val TEXT
  );
  """)

  let intVal = 42
  let realVal = 3.14
  let textVal = "Hello, SQLite!"
  let blobVal = @[byte 1, 2, 3, 4, 5]
  let dateVal = "2023-04-15 10:30:00"

  const insertSql = """
INSERT INTO test_data (int_val, real_val, text_val, blob_val, date_val)
VALUES (?, ?, ?, ?, ?);"""
  let stmt = db.prepare(insertSql, 
    intVal, realVal, textVal, blobVal, dateVal)
  discard stmt.step()

  const insertSql2 = """
INSERT INTO test_data (int_val, real_val, text_val, blob_val, date_val)
VALUES (42, ?, ?, ?, ?);"""
  let stmt2 = db.prepare(insertSql2, realVal, textVal, blobVal, dateVal)
  discard stmt2.step()

  var selectStmt = db.newSqliteStatement("SELECT * FROM test_data")
  while selectStmt.step() == SQLITE_ROW:
    # echo "ID: ", selectStmt.columnInt(0)
    # echo "Integer value: ", selectStmt.columnInt(1)
    # echo "Real value: ", selectStmt.columnFloat(2)
    # echo "Text value: ", selectStmt.columnText(3)
    let blob = selectStmt.columnBlob(4)
    # echo "Blob value: ", blob
    # echo "Date value: ", selectStmt.columnText(5)

    check selectStmt.columnInt(1) == intVal
    check selectStmt.columnFloat(2) == realVal
    check selectStmt.columnText(3) == textVal
    check selectStmt.columnBlob(4) == blobVal
    check selectStmt.columnText(5) == dateVal

  discard os.tryRemoveFile("test.db")