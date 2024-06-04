<!-- insert
+++
title = "Ranoth's Utility Static Site"
+++
end_insert -->

# Ranoth's Utility

## Description

Ranoth's Utility is a World of Warcraft addon designed to make **my** life easier.
Kind of like **LeatrixPlus** with features **I** specifically want.

## Features

- Slash commands to open all containers, all easter eggs, and print a bag item's info.
- Slash command to calculate an expression (e.g. /calc 1 + 1 = 2).
- Warlock and engineer utility spells trigger a chat response to advertize their availability to other players.
- Will detect an interrupt from the player or its pet and will trigger a chat response to advertize successfully interrupted spells by link in chat.

> TODO:
>
> - Add a command to toggle the speech on utility spells.
> - Make a persistent config to enable/disable speech on utility spells.
> - Find out how to use the say and yell channels to advertize utility spells and successful interrupts.

## Usage

- Commands:
  - /ranu help - Prints a list of available commands
  - /ranu openall - Opens all containers in your inventory
  - /ranu openeggs - Opens all Noblegarden eggs in your inventory
  - /ranu autoopen - Toggle automation to open all containers in a bag when a container is looted (depending on which bag the container is in)
  - /ranu swlang - Switches spoken language between all available languages for your character
  - /ranu calc - Calculates an expression and prints the result (e.g. /calc 1 + 1, /calc 2 \* 2, /calc 2 / 2)
  - /ranu toggledebug - Toggles debug mode on and off (prints in a "Debug" chat tab in the default chat frame instead of "General")

## Support

If you encounter any issues or have any questions about this addon, please submit an issue on this repository or whisp me in game on the EU cluster [@Ragnoth-Ysondre](https://worldofwarcraft.blizzard.com/en-gb/character/eu/ysondre/ragnoth).

## Contributing

If you want a feature added, feel free to submit a pull request or an issue. I'll review it and merge or implement it I like it.

## License

[MIT](https://choosealicense.com/licenses/mit/)
