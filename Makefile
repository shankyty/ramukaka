# Makefile for MacAssistant

.PHONY: build run test clean generate-xcodeproj

default: build

build:
	swift build -c release

run:
	swift build -c release
	./.build/release/MacAssistant

test:
	swift test

clean:
	rm -rf .build

generate-xcodeproj:
	@echo "Error: 'swift package generate-xcodeproj' is deprecated and removed in recent Swift versions."
	@echo "Please open the 'Package.swift' file directly in Xcode to work on the project."
	@exit 1
