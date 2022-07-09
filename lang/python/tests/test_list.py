import unittest
import random
import itertools

class ListTests(unittest.TestCase):
    NUMS = list(range(1, 11))
    DAYS = [
        "day1", "day2", "day3", "day4", "day5",
        "day6", "day7", "day8", "day9", "day10"
    ]

    def test_append(self):
        days = []
        for num in self.NUMS:
            days.append(f"day{num}")
        self.assertEqual(days, self.DAYS)

    def test_map(self):
        self.assertEqual(
            list(map(lambda num: f"day{num}", self.NUMS)),
            self.DAYS
        )

    def test_list_comprehension(self):
        self.assertEqual(
            [f"day{num}" for num in self.NUMS],
            self.DAYS
        )

    def test_shuffle_mutable(self):
        data = self.DAYS.copy()
        random.shuffle(data)
        self.assertNotEqual(data, self.DAYS)

    def test_shuffle_immutable(self):
        data = self.DAYS.copy()
        shuffled_data = random.sample(data, len(data))
        self.assertEqual(data, self.DAYS)
        self.assertNotEqual(shuffled_data, self.DAYS)

    def test_sort_mutable(self):
        data = self.DAYS.copy()
        random.shuffle(data)
        data.sort()
        self.assertEqual(
            data,
            [
                "day1", "day10", "day2", "day3", "day4",
                "day5", "day6", "day7", "day8", "day9"
            ]
        )

    def test_sort_immutable(self):
        data = self.DAYS.copy()
        random.shuffle(data)
        sorted_data = sorted(data)
        self.assertEqual(
            sorted_data,
            [
                "day1", "day10", "day2", "day3", "day4",
                "day5", "day6", "day7", "day8", "day9"
            ]
        )

    def extract_day_number(self, day_id):
        return int(day_id.split("day")[1])

    def test_sort_with_lambda(self):
        data = self.DAYS.copy()
        random.shuffle(data)
        sorted_data = sorted(data, key=lambda day_id: self.extract_day_number(day_id))
        self.assertEqual(sorted_data, self.DAYS)

    def test_sort_and_get_index(self):
        data = [100, 200, 10, 300]
        expected = [2, 0, 1, 3]
        value_index_tuples = [(v, i) for i, v in enumerate(data)]
        self.assertEqual(value_index_tuples, [(100, 0), (200, 1), (10, 2), (300, 3)])

        actual = list(
            map(
                lambda t: t[1], # extract indexes
                sorted(
                    value_index_tuples,
                    key=lambda t: t[0] # sort by value
                )
            )
        )
        self.assertEqual(actual, expected)

    def test_filter(self):
        expected = ["day8", "day9", "day10"]

        # use list comprehension
        actual = [
            day_id for day_id in self.DAYS
            if self.extract_day_number(day_id) > 7
        ]
        self.assertEqual(actual, expected)

        # use filter function
        actual = list(
            filter(
                lambda day_id: self.extract_day_number(day_id) > 7,
                self.DAYS
            )
        )
        self.assertEqual(actual, expected)

    def test_flatten(self):
        data = [[1, 2], [3, 4, 5, 6], [7]]
        expected = [1, 2, 3, 4, 5, 6, 7]
        self.assertEqual(
            list(itertools.chain.from_iterable(data)),
            expected
        )

if __name__ == "__main__":
    unittest.main()
