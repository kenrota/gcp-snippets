data = { 'a': 0, 'b': 1, 'c': 2 }

assert ['a', 'b', 'c'] == list(data.keys())
assert [0, 1, 2] == list(data.values())
assert 'a' in data.keys()
assert 'd' not in data.keys()
assert 'a,b,c' == ','.join(list(data.keys()))
assert '0,1,2' == ','.join(map(lambda d: str(d), data.values()))

keys = ['a', 'b', 'c', 'd'] # ignore extra key
values = [0, 1, 2]
assert data == dict(zip(keys, values))

keys = ['a', 'b', 'c']
values = [0, 1, 2, 3] # ignore extra value
assert data == dict(zip(keys, values))

copy = data.copy()
copy.clear()
assert {} == copy

assert { 'a': 0, 'b': 0, 'c': 0 } == dict.fromkeys(keys, 0) # initialize by given value
assert 3 == data.get('d', 3) # return given value if given key does not exist
assert 2 == data.get('c', 3) # not return given value if given key exists

copy = data.copy()
assert 0 == copy.pop('a')
assert { 'b': 1, 'c': 2 } == copy

result = []
for key, value in data.items():
    result.append([key, value])
assert [['a', 0], ['b', 1], ['c', 2]] == result
