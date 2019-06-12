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
    if t == :MySQL
        qry = :(MySQL.query)
        exe = :(MySQL.execute!)
    elseif t == :LibPQ
        qry = :(LibPQ.execute)
        exe = :(LibPQ.execute)
    elseif t == :ODBC
        qry = :(ODBC.query)
        exe = :(ODBC.execute)
    elseif t == :JDBC
        qry = :(JDBC.executeQuery)
        exe = :(JDBC.executeQuery)
    else
        error("Unsupported DBMS")
    end

    global QUERY_FUNC = :(q -> $qry(Esquelle.CONN, q))
    global EXECUTE_FUNC = :(q -> $exe(Esquelle.CONN, q))
    global CONN = con
    nothing
end