using Pkg; Pkg.activate("..")
using Test, Dates
using Esquelle

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

@test @create_sql(Car) == "CREATE TABLE Car ( id INT NOT NULL AUTO_INCREMENT, name VARCHAR(255), company VARCHAR(50), year TIMESTAMP, weight NUMERIC, color VARCHAR(50), valves INT, notes TEXT, topspeed NUMERIC , PRIMARY KEY (id), UNIQUE (name, company) )"

@test @select_sql(Car) == "SELECT id, name, company, year, weight, color, valves, notes, topspeed FROM Car"

@test @select_sql(
    Car(name, weight),
    topspeed > 100 && color == "grey",
    name => DESC) == "SELECT name, weight FROM Car WHERE topspeed > 100 AND color = 'grey' ORDER BY name DESC"

@test @insert_sql(Car, c) == "INSERT INTO Car (name, company, year, weight, color, valves, notes, topspeed) VALUES ('Octavia', 'Skoda', '2019-07-07', 0.0, '', 0, '', 0.0)"

@test @update_sql(Car, topspeed => 100, year => "2019-01-05", weight < 200 && year < "2019-01-01") == "UPDATE Car SET topspeed = 100, year = '2019-01-05' WHERE weight < 200 AND year < '2019-01-01'"

@test @delete_sql(Car) == "DELETE FROM Car"
@test @delete_sql(Car, c) == "DELETE FROM Car WHERE id = 0"
@test @delete_sql(Car, color == "grey") == "DELETE FROM Car WHERE color = 'grey'"

@test @drop_sql(Car) == "DROP TABLE Car"

@testset "MySQL" begin
    #include("mysql.jl")
end

@testset "PostgreSQL" begin
    #include("pgsql.jl")
end

@testset "SQLite" begin
    include("sqlite.jl")
end
