import unittest
import pandas as pd

class DataframeTests(unittest.TestCase):
    DATA_1 = pd.DataFrame(
        {
            "day": ["day1", "day2", "day3"],
            "temperature": [10, 20, 30],
        }
    )
    DATA_2 = pd.DataFrame(
        {
            "day": ["day4", "day5", "day6"],
            "temperature": [40, 50, 60],
        }
    )

    def test_init_index_automatically(self):
        self.assertEqual(self.DATA_1.index.to_list(), [0, 1, 2])
        self.assertEqual(self.DATA_2.index.to_list(), [0, 1, 2])

    def test_concat_keep_original_indices(self):
        data = pd.concat([self.DATA_1, self.DATA_2])
        self.assertEqual(data.index.to_list(), [0, 1, 2, 0, 1, 2])

    def test_concat_ignore_original_indices(self):
        data = pd.concat([self.DATA_1, self.DATA_2], ignore_index=True)
        self.assertEqual(data.index.to_list(), [0, 1, 2, 3, 4, 5])

    def test_replace_with_dict(self):
        replaced = self.DATA_1.replace({"temperature": {10: 11, 30: 33}})
        self.assertEqual(list(self.DATA_1["temperature"]), [10, 20, 30])
        self.assertEqual(list(replaced["temperature"]), [11, 20, 33])

if __name__ == "__main__":
    unittest.main()
