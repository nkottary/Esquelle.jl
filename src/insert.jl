function insert_sql(T::Symbol, arg::Union{Symbol, Expr})
    fields = get_all_fields(T)
    metadata = fields.metadata
    fns = filter(x -> x != fields.auto, fields.fieldnames)
    stmt = "INSERT INTO `$(type_repr(T))` (`$(join(fns, "`, `"))`) VALUES ("
    vals = []
    for f in fns
        if f == fields.auto
            continue
        end
        def = :(string(getfield($arg, $(QuoteNode(f)))))
        t = metadata[f]
        if t == :String || t == :Date || t == :DateTime || t isa Expr && t.head == :curly && t.args[1] == :VarChar
            def = :("'" * replace($def, "'" => "\\'") * "'")
        end
        push!(vals, def)
    end
    :($stmt * join([$(vals...)], ", ") * ")")
end

macro insert_sql(T, arg)
    esc(insert_sql(T, arg))
end

"""
Macro to insert a julia object via SQL.

Examples:
```
julia> using Esquelle, MySQL

julia> setconnection(MySQL.connect("0.0.0.0", "nishanth", "lovemydb"; db="Rainbow"))

julia> @record struct Car
           name::String
           speed::Int
           weight::Int
           color::String
       end

julia> c = Car("WagonR '10", 90, 200, "blue")
Car("WagonR '10", 90, 200, "blue")

julia> @insert Car c
1
```
"""
macro insert(T, arg)
    q = insert_sql(T, arg)
    quote
        a = $(esc(arg))
        if !(a isa $(esc(T)))
            $(esc(:error))("Type mismatch: " * $(esc(string(T))) * " expected got " * $(esc(string))($(esc(typeof))(a)))
        end

        $(esc(EXECUTE_FUNC))($(esc(q)))
    end
end
