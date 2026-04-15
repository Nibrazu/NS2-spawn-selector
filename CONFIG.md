# Spawn Selector – Config Guide

This file controls **which starting locations are allowed per map**.

## 📍 Config file:
configs/spawnselector/DEFAULT.json

---

# 🧠 How it works

- Only maps listed in the config are affected
- Any map **not listed** → uses vanilla spawn logic
- No config = no changes = safe by default

---

## ➕ Adding a new map

### 1. Make a copy of the example block

      {
        "name": "EXAMPLE - COPY THIS BLOCK",
        "description": "Duplicate this block, rename the map, and replace the tech point names with real ones from your map.",
        "enabled": false,
        "spawnData": [
          {
            "name": "Tech Point A",
            "team": "Marines",
            "weight": 1,
            "enemyspawns": ["Tech Point B"]
          },
          {
            "name": "Tech Point B",
            "team": "Aliens",
            "weight": 1,
            "enemyspawns": ["Tech Point A"]
          }
        ]
      }
    ],

### 2. Replace the information with the map you want to set custom spawn rules

    "ns2_jambi": [
      {
        "name": "Jambi custom rules",
        "description": "Aliens may only start at Pipeworks or Waste Recycling. Marines always start at Docking Bay.",
        "enabled": true,
        "spawnData": [
          {
            "name": "Pipeworks",
            "team": "Aliens",
            "weight": 1,
            "enemyspawns": ["Docking Bay"]
          },
          {
            "name": "Waste Recycling",
            "team": "Aliens",
            "weight": 1,
            "enemyspawns": ["Docking Bay"]
          },
          {
            "name": "Docking Bay",
            "team": "Marines",
            "weight": 1,
            "enemyspawns": ["Pipeworks", "Waste Recycling"]
          }
        ]
      }
    ], 
### (careful with the comma here, if it's the last map remove it, if not keep it.)

---

## 🧱 Rule format

                                    | Field         | Description                             |
  "name": "Pipeworks",              | `name`        | Tech point (must match in-game exactly) |
  "team": "Aliens",                 | `team`        | `"Aliens"`, `"Marines"` or `"Both"`     |
  "weight": 1,                      | `weight`      | Chance weight (leave as `1`)            |
  "enemyspawns": ["Docking Bay"]    | `enemyspawns` | Allowed enemy start locations           |

---

## 🎯 Examples

### Fixed marine spawn

Aliens → 2 options
Marines → always 1

{
  "name": "Pipeworks",
  "team": "Aliens",
  "enemyspawns": ["Docking Bay"]
}

### Random marine spawn

Aliens pick 1 → Marines get 2 possible

{
  "name": "Generator",
  "team": "Aliens",
  "enemyspawns": ["Cafeteria", "Terminal"]
}

---

## 🔁 Editing existing maps

Find the map block
Edit spawnData
Save file
Restart server

---

## 🚫 Disable a map

"enabled": false

---

## ❌ Remove a map

Delete the block completely → map becomes vanilla again

---

## ⚠️ Common mistakes

❌ Wrong room name
✔ Must match exactly (e.g. "Docking Bay")

❌ Wrong map name
✔ Must match file name (ns2_jambi)

❌ JSON errors
✔ No trailing commas
✔ Use " not '

---

## 🧰 Formatting (VSCode)

Auto-format file: Shift + Alt + F

---

## ✅ Best practice

Copy existing working map
Change names only
Keep weight: 1
Test one map at a time

---

## 🛡️ Safe behavior

If a map is not in this file:
👉 Spawn Selector does nothing
👉 Game uses normal NS2 spawn logic