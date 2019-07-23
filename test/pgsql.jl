using LibPQ, Tables
conn = LibPQ.Connection("host=localhost dbname=test password= user=postgres")
setconnection(conn)

try
    @drop(Car)
catch ex
end
@create(Car)
r = columntable(LibPQ.execute(conn, "select tablename from pg_catalog.pg_tables"))
@test "car" in r.tablename
r = columntable(execute(conn, "select column_name, data_type, character_maximum_length from INFORMATION_SCHEMA.COLUMNS where table_name = 'car'"))
@test [r.column_name...] == String["id",
                        "name",
                        "company",
                        "year",
                        "weight",
                        "color",
                        "valves",
                        "notes",
                        "topspeed"]
@test [r.data_type...] == String[ "integer",
 "character varying",
 "character varying",
 "timestamp without time zone",
 "numeric",
 "character varying",
 "integer",
 "text",
 "numeric",
]

@test map(x -> ismissing(x) ? -1 : x, r.character_maximum_length) == [
    -1,
    255,
    50,
    -1,
    -1,
    50,
    -1,
    -1,
    -1,
]
# TODO: Test for primary key
#
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
r = columntable(LibPQ.execute(conn, "select tablename from pg_catalog.pg_tables"))
@test !("Car" in r.tablename)
