using Pkg; Pkg.activate("..")
using Test, Dates
using MySQL, Esquelle

@record struct Car
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

c = Car("Octavia", "Skoda", Date("2019-07-07"))

import Esquelle: @select_sql, @insert_sql, @update_sql, @create_sql, @delete_sql, @drop_sql

@test @create_sql(Car) == "CREATE TABLE `Car` ( `id` INT NOT NULL AUTO_INCREMENT, `name` VARCHAR(255), `company` VARCHAR(50), `year` TIMESTAMP, `weight` NUMERIC, `color` VARCHAR(50), `valves` INT, `notes` TEXT, `topspeed` NUMERIC , PRIMARY KEY (`id`), UNIQUE (`name`, `company`) )"

@test @select_sql(Car) == "SELECT `id`, `name`, `company`, `year`, `weight`, `color`, `valves`, `notes`, `topspeed` FROM `Car`"

@test @select_sql(
    Car(name, weight),
    topspeed > 100 && color == "grey",
    name => DESC) == "SELECT `name`, `weight` FROM `Car` WHERE `topspeed` > 100 AND `color` = 'grey' ORDER BY `name` DESC"

@test @insert_sql(Car, c) == "INSERT INTO `Car` (`name`, `company`, `year`, `weight`, `color`, `valves`, `notes`, `topspeed`) VALUES ('Octavia', 'Skoda', '2019-07-07', 0.0, '', 0, '', 0.0)"

@test @update_sql(Car, topspeed => 100, year => "2019-01-05", weight < 200 && year < "2019-01-01") == "UPDATE `Car` SET `topspeed` = 100, `year` = '2019-01-05' WHERE `weight` < 200 AND `year` < '2019-01-01'"

@test @delete_sql(Car) == "DELETE FROM `Car`"
@test @delete_sql(Car, c) == "DELETE FROM `Car` WHERE `id` = 0"
@test @delete_sql(Car, color == "grey") == "DELETE FROM `Car` WHERE `color` = 'grey'"

@test @drop_sql(Car) == "DROP TABLE `Car`"

conn = MySQL.connect("0.0.0.0", "nishanth", "lovemydb"; db="Rainbow")
setconnection(conn)

# MySQL tests
#
try
    @drop(Car)
catch ex
end
@create(Car)
r = MySQL.query(conn, "show tables")
@test "Car" in r.Tables_in_Rainbow
r = MySQL.query(conn, "describe Car")
@test r.Field == String["id",
                        "name",
                        "company",
                        "year",
                        "weight",
                        "color",
                        "valves",
                        "notes",
                        "topspeed"]
@test r.Type == String["int(11)",
                       "varchar(255)",
                       "varchar(50)",
                       "timestamp",
                       "decimal(10,0)",
                       "varchar(50)",
                       "int(11)",
                       "text",
                       "decimal(10,0)"]
@test r.Key[1] == "PRI"

@insert(Car, c)

r = @select(Car)
@test r[1] == Car(1, "Octavia", "Skoda", Date("2019-07-07"), 0.0, "", 0, "", 0.0)

Car(n, c, y, w, co) = Car(0, n, c, y, w, co, 0, "", 0.0)
Car(n, c, y, w) = Car(0, n, c, y, w, "", 0, "", 0.0)

@insert(Car, Car("Ambassador", "Hindustan Motors", Date("1959-04-02"), 1200.0, "grey"))
@insert(Car, Car("800", "Maruthi Suzuki", Date("1990-10-15"), 800.0))

r = @select(
    Car(name, weight),
    weight > 1000.0 && color == "grey",
    name => DESC)

#=
@update(Car, topspeed => 100, year => "2019-01-05", weight < 200 && year < "2019-01-01")

@delete(Car)
@delete(Car, c)
@delete(Car, color == "grey")

@drop(Car)

=#
#TODO: Postgres support, SQLite support
