# Esquelle

An easy to use julia to SQL interface. Right now only MySQL backend is supported.

### Example

```
julia> using Esquelle, MySQL

julia> @record struct Car
           name::String
           speed::Int
           weight::Int
           color::String
       end

julia> conn = MySQL.connect("0.0.0.0", "nishanth", "lovemydb"; db="Rainbow")
MySQL Connection
------------
Host: 0.0.0.0
Port: 3306
User: nishanth
DB:   Rainbow


julia> setconnection(conn)

julia> @query Car
2-element Array{Car,1}:
 Car("WagonR", 80, 100, "grey")
 Car("Ford", 120, 500, "gold")

julia> @query Car speed > 100
1-element Array{Car,1}:
 Car("Ford", 120, 500, "gold")

julia> @query Car speed > 100 && weight < 1000
1-element Array{Car,1}:
 Car("Ford", 120, 500, "gold")

julia> @query Car speed > 50 speed => DESC
2-element Array{Car,1}:
 Car("Ford", 120, 500, "gold")
 Car("WagonR", 80, 100, "grey")

julia> @query Car(speed, name) speed => ASC
2-element Array{Car,1}:
 Car("WagonR", 80, nothing, nothing)
 Car("Ford", 120, nothing, nothing)

julia> @query Car color != NULL
2-element Array{Car,1}:
 Car("WagonR", 80, 100, "grey")
 Car("Ford", 120, 500, "gold")

julia> c = Car("WagonR '10", 90, 200, "blue")
Car("WagonR '10", 90, 200, "blue")

julia> @insert Car c
1

julia> @query Car
3-element Array{Car,1}:
 Car("WagonR", 80, 100, "grey")
 Car("Ford", 120, 500, "gold")
 Car("WagonR '10", 90, 200, "blue")
```

## TODO
- Docs
- Tests
- Auto increment awareness
- Unique keys awareness
- Update, Upsert and Delete statements
- Tutorial
- Support PostgreSQL, SQLite, ODBC, JDBC
