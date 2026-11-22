#!/usr/bin/env python3
"""Mechanical checks on the paired English/Japanese section files.

    python3 lint.py                 all section files
    python3 lint.py sections/intro.tex

ERRORs are rule violations that break a build or the pairing contract of
CONVENTIONS.md; the exit status is 1 if there is any. WARNings are things a
human or an agent must look at (they can be legitimate).

What it cannot check: whether the Japanese says what the English says, and
whether either says what the sources say.
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
BIB = HERE.parents[2] / 'literature' / 'refs' / 'zotero_export.bib'
DEFAULT = ['sections/intro.tex', 'sections/methods_a.tex', 'sections/methods_b.tex',
           'sections/backmatter.tex']

ID_RE = re.compile(r'^(I|C|B|[MRD]\d)-\d+[a-z]?$')
CITE_RE = re.compile(r'\\cite[a-zA-Z]*\*?(?:\[[^\]]*\])*\{([^}]*)\}')
MACRO_RE = re.compile(r'\\([A-Za-z@]+)')
MATH_RE = re.compile(r'\$[^$]*\$')
NUM_RE = re.compile(r'(?<![A-Za-z\\{])\d+(?:[.,]\d+)*')

# LaTeX, amsmath, natbib and the class: a generous whitelist, since an unknown
# macro is only a warning.
KNOWN = set('''begin end label ref eqref pageref cite citep citet citealp citealt citeauthor citeyear
citeyearpar textbf textit textrm textsf texttt emph frac dfrac tfrac sqrt left right mathrm mathit
mathsf mathbf mathcal boldsymbol bm sum prod int partial times cdot approx sim simeq equiv propto le ge
leq geq neq ne pm mp infty alpha beta gamma delta Delta epsilon varepsilon zeta eta theta lambda Lambda
mu nu xi rho sigma Sigma tau phi varphi psi Psi omega Omega pi langle rangle quad qquad text
textsuperscript textsubscript textdagger item ldots dots cdots overline bar hat tilde vec dot ddot min
max sin cos tan exp log ln lvert rvert vert mid to rightarrow leftarrow Rightarrow in notin subset cup
cap nabla prime circ footnote section subsection subsubsection paragraph input caption centering
hline toprule midrule bottomrule cmidrule multicolumn multirow tabular table figure includegraphics
small footnotesize normalsize large par noindent vspace hspace linewidth textwidth clearpage newpage
operatorname mathrm displaystyle textstyle big Big bigg Bigg bigl bigr Bigl Bigr left right lVert rVert
ldotp colon arg deg det dim gcd lim sup inf Pr mathbb underline overbrace underbrace stackrel
InputIfFileExists providecommand newcommand renewcommand fbox parbox relax protect nobreak
enspace thinspace negthinspace phantom hphantom vphantom ensuremath mbox hbox raisebox
abstract keywords articletype title author maketitle and received appendix bibliography
bibliographystyle parskip itemsep setlength tabcolsep arraystretch hfill hrulefill
sum Re Im ell hbar imath jmath aa AA ss o O l L ae AE oe OE i j'''.split())

AMERICAN = r'\b(colou?r(?<!colour)|center(?:ed|ing|s|line)?|behavior(?:s|al)?|analyz(?:e|ed|es|ing)|' \
           r'model(?:ed|ing)\b|label(?:ed|ing)\b|gray|favor(?:s|ed|able)?|neighbor\w*|vapor|liters?|' \
           r'meters?\b|fiber|catalog\b|travel(?:ed|ing)\b|signal(?:ed|ing)\b|channel(?:ed|ing)\b)\b'
ISE = r'\b\w*(characteris|normalis|visualis|stabilis|minimis|maximis|utilis|generalis|realis|recognis|' \
      r'summaris|organis|parameteris|synchronis|localis|standardis|optimis|randomis|linearis|' \
      r'emphasis(?:e[ds]?|ing))\w*'
FORBIDDEN = [
    (r'\bm/s\b|\bL/s\b|mm/min|\bm\^2/s', 'unit written with a slash; use the unit macros of notation.tex'),
    (r"``|''|\"", "double quotation marks; JHR uses single quotation marks"),
]
RETRACTED = [
    (r'still water|quiescent', '"still water" start is retracted; the start procedure is a placeholder'),
    (r'\bvalve', 'discharge was set by pump frequency, not valve opening'),
    (r'ultrasonic', 'the level gauge is a 60 GHz radar gauge'),
    (r'transit[- ]time', 'the transit-time discharge is retracted'),
    (r'\bCFD\b|numerical simulation', 'paper 1 carries no CFD result (outlook sentence at most)'),
]


def defined_macros(paths):
    names = set()
    for p in paths:
        if p.is_file():
            t = p.read_text(encoding='utf-8')
            names |= set(re.findall(r'\\(?:re|provide)?newcommand\*?\{\\([A-Za-z@]+)\}', t))
            names |= set(re.findall(r'\\providecommand\*?\{\\([A-Za-z@]+)\}', t))
            names |= set(re.findall(r'\\def\\([A-Za-z@]+)', t))
            names |= set(re.findall(r'\\NewDocumentEnvironment\{([A-Za-z@]+)\}', t))
    return names


def strip_macros(s):
    """Text with math, citations, source notes and macro names removed (for prose checks)."""
    s = re.sub(r'\\src\{.*', '', s, flags=re.S)
    s = MATH_RE.sub(' ', s)
    s = CITE_RE.sub(' ', s)
    s = re.sub(r'\\(?:ref|label|eqref)\{[^}]*\}', ' ', s)
    s = re.sub(r'\\[A-Za-z@]+\*?', ' ', s)
    return s


def lint_file(path, bibkeys, macros, seen_ids):
    out = []
    rel = path.relative_to(HERE)
    lines = path.read_text(encoding='utf-8').split('\n')
    state, cur_id, start = 'out', None, 0
    en, ja, last_end_en = [], [], None
    words = gapwords = 0

    def err(n, msg, level='ERROR'):
        out.append(f'{level} {rel}:{n + 1} [{cur_id or "-"}] {msg}')

    def close_pair(n):
        nonlocal words, gapwords
        e, j = '\n'.join(en), '\n'.join(ja)
        ce, cj = sorted(k.strip() for m in CITE_RE.findall(e) for k in m.split(',')), \
                 sorted(k.strip() for m in CITE_RE.findall(j) for k in m.split(','))
        if ce != cj:
            err(n, f'citations differ between en and ja: en {ce} / ja {cj}')
        for k in set(ce + cj):
            if k not in bibkeys:
                err(n, f'citekey not in zotero_export.bib: {k}')
        for mac in (r'\PH{', r'\PHref{', r'\unverified'):
            if e.count(mac) != j.count(mac):
                err(n, f'{mac.rstrip("{")} appears {e.count(mac)} times in en, {j.count(mac)} in ja')
        j_nosrc = re.sub(r'\\src\{.*', '', j, flags=re.S)
        if sorted(MATH_RE.findall(e)) != sorted(MATH_RE.findall(j_nosrc)):
            err(n, 'inline math differs between en and ja', 'WARN')
        ne = sorted(NUM_RE.findall(strip_macros(e)))
        nj = sorted(NUM_RE.findall(strip_macros(j_nosrc)))
        if ne != nj:
            err(n, f'numbers differ between en and ja: only en {sorted(set(ne) - set(nj))} / '
                   f'only ja {sorted(set(nj) - set(ne))}', 'WARN')
        prose = strip_macros(e)
        se = len(re.findall(r'[.?!](?:\s|$)', re.sub(r'\b(?:et al|Fig|Figs|Eq|Eqs|i\.e|e\.g|cf|approx|vs|No)\.', '', prose)))
        sj = len(re.findall(r'[．？！]', strip_macros(j_nosrc)))
        if se != sj:
            err(n, f'sentence count differs: en {se} / ja {sj}', 'WARN')
        if re.search(r'[、。]', j):
            err(n, 'Japanese punctuation must be ，． (found 、 or 。)')
        if r'\src{' in e:
            err(n, r'\src belongs at the end of the ja block, not in en')
        for pat, msg in FORBIDDEN:
            if re.search(pat, prose):
                err(n, msg)
        for pat, msg in RETRACTED:
            m = re.search(pat, prose, flags=re.I)
            if m:
                err(n, f'"{m.group(0)}": {msg}', 'WARN')
        m = re.search(AMERICAN, prose)
        if m:
            err(n, f'American spelling? "{m.group(0)}" (JHR: British with -ize)', 'WARN')
        m = re.search(ISE, prose)
        if m:
            err(n, f'-ise spelling? "{m.group(0)}" (JHR: -ize)', 'WARN')
        for blk in (e, j):
            if '#' in blk or r'\verb' in blk:
                err(n, 'no # or verbatim inside en/ja')
        words += len(re.findall(r"[A-Za-z][A-Za-z'-]*", prose))
        for g in re.findall(r'\\PH(?:ref)?\{((?:[^{}]|\{[^{}]*\})*)\}', e):
            gapwords += len(re.findall(r"[A-Za-z][A-Za-z'-]*", strip_macros(g)))

    for n, raw in enumerate(lines):
        s = raw.strip()
        for mname in MACRO_RE.findall(re.split(r'(?<!\\)%', raw)[0]):
            if mname not in KNOWN and mname not in macros:
                err(n, f'unknown macro \\{mname} (define it in notation.tex)', 'WARN')
        m_en = re.match(r'^\\begin\{en\}(?:\[([^\]]*)\])?$', s)
        if (r'\begin{en}' in s and not m_en) or (r'\begin{ja}' in s and s != r'\begin{ja}') \
                or (r'\end{en}' in s and s != r'\end{en}') or (r'\end{ja}' in s and s != r'\end{ja}'):
            err(n, r'\begin{en}, \end{en}, \begin{ja}, \end{ja} must each stand alone on a line')
            continue
        if m_en:
            if state != 'out':
                err(n, r'\begin{en} inside an open block')
            state, en, ja, start = 'en', [], [], n
            cur_id = m_en.group(1) or cur_id
            if m_en.group(1):
                if not ID_RE.match(m_en.group(1)):
                    err(n, f'paragraph ID "{m_en.group(1)}" does not match I-1 / M1-1 / R1-1 / D1-1 / C-1 / B-1')
                if m_en.group(1) in seen_ids:
                    err(n, f'paragraph ID "{m_en.group(1)}" already used at {seen_ids[m_en.group(1)]}')
                seen_ids[m_en.group(1)] = f'{rel}:{n + 1}'
        elif s == r'\end{en}':
            if state != 'en':
                err(n, r'\end{en} without \begin{en}')
            state, last_end_en = 'between', n
        elif s == r'\begin{ja}':
            if state != 'between':
                err(n, r'\begin{ja} must follow \end{en} directly')
            elif n != last_end_en + 1:
                err(n, r'nothing may stand between \end{en} and \begin{ja} (no blank line, no comment)')
            state = 'ja'
        elif s == r'\end{ja}':
            if state != 'ja':
                err(n, r'\end{ja} without \begin{ja}')
            else:
                close_pair(n)
            state = 'out'
        elif state == 'en':
            if not s:
                err(n, 'blank line inside the en block')
            en.append(raw)
        elif state == 'ja':
            if not s:
                err(n, 'blank line inside the ja block')
            ja.append(raw)
        elif state == 'between' and s:
            err(n, r'text between \end{en} and \begin{ja}')
    if state != 'out':
        out.append(f'ERROR {rel}:{len(lines)} [{cur_id}] file ends inside a block')
    return out, words, gapwords


def main():
    files = [HERE / f for f in (sys.argv[1:] or DEFAULT)]
    bibkeys = set(re.findall(r'^@\w+\{([^,\s]+),', BIB.read_text(encoding='utf-8'), flags=re.M))
    macros = defined_macros([HERE / 'notation.tex', HERE / 'bilingual.sty', HERE / 'figures' / 'all.tex'] + files)
    seen, total_err = {}, 0
    for f in files:
        if not f.is_file():
            continue
        out, words, gapwords = lint_file(f, bibkeys, macros, seen)
        for line in out:
            print(line)
        nerr = sum(1 for line in out if line.startswith('ERROR'))
        total_err += nerr
        print(f'-- {f.relative_to(HERE)}: {nerr} errors, {len(out) - nerr} warnings, '
              f'{words} English words in en blocks ({words - gapwords} without the contents of \\PH and \\PHref)')
    return 1 if total_err else 0


if __name__ == '__main__':
    sys.exit(main())
