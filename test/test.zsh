#!/usr/bin/env zsh

nvim --cmd 'set rtp+=./ | lua r = require("nbted-nvim") r.setup {}' test/level.dat
