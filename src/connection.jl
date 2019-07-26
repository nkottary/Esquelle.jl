"""
Set the connection. This lets `Esquelle` know what
DBMS you are using.

Parameters:
- `con`: The connection object of your chosen DBMS
initialized to your database.

Example:
```
conn = LibPQ.Connection("dbname=postgres")
setconnection(conn)
```
"""
function setconnection(con::T) where T
    t = Symbol(T.name.module)
    global connector = t
    if t == :MySQL
        qry = :(MySQL.query)
        exe = :(MySQL.execute!)
        auto = "INT NOT NULL AUTO_INCREMENT"
        lastid = :(MySQL.insertid)
    elseif t == :LibPQ
        qry = :((x, y) -> columntable(LibPQ.execute(x, y)))
        exe = :(LibPQ.execute)
        auto = "SERIAL"
        lastid = :((c) -> LibPQ.execute(c, "SELECT LASTVAL()"))
    elseif t == :SQLite
        qry = :((x, y) -> columntable(SQLite.Query(x, y)))
        exe = :(SQLite.Query)
        auto = "INTEGER PRIMARY KEY AUTOINCREMENT"
        lastid = :(SQLite.last_insert_rowid)
    elseif t == :ODBC
        qry = :(ODBC.query)
        exe = :(ODBC.execute)
        auto = "INT NOT NULL AUTO_INCREMENT"
    elseif t == :JDBC
        qry = :(JDBC.executeQuery)
        exe = :(JDBC.executeQuery)
        auto = "INT NOT NULL AUTO_INCREMENT"
    else
        error("Unsupported DBMS")
    end

    global QUERY_FUNC = :(q -> $qry(Esquelle.CONN, q))
    global EXECUTE_FUNC = :(q -> $exe(Esquelle.CONN, q))
    global LASTID_FUNC = :(() -> $lastid(Esquelle.CONN))
    global CONN = con
    global AUTO = auto
    nothing
end
