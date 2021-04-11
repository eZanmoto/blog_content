# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 <file-path> [--skip-checksum]` outputs all lines of the file at
# `file-path` but with all `!snippet` declarations replaced by the appropriate
# snippets.
#
# Snippet declarations have the following format:
#
#     !snippet file_path start_line num_lines sha1
#
# * `file_path` is evaluated relative to the current working directory of the
#   script execution.
# * `start_line` is a 1-based inclusive line number.
# * `num_lines` is a positive number of lines to include, starting at
#   `start_line`.
# * `sha1` is a SHA1 hash of the contents of the snippet. This is used to
#   ensure reproducible output, so that an alert will be triggered if the
#   contents of the snippet change. This check can be skipped using
#   `--skip-checksum`.

import base64
import hashlib
import sys


def main(argv):
    if len(argv) > 3:
        fatal("usage: {} <file-path> [--skip-checksum]".format(argv[0]))

    file_path = argv[1]

    skip_checksum = False
    if len(argv) > 2:
        if argv[2] != '--skip-checksum':
            fatal("usage: {} <file-path> [--skip-checksum]".format(argv[0]))
        skip_checksum = True

    try:
        with open(file_path) as f:
            err = print_lines(f, skip_checksum)
    except FileNotFoundError:
        fatal("couldn't open '{}': file not found".format(file_path))

    if err is not None:
        (line_num, err_msg) = err
        fatal("{}:{}: {}".format(file_path, line_num, err_msg))


def fatal(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


def print_lines(file_stream, skip_checksum):
    cur_line_num = 1
    for line in file_stream:
        output = line
        if line.startswith(MARKER):
            output, err_msg = get_snippet(
                line[len(MARKER):].rstrip('\n'),
                skip_checksum,
            )
            if err_msg is not None:
                return (cur_line_num, err_msg)
        print(output, end='')
        cur_line_num += 1
    return None


MARKER = '!snippet '


def get_snippet(line, skip_checksum):
    defn, err_msg = parse_snippet_line(line)
    if err_msg is not None:
        return None, "couldn't parse snippet line: " + err_msg

    fpath, start_line, num_lines, exp_sha1 = defn

    snippet, err_msg = read_snippet(fpath, start_line, num_lines)
    if err_msg is not None:
        return None, "couldn't get snippet: " + err_msg

    if not skip_checksum:
        snippet_bytes = bytes(snippet, 'ascii')
        sha1_bytes = hashlib.sha1(snippet_bytes).digest()
        act_sha1 = base64.b64encode(sha1_bytes).decode('ascii')
        if exp_sha1 != act_sha1:
            return None, "checksum doesn't match actual value: " + act_sha1

    return snippet, None


def parse_snippet_line(line):
    parts = line.split(' ')
    if len(parts) != 4:
        form = '!snippet file_path start_line num_lines sha1'
        return None, "snippets should be of the form `{}`".format(form)

    fpath, start_line_, num_lines_, exp_sha1 = parts

    start_line = int(start_line_)
    if start_line <= 0:
        return None, "`start_line` must be greater than 0"

    num_lines = int(num_lines_)
    if num_lines <= 0:
        return None, "`num_lines` must be greater than 0"

    return (fpath, start_line, num_lines, exp_sha1), None


def read_snippet(fpath, start_line, num_lines):
    try:
        with open(fpath) as snippet_file:
            snippet_lines = [ln for ln in snippet_file]
    except FileNotFoundError:
        msg = "couldn't open snippet at '{}': file not found".format(fpath)
        return (None, msg)

    start = start_line - 1
    end = start + num_lines

    if end > len(snippet_lines):
        msg = "`num_lines` is greater than the remaining number of lines"
        return (None, msg)

    return (''.join(snippet_lines[start:start+num_lines]), None)


if __name__ == '__main__':
    main(sys.argv)
