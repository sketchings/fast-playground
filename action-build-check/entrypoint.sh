#!/bin/sh -l

sh -c "echo build development image"
sh -c "make build"
sh -c "echo run linter"
sh -c "make lint"
sh -c "echo run formatter"
sh -c "make format BLACK_ARGS=--check"
sh -c "echo cleanup"
sh -c "docker-compose down -v"
