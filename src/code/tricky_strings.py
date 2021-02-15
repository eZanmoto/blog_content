# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

x = "# This is fine"
x = "" # This is not

def is_likely_in_str(line, index):
    """
        Return `True` if the `index` is likely to be within a string,
        according to the handling of strings in typical programming
        languages. Index `0` is considered to be outside a string.
    """
    pass

is_likely_in_str('', 0)

def is_likely_in_str(line, i):
    cur_str_char = None
    for char in line[:i]:
        if char in ['\'', '"', '`']:
            cur_str_char = char if cur_str_char is None else None
    return cur_str_char is None

is_likely_in_str('', 0)

TESTS = [
    (
        "x = 'abc'",
        [False, False, False, False, False, True, True, True, True, False],
    ),
    # ...
]

TESTS = [
    (
        "x = 'abc'",
        "0000011110",
    ),
]

TESTS = [
    ["x = '", "abc", "'"],
]

def is_in_strs(substrs):
    """
        Return a list containing a boolean for each character boundary in
        `''.join(substrs)`, where each element is `True` if it's "inside a
        string" and `False` otherwise.
    """
    pass

is_in_strs([])

def is_in_strs(substrs):
    in_str = False
    in_strs = [in_str]
    for substr in substrs:
        for char in substr:
            in_strs.append(in_str)
        in_str = not in_str
    return in_strs

is_in_strs(["x = '", "abc", "'"])
# We get this: 0000001110
# But we want: 0000011110
#                   ^

def assert_eq(a, b):
    assert a == b, '{} != {}'.format(a, b)

def to_bstring(vs):
    return ''.join(['1' if v else '0' for v in vs])

assert_eq(to_bstring(is_in_strs(["x = '", "abc", "'"])), "0000001110")
assert_eq(to_bstring(is_in_strs(["x = '", "", "'"])), "0000000")

def is_in_strs(substrs):
    in_str = False
    in_strs = [in_str]
    for substr in substrs:
        if len(substr) == 0:
            in_strs[-1] = not in_strs[-1]
        else:
            in_strs += [in_str] * len(substr)
        in_str = not in_str
    return in_strs

assert_eq(to_bstring(is_in_strs(["x = '", "abc", "'"])), "0000001110")
assert_eq(to_bstring(is_in_strs(["x = '", "", "'"])), "0000010")

def is_in_strs(substrs):
    in_str = False
    in_strs = [in_str]
    for substr in substrs:
        mod = 1 if in_str else -1
        in_strs += [in_str] * (len(substr) + mod)
        in_str = not in_str
    return in_strs

is_in_strs(["x = '"])
# We get this: 00000
# But we want: 000001
#                   ^

assert_eq(to_bstring(is_in_strs(["x = '"])), "00000")

def is_in_strs(substrs):
    in_str = False
    in_strs = [in_str]
    for substr in substrs:
        mod = 1 if in_str else -1
        in_strs += [in_str] * (len(substr) + mod)
        in_str = not in_str
    if in_str:
        in_strs += [False]
    return in_strs

# assert_eq(to_bstring(is_in_strs(["x = '"])), "00001")

"x = '(abc)'"   # `abc`  is in a string
"x = '(ab)'c"   # `ab`   is in a string
"x = '(ab\'c"   # `ab'c` is in a string
"x = '(ab\\)'c" # `ab\`  is in a string

def is_likely_in_str(line, index):
    cur_str_char = None
    in_str = lambda: cur_str_char is not None

    for i, char in enumerate(line[:index]):
        if char in ['\'', '"', '`']:
            if in_str():
                escaped = i > 0 and line[i-1] == '\\'
                double_escaped = i > 1 and line[i-2] == '\\'
                if char == cur_str_char:
                    if escaped:
                        if double_escaped:
                            cur_str_char = None
                    else:
                        cur_str_char = None
            else:
                cur_str_char = char
    return in_str()

TESTS = [
    "x = ''",
    "x = '\\'",
    "x = '\\\\'",
    "x = '\\\\\\'",
]
assert_eq(is_likely_in_str(TESTS[0], len(TESTS[0])), False)
assert_eq(is_likely_in_str(TESTS[1], len(TESTS[1])), True)
assert_eq(is_likely_in_str(TESTS[2], len(TESTS[2])), False)
assert_eq(is_likely_in_str(TESTS[3], len(TESTS[3])), False)

def is_likely_in_str(line, index):
    cur_str_char = None
    in_str = lambda: cur_str_char is not None
    escaped = False

    for i, char in enumerate(line[:index]):
        if char in ['\'', '"', '`']:
            if in_str():
                if char == cur_str_char and not escaped:
                    cur_str_char = None

                if char == '\\':
                    escaped = not escaped
                else:
                    escaped = False
            else:
                cur_str_char = char
                escaped = False

    return in_str()

TESTS = [
    "x = '\\'",
    "x = '\n\\'",
    "x = '\\\\\\'",
]
assert_eq(is_likely_in_str(TESTS[0], len(TESTS[0])), False)
assert_eq(is_likely_in_str(TESTS[1], len(TESTS[1])), False)
assert_eq(is_likely_in_str(TESTS[2], len(TESTS[2])), False)

def is_likely_in_str(line, index):
    cur_str_char = None
    in_str = lambda: cur_str_char is not None
    escaped = False

    for i, char in enumerate(line[:index]):
        if in_str():
            if char == '\\':
                escaped = not escaped
            else:
                escaped = False
        else:
            escaped = False

        if char in ['\'', '"', '`']:
            if in_str():
                if char == cur_str_char and not escaped:
                    cur_str_char = None
            else:
                cur_str_char = char

    return in_str()

def is_likely_in_str(line, index):
    cur_str_char = None
    escaped = False

    def in_str():
        return cur_str_char is not None

    for i, char in enumerate(line[:index]):
        if char in ['\'', '"', '`']:
            if in_str():
                if char == cur_str_char and not escaped:
                    cur_str_char = None
            else:
                cur_str_char = char

        escaped = in_str() and char == '\\' and not escaped

    return in_str()

assert_eq(is_likely_in_str("x = '\\\\\\'", 9), True)

def is_in_strs(substrs):
    in_str = False
    in_strs = [in_str]
    for substr in substrs:
        in_strs += [in_str] * len(substr)
        in_str = not in_str
    return in_strs

x = ["x = ", "'abc", "'"]
assert_eq(to_bstring(is_in_strs(x)), "0000011110")

def is_in_strs(substrs):
    groups = [[i % 2 == 1] * len(s) for i, s in enumerate(substrs)]
    return [False] + [v for group in groups for v in group]

x = ["x = ", "'abc", "'"]
assert_eq(to_bstring(is_in_strs(x)), "0000011110")
