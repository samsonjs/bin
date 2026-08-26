# Compiled tools live in the parent dir alongside the scripts.
all: ../screenshare-display

../screenshare-display: screenshare-display.swift
	swiftc -O -o $@ $<

.PHONY: all
