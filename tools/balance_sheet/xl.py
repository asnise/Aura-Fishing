"""Tiny xlsx writer + formula evaluator (no third-party packages).

Cells hold a value or a formula string ("=..."). evaluate() computes every formula with a small Excel-subset
interpreter so the file can carry cached values and so formulas can be checked against the game's real maths.
"""
import re
import zipfile
from xml.sax.saxutils import escape

# ---------- styles (index into cellXfs) ----------
S_DEFAULT, S_HEADER, S_INPUT, S_PCT, S_INPUT_PCT, S_TITLE, S_NOTE, S_INT, S_DEC2, S_BOLD, S_WRAP, S_DEC3, S_SECTION, S_OUT, S_OUT_PCT, S_OUT_INT, S_INPUT_INT = range(17)


def col_letter(n):  # 1-based
    s = ""
    while n:
        n, r = divmod(n - 1, 26)
        s = chr(65 + r) + s
    return s


def col_number(s):
    n = 0
    for ch in s:
        n = n * 26 + ord(ch) - 64
    return n


def ref(r, c):
    return f"{col_letter(c)}{r}"


class Sheet:
    def __init__(self, name):
        self.name = name
        self.cells = {}  # (r, c) -> [value_or_formula, style]
        self.widths = {}
        self.freeze = None  # (row, col) first unfrozen cell
        self.validations = []  # (sqref, formula)

    def put(self, r, c, v, s=S_DEFAULT):
        self.cells[(r, c)] = [v, s]

    def width(self, c, w):
        self.widths[c] = w

    def row(self, r, c0, values, s=S_DEFAULT):
        for i, v in enumerate(values):
            style = s[i] if isinstance(s, (list, tuple)) else s
            self.put(r, c0 + i, v, style)


class Book:
    def __init__(self):
        self.sheets = []
        self.by_name = {}

    def sheet(self, name):
        sh = Sheet(name)
        self.sheets.append(sh)
        self.by_name[name] = sh
        return sh


# ---------- formula interpreter ----------
class Rng:
    def __init__(self, rows):
        self.rows = rows  # list of lists

    @property
    def flat(self):
        return [x for r in self.rows for x in r]

    def map2(self, other, fn):
        if isinstance(other, Rng):
            a, b = self.flat, other.flat
            if len(a) != len(b):
                raise ValueError("range size mismatch")
            out = [fn(x, y) for x, y in zip(a, b)]
        else:
            out = [fn(x, other) for x in self.flat]
        return Rng(_reshape(out, self.rows))

    def map1(self, fn):
        return Rng(_reshape([fn(x) for x in self.flat], self.rows))


def _reshape(flat, like):
    out, i = [], 0
    for r in like:
        out.append(flat[i:i + len(r)])
        i += len(r)
    return out


class XlError(Exception):
    pass


def num(x):
    if x is None or x == "":
        return 0.0
    if isinstance(x, bool):
        return 1.0 if x else 0.0
    if isinstance(x, (int, float)):
        return float(x)
    try:
        return float(x)
    except Exception:
        raise XlError("#VALUE!")


def _bin(a, b, fn):
    if isinstance(a, Rng):
        return a.map2(b, fn)
    if isinstance(b, Rng):
        return b.map2(a, lambda x, y: fn(y, x))
    return fn(a, b)


def _eq(x, y):
    if isinstance(x, str) or isinstance(y, str):
        return str(x if x is not None else "").lower() == str(y if y is not None else "").lower()
    return num(x) == num(y)


TOKEN = re.compile(r"""\s*(?:
    (?P<num>\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+)|
    (?P<str>"(?:[^"]|"")*")|
    (?P<ref>(?:(?:'[^']+'|[A-Za-z_][A-Za-z0-9_ .]*?)!)?\$?[A-Z]{1,3}\$?\d+(?::\$?[A-Z]{1,3}\$?\d+)?)|
    (?P<func>[A-Z][A-Z0-9.]*)\(|
    (?P<bool>TRUE|FALSE)|
    (?P<op><>|<=|>=|[-+*/^&=<>%(),])
)""", re.X)


def tokenize(src):
    pos, out = 0, []
    while pos < len(src):
        m = TOKEN.match(src, pos)
        if not m or m.end() == pos:
            if src[pos:].strip() == "":
                break
            raise XlError(f"cannot tokenize at {src[pos:pos+20]!r} in {src!r}")
        pos = m.end()
        kind = m.lastgroup
        out.append((kind, m.group(kind)))
    return out


