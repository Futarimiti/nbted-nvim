#!/usr/bin/env zsh

nvim --cmd 'set rtp+=./ | setlocal ft=nbted' test/level.dat.txt
