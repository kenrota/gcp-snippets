data = Vector(1:10)

# Filter with anonymous function

actual = filter(x -> x % 2 == 0, data)
@assert [2, 4, 6, 8, 10] == actual

# Filter with user define function

function isdivisible(num::Int; by::Int)::Bool
    num % by == 0
end

@assert !isdivisible(1, by=3)
@assert isdivisible(3, by=3)

actual = filter(x -> isdivisible(x, by=3), data)
@assert [3, 6, 9] == actual

# Map with user define function

function addprefix(name::String)::String
    "example_$name"
end

five_divisibles = filter(x -> isdivisible(x, by=5), data)
actual = map(x -> addprefix(string(x)), five_divisibles)
@assert ["example_5", "example_10"] == actual

# Shuffle and sort data

using Random
Random.seed!(0)
expected_shuffle_data = [8, 2, 5, 4, 7, 9, 10, 6, 3, 1]

original_data = copy(data)
shuffled_data = shuffle(data)
@assert original_data == data # immutable
@assert expected_shuffle_data == shuffled_data

original_data = copy(shuffled_data)
sorted_data = sort(shuffled_data)
@assert original_data == shuffled_data # immutable
@assert data == sorted_data
