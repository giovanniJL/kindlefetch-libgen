# KF LibGen

Search and download books from **Library Genesis (LibGen)** directly on a jailbroken Kindle — on-device, with the on-screen keyboard, no computer required.

It exists because **KindleFetch's Anna's Archive search stopped working**: Anna's Archive now answers `/search` with a `302` redirect to `?check=1`, which lands on DDoS-Guard's JavaScript challenge. A plain `curl` cannot solve a JS challenge, so no amount of curl updating fixes it (evidence in [docs/notes.md](docs/notes.md)).

KF LibGen sidesteps that completely by searching **LibGen** instead, reusing the mirror list and the `ads.php → get.php` download flow that KindleFetch already had for LibGen.

> **Unofficial.** This is an independent project. It is **not** affiliated with, endorsed by, or a component of [KindleFetch](https://github.com/justrals/KindleFetch) — it reuses that project's LibGen download approach, with credit (see [THIRD-PARTY.md](THIRD-PARTY.md)). The repository name is descriptive, not a claim of association.

## Features

- KindleFetch-style main menu: search, filter, list books, settings
- Tries several LibGen mirrors until one answers
- Extension filter (epub / pdf / cbz / mobi / azw3 …)
- Downloads straight into `/mnt/us/documents`, so the Kindle library indexes the book
- Settings persist in `/mnt/us/kflg.conf`
- E-ink friendly: large text, minimal scrolling

## Requirements

- A jailbroken Kindle (the `hdnext` stack: SpiderCat, Vera, Sanctuary, WinterBreak …) — see <https://kindlemodding.org>
- `kterm` installed through KPM
- A modern `curl` at `/mnt/us/bin/curl-static`. The stock Kindle curl is 7.86.0 with OpenSSL 1.0.2q and cannot complete TLS handshakes with many current sites.

## Install

### 1. kterm

In the Kindle search bar:

```
;kpm update
;kpm install kterm
```

### 2. Modern curl

```sh
mkdir -p /mnt/us/bin
curl -fL -o /mnt/us/bin/curl-static \
  https://github.com/moparisthebest/static-curl/releases/latest/download/curl-armhf
chmod +x /mnt/us/bin/curl-static
/mnt/us/bin/curl-static --version
```

You can also download `curl-armhf` on a PC and copy it to `/mnt/us/bin/curl-static` over USB. It should report version 8.x.

### 3. The scriptlet

Copy `KF-LibGen.sh` into the `documents` folder on the Kindle. It appears in your library as **KF LibGen** — tap it to start.

## Usage

Main menu:

```
1. Search and download books
2. Filter search results
3. List my books
4. Settings
q. Exit
```

At the results screen: a **number** downloads that book, **`s`** starts a new search, **`f`** changes the extension filter, **`q`** returns to the menu.

Typing something that isn't a number offers to search for it instead, so a typo never leaves you stuck in a result list.

## Troubleshooting

### kterm opens but the on-screen keyboard is missing

The KPM `kterm` package installs to `/mnt/us/kterm`, but the binary was compiled with `/mnt/us/extensions/kterm` as the default keyboard-layout path, and its `launch.sh` only overrides that when it can parse a DPI value out of `/var/log/Xorg.0.log` (an X11-era file that yields nothing on `hdnext`). So it looks for a layout that does not exist and shows no keyboard.

Fix: make the expected path exist. Over USB, copy the `layouts` and `vte` folders from `kterm\` into `extensions\kterm\` (create that folder). Details in [docs/notes.md](docs/notes.md).

### "No mirror returned results"

Wi-Fi is down, or every mirror refused. Try **Settings → 2** to pin a specific mirror, or search again later.

### The downloaded book doesn't appear in the library

Check **Settings → 1**: only `/mnt/us/documents` is indexed by the Kindle library. Otherwise open the file with KOReader (it reads epub, cbz, pdf, and more) from its file browser.

### TLS / connection errors

Confirm the modern curl is being used — the menu header shows the curl version. If it shows `7.86.0`, `/mnt/us/bin/curl-static` is missing or not executable.

## Credits

See [THIRD-PARTY.md](THIRD-PARTY.md). In short: this stands on the shoulders of [KindleFetch](https://github.com/justrals/KindleFetch) by justrals (MIT), [kterm](https://github.com/bfabiszewski/kterm) by B. Fabiszewski (GPLv3), [static-curl](https://github.com/moparisthebest/static-curl) by moparisthebest (MIT), and the [KindleModding wiki](https://kindlemodding.org).

## License

MIT — see [LICENSE](LICENSE).

## Disclaimer

KF LibGen is an independent client for a third-party service (Library Genesis). It is not affiliated with Library Genesis, Amazon, or any project credited above. You are responsible for how you use it and for complying with the laws that apply to you.