class Parser:
    PREC = {"=": 1, "<>": 1, "<": 1, ">": 1, "<=": 1, ">=": 1, "&": 2, "+": 3, "-": 3, "*": 4, "/": 4, "^": 5}

    def __init__(self, tokens):
        self.t, self.i = tokens, 0

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else (None, None)

    def take(self):
        tok = self.t[self.i]
        self.i += 1
        return tok

    def parse(self, minp=0):
        left = self.unary()
        while True:
            kind, val = self.peek()
            if kind == "op" and val in self.PREC and self.PREC[val] >= minp:
                p = self.PREC[val]
                self.take()
                right = self.parse(p + (0 if val == "^" else 1))
                left = ("bin", val, left, right)
            else:
                return left

    def unary(self):
        kind, val = self.peek()
        if kind == "op" and val in "+-":
            self.take()
            return ("neg" if val == "-" else "pos", self.unary())
        return self.postfix()

    def postfix(self):
        node = self.primary()
        while self.peek() == ("op", "%"):
            self.take()
            node = ("bin", "/", node, ("num", 100.0))
        return node

    def primary(self):
        kind, val = self.take()
        if kind == "num":
            return ("num", float(val))
        if kind == "str":
            return ("str", val[1:-1].replace('""', '"'))
        if kind == "bool":
            return ("num", 1.0 if val == "TRUE" else 0.0)
        if kind == "ref":
            return ("ref", val)
        if kind == "func":
            args = []
            if self.peek() == ("op", ")"):
                self.take()
                return ("call", val, args)
            while True:
                args.append(self.parse())
                k, v = self.take()
                if v == ")":
                    break
                if v != ",":
                    raise XlError("bad call syntax")
            return ("call", val, args)
        if (kind, val) == ("op", "("):
            node = self.parse()
            if self.take() != ("op", ")"):
                raise XlError("missing )")
            return node
        raise XlError(f"unexpected {kind} {val}")


def parse_formula(src):
    toks = tokenize(src)
    p = Parser(toks)
    node = p.parse()
    if p.i != len(toks):
        raise XlError(f"trailing tokens in {src!r}")
    return node


