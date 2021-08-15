import random

nums = list(range(1, 11))
day_format = lambda num: f"day{num}"
expected = ['day1', 'day2', 'day3', 'day4', 'day5', 'day6', 'day7', 'day8', 'day9', 'day10']

# map

actual = []
for num in nums:
    actual.append(day_format(num))
assert expected == actual

actual = [day_format(num) for num in nums]
assert expected == actual

actual = list(map(lambda num: day_format(num), nums))
assert expected == actual


def add_prefix(num):
    return day_format(num)


actual = list(map(add_prefix, nums))
assert expected == actual

actual = [add_prefix(num) for num in nums]
assert expected == actual

# sort

random_days = random.sample(expected, len(expected))
assert expected != random_days

actual = sorted(random_days)
expected_as_string = ['day1', 'day10', 'day2', 'day3', 'day4', 'day5', 'day6', 'day7', 'day8', 'day9']
assert expected_as_string == actual

actual = sorted(random_days, key=lambda d: int(d.split('day')[1]))
assert expected == actual
