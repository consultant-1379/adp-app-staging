#!/usr/bin/env bash
sum=$(sha256sum <(find . -type f -exec sha256sum {} ';' | sort))
echo "$sum"
