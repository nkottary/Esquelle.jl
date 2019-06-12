function create_sql(T::Symbol)
    stmt = "CREATE TABLE `$T` ("
    fields = []
    r = get_all_fields(T)
    for f in r.fieldnames
        t = r.metadata[f]
        push!(fields, :("`" * $(show_unquoted(f)) * "` " * Esquelle.convert_sql_type($t)))
    end
    fs = join_exprs(", ", fields...)
    extras = ""
    if r.pkey !== nothing
        extras *= ", PRIMARY KEY (`$(join(r.pkey, "`, `"))`)"
    end
    if r.ukey !== nothing
        extras *= ", UNIQUE (`$(join(r.ukey, "`, `"))`)"
    end
    join_exprs(" ", stmt, fs, extras * " )")
end

macro create_sql(T)
    esc(create_sql(T))
end

macro create(T)
    q = create_sql(T)
    quote
        $EXECUTE_FUNC($q)
    end |> esc
end
