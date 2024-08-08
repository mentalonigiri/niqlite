import macros

const SQLITE_CFLAGS {.strdefine.} = "-DSQLITE_ENABLE_FTS5 -O3"

{.compile("sqlite3.c", SQLITE_CFLAGS).}

const 
  SQLITE_OK* = 0
  SQLITE_ROW* = 100
  SQLITE_DONE* = 101

# low-level api

type 
  CSqlite = ptr object
  CSqliteStatement = ptr object
  CSqliteCallback = proc (arg: pointer, argc: cint, argv: cstringArray, colNames: cstringArray): cint {.cdecl.}

const emptyCallback = proc (arg: pointer, argc: cint, argv: cstringArray, colNames: cstringArray): cint {.cdecl.} =
  return 0

proc sqlite3_open(filename: cstring, db: ptr CSqlite): int {.importc.}
proc sqlite3_close(db: CSqlite): int {.importc.}
proc sqlite3_prepare(db: CSqlite, sql: cstring, sqlMaxLength: int, 
  statement: ptr CSqliteStatement): int {.importc.}
proc sqlite3_finalize(stmt: CSqliteStatement): int {.importc.}
proc sqlite3_exec(
     db: CSqlite, sql: cstring, 
     callback: pointer,
     arg: pointer,
     errmsg: ptr cstring
   ): int {.cdecl, importc.}
proc sqlite3_step(stmt: CSqliteStatement): int {.importc.}
proc sqlite3_column_count(pStmt: CSqliteStatement): cint {.importc.}
proc sqlite3_column_type(pStmt: CSqliteStatement, iCol: cint): cint {.importc.}
proc sqlite3_column_int(pStmt: CSqliteStatement, iCol: cint): cint {.importc.}
proc sqlite3_column_int64(pStmt: CSqliteStatement, iCol: cint): int64 {.importc.}
proc sqlite3_column_double(pStmt: CSqliteStatement, iCol: cint): cdouble {.importc.}
proc sqlite3_column_text(pStmt: CSqliteStatement, iCol: cint): cstring {.importc.}
proc sqlite3_column_blob(pStmt: CSqliteStatement, iCol: cint): pointer {.importc.}
proc sqlite3_column_bytes(pStmt: CSqliteStatement, iCol: cint): cint {.importc.}
proc sqlite3_column_name(pStmt: CSqliteStatement, iCol: cint): cstring {.importc.}

# higher-level api

# sqlite database class
type
  SqliteDatabaseData = object
    cSqliteHandle: CSqlite

proc newSqliteDatabaseData(filename: cstring): SqliteDatabaseData =
  var sqlite: CSqlite
  var rc = sqlite3_open(filename, addr sqlite)
  assert(rc == SQLITE_OK, "sqlite open error")
  result.cSqliteHandle = sqlite

proc `=destroy`(db: SqliteDatabaseData) =
  var rc = sqlite3_close(db.cSqliteHandle)
  assert(rc == SQLITE_OK, "sqlite3_close failed")

type SqliteDatabase* = ref SqliteDatabaseData
proc newSqliteDatabase*(filename: cstring): SqliteDatabase = 
  new (result)
  result[] = newSqliteDatabaseData(filename)

proc exec*(db: SqliteDatabase, sql: cstring) =
  var rc = sqlite3_exec(db.cSqliteHandle, sql, emptyCallback, nil, nil)
  assert(rc == SQLITE_OK, "sqlite_exec failed")

# sqlite statement class
type SqliteStatementData = object
  cSqliteStatement: CSqliteStatement
  db: SqliteDatabase

proc newSqliteStatementData(db: SqliteDatabase, 
  sql: cstring, 
  sqlMaxLength: int): SqliteStatementData =
    result.db = db
    var stmt: CSqliteStatement
    var rc = sqlite3_prepare(db.cSqliteHandle, sql, sqlMaxLength, addr stmt)
    result.cSqliteStatement = stmt

proc `=destroy`(stmt: SqliteStatementData) =
  var rc = sqlite3_finalize(stmt.cSqliteStatement)
  assert(rc == SQLITE_OK, "failed to sqlite3_finalize")

type SqliteStatement* = ref SqliteStatementData
proc newSqliteStatement*(db: SqliteDatabase,
  sql: cstring,
  sqlMaxLength: int = 4096): SqliteStatement =
    new(result)
    result[] = newSqliteStatementData(
      db, sql, sqlMaxLength
    )

proc step*(stmt: SqliteStatement): int =
     result = sqlite3_step(stmt.cSqliteStatement)
     assert(result == SQLITE_ROW or result == SQLITE_DONE, "sqlite3_step failed")

proc columnCount*(stmt: SqliteStatement): int =
  return sqlite3_column_count(stmt.cSqliteStatement).int

proc columnType*(stmt: SqliteStatement, col: int): int =
  return sqlite3_column_type(stmt.cSqliteStatement, col.cint).int

proc columnInt*(stmt: SqliteStatement, col: int): int =
  return sqlite3_column_int(stmt.cSqliteStatement, col.cint).int

proc columnInt64*(stmt: SqliteStatement, col: int): int64 =
  return sqlite3_column_int64(stmt.cSqliteStatement, col.cint)

proc columnFloat*(stmt: SqliteStatement, col: int): float =
  return sqlite3_column_double(stmt.cSqliteStatement, col.cint).float

