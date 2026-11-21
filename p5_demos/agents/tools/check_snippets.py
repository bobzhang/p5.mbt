"""Check that every MoonBit snippet the film shows is verified code.

    python3 p5_demos/agents/tools/check_snippets.py

Each snippet drawn on screen (the "MoonBit" code beside each language in
languages.mbt, and MoonBit's own editor in scenes.mbt)
must appear line for line in snippets/snippets.mbt, which `moon test`
compiles and tests. Block separators (`///|`) are ignored when matching.
Exits non-zero on the first snippet that is not found.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STR = re.compile(r'"((?:[^"\\]|\\.)*)"')


def strings(block):
    return [re.sub(r'\\(.)', r'\1', m) for m in STR.findall(block)]


def bracket(src, start):
    """The text between the `[` at or after `start` and its matching `]`."""
    i = src.index("[", start)
    depth = 0
    for j in range(i, len(src)):
        c = src[j]
        if c == '"':
            # skip a string literal
            k = j + 1
            while src[k] != '"':
                k += 2 if src[k] == "\\" else 1
            continue
        if c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                return src[i + 1:j]
    raise ValueError("unbalanced brackets")


def snippets():
    out = []
    langs = open(os.path.join(ROOT, "languages.mbt")).read()
    body = langs[langs.index("fn link_of("):]
    for m in re.finditer(r'"([^"]+)" =>|_ =>', body):
        name = m.group(1) or "WebAssembly"
        rest = body[m.end():]
        code = strings(bracket(rest, rest.index("code:")))
        terminal = re.search(r"terminal:\s*(true|false)", rest).group(1) == "true"
        if not terminal:
            out.append((name, code))
        if m.group(0) == "_ =>":
            break
    scenes = open(os.path.join(ROOT, "scenes.mbt")).read()
    out.append(("MoonBit editor", strings(bracket(scenes, scenes.index("= [", scenes.index("let moonbit_code"))))))
    return out


def lines(text):
    return [l.rstrip() for l in text if l.strip() != "///|"]


source = lines(open(os.path.join(ROOT, "snippets/snippets.mbt")).read().splitlines())
ok = True
for name, code in snippets():
    want = lines(code)
    found = len(want) > 0 and any(
        source[i:i + len(want)] == want for i in range(len(source) - len(want) + 1))
    print(f"{'ok  ' if found else 'MISSING'}  {name}: {len(want)} lines")
    ok &= found
sys.exit(0 if ok else 1)
