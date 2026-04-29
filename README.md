# Spawn Selector (NS2)

Workshop ID: 3692961962

A lightweight standalone mod for Natural Selection 2 adapted from the NSL mod that allows the Alien Commander to select the starting hive location before the round begins — now with optional JSON-based map configuration.

---

## ✨ Features

- Alien starting hive selection menu
- Supports **map-specific spawn rules via JSON config**
- Restrict or customize:
  - Alien spawn locations
  - Marine spawn locations
  - Spawn pairings between teams
- Falls back to **vanilla behavior** for unconfigured maps
- Clean standalone implementation inspired by the NSL mod (no dependency required)
- Lightweight and easy to extend

---

## ⚙️ How it works

1. Alien Commander is presented with a spawn selection menu
2. Available Tech Points are filtered (if configured)
3. Alien selects a starting location
4. Marine spawn is chosen based on configured rules
5. Game starts using the selected spawns

---

## 🧩 Configuration

Spawn rules can be customized per map using a JSON file located in:
```
lua/SpawnSelector/config/
```
- Only maps listed in the config are affected
- Unlisted maps use **default NS2 spawn logic**
- Supports:
  - Fixed spawn pairings
  - Multiple possible enemy spawns
  - Fully custom map specific setups

👉 See [CONFIG.md](CONFIG.md) for full configuration guide

---

## 📝 Notes

- Based on the NSL spawn selector system, but simplified and standalone
- Configuration system is optional — mod works without it
- Designed to be easy to tweak or extend

---

## 🚧 Future Improvements (Possible, not guaranteed)

- Admin commands (enable/disable rules in-game)
- Better UI feedback for restricted spawns
- Validation/logging for config errors

---

## 🙏 Credits

- Original concept and implementation inspired by the NSL mod  
  https://github.com/xToken/NSL

---

## 📄 License

See `LICENSE.txt` for details.