class Evaluator:
    def __init__(self, book):
        self.book = book
        self.memo = {}
        self.busy = set()
        self.errors = []

    def cell(self, sheet, r, c):
        key = (sheet, r, c)
        if key in self.memo:
            return self.memo[key]
        sh = self.book.by_name[sheet]
        entry = sh.cells.get((r, c))
        if entry is None:
            return None
        v = entry[0]
        if isinstance(v, str) and v.startswith("="):
            if key in self.busy:
                raise XlError(f"circular reference at {sheet}!{ref(r, c)}")
            self.busy.add(key)
            try:
                val = self.ev(parse_formula(v[1:]), sheet)
            except XlError as e:
                val = f"#ERR {e}"
                self.errors.append((sheet, ref(r, c), v, str(e)))
            except ZeroDivisionError:
                val = "#DIV/0!"
                self.errors.append((sheet, ref(r, c), v, "div0"))
            finally:
                self.busy.discard(key)
            if isinstance(val, Rng):
                val = val.flat[0]
            self.memo[key] = val
            return val
        self.memo[key] = v
        return v

    def rng(self, text, sheet):
        if "!" in text:
            sname, text = text.rsplit("!", 1)
            sheet = sname.strip("'")
        text = text.replace("$", "")
        if ":" in text:
            a, b = text.split(":")
        else:
            a = b = text
        ma, mb = re.match(r"([A-Z]+)(\d+)", a), re.match(r"([A-Z]+)(\d+)", b)
        c1, r1, c2, r2 = col_number(ma.group(1)), int(ma.group(2)), col_number(mb.group(1)), int(mb.group(2))
        if sheet not in self.book.by_name:
            raise XlError(f"unknown sheet {sheet}")
        rows = [[self.cell(sheet, r, c) for c in range(c1, c2 + 1)] for r in range(r1, r2 + 1)]
        if r1 == r2 and c1 == c2:
            return rows[0][0]
        return Rng(rows)

    def ev(self, n, sheet):
        k = n[0]
        if k == "num" or k == "str":
            return n[1]
        if k == "ref":
            return self.rng(n[1], sheet)
        if k == "neg":
            v = self.ev(n[1], sheet)
            return v.map1(lambda x: -num(x)) if isinstance(v, Rng) else -num(v)
        if k == "pos":
            return self.ev(n[1], sheet)
        if k == "bin":
            op, a, b = n[1], self.ev(n[2], sheet), self.ev(n[3], sheet)
            f = {
                "+": lambda x, y: num(x) + num(y),
                "-": lambda x, y: num(x) - num(y),
                "*": lambda x, y: num(x) * num(y),
                "/": lambda x, y: num(x) / num(y),
                "^": lambda x, y: num(x) ** num(y),
                "&": lambda x, y: _text(x) + _text(y),
                "=": _eq,
                "<>": lambda x, y: not _eq(x, y),
                "<": lambda x, y: num(x) < num(y),
                ">": lambda x, y: num(x) > num(y),
                "<=": lambda x, y: num(x) <= num(y),
                ">=": lambda x, y: num(x) >= num(y),
            }[op]
            return _bin(a, b, f)
        if k == "call":
            return self.call(n[1], n[2], sheet)
        raise XlError(f"bad node {k}")

    def call(self, name, args, sheet):
        def val(i):
            return self.ev(args[i], sheet)

        def flat(v):
            return v.flat if isinstance(v, Rng) else [v]

        def nums(values):
            return [num(x) for x in values if isinstance(x, (int, float)) and not isinstance(x, bool)]

        if name == "IF":
            cond = val(0)
            truthy = bool(num(cond)) if not isinstance(cond, str) else cond != ""
            if truthy:
                return val(1)
            return val(2) if len(args) > 2 else False
        if name == "IFERROR":
            try:
                r = val(0)
                if isinstance(r, str) and r.startswith("#"):
                    return val(1)
                return r
            except (XlError, ZeroDivisionError):
                return val(1)
        if name == "AND":
            return all(bool(num(x)) for a in range(len(args)) for x in flat(val(a)))
        if name == "OR":
            return any(bool(num(x)) for a in range(len(args)) for x in flat(val(a)))
        if name == "NOT":
            return not bool(num(val(0)))
        if name == "SUM":
            return sum(nums(x for a in range(len(args)) for x in flat(val(a))))
        if name == "MIN":
            v = nums(x for a in range(len(args)) for x in flat(val(a)))
            return min(v) if v else 0.0
        if name == "MAX":
            v = nums(x for a in range(len(args)) for x in flat(val(a)))
            return max(v) if v else 0.0
        if name == "AVERAGE":
            v = nums(x for a in range(len(args)) for x in flat(val(a)))
            return sum(v) / len(v)
        if name == "COUNT":
            return float(len(nums(x for a in range(len(args)) for x in flat(val(a)))))
        if name == "INT":
            import math
            return float(math.floor(num(val(0))))
        if name == "ROUND":
            import math
            x, d = num(val(0)), int(num(val(1)))
            m = 10 ** d
            return math.floor(abs(x) * m + 0.5) / m * (1 if x >= 0 else -1)
        if name == "ABS":
            return abs(num(val(0)))
        if name == "SQRT":
            return num(val(0)) ** 0.5
        if name == "POWER":
            return num(val(0)) ** num(val(1))
        if name == "MOD":
            return num(val(0)) % num(val(1))
        if name == "SUMPRODUCT":
            arrays = [flat(val(a)) for a in range(len(args))]
            total = 0.0
            for items in zip(*arrays):
                p = 1.0
                for x in items:
                    p *= num(x)
                total += p
            return total
        if name == "MATCH":
            key, rng = val(0), val(1)
            for i, x in enumerate(flat(rng)):
                if _eq(x, key):
                    return float(i + 1)
            raise XlError("#N/A")
        if name == "INDEX":
            rng = val(0)
            if not isinstance(rng, Rng):
                return rng
            r = int(num(val(1)))
            c = int(num(val(2))) if len(args) > 2 else 1
            got = rng.rows[0][r - 1] if (len(rng.rows) == 1 and len(args) == 2) else rng.rows[r - 1][c - 1]
            return 0.0 if got is None else got
        if name in ("SUMIF", "COUNTIF"):
            rng, crit = val(0), val(1)
            sumr = val(2) if len(args) > 2 else rng
            total = 0.0
            for x, y in zip(flat(rng), flat(sumr)):
                if _eq(x, crit):
                    total += 1.0 if name == "COUNTIF" else num(y)
            return total
        raise XlError(f"unsupported function {name}")


def _text(x):
    if x is None:
        return ""
    if isinstance(x, float) and x == int(x):
        return str(int(x))
    return str(x)


def evaluate(book):
    ev = Evaluator(book)
    for sh in book.sheets:
        for (r, c) in list(sh.cells):
            ev.cell(sh.name, r, c)
    return ev