proc columnText*(stmt: SqliteStatement, col: int): string =
  return $sqlite3_column_text(stmt.cSqliteStatement, col.cint)

proc columnBytes*(stmt: SqliteStatement, col: int): int =
  return sqlite3_column_bytes(stmt.cSqliteStatement, col.cint).int

proc columnBlob*(stmt: SqliteStatement, col: int): seq[byte] =
  let blob = sqlite3_column_blob(stmt.cSqliteStatement, col.cint)
  let size = columnBytes(stmt, col)
  result = newSeq[byte](size)
  if size > 0:
    copyMem(addr result[0], blob, size)

proc columnName*(stmt: SqliteStatement, col: int): string =
  return $sqlite3_column_name(stmt.cSqliteStatement, col.cint)

# part with binding values

proc sqlite3_bind_int(stmt: CSqliteStatement, idx: cint, val: cint): cint {.importc.}
proc sqlite3_bind_int64(stmt: CSqliteStatement, idx: cint, val: int64): cint {.importc.}
proc sqlite3_bind_double(stmt: CSqliteStatement, idx: cint, val: cdouble): cint {.importc.}
proc sqlite3_bind_text(stmt: CSqliteStatement, idx: cint, val: cstring, n: cint, destructor: pointer): cint {.importc.}
proc sqlite3_bind_blob(stmt: CSqliteStatement, idx: cint, val: pointer, n: cint, destructor: pointer): cint {.importc.}
proc sqlite3_bind_null(stmt: CSqliteStatement, idx: cint): cint {.importc.}

proc bindInt(stmt: SqliteStatement, idx: int, value: int) =
  let rc = sqlite3_bind_int(stmt.cSqliteStatement, idx.cint, value.cint)
  assert(rc == SQLITE_OK, "Failed to bind int parameter")

proc bindInt64(stmt: SqliteStatement, idx: int, value: int64) =
  let rc = sqlite3_bind_int64(stmt.cSqliteStatement, idx.cint, value)
  assert(rc == SQLITE_OK, "Failed to bind int64 parameter")

proc bindFloat(stmt: SqliteStatement, idx: int, value: float) =
  let rc = sqlite3_bind_double(stmt.cSqliteStatement, idx.cint, value.cdouble)
  assert(rc == SQLITE_OK, "Failed to bind float parameter")

proc bindText(stmt: SqliteStatement, idx: int, value: string) =
  let rc = sqlite3_bind_text(stmt.cSqliteStatement, idx.cint, value.cstring, value.len.cint, nil)
  assert(rc == SQLITE_OK, "Failed to bind text parameter")

proc bindBlob(stmt: SqliteStatement, idx: int, value: seq[byte]) =
  let rc = sqlite3_bind_blob(stmt.cSqliteStatement, idx.cint, unsafeAddr value[0], value.len.cint, nil)
  assert(rc == SQLITE_OK, "Failed to bind blob parameter")

proc bindNull(stmt: SqliteStatement, idx: int) =
  let rc = sqlite3_bind_null(stmt.cSqliteStatement, idx.cint)
  assert(rc == SQLITE_OK, "Failed to bind null parameter")



proc bindParam(stmt: SqliteStatement, idx: int, value: int) =
  let rc = sqlite3_bind_int(stmt.cSqliteStatement, idx.cint, value.cint)
  assert(rc == SQLITE_OK, "Failed to bind int parameter")

proc bindParam(stmt: SqliteStatement, idx: int, value: int64) =
  let rc = sqlite3_bind_int64(stmt.cSqliteStatement, idx.cint, value)
  assert(rc == SQLITE_OK, "Failed to bind int64 parameter")

proc bindParam(stmt: SqliteStatement, idx: int, value: float) =
  let rc = sqlite3_bind_double(stmt.cSqliteStatement, idx.cint, value.cdouble)
  assert(rc == SQLITE_OK, "Failed to bind float parameter")

proc bindParam(stmt: SqliteStatement, idx: int, value: string) =
  let rc = sqlite3_bind_text(stmt.cSqliteStatement, idx.cint, value.cstring, value.len.cint, nil)
  assert(rc == SQLITE_OK, "Failed to bind text parameter")

proc bindParam(stmt: SqliteStatement, idx: int, value: seq[byte]) =
  let rc = sqlite3_bind_blob(stmt.cSqliteStatement, idx.cint, unsafeAddr value[0], value.len.cint, nil)
  assert(rc == SQLITE_OK, "Failed to bind blob parameter")

proc bindParam(stmt: SqliteStatement, idx: int, value: type(nil)) =
  let rc = sqlite3_bind_null(stmt.cSqliteStatement, idx.cint)
  assert(rc == SQLITE_OK, "Failed to bind null parameter")


macro prepare*(db: SqliteDatabase, sql: string, args: varargs[untyped]): untyped =
  var stmtDef = nnkLetSection.newTree(
    nnkIdentDefs.newTree(
      newIdentNode("stmt"),
      newEmptyNode(),
      newCall(bindSym"newSqliteStatement", db, sql, newLit(-1))
    )
  )

  var body = newStmtList(stmtDef)

  for i, arg in args:
    let idx = i + 1
    body.add(
      newCall(bindSym"bindParam",
        newIdentNode("stmt"),
        newLit(idx),
        arg
      )
    )

  body.add(newIdentNode("stmt"))

  result = newBlockStmt(body)