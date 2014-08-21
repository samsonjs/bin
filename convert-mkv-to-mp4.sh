#!/bin/bash
#
# convert-mkv-to-mp4.sh
#
# Copyright (c) 2014 Don Melton
#

about() {
    cat <<EOF
$program 1.0 of July 9, 2014
Copyright (c) 2013-2014 Don Melton
EOF
    exit 0
}

usage() {
    cat <<EOF
Convert Matroska video file into MP4 format without transcoding.

Usage: $program [OPTION]... [FILE]

    --help      display this help and exit
    --version   output version information and exit

Requires \`ffprobe\`, \`ffmpeg\` and \`mp4track\` executables in \$PATH.
Output is written to current working directory.
EOF
    exit 0
}

syntax_error() {
    echo "$program: $1" >&2
    echo "Try \`$program --help\` for more information." >&2
    exit 1
}

die() {
    echo "$program: $1" >&2
    exit ${2:-1}
}

readonly program="$(basename "$0")"

case $1 in
    --help)
        usage
        ;;
    --version)
        about
        ;;
esac

readonly input="$1"

if [ ! "$input" ]; then
    syntax_error 'too few arguments'
fi

if [ ! -f "$input" ]; then
    die "input file not found: $input"
fi

readonly output="$(basename "$input" | sed 's/\.[^.]*$//').mp4"

if [ -e "$output" ]; then
    die "output file already exists: $output"
fi

for tool in ffprobe ffmpeg mp4track; do

    if ! $(which $tool >/dev/null); then
        die "executable not in \$PATH: $tool"
    fi
done

readonly container="$(ffprobe -show_format "$input" 2>/dev/null | sed -n '/^format_name=/p' | sed 's/^.*=//;s/,.*$//')"

if [ "$container" != 'matroska' ]; then
    die "input file not Matroska format: $input"
fi

readonly track1="$(ffprobe -show_streams -select_streams a:0 "$input" 2>/dev/null | sed -n '/^codec_name=/p' | sed 's/^.*=//;s/,.*$//')"
readonly track2="$(ffprobe -show_streams -select_streams a:1 "$input" 2>/dev/null | sed -n '/^codec_name=/p' | sed 's/^.*=//;s/,.*$//')"

adjust_defaults=''

if [ "$track1" == 'ac3' ] && [ "$track2" == 'aac' ]; then
    map_options='-map 0:2 -map 0:1'
    adjust_defaults='true'

elif [ "$track1" == 'aac' ]; then
    map_options='-map 0:1'
else
    die "input file does not contain compatible audio tracks: $input"
fi

echo "Converting: $input" >&2

time {
    ffmpeg \
        -i "$input" \
        -map 0:0 \
        $map_options \
        -c copy \
        "$output" \
        || exit 1

    if [ "$adjust_defaults" ]; then
        mp4track --track-index 1 --enabled true "$output" &&
        mp4track --track-index 2 --enabled false "$output" || exit 1
    fi
}