# ---------- xlsx writer ----------
STYLES_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="4"><numFmt numFmtId="164" formatCode="0.0%"/><numFmt numFmtId="165" formatCode="#,##0"/><numFmt numFmtId="166" formatCode="#,##0.00"/><numFmt numFmtId="167" formatCode="0.000"/></numFmts>
<fonts count="6">
<font><sz val="11"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
<font><b/><sz val="16"/><color rgb="FF1F2A44"/><name val="Calibri"/></font>
<font><i/><sz val="10"/><color rgb="FF5A6470"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><name val="Calibri"/></font>
<font><b/><sz val="12"/><color rgb="FF1F2A44"/><name val="Calibri"/></font>
</fonts>
<fills count="6">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF2F4B6E"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFF2B3"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFDDEBF7"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFE2F0D9"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFBFC7D1"/></left><right style="thin"><color rgb="FFBFC7D1"/></right><top style="thin"><color rgb="FFBFC7D1"/></top><bottom style="thin"><color rgb="FFBFC7D1"/></bottom><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="17">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="3" borderId="1" xfId="0" applyFill="1" applyBorder="1"/>
<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
<xf numFmtId="164" fontId="0" fillId="3" borderId="1" xfId="0" applyNumberFormat="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
<xf numFmtId="166" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
<xf numFmtId="0" fontId="4" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="167" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
<xf numFmtId="0" fontId="5" fillId="4" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
<xf numFmtId="166" fontId="4" fillId="5" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="164" fontId="4" fillId="5" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="165" fontId="4" fillId="5" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="165" fontId="0" fillId="3" borderId="1" xfId="0" applyNumberFormat="1" applyFill="1" applyBorder="1"/>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>"""


def _cell_xml(r, c, v, s, cached):
    a = ref(r, c)
    st = f' s="{s}"' if s else ""
    if isinstance(v, str) and v.startswith("="):
        f = escape(v[1:])
        if isinstance(cached, bool):
            return f'<c r="{a}"{st} t="b"><f>{f}</f><v>{int(cached)}</v></c>'
        if isinstance(cached, (int, float)):
            return f'<c r="{a}"{st}><f>{f}</f><v>{repr(float(cached))}</v></c>'
        if cached is None:
            return f'<c r="{a}"{st}><f>{f}</f></c>'
        return f'<c r="{a}"{st} t="str"><f>{f}</f><v>{escape(str(cached))}</v></c>'
    if v is None:
        return f'<c r="{a}"{st}/>'
    if isinstance(v, bool):
        return f'<c r="{a}"{st} t="b"><v>{int(v)}</v></c>'
    if isinstance(v, (int, float)):
        return f'<c r="{a}"{st}><v>{repr(v)}</v></c>'
    text = escape(str(v))
    return f'<c r="{a}"{st} t="inlineStr"><is><t xml:space="preserve">{text}</t></is></c>'


def write_xlsx(book, path, ev=None):
    ev = ev or evaluate(book)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>"""
                   + "".join(f'<Override PartName="/xl/worksheets/sheet{i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(len(book.sheets)))
                   + '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>')
        z.writestr("_rels/.rels", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
        z.writestr("xl/workbook.xml", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
                   + "".join(f'<sheet name="{escape(sh.name)}" sheetId="{i+1}" r:id="rId{i+1}"/>' for i, sh in enumerate(book.sheets)) + "</sheets></workbook>")
        z.writestr("xl/_rels/workbook.xml.rels", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                   + "".join(f'<Relationship Id="rId{i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i+1}.xml"/>' for i in range(len(book.sheets)))
                   + f'<Relationship Id="rId{len(book.sheets)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>')
        z.writestr("xl/styles.xml", STYLES_XML)
        for i, sh in enumerate(book.sheets):
            rows = {}
            for (r, c), (v, s) in sh.cells.items():
                rows.setdefault(r, []).append((c, v, s))
            parts = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">']
            if sh.freeze:
                fr, fc = sh.freeze
                xs = (' xSplit="%d"' % (fc - 1)) if fc > 1 else ""
                ys = (' ySplit="%d"' % (fr - 1)) if fr > 1 else ""
                active = "bottomRight" if fr > 1 and fc > 1 else ("bottomLeft" if fr > 1 else "topRight")
                pane = '<pane%s%s topLeftCell="%s" activePane="%s" state="frozen"/>' % (xs, ys, ref(fr, fc), active)
                parts.append(f'<sheetViews><sheetView workbookViewId="0">{pane}</sheetView></sheetViews>')
            if sh.widths:
                parts.append("<cols>" + "".join(f'<col min="{c}" max="{c}" width="{w}" customWidth="1"/>' for c, w in sorted(sh.widths.items())) + "</cols>")
            parts.append("<sheetData>")
            for r in sorted(rows):
                parts.append(f'<row r="{r}">')
                for c, v, s in sorted(rows[r]):
                    cached = ev.memo.get((sh.name, r, c)) if isinstance(v, str) and v.startswith("=") else None
                    parts.append(_cell_xml(r, c, v, s, cached))
                parts.append("</row>")
            parts.append("</sheetData>")
            if sh.validations:
                parts.append(f'<dataValidations count="{len(sh.validations)}">' + "".join(
                    f'<dataValidation type="list" allowBlank="1" showErrorMessage="1" sqref="{sq}"><formula1>{escape(f)}</formula1></dataValidation>' for sq, f in sh.validations) + "</dataValidations>")
            parts.append("</worksheet>")
            z.writestr(f"xl/worksheets/sheet{i+1}.xml", "".join(parts))
