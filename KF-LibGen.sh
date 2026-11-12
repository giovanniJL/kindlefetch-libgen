#!/bin/sh
# Name: KF LibGen
# Author: giovanniJL
# DontUseFBInk
#
# LibGen search + download for jailbroken Kindles, with a KindleFetch-style
# main menu. Standalone alternative to KindleFetch's Anna's Archive search,
# which now sits behind a DDoS-Guard JavaScript challenge curl cannot solve.
#
# Needs: /mnt/us/bin/curl-static (modern curl) - falls back to system curl.
# Settings persist in /mnt/us/kflg.conf
#
# The LibGen download flow (ads.php -> get.php) and the mirror list are
# adapted from KindleFetch by justrals (MIT):
#   https://github.com/justrals/KindleFetch
# See THIRD-PARTY.md for the full notice.

SELF=/mnt/us/documents/KF-LibGen.sh

# ---- not yet inside the terminal: launch kterm with ourselves -------------
if [ "$1" != "interactive" ]; then
    export DISPLAY=:0
    export TERM=xterm
    export TERMINFO=/mnt/us/kterm/vte/terminfo
    exec /mnt/us/kterm/bin/kterm -k 1 -o U -s 7 -e "sh $SELF interactive"
fi

# ---- configuration -------------------------------------------------------
CURL=/mnt/us/bin/curl-static
[ -x "$CURL" ] || CURL=curl
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36"
MIRRORS="https://libgen.vg https://libgen.li https://libgen.gl https://libgen.la https://libgen.bz"
CONF=/mnt/us/kflg.conf
DEST=/mnt/us/documents
PREFERRED=""
EXTFILTER=""
MIRROR=""
RAW=/tmp/kflg_raw.html
ALL=/tmp/kflg_all.tsv
LIST=/tmp/kflg_list.tsv
ADS=/tmp/kflg_ads.html
TAB=$(printf '\t')

load_conf() {
    [ -f "$CONF" ] && . "$CONF"
}

save_conf() {
    {
        echo "DEST=\"$DEST\""
        echo "PREFERRED=\"$PREFERRED\""
        echo "EXTFILTER=\"$EXTFILTER\""
    } > "$CONF"
}

load_conf
[ -d "$DEST" ] || mkdir -p "$DEST" 2>/dev/null
CURLVER=$("$CURL" --version 2>&1 | head -1 | cut -d' ' -f1,2)

