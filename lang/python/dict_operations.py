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
