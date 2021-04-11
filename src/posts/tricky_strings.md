---
title: The Surprising Difficulty of a Simple String Problem
date: 2021-02-15
tags:
- beginner
- python
- python3
- story
---

The Setup
---------

This story revolves around a feature I added to [a recent side
project](https://github.com/eZanmoto/comment_style), one which checks formatting
of code comments based on opinionated rules. The feature was to add a heuristic
check to see if a comment occurred after some code, because one of these rules
is that comments should be on their own line. However, the main situation we're
trying to avoid with this check is accidentally flagging a line as containing a
trailing comment when the comment marker actually occurs within a string:

```python
!snippet code/tricky_strings.py 5 2 DjFd4wPGlhOmrFlLPENwYZcVldg=
```

Thus began my effort to reach the current implementation of
`is_likely_in_str()`:

```python
!snippet code/tricky_strings.py 8 6 3DibHemVqAt044yHGACx37FoMto=
```

This seemed to have a fairly trivial implementation to start off with:

```python
!snippet code/tricky_strings.py 18 6 ZmjCVmlFfZ1iPjDww0W/7BXMFTA=
```

And it worked! It purposefully doesn't handle some obvious cases such as comment
markers in multi-line strings, but running this heuristic on the moderately
large codebase that I was testing with actually yielded zero false positives.

That was a nice start, but the main issue I wanted to account for for the future
was escaped delimiters:

```c
char* eg = "Quoting \"http://localhost\" in C would be a bad idea here";
```

Handling this was a little trickier than I expected, so I decided to do up some
unit tests to experiment with different implementations.

Simple Unit Testing
-------------------

Writing up the unit tests was a straightforward affair. I opted for a simple,
table-driven approach where I would have a source string paired with a list of
booleans, where each boolean represented whether `is_likely_in_str()` should
return `True` for that index:

```python
!snippet code/tricky_strings.py 27 5 /LMMX7rvc6CvVuijOYHYjh8Vfao=
```

Straightforward and simple, but borderline unusable; writing such definitions by
hand would be tedious and error prone, and figuring out what those lists should
look like in the case of a bug would be likely to just add oil to a flame. Even
a more compact representation doesn't quite do it, since the misalignment
between boundary indices versus actual indices still obscures the intent:

```python
!snippet code/tricky_strings.py 36 4 R241w0XUqgnqTdNZ3gQtSn/5C9I=
```

So... Abstract it! We can process the test case with a function to produce our
source string and our list of target booleans. With that we can make it very
clear at a glance what sections we expect to be inside a string and what ones
should be outside:

```python
!snippet code/tricky_strings.py 43 1 +1wEbkDqdByO6OYwG39EtTg/Nlg=
```

And here we arrive at the first simple string problem that turned out to be
surprisingly difficult:

```python
!snippet code/tricky_strings.py 46 6 Qtpm3CNsMOO2wNljSfpf1nvaJcs=
```

The First Hurdle
----------------

Due to the representation, it seemed straightforward that I'd just toggle the
state of `in_str` between each section and append a copy of the state for each
character. I started with the boundary condition of `[False]` since it's assumed
that a line starts off by not being within a string:

```python
!snippet code/tricky_strings.py 56 8 FuLGMzwXkuB3uvO9dAy5Y+RMsKI=
```

Ah, but how naive programming at 9:00 PM on a Thursday can make you when you're
no longer in college:

```python
!snippet code/tricky_strings.py 65 4 cG7TqJYWlP3rSpDcwFpYek14rH8=
```

Moreover, `is_in_strs(["x = '", "", "'"])` will give us all `False`s! So I
focused on this case with the empty string. It became apparent that there were a
few subtleties to this problem that I should take into consideration:

* In this representation some character boundaries theoretically get represented
  twice. For instance, in `["x = '", "1"]`, the boundary between `'` and `1`
  gets represented once by the end of the first substring and again by the start
  of the second substring.
* There is a bit of asymmetry in how delimiters are handled. In the
  `["x = '", "abc", "'"]` sequence the first `'` signals that a change in state
  occurs after `'`, but the second `'` signals that that change should have
  occurred before the `'`. Changing the representation to something like
  `["x = ", "'abc", "'"]` may have helped make things more consistent for
  processing, but at the cost of being subjectively less readable.

The next iteration focused on the issue with the empty substring:

```python
!snippet code/tricky_strings.py 81 6 wP/XM+7KXOyfvEWV9Zdizn50Rpo=
```

One small improvement here was simplifying
`for char in substr: in_strs.append(in_str)` into
`in_strs += [in_str] * len(substr)`, but other than that this solution didn't
present much progress - it handled the specific case of an empty substring
(poorly), but nothing else.

So, I tried breaking the problem down further on paper.

<!-- markdownlint-disable fenced-code-language -->
```
  _________   _   _
  x   =   '   a   '       len=5
F   F   F   T   T   F
```
<!-- markdownlint-enable -->

I represented the desired output for this in sequences of `T`s and `F`s. The
above would be `Fx3 + Tx2 + Fx1` for a string with substrings of length `3 1 1`,
and the earlier example with an empty string of lengths `3 0 1` would give
`Fx3 + Tx1 + Fx1`. I then separated out the boundary values in the target
output, and plotted out different examples, such as the following:

<!-- markdownlint-disable fenced-code-language -->
```
_____   _        3     0     1
x = '   ' = F + Fx2 + Tx1 + Fx0 + F

_____ _ _        3     1     1
x = ' a ' = F + Fx2 + Tx2 + Fx0 + F

_ _____ _____ _____ _        1     3     3     3     1
' x = 1 ' = ` a = 2 ` = F + Fx0 + Tx4 + Fx2 + Tx4 + Fx0 + F
```
<!-- markdownlint-enable -->

At this point I just eyeballed the different examples to see if a pattern
emerged. Mercifully it did, and it boiled down to: "if a substring represents a
string, add 1 to the number of `T`s it has, otherwise subtract 1 from its `F`s."
This gave me:

```python
!snippet code/tricky_strings.py 93 8 C7yFfnhwJY0QfbCpn16rSF32q9I=
```

Fairly straightforward, but luckily a test alerted me to an edge case that I
overlooked:

```python
!snippet code/tricky_strings.py 102 4 cmhdcHK52Pecmyq2mz+HD4Ie2uM=
```

I'll admit it though; my fix for this was just the first thing to come to my
head that I thought would get tests passing:

```python
!snippet code/tricky_strings.py 116 3 khOUQ7ICPH8iK8Ecg4k7vhDm2qw=
```

Thankfully (or, suspiciously?) this passed all the tests. I ignored the
"seat-of-the-pants" approach that I used to arrive at this answer for now. [The
implementation that I actually added to my
project](https://github.com/eZanmoto/comment_style/blob/8df5dede0400591423afcc980a0f9123f98a16ba/test_comment_style.py#L60-L91)
also contained some special string splitting logic to let me mark expected
substrings in a more readable fashion. With that, I was finally able to make a
readable list of test cases with which to validate my `is_likely_in_str()`
function (the trailing comments here are only presented for clarification and
aren't in the actual source code!):

```python
!snippet code/tricky_strings.py 122 4 0yT/GSwsAaO35kOHquJKthx/i+Q=
```

Out of the Woods?
-----------------

With the unit tests finally giving results that could be manually verified, I
moved on to the more straightforward implementation of the original
`is_likely_in_str()` function:

```python
!snippet code/tricky_strings.py 127 18 XAGS1qPO7LMj45i+ozRIZpEnvos=
```

I felt this to be a fairly neat implementation, and the logic matched my
intuition. There wasn't even much added to account for escaping - if we find our
opening delimiter then we make sure that it isn't escaped, and if it is escaped
then we further make sure that the escape isn't escaped. Makes sense and reads
logically, the only real problem with it is that it doesn't work.

Thankfully I had a nice little suite of test cases to remind me of how brazen it
was of me to think that I could write a line-processing function on my first
try. One test case was very helpful in pointing out the fact that I had
completely overlooked tracking of the current `escaped` state in the loop:

```python
!snippet code/tricky_strings.py 150 1 JY2pbuEWI/Xr/UQOjnqTYbth0EY=
```

Ignoring the escaping that was added for Python's sake, this string is stored as
`x = '\\\'`. In this test case, the first pair of backslashes should "cancel
out", and the third backslash should escape the final `'`. As such, the string
is never closed, and so the final boundary index of this string should be
considered to be "in a string". However, the current `is_likely_in_str()`
implementation gives us the opposite result in this case. So the next thing is
to actually keep a record of whether the current character is escaped or not:

```python
!snippet code/tricky_strings.py 157 20 408i3SHRwgpgwYB/qLR3dZ7ArA8=
```

Three more failures...

```python
!snippet code/tricky_strings.py 179 3 Vr4M/JBY8IFH8fMNqr9fRl0kfLY=
```

The end of all of these test cases should be considered to be in a string, but
each returned `False`. Naturally so, as this implementation was only checking
whether the current character was `\` after it had already confirmed that it was
a string delimiter.

Also, my notes start giving up somewhat around here. I guess it's difficult to
keep a log of how badly you're being beaten by what could conceivably appear in
the warm-up round of a programming competition. But there is a happy ending to
this story in that, as bruised as my ego was, I did finally arrive at the simple
solution that I had set out to achieve, by taking the escape check out of the
delimiter check:

```python
!snippet code/tricky_strings.py 210 18 u4uS0nlcijECPFrFv8FHbp06o5A=
```

Finally, my tests were figuratively green. The only thing left to do was to
write a blog post to lend a little inspiration to the next generation - to say,
yes, if you study hard at college, work at a variety of software development
companies and invest significant portions of your free time working on hobby
code and learning new programming languages and technologies, you too can spend
the better part of a week failing to write 20-line string processing function
for a hobby project.

But that's not to say that I didn't have a lot of fun doing it.

Postscript
----------

### Why `is_in_strs()` works

The last bit of experimentation on `is_in_strs()` seemed to result in a somewhat
magical solution that "just worked" according to my test cases. That's fine
during research but it's always better to know why code is working rather than
leaving it up to chance. Examining this implementation a bit more closely, the
logic of why it works follows quite naturally.

First of all, the initial `False` we added to our result list accounts for the
fact that we're working with boundary indices and not regular indices, so we
want to end up with `len(str) + 1` elements in our list of booleans.

Second of all, this procedure effectively performs the string balancing that was
observed earlier. That is, if we had an input like `["x = ", "'abc", "'"]`, then
the final `is_in_strs()` could be simplified to the following:

```python
!snippet code/tricky_strings.py 231 7 XL4JaEE++1UOAf38Ixyb5sB+dOc=
```

Or even the following, at the expense of readability:

```python
!snippet code/tricky_strings.py 242 3 Q5W0FOeSznWo9EMhSRHYm205Xqg=
```

If we then consider the desired representation (`["x = '", "abc", "'"]`) in
relation to this "logical" layout, we can think of it as moving the opening
delimiter from the "inside a string" substring to the "outside a string" one. At
this point we account for that fact by modifying the length of the different
substrings. We also append an extra `False` in the case that we end outside a
string (confusingly checked using `if in_str:` in the given solution), because
we'll have removed the final delimiter from the length of the string and this
will need to be accounted for.

### Testing `is_in_strs()`

The `is_in_strs()` function that I was going to use for testing ended up being
surprisingly complicated, so realistically it needed its own tests. I used a
small set of [doctest](https://docs.python.org/3/library/doctest.html)s for
this.
