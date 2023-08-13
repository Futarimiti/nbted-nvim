if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "nbted"

syntax region nbtString start=/\v"/ skip=/\v\\./ end=/\v"/
syntax keyword nbtBuiltinType Int Double Byte Long List String Float Short
syntax keyword nbtArray IntArray ByteArray LongArray
syntax keyword nbtCompound Compound
syntax keyword nbtEnd End
syntax keyword nbtZipMetmod Gzip Zlib
syntax match nbtNumber "\v[-]?[0-9]*[.]?[0-9]+"

highlight default link nbtString String
highlight default link nbtBuiltinType Type
highlight default link nbtArray Type
highlight default link nbtCompound Structure
highlight default link nbtEnd Structure
highlight default link nbtZipMetmod Structure
highlight default link nbtNumber Number
