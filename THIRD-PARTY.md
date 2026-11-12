# Third-party notices

KF LibGen would not exist without these projects. Only the first one contributes code that this repository derives from; the others are runtime dependencies or documentation sources.

---

## KindleFetch — MIT — © 2025 justrals

<https://github.com/justrals/KindleFetch>

**What is used from it:**

- the LibGen download flow: fetch `ads.php?md5=<md5>`, extract the `get.php` link, then download it (`bin/downloads/lgli_download.sh`)
- the LibGen mirror list (`bin/link_config`): `libgen.li`, `libgen.la`, `libgen.gl` (extended here with `libgen.vg` and `libgen.bz`)
- the general approach of a menu-driven, on-device downloader for jailbroken Kindles

The code in this repository is a rewrite, not a copy, but it is derived from that work, so the original notice is reproduced in full below as the MIT license requires.

```
MIT License

Copyright (c) 2025 justrals

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## kterm — GPLv3 — Bartek Fabiszewski

<https://github.com/bfabiszewski/kterm>

The terminal emulator this scriptlet runs inside. **Not bundled here** — it is installed separately through KPM (`;kpm install kterm`), so its GPLv3 terms apply to that package, not to this repository. It is credited because the on-screen keyboard and terminal behaviour are entirely its work.

## static-curl — MIT — moparisthebest

<https://github.com/moparisthebest/static-curl>

Provides the modern statically-linked `curl` binary the README tells you to install. **Not bundled here** — download it from their releases page so you always get the current build (and so their notices travel with their binary).

## KindleModding wiki and KPM repository

<https://kindlemodding.org> · <https://github.com/KindleModding/repo>

Documentation for scriptlets, KPM and the jailbreak stack, and the source of the `kterm` package whose default keyboard path causes the issue described in [docs/notes.md](docs/notes.md).

## KindleFetch issue reports

- [#40 — TLS/curl handshake failure](https://github.com/justrals/KindleFetch/issues/40)
- [#48 — Empty search results](https://github.com/justrals/KindleFetch/issues/48)

These threads document the two failure modes this project works around; the diagnosis here was verified independently.
