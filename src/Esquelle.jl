module Esquelle

export @record, @select, setconnection, @insert, @update, @create, @delete, @drop

using MacroTools
using Dates

include("util.jl")

struct Record
    metadata::Dict{Symbol, Union{Symbol, Expr}}
    fieldnames::Array{Symbol}
    pkey::Array{Symbol}
    auto::Union{Symbol, Nothing}
    ukey::Array{Symbol}
end

const FIELDS_DICT = Dict{Symbol, Record}()
CONN = nothing
QUERY_FUNC = nothing
EXECUTE_FUNC = nothing

include("connection.jl")
include("record.jl")
include("getfields.jl")

include("whereclause.jl")
include("select.jl")
include("insert.jl")
include("update.jl")
include("create.jl")
include("delete.jl")
include("drop.jl")

#TODO: Add @upsert

end  # module
