# Chatter
[Description]

## Setup 
### Prerequisites
- Python 3.8+
- CMake 3.16+
- A C++20 compiler (MSVC 2019+, GCC 11+, Clang 13+)

Everything else is handled automatically via the bootstrap scripts.

### Bootstrapping
Setup your environment via prepared scripts depending on your OS.
- Windows: Run the script at `.\setup\winBootstrap.ps1` in a Powershell terminal.
- MacOS: (coming soon)
- Linux: (coming soon)

### Linting
To automatically use the linter, your setup will require clang-format. If in VS Code, you can add a block like this into your .vscode/settings.json file (might need to create it yourself)
```
{    
    "[cpp]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "llvm-vs-code-extensions.vscode-clangd"
    }
}
``` 

## Building
(coming soon)
