"""
Convert an array of `Pair` expressions to `SET` clause
"""
function pairs2assign(r::Record, args...)
    expressions = []
    for e in args
        if !ispair(e)
            error("`Pair` expected for `SET` clause")
        end
        k, v = e.args[2:3]
        if !(k isa Symbol) || !(k in r.fieldnames)
            error("Fieldname expected in `SET` clause")
        end
        push!(expressions,
            quote
                $(show_unquoted(k)) * " = " * $(quotestring(r.metadata[k], v))
            end)
    end
    join_exprs(", ", expressions...)
end

"""
Convert a julia expression to SQL `UPDATE` statement
"""
function update_sql(T::Union{Symbol, Expr}, args...)
    if length(args) == 0
        error("Missing `SET` argument")
    end

    if !ispair(args[1])
        error("`SET` arguments must be `Pair`s")
    end

    fs = get_all_fields(T)

    if ispair(args[end])
        setstmt = pairs2assign(fs, args...)
        wclause = ""
    else
        setstmt = pairs2assign(fs, args[1:end-1]...)
        if !(args[end] isa Expr)
            error("Expression expected for `SET` or `WHERE` clause")
        end
        wclause = whereclause(fs, args[end])
    end
    join_exprs(
        " ",
        "UPDATE",
        show_unquoted(type_repr(T)),
        "SET",
        setstmt,
        "WHERE",
        wclause
    )
end

macro update_sql(args...)
    esc(update_sql(args...))
end

"""
Convert and execute a julia expressions as an SQL `UPDATE` statement

Example:

```
@update  Car  speed => 100   weight < 100
```
"""
macro update(args...)
    q = update_sql(args...)
    quote
        $EXECUTE_FUNC($q)
    end |> esc
end
