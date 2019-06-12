function drop_sql(T::Symbol)
    return "DROP TABLE `$T`"
end

macro drop_sql(T)
    esc(drop_sql(T))
end

macro drop(T)
    q = drop_sql(T)
    quote
        $(EXECUTE_FUNC)($q)
    end |> esc
end
