using SQLite
using Tables
conn = SQLite.DB("test.sqlite")
setconnection(conn)

@record struct Vehicle
    id::Auto
    name::VarChar{255}
    company::VarChar{50}
    year::Date
    weight::Float64
    color::VarChar{50}
    valves::Int
    notes::String
    topspeed::Float64

    ukey=name,company

    Vehicle(name::String, company::String, year::Date) = new(0, name, company, year, 0, "", 0, "", 0)
    Vehicle(i, n, c, y, w, co, v, no, t) = new(i, n, c, y, w, co, v, no, t)
end

v = Vehicle("Octavia", "Skoda", Date("2019-07-07"))

try
    @drop(Vehicle)
catch ex
end
@create(Vehicle)
r = columntable(SQLite.Query(conn, "select tbl_name, sql from sqlite_master where type='table' and tbl_name='Vehicle'"))
@test length(r) != 0
@test r.sql[1] == Esquelle.@create_sql(Vehicle)

@insert(Vehicle, v)

@test c.id.val == 1

r = @select(Vehicle)
@test r[1] == Vehicle(1, "Octavia", "Skoda", Date("2019-07-07"), 0.0, "", 0, "", 0.0)

Vehicle(n, c, y, w, co) = Vehicle(0, n, c, y, w, co, 0, "", 0.0)
Vehicle(n, c, y, w) = Vehicle(0, n, c, y, w, "", 0, "", 0.0)

@insert(Vehicle, Vehicle("Ambassador", "Hindustan Motors", Date("1989-04-02"), 1200.0, "grey"))
@insert(Vehicle, Vehicle("800", "Maruthi Suzuki", Date("1990-10-15"), 800.0))

r = @select(
    Vehicle(name, weight),
    weight > 1000.0 && color == "grey",
    name => DESC)

@test length(r) == 1
@test r[1] == Vehicle(nothing, "Ambassador", nothing, nothing, 1200.0, nothing, nothing, nothing, nothing)

@update(Vehicle, topspeed => 100, year => "2019-01-05", weight == 800.0 && year < "2019-01-01")

r = @select(Vehicle, name == "800")

@test r[1] == Vehicle(3, "800", "Maruthi Suzuki", Date("2019-01-05"), 800.0, "", 0, "", 100.0)

@delete(Vehicle, color == "grey")

r = @select(Vehicle)

@test r == [Vehicle(1, "Octavia", "Skoda", Date("2019-07-07"), 0.0, "", 0, "", 0.0),
            Vehicle(3, "800", "Maruthi Suzuki", Date("2019-01-05"), 800.0, "", 0, "", 100.0)]

@drop(Vehicle)
r = columntable(SQLite.Query(conn, "select tbl_name from sqlite_master where type = 'table'"))
@test !("Vehicle" in r.tbl_name)
