module Quantities
using Lib

export Dimension, Unit, Quantity

import Base: show, convert, promote_rule

ADDITION_ERROR = "Addition not defined for dissimilar dimensions"
SUBTRACTION_ERROR = "Subtraction not defined for dissimilar dimensions"

immutable Dimension{T}
  mass::T
  length::T
  time::T
  charge::T
  temp::T
  amount::T
end

function Dimension(;args...)
    d = {:mass=>0, :length=>0, :time=>0, :charge=>0, :temp=>0, :amount=>0}
    for a in args
      d[a[1]] = a[2]
    end
    Dimension(d[:mass], d[:length], d[:time], d[:charge], d[:temp], d[:amount])
end

function Dimension{T}(a::Array{T,1}) 
  Dimension(a[1], a[2], a[3], a[4], a[5], a[6])
end

function powers(d::Dimension)
  [getfield(d, pow) for pow in names(d)]
end

function show(io::IO, d::Dimension)
  symbols = ['M', 'L', 'T', 'Q', 'Θ', '#']
  pow = powers(d)
  for i in 1:length(pow)
    if pow[i] != 0
      if pow[i] == 1
        print(io, symbols[i], " ")
      else
        print(io, symbols[i], "^", pow[i], " ")
      end
    end
  end
end

*(x::Dimension, y::Dimension) = Dimension(powers(x) + powers(y))
/(x::Dimension, y::Dimension) = Dimension(powers(x) - powers(y))
+(x::Dimension, y::Dimension) = x == y ? x : error(ADDITION_ERROR)
-(x::Dimension, y::Dimension) = x == y ? x : error(SUBTRACTION_ERROR)
^{T<:Real, U<:Integer}(x::Dimension{T}, b::U) = Dimension(powers(x) * b)
^{T<:Real, U<:Real}(x::Dimension{T}, b::U) = Dimension(powers(x) * b)
sqrt(x::Dimension) = x^0.5

Mass = Dimension(mass=1)
Length = Dimension(length=1)
Time = Dimension(time=1)
Charge = Dimension(charge=1)
Temperature = Dimension(temp=1)
Amount = Dimension(amount=1)



immutable Unit
  dimension::Dimension
  symbol::String
end

function show(io::IO, u::Unit)
  print(io, u.symbol)
end

*{T <: Number}(c::T, u::Unit) = Quantity(c, [u], [1])
*{T <: Number}(u::Unit, c::T) = c * u
/{T <: Number}(u::Unit, c::T) = Quantity(1/c, [u], [1])
/{T <: Number}(c::T, u::Unit) = Quantity(c, [u], [-1])
/(x::Unit, y::Unit) = Quantity(1, [x, y], [1, -1])
*(x::Unit, y::Unit) = x == y ? Quantity(1, [x], [2]) : Quantity(1, [x, y], [1, 1])
^{T <: Number}(u::Unit, c::T) = Quantity(1, [u], [c])


immutable Quantity{T<:Number, N<:Number}
  value::T
  units::Array{Unit, 1}
  powers::Array{N, 1}
end

function Quantity{T<:Number, N<:Number}(value::T, units::Array{Unit, 1}, powers::Array{N, 1})
  units = units[powers .!= 0]
  powers = powers[powers .!= 0]
  if ! all(powers .== powers[1])
    units = units[sortperm(powers)]
    powers = sort(powers)
  end
  Quantity{T, N}(value, reverse(units), reverse(powers))  
end


function Quantity{T}(value::T, units::Array{None, 1}, powers::Array{None, 1})
  Quantity(value, Array(Unit, 0), Array(Int, 0))
end


function show(io::IO, q::Quantity)
  print(q.value)
  for i=1:length(q.units)
    if q.powers[i] == 1
      print(" ", q.units[i])
    else
      print(" ", q.units[i], "^", q.powers[i])
    end
  end
end

function dimension(q::Quantity)
  prod([q.units[i].dimension^q.powers[i] for i=1:length(q.units)])
end

function simplify(q::Quantity)
  unique_units = unique(q.units)
  unique_powers = zeros(Int, length(unique_units))
  for i = 1:length(unique_units)
    unique_powers[i] = sum(q.powers[q.units .== unique_units[i]])
  end
  return Quantity(q.value, unique_units, unique_powers)
end


*{T<:Number}(c::T, q::Quantity) = Quantity(q.value * c, q.units, q.powers)
.*{T<:Number}(c::T, q::Quantity) = Quantity(q.value * c, q.units, q.powers)
*{T<:Number}(q::Quantity, c::T) = c * q
.*{T<:Number}(q::Quantity, c::T) = c * q
*(q::Quantity, u::Unit) = q * Quantity(1, [u], [1])
*(u::Unit, q::Quantity) = q * Quantity(1, [u], [1])
/{T<:Number}(q::Quantity, c::T) = Quantity(q.value / c, q.units, q.powers)
/{T<:Number}(c::T, q::Quantity) = Quantity(c / q.value, q.units, -1 .* q.powers)
/(q::Quantity, u::Unit) = q / Quantity(1, [u], [1])
/(u::Unit, q::Quantity) = Quantity(1, [u], [1]) / q
^(q::Quantity, c::Integer) = Quantity(q.value^c, q.units, q.powers.*c)
^{T<:Number}(q::Quantity, c::T) = Quantity(q.value^c, q.units, q.powers.*c)

function +(x::Quantity, y::Quantity)
  if dimension(x) != dimension(y)
    error(ADDITION_ERROR)
  elseif Set(x.units) != Set(y.units)
    error("Can't convert units yet")
  else
    Quantity(x.value + y.value, x.units, x.powers)
  end
end

function -(x::Quantity, y::Quantity)
  if dimension(x) != dimension(y)
    error(SUBTRACTION_ERROR)
  elseif Set(x.units) != Set(y.units)
    error("Can't convert units yet")
  else
    Quantity(x.value - y.value, x.units, x.powers)
  end
end

function *{Tx, Nx, Ty, Ny}(x::Quantity{Tx, Nx}, y::Quantity{Ty, Ny})
  value = x.value * y.value
  units = [x.units, y.units]
  powers = [x.powers, y.powers]
  return simplify(Quantity(value, units, powers))
end


function /{Tx, Nx, Ty, Ny}(x::Quantity{Tx, Nx}, y::Quantity{Ty, Ny})
  value = x.value / y.value
  units = [x.units, y.units]
  powers = [x.powers, -y.powers]
  return simplify(Quantity(value, units, powers))
end

# type QuantityArray
#   values
#   units
#   powers
# end

# function show(io::IO, x::QuantityArray)
#   println(x.values)
#   println("Units: ")
#   for i=1:length(x.units)
#     if x.powers[i] == 1
#       print(" ", x.units[i])
#     else
#       print(" ", x.units[i], "^", x.powers[i])
#     end
#   end
# end

# .*{T<:Number}(c::T, x::QuantityArray) = QuantityArray(c .* x.values, x.units, x.powers)
# .*{T<:Number}(x::QuantityArray, c::T) = c .* x
# *{T<:Number}(x::QuantityArray, c::T) = c .* x
# *{T<:Number}(c::T, x::QuantityArray) = c .* x
# /{T<:Number}(c::T, x::QuantityArray) = QuantityArray(c / x.values, x.units, x.powers)
# /{T<:Number}(x::QuantityArray, c::T) = x * (1/c)

# function show{T, N, d}(io::IO, x::Array{Quantity{T, N}, d})
  
# end


end # module