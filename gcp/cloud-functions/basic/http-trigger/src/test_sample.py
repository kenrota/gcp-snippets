# pytestのサンプル
# https://github.com/pytest-dev/pytest/blob/main/README.rst


def inc(x):
    return x + 1


def test_answer():
    assert inc(4) == 5
