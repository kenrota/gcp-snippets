import random

nums = list(range(1, 11))
day_format = lambda num: f"day{num}"
day_ids = ['day1', 'day2', 'day3', 'day4', 'day5', 'day6', 'day7', 'day8', 'day9', 'day10']
expected = day_ids.copy()

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

# shuffle

data_to_shuffle = day_ids.copy()
data_before_shuffling = data_to_shuffle.copy()
random.shuffle(data_to_shuffle) # mutable operation
assert data_before_shuffling != data_to_shuffle

data_to_shuffle = day_ids.copy()
data_before_shuffling = data_to_shuffle.copy()
actual = random.sample(data_to_shuffle, len(data_to_shuffle)) # immutable operation
assert data_before_shuffling == data_to_shuffle
assert data_before_shuffling != actual

# sort

random_day_ids = random.sample(day_ids, len(day_ids))
assert expected != random_day_ids

actual = sorted(random_day_ids)
expected_as_string = ['day1', 'day10', 'day2', 'day3', 'day4', 'day5', 'day6', 'day7', 'day8', 'day9']
assert expected_as_string == actual


def extract_day_number(day_id):
    return int(day_id.split('day')[1])


actual = sorted(random_day_ids, key=lambda day_id: extract_day_number(day_id))
assert expected == actual
