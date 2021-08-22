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

actual = filter(x -> isdivisible(x, by=2), data)
@assert [2, 4, 6, 8, 10] == actual
