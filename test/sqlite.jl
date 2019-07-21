using SQLite
conn = SQLite.DB("test.sqlite")
setconnection(conn)

try
    @drop(Car)
catch ex
end
@create(Car)
r = columntable(SQLite.Query(conn, "select tbl_name, sql from sqlite_master where type='table'"))
@test "Car" == r.tbl_name[1]
@test r.sql[1] == Esquelle.@create_sql(Car)

@insert(Car, c)

r = @select(Car)
@test r[1] == Car(1, "Octavia", "Skoda", Date("2019-07-07"), 0.0, "", 0, "", 0.0)

Car(n, c, y, w, co) = Car(0, n, c, y, w, co, 0, "", 0.0)
Car(n, c, y, w) = Car(0, n, c, y, w, "", 0, "", 0.0)

@insert(Car, Car("Ambassador", "Hindustan Motors", Date("1989-04-02"), 1200.0, "grey"))
@insert(Car, Car("800", "Maruthi Suzuki", Date("1990-10-15"), 800.0))

r = @select(
    Car(name, weight),
    weight > 1000.0 && color == "grey",
    name => DESC)

@test length(r) == 1
@test r[1] == Car(nothing, "Ambassador", nothing, nothing, 1200.0, nothing, nothing, nothing, nothing)

@update(Car, topspeed => 100, year => "2019-01-05", weight == 800.0 && year < "2019-01-01")

r = @select(Car, name == "800")

@test r[1] == Car(3, "800", "Maruthi Suzuki", Date("2019-01-05"), 800.0, "", 0, "", 100.0)

@delete(Car, color == "grey")

r = @select(Car)

@test r == [Car(1, "Octavia", "Skoda", Date("2019-07-07"), 0.0, "", 0, "", 0.0),
            Car(3, "800", "Maruthi Suzuki", Date("2019-01-05"), 800.0, "", 0, "", 100.0)]

@drop(Car)
r = columntable(SQLite.Query(conn, "select tbl_name from sqlite_master where type = 'table'"))
@test !("Car" in r.tablename)
