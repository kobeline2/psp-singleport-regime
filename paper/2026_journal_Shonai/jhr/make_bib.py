#!/usr/bin/env python3
"""Write refs.bib for the JHR manuscript from the Zotero export.

The Zotero export (literature/refs/zotero_export.bib) stays the single source
of bibliographic data. This filter only drops fields that must not reach the
reference list or that BibTeX does not need:

  month     APA journal references carry no month, but apacite prints it
  abstract, file, urldate, langid, keywords, issn, shorttitle

Run by build.sh before BibTeX. refs.bib is generated, so it is not tracked.
"""
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
SRC = HERE.parents[2] / 'literature' / 'refs' / 'zotero_export.bib'
DST = HERE / 'refs.bib'
DROP = {'month', 'abstract', 'file', 'urldate', 'langid', 'keywords', 'issn', 'shorttitle'}


def entries(text):
    """Yield (head, body) for each @type{key, ...} entry, brace-balanced."""
    i = 0
    while True:
        i = text.find('@', i)
        if i < 0:
            return
        j = text.find('{', i)
        depth, k = 0, j
        while k < len(text):
            if text[k] == '{':
                depth += 1
            elif text[k] == '}':
                depth -= 1
                if depth == 0:
                    break
            k += 1
        yield text[i:j + 1], text[j + 1:k]
        i = k + 1


def split_fields(body):
    """Split an entry body at top-level commas (outside braces and quotes)."""
    parts, depth, quote, cur = [], 0, False, []
    for ch in body:
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
        elif ch == '"' and depth == 0:
            quote = not quote
        if ch == ',' and depth == 0 and not quote:
            parts.append(''.join(cur))
            cur = []
        else:
            cur.append(ch)
    parts.append(''.join(cur))
    return [p.strip() for p in parts if p.strip()]


def main():
    text = SRC.read_text(encoding='utf-8')
    out, n = [], 0
    for head, body in entries(text):
        fields = split_fields(body)
        key, kept = fields[0], []
        for f in fields[1:]:
            name = f.split('=', 1)[0].strip().lower()
            if name not in DROP:
                kept.append('  ' + f)
        out.append(head + key + ',\n' + ',\n'.join(kept) + '\n}\n')
        n += 1
    DST.write_text('\n'.join(out), encoding='utf-8')
    print(f'refs.bib: {n} entries from {SRC.name}', file=sys.stderr)


if __name__ == '__main__':
    main()
