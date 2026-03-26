# Spawn Selector (NS2)

A lightweight standalone mod for Natural Selection 2 adapted from the NSL mod that allows the Alien Commander to select the starting hive location before the round begins.

## Features

- Alien starting hive Menu
- All viable Tech Points are available for selection
- Marine spawn is automatically selected depending on map and/or Alien start
- Clean standalone implementation (no NSL dependency)
- Minimal and easy to extend

## How it works

1. Alien Commander is presented with a spawn selection menu
2. A Tech Point is selected
3. Server stores the selected hive
4. Marine spawn is automatically chosen
5. Game starts using the selected spawns

## Notes

- This is a stripped-down version of the NSL spawn selector system
- JSON/config system was intentionally removed for simplicity
- Designed to be easy to modify or extend

## Future Improvements (I might add in the future if needed)

- Configurable spawn rules 
- Map-specific spawn pairing logic
- Admin controls
- UI improvements

## Credits

- Original concept and implementation inspired by the NSL mod  
  https://github.com/xToken/NSL

## License

See `LICENSE.txt` for details.
