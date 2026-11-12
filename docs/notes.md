# Technical notes

Everything here was reproduced on a Kindle (10th gen, firmware 5.18.1.1, SpiderCat jailbreak, KPM/kterm installed) while building this scriptlet. It is written down because none of it is obvious and all of it cost time.

---

## 1. Why the Anna's Archive search cannot work any more

KindleFetch searches by scraping `$ANNAS_URL/search?page=N&q=...` and parsing the HTML rows.

What the server actually returns now:

```
$ curl -s -o /dev/null -w '%{http_code} %{size_download}' 'https://annas-archive.gl/search?q=dune'
302 239
```

A `302`, not results — and the body is a Flask redirect stub:

```html
<title>Redirecting...</title>
<p>You should be redirected automatically to the target URL:
<a href="/search?q=dune&amp;check=1">/search?q=dune&amp;check=1</a>.
```

KindleFetch fetches with `curl -s` (no `-L`), so it never follows it, parses zero rows, and reports "Page 1 of 1" with an empty list.

Following the redirect makes it worse, not better:

```
$ curl -sL 'https://annas-archive.gl/search?q=dune'      # modern curl 8.21.0
403 902
<!doctype html><html><head><title>DDoS-Guard</title>
<link rel="stylesheet" href="/.well-known/ddos-guard/js-challenge/index.css">
<script defer src="/.well-known/ddos-guard/js-challenge/view.js"></script>
```

`?check=1` triggers DDoS-Guard's **JavaScript challenge**. A JS challenge needs a JS engine, so no curl flags, cookies, or User-Agent will pass it. Verified: browser User-Agent, `Referer`, and a cookie jar from the homepage (`__ddg1_`, `__ddg8_`, `__ddg9_`, `__ddg10_`) all still end at the 403 challenge. The homepage (`/`) loads fine — only `/search` is protected.

