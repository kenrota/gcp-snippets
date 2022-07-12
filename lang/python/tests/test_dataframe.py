import unittest
import pandas as pd

class DataframeTests(unittest.TestCase):
    TEMPERATURES_1 = pd.DataFrame(
        {
            'day': ['day1', 'day2', 'day3'],
            'temperature': [10, 20, 30],
        }
    )
    TEMPERATURES_2 = pd.DataFrame(
        {
            'day': ['day4', 'day5', 'day6'],
            'temperature': [40, 50, 60],
        }
    )

    def test_init_index_automatically(self):
        self.assertEqual(self.TEMPERATURES_1.index.to_list(), [0, 1, 2])
        self.assertEqual(self.TEMPERATURES_2.index.to_list(), [0, 1, 2])

    def test_concat_keep_original_indices(self):
        temperatures = pd.concat([self.TEMPERATURES_1, self.TEMPERATURES_2])
        self.assertEqual(temperatures.index.to_list(), [0, 1, 2, 0, 1, 2])

    def test_concat_ignore_original_indices(self):
        temperatures = pd.concat([self.TEMPERATURES_1, self.TEMPERATURES_2], ignore_index=True)
        self.assertEqual(temperatures.index.to_list(), [0, 1, 2, 3, 4, 5])

if __name__ == "__main__":
    unittest.main()
