# Ranoth's Utility

## Description

Ranoth's Utility is a World of Warcraft addon designed to make **my** life easier.
Kind of like **LeatrixPlus** with features **I** specifically want.

## Features

- Slash commands to open all containers, all easter eggs, and print a bag item's info.
- Warlock and engineer utility spells trigger a chat response to advertize their availability to other players.
- Will detect an interrupt from the player or its pet and will trigger a chat response to advertize successfully interrupted spells by link in chat.

> TODO:
>
> - Add a command to toggle the speech on utility spells.
> - Make a persistent config to enable/disable speech on utility spells.
> - Find out how to use the say and yell channels to advertize utility spells and successful interrupts.

<!-- ## Installation

To install Ranoth's Utility, follow these steps: -->

## Usage

- Commands:
  - /openall - Opens all containers in your inventory
  - /openeggs - Opens all Noblegarden eggs in your inventory
  - /dumpii(bag, slot) - Prints the item info for the item in the specified bag and slot
    > Note that the slot is 1-indexed, not 0-indexed and you can know the bag and slot numbers by using the framestack debug feature
  - /swlang - Switches spoken language between all available languages for your character

## Support

If you encounter any issues or have any questions about this addon, please submit an issue on this repository or whisp me in game on the EU cluster [@Ragnoth-Ysondre](https://worldofwarcraft.blizzard.com/en-gb/character/eu/ysondre/ragnoth).

## Contributing

If you want a feature added, feel free to submit a pull request or an issue. I'll review it and merge or implement it I like it.

## License

[MIT](https://choosealicense.com/licenses/mit/)
