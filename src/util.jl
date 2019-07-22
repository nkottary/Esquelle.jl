type_repr(T::Symbol) = T
type_repr(T::Expr) = T.args[1]

ispair(ex) = ex isa Expr && ex.head == :call && ex.args[1] == :(=>)

function quotestring(t::Union{Symbol, Expr}, v)
    quote
        if $t <: AbstractString
            "'" * replace(string($v), "'" => "\\\'") * "'"
        elseif $t <: Union{Date, DateTime}
            "'" * string($v) * "'"
        else
            string($v)
        end
    end
end

function quotestring(t::Union{Symbol, Expr}, v, op::Symbol)
    quote
        if $t <: AbstractString
            if $(QuoteNode(op)) in [:(in), :(==), :(!=)]
                "'" * replace(string($v), "'" => "\\\'") * "'"
            else
                error($(string(op)) * " does not work on strings")
            end
        elseif $t <: Union{Date, DateTime}
            "'" * string($v) * "'"
        else
            string($v)
        end
    end
end

join_exprs(delim, exprs...) = reduce((x, y) -> :($x * $delim * $y), exprs)
show_unquoted(x) = sprint(Base.show_unquoted, x)

struct VarChar{N} <: AbstractString
    str::String
end

struct Auto
    val::Int
end

export VarChar, Auto

import Base: convert, string, show

Base.convert(::Type{VarChar{N}}, s::String) where N = VarChar{N}(s)
Base.convert(::Type{String}, v::VarChar{N}) where N = s.str
Base.convert(::Type{Auto}, i::Int) = Auto(i)
Base.convert(::Type{Auto}, i::Int32) = Auto(i)
Base.convert(::Type{Int}, a::Auto) = a.val
Base.convert(::Type{Date}, s::String) = Date(s)
Base.string(s::VarChar{N}) where N = s.str
Base.string(a::Auto) = a.val
Base.show(io::IO, a::Auto) = show(io, a.val)
Base.show(io::IO, s::VarChar{N}) where N = show(io, s.str)

convert_sql_type(::Type{T}) where T <: Union{Date, DateTime, Time} = "TIMESTAMP"
convert_sql_type(::Type{T}) where T <: AbstractString = "TEXT"
convert_sql_type(::Type{Int}) = "INT"
convert_sql_type(::Type{Auto}) = AUTO
convert_sql_type(::Type{T}) where T <: Number = "NUMERIC"
convert_sql_type(::Type{VarChar{N}}) where N = "VARCHAR($N)"
