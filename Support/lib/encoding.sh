#!/usr/bin/bash
#
##################################################
#
# map.sh
#
# Provides simple associative arrays for Bash
# 
# 
# map_put map_name key value
#
function map_put
{
  alias "${1}$2"="$3"
}

# map_get map_name key
# @return value
#
function map_get
{
  alias "${1}$2" | awk -F"'" '{ print $2; }'
}

# map_keys map_name 
# @return map keys
#
function map_keys
{
  alias -p | grep $1 | cut -d'=' -f1 | awk -F"$1" '{print $2; }'
}

# map_load map_name map_text
# 
function map_load
{
  for l in $2
  do
    KEY=$(echo $l | cut -d: -f1)
    VALUE=$(echo $l | cut -d: -f2)
    map_put "$1" "$KEY" "$VALUE"
  done
}

##################################################
#
# encoding.sh
#
# Handles encoding of extended ascii characters for TextMate bundle for FileMaker
#

# Map character ids used by AppleScript
mapName="map"
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
map_load $mapName "$mapText"

# char_list text
# Replaces supplied characters with ASCII number
#
ascii_replace () {
  for l in $mapName
  do
    TAG="#:$(echo $l | cut -d: -f1):#"
    CHAR=$(echo $l | cut -d: -f2)
    TEXT=$(echo "$1" | sed "s/$CHAR/$TAG/")
  done
  echo "$TEXT"
}
# Tried using printf but it didn't work with extended ascii
# TAG="!:$(printf '%d' "'$char"):!"

if [ -n "$1" ]; then
  ascii_replace "$1"
fi
