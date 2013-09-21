
# require("Quantities")
# using Quantites

tests_to_run = ["test/basic_tests.jl"]

println("Running tests:")

for test in tests_to_run
	println((" * $(test)"))
	include(test)
end