This matches the still-open [issue #48](https://github.com/justrals/KindleFetch/issues/48) ("did the curl fix, fully updated app, tried different mirrors, still no results").

**Conclusion:** Anna's Archive search is unreachable from a shell. Use LibGen (this project), the Kindle's browser, or a PC.

---

## 2. The Kindle's stock curl cannot do modern TLS

```
$ curl --version
curl 7.86.0 (arm-none-linux-gnueabi) libcurl/7.86.0 OpenSSL/1.0.2q ...

$ curl -v https://annas-archive.gl
* TLSv1.2 (IN), TLS alert, protocol version (582):
* error:1407742E:SSL routines:SSL23_GET_SERVER_HELLO:tlsv1 alert protocol version
```

Every request to Anna's Archive fails in ~0.3 s with `http_code=000` and zero bytes. This is the [issue #40](https://github.com/justrals/KindleFetch/issues/40) failure.

Fix: a modern static build at `/mnt/us/bin/curl-static`.

```
$ /mnt/us/bin/curl-static --version
curl 8.21.0 (armv7l-unknown-linux-musleabihf) libcurl/8.21.0 OpenSSL/3.5.7 ...
$ /mnt/us/bin/curl-static -s -o /dev/null -w '%{http_code} %{size_download}\n' https://annas-archive.gl
200 175818
```

Note that this alone does **not** fix KindleFetch's search — see note 1. It is still required for LibGen, which refuses the old TLS stack on some mirrors.

---

## 3. LibGen mirrors serve a blank page to `curl` User-Agents

This is why KindleFetch's LibGen provider never worked either:

```
$ curl -s https://libgen.la/index.php?req=dune        # UA: curl/8.21.0
<title>Welcome to nginx!</title>                       # 638 bytes, no results

$ curl -s -A 'Mozilla/5.0 ...' https://libgen.la/index.php?req=dune
<title>Library Genesis</title>                         # ~104 KB, 25 results
```

KindleFetch's `find_working_url` accepts any status below 500, so the default nginx page passes its check with `200` — the mirror looks healthy while returning nothing usable.

**KF LibGen always sends a browser User-Agent.**

Working mirrors at the time of writing (browser UA): `libgen.vg`, `libgen.li`, `libgen.gl`, `libgen.la`, `libgen.bz`.
Dead or broken: `libgen.is`, `libgen.rs`, `libgen.st` (connection refused), `libgen.gs`/`libgen.se` (NXDOMAIN), `libgen.fun` (expired certificate), `libgen.pw` (parked page).

The download flow itself:

```
GET /ads.php?md5=<md5>   ->  HTML containing href="get.php?md5=<md5>&key=<KEY>"
GET /get.php?md5=...     ->  200 application/octet-stream, Content-Disposition: attachment, body starts with PK (epub/zip)
```

---

## 4. kterm: no on-screen keyboard after a KPM install

The KPM `kterm` package installs to `/mnt/us/kterm`, but the binary was compiled with the old path baked in. Strings inside the binary:

```
/mnt/us/extensions/kterm/layouts/keyboard.xml
/mnt/us/extensions/kterm/vte/terminfo
```

`launch.sh` only passes an explicit layout when it can parse a DPI value:

```sh
DPI=`cat /var/log/Xorg.0.log | grep DPI | sed -n 's/.*(\([0-9]\+\), [0-9]\+).*/\1/p'`
if [ ${DPI} -gt 290 ]; then PARAM="-l ${EXTENSION}/layouts/keyboard-300dpi.xml"
elif [ ${DPI} -gt 200 ]; then PARAM="-l ${EXTENSION}/layouts/keyboard-200dpi.xml"
fi          # no else branch
```

On `hdnext` that lookup yields nothing, so no `-l` is passed and kterm falls back to `/mnt/us/extensions/kterm/layouts/keyboard.xml`, which does not exist. Result: terminal opens, keyboard never appears.

**Fix (no typing needed):** over USB, copy `layouts` and `vte` from `kterm\` into `extensions\kterm\` on the Kindle. Alternatively set `kb_conf_path` in `/mnt/us/kterm/bin/kterm.conf`, or add the missing `else` branch to `launch.sh`.

---

## 5. kterm's `-e` does not run a shell

`kterm -e` splits its argument on whitespace and execs it directly, so a shell construct fails:

```
kterm -e "PATH=/mnt/us/bin:$PATH sh /path/script.sh"
-> Vte terminal failed to execute child process (No such file or directory)
```

It tried to execute a program literally named `PATH=/mnt/us/bin:...`.

Workarounds: pass a plain command (`sh /path/script.sh`), or export variables **before** launching kterm — kterm's child inherits them, which is why `launch.sh` exports `DISPLAY`, `TERM` and `TERMINFO` up front.

A scriptlet also needs that environment, since it runs headless:

```sh
export DISPLAY=:0 TERM=xterm TERMINFO=/mnt/us/kterm/vte/terminfo
exec /mnt/us/kterm/bin/kterm -k 1 -o U -s 7 -e "sh /mnt/us/documents/KF-LibGen.sh interactive"
```

---

## 6. Parsing LibGen's results table

Rows are delimited by `<tr>`, cells by `</td>`, and the md5 lives in either `ads.php?md5=` or `get.php?md5=` inside the last cell. Two gotchas:

- Attribute values can contain `>`, e.g. `title="Add/Edit : ...<br>Dune The Official Comic Book"`. A naive `<[^>]*>` tag stripper breaks mid-attribute and leaks `" href="edition.php?id=...` into the title. Strip `[a-zA-Z-]+="[^"]*"` **before** stripping tags.
- Reading the parsed TSV with `IFS=$'\t'` and `read` collapses **empty** fields (tab is an IFS whitespace character), which shifts every following column — a row with no year prints its language as the year. Emit a placeholder (`-`) for empty fields instead.

---

## 7. Where files land

Only `/mnt/us/documents` is indexed by the Kindle library. Downloading into a custom folder (KindleFetch lets you configure one, e.g. `/mnt/us/get`) means the book never shows up in the library even though it downloaded fine. KF LibGen defaults to `/mnt/us/documents` and lets you change it in Settings.
