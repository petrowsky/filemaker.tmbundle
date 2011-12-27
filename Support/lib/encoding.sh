#!/usr/bin/env bash
#
# encoding.sh
#
# Handles encoding of extended ascii characters for TextMate bundle for FileMaker
#

# Map character ids used by AppleScript
mapText="161:¡
162:¢
163:£
165:¥
167:§
168:¨
169:©
170:ª
171:«
172:¬
174:®
175:¯
176:°
177:±
180:´
181:µ
182:¶
183:·
247:÷
338:Œ
339:œ
376:Ÿ
402:ƒ
710:ˆ
732:˜
8211:–
8212:—
8216:‘
8217:’
8218:‚
8220:“
8221:”
8222:„
8225:‡
8226:•
8230:…
8240:‰
8249:‹
8250:›
8482:™"

# char_list text
# Replaces supplied characters with ASCII number
# printf doesn't support extended ascii, so provide manual mappings
#
ascii_replace () {
  TEMPFILE=`mktemp -t filemaker`
  echo "$1" > "$TEMPFILE"
  for l in $mapText
  do
    TAG="#:$(echo $l | cut -d: -f1):#"
    CHAR=$(echo $l | cut -d: -f2)
    TEXT=$(cat $TEMPFILE | sed "s/$CHAR/$TAG/g")
    echo "$TEXT" > "$TEMPFILE"
  done
  cat "$TEMPFILE"
}

# Perform replacement on input
if [ -n "$1" ]; then
  ascii_replace "$1"
fi