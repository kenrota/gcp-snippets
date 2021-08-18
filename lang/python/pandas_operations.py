import pandas as pd

temperatures_1 = pd.DataFrame(
    {
        'day': ['day1', 'day2', 'day3'],
        'temperature': [10, 20, 30],
    }
)
assert [0, 1, 2] == temperatures_1.index.to_list()

temperatures_2 = pd.DataFrame(
    {
        'day': ['day4', 'day5', 'day6'],
        'temperature': [40, 50, 60],
    }
)
assert [0, 1, 2] == temperatures_1.index.to_list()


# append()

# Ignore original indices
temperatures = temperatures_1.append(temperatures_2, ignore_index=True)
assert [0, 1, 2] == temperatures_1.index.to_list()
assert [0, 1, 2, 3, 4, 5] == temperatures.index.to_list()


# concat()

# Keep original indices
temperatures = pd.concat([temperatures_1, temperatures_2])
assert [0, 1, 2, 0, 1, 2] == temperatures.index.to_list()

# Ignore original indices
temperatures = pd.concat([temperatures_1, temperatures_2], ignore_index=True)
assert [0, 1, 2, 3, 4, 5] == temperatures.index.to_list()
