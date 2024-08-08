# niqlite
Minimalistic Sqlite3 wrapper for Nim


see example in [testExample.nim](./tests/testExample.nim)

## tutorial

### start with importing libs
```nim
import niqlite
import std/os
```

### open database:
```nim
var db = niqlite.newSqliteDatabase("test.db")
```

### execute some sql
```nim
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
```
db.exec also optionally takes second argument, int, which is maximum length of sql string to accept:
```nim
db.exec("""
CREATE TABLE test_data (
id INTEGER PRIMARY KEY,
int_val INTEGER,
real_val REAL,
text_val TEXT,
blob_val BLOB,
date_val TEXT
);
""", 1024)
```

### put some data into db
```
let intVal = 42
let realVal = 3.14
let textVal = "Hello, SQLite!"
let blobVal = @[byte 1, 2, 3, 4, 5]
let dateVal = "2023-04-15 10:30:00"

const insertSql = "INSERT INTO test_data (int_val, real_val, text_val, blob_val, date_val) VALUES (?, ?, ?, ?, ?);"
let stmt = db.prepare(insertSql, 
intVal, realVal, textVal, blobVal, dateVal)
discard stmt.step() # does the insert

# multiline string also works
const insertSql2 = """
INSERT INTO test_data (int_val, real_val, text_val, blob_val, date_val)
VALUES (42, ?, ?, ?, ?);"""
let stmt2 = db.prepare(insertSql2, realVal, textVal, blobVal, dateVal)
discard stmt2.step()
```

### lets extract some data back
```
var selectStmt = db.newSqliteStatement("SELECT * FROM test_data")
while selectStmt.step() == SQLITE_ROW:
    echo "ID: ", selectStmt.columnInt(0)
    echo "Integer value: ", selectStmt.columnInt(1)
    echo "Real value: ", selectStmt.columnFloat(2)
    echo "Text value: ", selectStmt.columnText(3)
    let blob = selectStmt.columnBlob(4)
    echo "Blob value: ", blob
    echo "Date value: ", selectStmt.columnText(5)
```

### set custom build flags for sqlite.c
to set custom flags for building sqlite, you can for example put this
in your config.nims near your source files:
`switch("define", "SQLITE_CFLAGS=-DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_JSON1 -O3")`

Basically, this is same as doing 
`nim c -d:SQLITE_CFLAGS="-DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_JSON1 -O3" your_file.nim`

Any way to change that "define" thing will do.