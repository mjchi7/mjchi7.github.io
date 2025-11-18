# Makefile for blog project
# Converted from myke.yml

# Default target
.DEFAULT_GOAL := build

# Remove all build artifacts
.PHONY: clean
clean:
	rm -rf docs/

# Build the blog
.PHONY: build
build: clean
	hugo -d docs/
	cp -r images docs/

# Serve the blog locally
.PHONY: serve
serve:
	hugo serve

# Mark all targets as .PHONY since they don't produce files matching their names
.PHONY: all
all: clean build serve