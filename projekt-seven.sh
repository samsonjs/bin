#!/bin/sh

VOICES=$(say -v '?' | cut -d' ' -f1)
while true; do
  VOICE=$(echo "$VOICES" | perl -e 'srand; rand($.) < 1 && ($line = $_) while <>; print $line;')
  echo "$VOICE"
  say -v "$VOICE" project seven
  sleep 0.3
done
