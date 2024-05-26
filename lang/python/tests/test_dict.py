import unittest


class BuiltInFunctionTests(unittest.TestCase):
    SAMPLE_DATA = {"a": 0, "b": 1, "c": 2}

    def test_keys(self):
        self.assertEqual(list(self.SAMPLE_DATA.keys()), ["a", "b", "c"])

    def test_values(self):
        self.assertEqual(list(self.SAMPLE_DATA.values()), [0, 1, 2])

    def test_key_does_exist_in(self):
        self.assertTrue("a" in self.SAMPLE_DATA.keys())

    def test_key_does_not_exist_in(self):
        self.assertTrue("d" not in self.SAMPLE_DATA.keys())

    def test_make_dict_from_lists(self):
        keys = ["a", "b", "c"]
        values = [0, 1, 2]
        self.assertEqual(dict(zip(keys, values)), self.SAMPLE_DATA)

    def test_clear_content(self):
        data = self.SAMPLE_DATA.copy()
        data.clear()
        self.assertEqual(data, {})

    def test_initialize_given_values(self):
        keys = ["a", "b", "c"]
        self.assertEqual(dict.fromkeys(keys, 0), {"a": 0, "b": 0, "c": 0})

    def test_return_given_value_if_the_key_does_not_exist(self):
        self.assertEqual(self.SAMPLE_DATA.get("d", 3), 3)

    def test_not_return_given_value_if_the_key_does_not_exist(self):
        self.assertEqual(self.SAMPLE_DATA.get("c", 3), 2)

    def test_pop_by_key(self):
        data = self.SAMPLE_DATA.copy()
        self.assertEqual(data.pop("a"), 0)
        self.assertEqual(data, {"b": 1, "c": 2})

    def test_iterate_items(self):
        result = []
        for key, value in self.SAMPLE_DATA.items():
            result.append([key, value])
        self.assertEqual(result, [["a", 0], ["b", 1], ["c", 2]])


if __name__ == "__main__":
    unittest.main()
