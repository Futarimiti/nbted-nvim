# NBTed-nvim

This plugin lets you edit Minecraft NBT files directly in nvim
with the help of [`nbted`][nbted], the command line NBT editor.

## Rationale

[`nbted`][nbted] is an awesome command line NBT editor
that makes it possible to edit NBT in a human-friendly way,
and most importantly, in **your own favourite editor** (i.e. nvim).
I do however, find it a bit of annoying to type `nbted` everytime
while already forming the muscle memory of `nvim <file>`;
also you must exit nvim everytime you finish editing
for `nbted` to "encode" your edits.
Why can't you just open it directly with nvim
and encode it whenever you save so you don't have to
leave nvim everytime?
That's what I have pictured at least, and now here it is.

Also I believe some syntax highlighting would be good
so you're welcome.

## Installation

```lua
use 'Futarimiti/nbted-nvim'
```

## Usage

`require 'nbted-nvim'` comes with only one function: `setup`;
other functionalities will be added once completed the setup.

```lua
local nbt = require 'nbt-nvim'
nbt.setup {}
nbt.use_some_functionality()  -- ...
```

## Configuration

Use `setup` to configure this plugin,
which will remove itself after you call it.

Similar to most nvim plugins,
`setup` accepts a table of optional configuring parameters,
listed and explained below.

| Parameter          | Type                         | Desc                                                                                                                                                   |
|--------------------|------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `auto_detect_nbt`  | bool                         | Auto detect NBT file upon entering a new buffer, and immediately turn to edit its human-readable translation. Uses `detect_nbt` if enabled.            |
| `auto_encode`      | bool                         | Upon saving, auto encode human-readable text into NBT and write to the original NBT file. Will backup on the first time if enabled `backup_on_encode`. |
| `enable_commands`  | bool                         | Create vim command `:NBT do_sth` as equivalent to `require('nbted-nvim').do_sth()`.                                                                    |
| `backup_on_encode` | bool                         | **Highly recommend enable at the moment**. See `auto_encode`.                                                                                          |
| `verbose`          | bool                         | Produce helpful (or long-winded) logs as you use the functionalities.                                                                                  |
| `nbted_command`    | string                       | `path/to/your/nbted/executable`, or simply `nbted` if that's already on your PATH.                                                                     |
| `detect_nbt`       | `'auto' \| filepath -> bool` | Used by `auto_detect_nbt`, determine if a file is a compressed NBT from its full filepath. Use `'auto'` to let me take a (poor) guess.                 |
| `minecraft_dir`    | `'infer' \| filepath`        | Absolute filepath of Minecraft data directory, for example `%appdata%/.minecraft`. Use `'infer'` to infer it based on your OS.                         |

Default configuration:

```lua
{ auto_detect_nbt = false
, auto_encode = false
, enable_commands = false
, backup_on_encode = true
, verbose = false
, nbted_command = 'nbted'
, detect_nbt = 'auto'
, minecraft_dir = 'infer'
}
```

## Functionalities

### Decoding

`nbt.decode()` or `:NBT decode` tries to read the current file, 
assuming it is a compressed NBT,
and decodes it into human-friendly syntax in a tempfile for you to edit.

### Encoding

After decoding, you can encode on the decoded tempfile
to encode it back into compressed NBT format to save your edits
via `nbt.encode()` or `:NBT encode`,
which will not be available until you have previously decoded.
The original NBT file will be overriden and a backup may or 
may not be created, according to your configuration.

### Automating

`auto_detect_nbt`: automatically detect if you're editting on
a compressed NBT file when entering a new buffer;
If so, you will be directly editting its decoded version.

`auto_encode`: write encoded result to the original NBT file
everytime you save on the decoded tempfile.

[nbted]: https://github.com/C4K3/nbted
