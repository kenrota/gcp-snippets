import pandas as pd

temperatures_1 = pd.DataFrame(
    {
        'day': ['day1', 'day2', 'day3'],
        'temperature': [10, 20, 30],
    }
)

temperatures_2 = pd.DataFrame(
    {
        'day': ['day4', 'day5', 'day6'],
        'temperature': [40, 50, 60],
    }
)

# keep original indices
temperatures = pd.concat([temperatures_1, temperatures_2])
assert [0, 1, 2, 0, 1, 2] == temperatures.index.to_list()

# ignore original indices
temperatures = pd.concat([temperatures_1, temperatures_2], ignore_index=True)
assert [0, 1, 2, 3, 4, 5] == temperatures.index.to_list()
