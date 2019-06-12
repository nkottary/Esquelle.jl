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
#TODO: Add unique keys
macro record(e)
    if !@capture(e, struct T_ fields__ end)
        error("@know not applied on a struct")
    end

    d = Dict()
    pkey = nothing
    ukey = nothing
    auto = nothing
    safe_fields = []
    constructors = []
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
            if tex == :Auto
                auto = fname
            end

            if tex isa Expr && tex.head == :curly && tex.args[1] == :Union && :Nothing in tex.args[2:end]
                def = f
            else
                def = :($fname::Union{Nothing, $tex})
            end

        elseif f.head == :(=)
            if f.args[1] == :pkey
                if pkey !== nothing
                    error("Duplicate primary key declaration")
                else
                    pkey = f.args[2]
                end
            elseif f.args[1] == :ukey
                if ukey !== nothing
                    error("Duplicate unique key declaration")
                else
                    ukey = f.args[2]
                end
            else
                push!(constructors, f)
            end
            continue
        elseif f.head == :function
            push!(constructors, f)
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

    if pkey == nothing
        pkey = []
    elseif pkey isa Symbol
        pkey = [pkey]
    else
        pkey = pkey.args
    end

    if ukey !== nothing
        err = false
        if ukey isa Symbol
            if !(ukey in fieldnames)
                err = true
            end
        else
            if ukey.head != :tuple
                err = true
            elseif length(intersect(ukey.args, fieldnames)) != length(ukey.args)
                err = true
            end
        end
        if err
            error("Unique key declaration must be a field name or tuple of field names")
        end
    end

    if ukey == nothing
        ukey = []
    elseif ukey isa Symbol
        ukey = [ukey]
    else
        ukey = ukey.args
    end

    FIELDS_DICT[T] = Record(d, fieldnames, pkey, auto, ukey)

    quote
        struct $T
            $(safe_fields...)
            $(constructors...)
        end
    end |> esc
end