# ---- HTML parsing --------------------------------------------------------
parse() {
awk '
function strip(s) {
    gsub(/[a-zA-Z-]+="[^"]*"/, " ", s)
    gsub(/<[^<>]*>/, " ", s)
    gsub(/&amp;/, "\\&", s)
    gsub(/&[a-zA-Z#0-9]+;/, " ", s)
    gsub(/[ \t\r\n]+/, " ", s)
    sub(/^ /, "", s); sub(/ $/, "", s)
    return s
}
function ne(s) {
    if (s == "") return "-"
    return s
}
BEGIN { RS = "<tr>"; n = 0 }
/ads\.php\?md5=[a-f0-9]|get\.php\?md5=[a-f0-9]/ {
    p = index($0, "md5=")
    if (p == 0) next
    md5 = substr($0, p + 4, 32)
    if (length(md5) != 32) next
    m = split($0, f, "</td>")
    if (m < 8) next
    t = f[1]
    if (match(t, /<b>/)) {
        t2 = substr(t, RSTART + 3)
        if (match(t2, /<\/b>/)) t2 = substr(t2, 1, RSTART - 1)
        t = t2
    }
    title = strip(t)
    if (title == "") next
    n++
    printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", n, md5, ne(title), ne(strip(f[2])), ne(strip(f[4])), ne(strip(f[5])), ne(strip(f[7])), ne(strip(f[8]))
}
' "$RAW"
}

apply_filter() {
    if [ -z "$EXTFILTER" ]; then
        cp -f "$ALL" "$LIST"
    else
        awk -F'\t' -v e="$EXTFILTER" 'tolower($8) == tolower(e)' "$ALL" > "$LIST"
    fi
    awk -F'\t' -v OFS='\t' '{$1 = NR; print}' "$LIST" > /tmp/kflg_ren.tsv && mv -f /tmp/kflg_ren.tsv "$LIST"
}

count_lines() {
    wc -l < "$1" 2>/dev/null | tr -d ' '
}

# ---- helpers -------------------------------------------------------------
ask_filter() {
    printf '  Only this extension (epub, pdf, cbz...; empty = all): '
    read -r fe
    EXTFILTER="$fe"
    save_conf
}

find_mirror() {
    order="$MIRRORS"
    [ -n "$PREFERRED" ] && order="$PREFERRED $MIRRORS"
    for m in $order; do
        printf '  checking %s ...\n' "$m"
        "$CURL" -s -A "$UA" -L --max-time 45 -o "$RAW" "$m/index.php?req=$1"
        if grep -q 'ads\.php?md5=' "$RAW" 2>/dev/null; then
            MIRROR="$m"
            return 0
        fi
    done
    return 1
}

download() {
    row="$1"
    md5=$(printf '%s' "$row" | cut -f2)
    title=$(printf '%s' "$row" | cut -f3)
    ext=$(printf '%s' "$row" | cut -f8)

    printf '\n  Download "%s" ? [Y/n] ' "$title"
    read -r ok
    case "$ok" in [nN]) return 0;; esac

    echo "  Getting the download link..."
    "$CURL" -s -A "$UA" -L --max-time 45 -o "$ADS" "$MIRROR/ads.php?md5=$md5"
    link=$(grep -o 'href="[^"]*get\.php[^"]*"' "$ADS" | head -1 | sed 's/^href="//; s/"$//')
    if [ -z "$link" ]; then
        echo "  No direct LibGen download for this entry."
        printf '  Press Enter...'; read -r _
        return 0
    fi
    case "$link" in
        http*) url="$link";;
        /*)    url="$MIRROR$link";;
        *)     url="$MIRROR/$link";;
    esac

    name=$(printf '%s' "$title" | sed 's/[^A-Za-z0-9._ -]/_/g' | tr ' ' '_' | cut -c1-80)
    [ -n "$ext" ] && name="$name.$ext"
    out="$DEST/$name"

    printf '  Downloading %s ...\n' "$name"
    if "$CURL" -A "$UA" -L --max-time 900 -# -o "$out" "$url"; then
        sz=$(wc -c < "$out" | tr -d ' ')
        if [ "$sz" -lt 2000 ]; then
            echo "  Only $sz bytes - not a book, removing."
            head -c 200 "$out"
            echo
            rm -f "$out"
        else
            echo "  Saved: $out"
            echo "  Size : $sz bytes"
        fi
    else
        echo "  Download failed."
    fi
    printf '  Press Enter...'
    read -r _
}

# ---- screens -------------------------------------------------------------
do_search() {
    haveq=0
    while :; do
        if [ "$haveq" = "1" ]; then
            haveq=0
        else
            clear
            printf '  Query (empty = back, q = menu): '
            read -r q
            [ -z "$q" ] && return 0
            case "$q" in [qQ]) return 0;; esac
        fi

        enc=$(printf '%s' "$q" | sed 's/ /+/g')
        echo
        if ! find_mirror "$enc"; then
            echo "  No mirror returned results (Wi-Fi up?)."
            printf '  Press Enter...'; read -r _
            continue
        fi
        parse > "$ALL"
        if [ "$(count_lines "$ALL")" -eq 0 ]; then
            echo "  Nothing found for '$q'."
            printf '  Press Enter...'; read -r _
            continue
        fi
        apply_filter

        back=0
        while :; do
            clear
            echo "  '$q'  -  $(count_lines "$LIST") results via $MIRROR"
            [ -n "$EXTFILTER" ] && echo "  filter: only .$EXTFILTER"
            echo "  ------------------------------------------------"
            while IFS="$TAB" read -r num md5 title author year lang size ext; do
                printf '%2s. %s\n' "$num" "$title"
                printf '    %s | %s | .%s | %s\n' "$author" "$year" "$ext" "$size"
            done < "$LIST"
            echo "  ------------------------------------------------"
            printf '  Number, s=new search, f=filter, q=menu: '
            read -r sel

            case "$sel" in
                [qQ]) return 0;;
                [sS]) back=1; break;;
                [fF]) ask_filter; apply_filter; continue;;
                '') continue;;
                *[!0-9]*)
                    printf '  Search for "%s" instead? [Y/n] ' "$sel"
                    read -r yn
                    case "$yn" in
                        [nN]) continue;;
                        *) q="$sel"; haveq=1; back=1; break;;
                    esac
                    ;;
            esac

            row=$(awk -F'\t' -v n="$sel" '$1 == n {print; exit}' "$LIST")
            if [ -z "$row" ]; then
                echo "  No entry number $sel."
                sleep 2
                continue
            fi
            download "$row"
        done
        [ "$back" = "1" ] || return 0
    done
}

list_books() {
    clear
    echo "  Books in $DEST"
    echo "  ------------------------------------------------"
    n=0
    for f in "$DEST"/*; do
        [ -f "$f" ] || continue
        n=$((n + 1))
        printf '%3s. %s\n' "$n" "$(basename "$f")"
        printf '     %s bytes\n' "$(wc -c < "$f" | tr -d ' ')"
    done
    [ "$n" -eq 0 ] && echo "  (empty)"
    echo
    printf '  Press Enter...'
    read -r _
}

settings_menu() {
    while :; do
        clear
        echo "  Settings"
        echo "  ------------------------------------------------"
        echo "  1. Download folder : $DEST"
        echo "  2. Mirror          : ${PREFERRED:-auto (try all)}"
        echo "  3. Extension filter: ${EXTFILTER:-all}"
        echo
        echo "  q. Back"
        printf '  Choose option: '
        read -r o
        case "$o" in
            1)
                printf '  New folder path: '
                read -r nd
                if [ -n "$nd" ]; then
                    DEST="$nd"
                    mkdir -p "$DEST" 2>/dev/null
                    save_conf
                fi
                ;;
            2)
                i=1
                for m in $MIRRORS; do
                    echo "  $i) $m"
                    i=$((i + 1))
                done
                echo "  a) auto (try all in order)"
                printf '  Choose: '
                read -r mo
                case "$mo" in
                    ''|a|A) PREFERRED="";;
                    *[!0-9]*) : ;;
                    *) PREFERRED=$(printf '%s\n' $MIRRORS | sed -n "${mo}p");;
                esac
                save_conf
                ;;
            3) ask_filter;;
            [qQ]) return 0;;
        esac
    done
}

# ---- main menu -----------------------------------------------------------
while :; do
    clear
    echo "  KF LibGen"
    echo "  ------------------------------------------------"
    echo "  curl   : $CURLVER"
    echo "  books  : $DEST"
    MIRRORSHOW="$MIRROR"
    [ -n "$PREFERRED" ] && MIRRORSHOW="$PREFERRED (preferred)"
    echo "  mirror : ${MIRRORSHOW:-auto}"
    echo "  filter : ${EXTFILTER:-all}"
    echo "  ------------------------------------------------"
    echo "  1. Search and download books"
    echo "  2. Filter search results"
    echo "  3. List my books"
    echo "  4. Settings"
    echo
    echo "  q. Exit"
    printf '  Choose option: '
    read -r opt
    case "$opt" in
        1) do_search;;
        2) ask_filter;;
        3) list_books;;
        4) settings_menu;;
        [qQ]) echo "bye"; exit 0;;
    esac
done
