"""
Convert julia operators to SQL `WHERE` clause operators

Parameters:
- `e::Expr`: A julia conditional expression

Returns:
A `String` containing the operator that can be used in a SQL `WHERE` clause.
"""
function whereclause_operators(e::Expr)
    if e.head == :call
        if e.args[1] == :(==)
            return " = "
        elseif e.args[1] == :(!)
            return "NOT "
        elseif e.args[1] == :(!=)
            return " != "
        elseif e.args[1] == :(>=)
            return " >= "
        elseif e.args[1] == :(<=)
            return " <= "
        elseif e.args[1] == :(>)
            return " > "
        elseif e.args[1] == :(<)
            return " < "
        elseif e.args[1] == :(in)
            return " IN "
        else
            error("Invalid where clause operator $(e.args[1])")
        end
    elseif e.head == :(&&)
        return " AND "
    elseif e.head == :(||)
        return " OR "
    else
        error("Unknown symbol $(e.head)")
    end
end

"""
Create a SQL `WHERE` clause from julia expression

Parameters:
- `fields::Array{Expr}`: An array whose elements are expressions
of the form `:(fieldname::T)`. This describes the table for the
`WHERE` clause.
- `e::Expr`: The julia conditional expression to convert. Note that
the LHS of each condition in the expression must be a fieldname in the
table.

Returns:
A `String` containing the `WHERE` clause.
"""
function whereclause(fields::Record, e::Expr)
    if e.head == :call && e.args[1] == :(!)
        op = whereclause_operators(e)
        arg = whereclause(fields, e.args[2])
        stmt = op * "( "
        return :($stmt * $arg * " )")
    elseif e.head == :call
        if !(e.args[2] isa Symbol)
            error("LHS can be an attribute name only")
        end

        lhs = e.args[2]

        if !haskey(fields.metadata, lhs)
            error("LHS attribute `$lhs` not found in struct")
        end

        if e.args[3] == :NULL
            op = e.args[1] == :(==) ? " IS " : " IS NOT "
            rhs = "NULL"
        else
            op = whereclause_operators(e)
            rhs = quotestring(fields.metadata[e.args[2]], e.args[3], e.args[1])
        end

        stmt = "`$lhs`$op"
        return :($stmt * string($rhs))

    elseif e.head == :(&&) || e.head == :(||)
        lhs = whereclause(fields, e.args[1])
        op = whereclause_operators(e)
        rhs = whereclause(fields, e.args[2])
        return :($lhs * $op * $rhs)
    else
        error("Unsupported conditional expression")
    end
end
