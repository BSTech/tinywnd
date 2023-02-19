## tinywnd - Simple PoC Win32 GUI Application, all written in x86 Assembly! (my first time with no experience)
_just when you are too bored to make this a thing_

### Features:
- No MASM macros (`invoke`, `struct`, etc.) are used except `equ`
- No structure definition - everything is pure data and offsets
- No local variables - just globals, registers, and the stack as a way of passing parameters
- No `lea` instruction
- No includes of libraries and definitions (including WinAPI library files)
- No import address table - all functions, including LoadLibrary(), are dynamically loaded from [PEB](https://en.wikipedia.org/wiki/Process_Environment_Block)
- Has a "proper" message loop implemented
- Uses Common Controls v6 controls (links, modern buttons, etc.)
- Utilizes the default GUI font instead of the default VGA console font
- Last but not least, a tiny executable file (around 7 kilobytes, which could be shrunk more)

### Bugs:
- Win32's `DispatchMessageA()` function "magically"* increases the `ESP` the size of one `dword`, so we subtract that after the call (I don't even know if it is a bug, but this fix works)

_*: I tried to find and understand why it occurs but couldn't find it (yet)_

### Building:
See `build.cmd` -_you need VS and MASM (`ml.exe`) installed on your system_- <br><br>
As VSCode project:
- run VS developer command prompt
- `cd` into the project folder
- run `code .` (the dot is included)

### Notes:
- During coding, I was learning the x86 Assembly on my own so the comments might be weird or funny depending on your level
- Yes, even though I have used `equ` in a few places, I hardcoded most of the offsets as integers (forgive my laziness)