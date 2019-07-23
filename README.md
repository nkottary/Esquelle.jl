# Esquelle

An easy to use julia to SQL interface. MySQL, PostgreSQL and SQLite backends are supported.

### Example

```
julia> using Esquelle, MySQL, Dates

julia> @record struct Car
           id::Auto
           name::VarChar{255}
           company::VarChar{50}
           year::Date
           weight::Float64
           color::VarChar{50}
           valves::Int
           notes::String
           topspeed::Float64

           pkey=id
           ukey=name,company

           Car(name::String, company::String, year::Date) = new(0, name, company, year, 0, "", 0, "", 0)
           Car(i, n, c, y, w, co, v, no, t) = new(i, n, c, y, w, co, v, no, t)
       end

julia> c = Car("Octavia", "Skoda", Date("2019-07-07"))
Car(0, "Octavia", "Skoda", 2019-07-07, 0.0, "", 0, "", 0.0)

julia> conn = MySQL.connect("127.0.0.1", "root", ""; db="test")
MySQL Connection
------------
Host: 127.0.0.1
Port: 3306
User: root
DB:   test

julia> setconnection(conn)

julia> @create(Car)    # Create the Car table in MySQL
0

julia> @insert(Car, c) # Insert `c` into the Car table
1

julia> @select(Car)    # Get all rows in Car
1-element Array{Car,1}:
 Car(1, "Octavia", "Skoda", 2019-07-07, 0.0, "", 0, "", 0.0)

julia> @select(Car(name, weight),
               topspeed > 100 && color == "grey",
               name => DESC)  # Get just the `name` and `weight` with the given condition as a WHERE clause and order by `name`.
```

See `test/runtests.jl` for more examples.

## TODO
- Docs
- More tests
- Upsert statements
- Tutorial
- Support ODBC, JDBC
