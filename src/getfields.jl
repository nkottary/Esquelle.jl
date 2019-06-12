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