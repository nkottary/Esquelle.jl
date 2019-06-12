"""
Convert the julia expression to SQL `SELECT` query.

Parameters:
- `T::Union{Symbol, Expr}`: The table as a `Symbol` or constructor
expression. If a constructor expression is provided only the
fields mentioned in the expression are queried. If it is only
a `Symbol` then all fields are retrieved.
- `e::Union{Expr, Nothing}=nothing`: The optional julia conditional
expression which should be the `WHERE` clause
- `o...`: Order by expressions. These should be pairs of the form
`fieldname => ASC|DESC`.

Returns:
A SQL `SELECT` query `String`
"""
function select_sql(T::Union{Symbol, Expr})
    fields = ["`" * string(e) * "`" for e in get_requested_fieldnames(T)]
    "SELECT $(join(fields, ", ")) FROM `$(type_repr(T))`"
end

"""
Convert julia expressions to SQL `SELECT` query.

Examples:

```
julia> @record struct Car
           name::String
           speed::Int
           weight::Float64
           color::String
       end

julia> @select Car
"SELECT `name`, `speed`, `weight`, `color` FROM `Car`"

julia> @select Car(speed, name)
"SELECT `speed`, `name` FROM `Car`"

julia> @select(Car(speed, name), speed > 50 && weight > 100, speed => ASC)
"SELECT `speed`, `name` FROM `Car` WHERE `speed` > 50 AND `weight` > 100 ORDER BY `speed` ASC"

julia> @select(Car(speed, name), speed > 50 && weight != NULL, speed => DESC)
"SELECT `speed`, `name` FROM `Car` WHERE `speed` > 50 AND `weight` IS NOT NULL ORDER BY `speed` ASC"
```
"""
macro select(T)
    select_sql(T)
end

function select_sql(T::Union{Symbol, Expr}, e::Expr)
    stmt = select_sql(T)
    if e.head == :call && e.args[1] == :(=>)
        :($stmt * $(orderbyclause(T, e)))
    else
        fields = get_all_fields(T)
        stmt = stmt * " WHERE "
        :($stmt * $(whereclause(fields, e)))
    end
end

macro select(T, e)
    esc(select_sql(T, e))
end

"""
Convert an array of julia `Pair`s to julia `ORDER BY` clause.

Parameters:
- `T::Union{Symbol, Expr}`: The table as a symbol or constructor
expression.
- `o...`: `Pair`s of the form `fieldname => ASC|DESC`

Returns:
An `ORDER BY` SQL `String`
"""
function orderbyclause(T, o...)
    fields = get_all_fieldnames(T)
    ob = []
    for pair in o
        if pair.head != :call || pair.args[1] != :(=>)
            error("ORDER BY parameter must be a `Pair`")
        end

        p = pair.args[2]
        if !(p in fields)
            error("ORDER BY parameter `$p` not in fields")
        end

        v = pair.args[3]
        if !(v in [:ASC, :DESC])
            error("ORDER BY value must be either `ASC` or `DESC`")
        end

        push!(ob, "`$p` $v")
    end
    return " ORDER BY " * join(ob, ", ")
end

function select_sql(T::Union{Symbol, Expr}, e::Expr, o...)
    if e.head == :call && e.args[1] == :(=>)
        obc = orderbyclause(T, e, o...)
        :($(select_sql(T)) * $obc)
    else
        obc = orderbyclause(T, o...)
        :($(select_sql(T, e)) * $obc)
    end
end

macro select(T, e, o...)
    esc(select_sql(T, e, o...))
end

"""
Convert julia expressions to SQL `SELECT` query, execute it and get results.

Examples:

```
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
```
"""
macro query(T, args...)
    q = select_sql(T, args...)
    fs = get_all_fieldnames(T)
    rfs = get_requested_fieldnames(T)

    params = [ f in rfs ? :(res[$(QuoteNode(f))][i]) : nothing for f in fs ]
    struct_name = type_repr(T)
    afield = QuoteNode(first(rfs))

    quote
        res = $(esc(QUERY_FUNC))($(esc(q)))
        [$(esc(struct_name))($(params...)) for i=1:length(res[$afield])]
    end
end
