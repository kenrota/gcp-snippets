import unittest


class BuiltInFunctionTests(unittest.TestCase):
    def test_join(self):
        self.assertEqual(",".join(["a", "b", "c"]), "a,b,c")

    def test_zip(self):
        values_1 = ["a", "b", "c"]
        values_2 = [0, 1, 2]
        self.assertEqual(list(zip(values_1, values_2)), [("a", 0), ("b", 1), ("c", 2)])

        # Ignore extra value
        extra = values_1 + ["d"]
        self.assertEqual(list(zip(extra, values_2)), [("a", 0), ("b", 1), ("c", 2)])


if __name__ == "__main__":
    unittest.main()
