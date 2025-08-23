# Lua Card Game

A card-based game built with LÖVE (Love2D) framework using Lua.

## Description

This is a card game that features:
- Plant and Magic card types
- Potion crafting mechanics
- Deck building elements
- Strategic gameplay

## Prerequisites

To run this game, you need to have LÖVE (Love2D) installed on your system.

### Installing LÖVE

**macOS:**
```bash
# Using Homebrew
brew install love

# Or download from https://love2d.org/
```

**Windows:**
- Download from https://love2d.org/
- Extract and add to PATH

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install love

# Fedora
sudo dnf install love

# Arch
sudo pacman -S love
```

## Running the Game

1. Clone this repository:
```bash
git clone <your-repository-url>
cd <repository-name>
```

2. Run the game:
```bash
love .
```

Or drag the project folder onto the LÖVE executable.

## Project Structure

```
├── main.lua              # Main entry point
├── conf.lua              # LÖVE configuration
├── core_game.lua         # Core game logic and data
├── draw.lua              # Drawing and rendering functions
├── handlers.lua          # Input and event handlers
├── bubbles.lua           # Bubble/particle effects
├── sort.lua              # Sorting algorithms
├── inspect.lua           # Debug/inspection utilities
├── ui/                   # User interface components
│   ├── button.lua
│   ├── overlay_manager.lua
│   ├── potion_decision_overlay.lua
│   ├── potion_list_overlay.lua
│   ├── shop_overlay.lua
│   ├── spell_selection_overlay.lua
│   ├── deck_view_overlay.lua
│   └── game_over_overlay.lua
└── NOTES/                # Development notes
```

## Development

This project uses:
- **Lua** as the primary language
- **LÖVE (Love2D)** as the game framework
- **StyLua** for code formatting (see `stylua.toml`)
- **Luacheck** for linting (see `.luacheckrc`)

### Code Style

The project follows Lua best practices with:
- Consistent indentation (4 spaces)
- Descriptive variable and function names
- Modular code organization
- Comprehensive comments

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Built with [LÖVE (Love2D)](https://love2d.org/)
- Inspired by card-based strategy games
