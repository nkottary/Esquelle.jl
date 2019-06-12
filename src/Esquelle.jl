module Esquelle

export @record, @query, setconnection, @insert

using MacroTools

struct Record
    metadata::Dict{Symbol, Union{Symbol, Expr}}
    fieldnames::Array{Symbol}
    pkey::Array{Symbol}
    auto::Union{Symbol, Nothing}
end

const FIELDS_DICT = Dict{Symbol, Record}()
CONN = nothing
QUERY_FUNC = nothing
EXECUTE_FUNC = nothing

"""
Set the connection. This lets `AmazingSQL` know what
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

    global QUERY_FUNC = :(q -> $qry(AmazingSQL.CONN, q))
    global EXECUTE_FUNC = :(q -> $exe(AmazingSQL.CONN, q))
    global CONN = con
    nothing
end

"""
Macro to define a struct that can be used with the SQL
operators in this package.

Example:
```
@record struct Car
    name::String
    speed::Int
    weight::Float64
    color::String
end
```
"""
#TODO: Add unique keys and auto increment
#TODO: Create a constructor that ignores autoincrement
macro record(e)
    if !@capture(e, struct T_ fields__ end)
        error("@know not applied on a struct")
    end

    d = Dict()
    pkey = nothing
    auto = nothing
    safe_fields = []
    fieldnames = []
    for f in fields
        if f isa Symbol
            d[f] = :Any
            fname = f
            def = :($f::Union{Nothing, Any})
        elseif f.head == :(::)
            tex = f.args[2]
            fname = f.args[1]
            d[fname] = tex
            if tex isa Expr && tex.head == :curly && tex.args[1] == :Union && :Nothing in tex.args[2:end]
                def = f
            else
                def = :($(f.args[1])::Union{Nothing, $(f.args[2])})
            end
        elseif f.head == :(=)
            if f.args[1] == :pkey
                if pkey !== nothing
                    error("Duplicate primary key declaration")
                else
                    pkey = f.args[2]
                end
            elseif f.args[1] == :auto
                if auto !== nothing
                    error("Duplicate auto increment declaration")
                else
                    auto = f.args[2]
                end
            end
            continue
        else
            continue
        end
        push!(safe_fields, def)
        push!(fieldnames, fname)
    end

    if pkey !== nothing
        err = false
        if pkey isa Symbol
            if !(pkey in fieldnames)
                err = true
            end
        else
            if pkey.head != :tuple
                err = true
            elseif length(intersect(pkey.args, fieldnames)) != length(pkey.args)
                err = true
            end
        end
        if err
            error("Primary key declaration must be a field name or tuple of field names")
        end
    end

    if auto !== nothing
        if !(auto isa Symbol) || !(auto in fieldnames)
            error("Auto increment must be a field name")
        end
    end

    if pkey == nothing
        pkey = []
    elseif pkey isa Symbol
        pkey = [pkey]
    else
        pkey = pkey.args
    end
    FIELDS_DICT[T] = Record(d, fieldnames, pkey, auto)

    quote
        struct $T
            $(safe_fields...)
        end
    end |> esc
end

"""
Get an array of fields of a type. Each field is an expression of the form
`:(fieldname::fieldtype)`. The array of fields is retrieved from a global
dictionary. The fields were initially stored there by calling the `@record`
macro on a struct.

Parameters:
- `T::Union{Symbol, Expr}`: The type as a `Symbol` or constructor expression
whose fields are to be recieved.

Returns:
An `Array{Expr}` of the fields of `T`. 
"""
function get_all_fields(T::Symbol)
    if !haskey(FIELDS_DICT, T)
        error("struct `$(type_repr(T))` not recognized. Add `@record` to its definition")
    end
    return FIELDS_DICT[T]
end

function get_all_fields(T::Expr)
    if T.head == :call
        get_all_fields(T.args[1])
    else
        get_fields_error()
    end
end

get_all_fields(T) = get_fields_error()
get_fields_error() = error("Argument must be either a type or a type with fields. Ex: `Car(name, speed)`")

"""
Get the fieldnames of a type represented by a symbol or constructor expression

Parameters:
- `T::Union{Symbol, Expr}`: The type as a `Symbol` or a constructor
expression, for example: `Car(name, speed)`

Returns:
An `Array{String}` of fieldnames
"""
get_all_fieldnames(T) = get_all_fields(T).fieldnames

type_repr(T::Symbol) = T
type_repr(T::Expr) = T.args[1]

"""
Get fieldnames requested in a constructor expression. If a symbol is passed
then the names of all the fields of the type is returned.

Parameters:
- `T::Union{Symbol, Expr}`: The type as a `Symbol` or a constructor
expression, for example: `Car(name, speed)`

Returns:
An `Array{String}` of the fieldnames requested
"""
get_requested_fieldnames(T::Symbol) = get_all_fieldnames(T)

function get_requested_fieldnames(T::Expr)
    fields = get_all_fieldnames(T)
    req = T.args[2:end]
    if isempty(req)
        error("Requested fields cannot be empty. If you wanted all fields remove the `()`")
    end

    for r in req
        if !(r isa Symbol)
            error("`$r` is not an attribute name")
        end
        if !(r in fields)
            error("Requested field `$r` not found in type `$(type_repr(T))`")
        end
    end
    return req
end
get_requested_fieldnames(T) = get_fields_error()

include("whereclause.jl")
include("query.jl")
include("insert.jl")

#TODO: Add @update
#TODO: Add @upsert
#TODO: Add @delete

end  # module
