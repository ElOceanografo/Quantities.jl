require("Quantities")
using Base.Test
using Quantities
include("./src/quantities.jl")
meter = Unit(Length, "m")
second = Unit(Time, "s")

g = Quantity(9.81, [meter, second], [1, -2])
# arr = QuantityArray([1:5], [meter, second], [1, -1])

println(g)