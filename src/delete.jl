function delete_sql(T::Symbol, args...)
    if !isempty(args)
        fs = get_all_fields(T)
        if args[1] isa Symbol
            if length(args) > 1
                error("Provide either object or fields to @delete")
            end
            if fs.pkey !== nothing
                wargs = [:($a == $(args[1]).$a) for a in fs.pkey]
            elseif fs.ukey !== nothing
                wargs = [:($a == $(args[1]).$a) for a in fs.ukey]
            else
                error("$T has no declared primary or unique key")
            end
        else
            wargs = args
        end
        return join_exprs(
            " ",
            "DELETE FROM",
            "$(type_repr(T))",
            "WHERE",
            whereclause(fs, wargs...)
        )
    else
        return "DELETE FROM $(type_repr(T))"
    end
end

macro delete_sql(args...)
    esc(delete_sql(args...))
end

macro delete(args...)
    q = delete_sql(args...)
    quote
        $(EXECUTE_FUNC)($q)
    end |> esc
end
