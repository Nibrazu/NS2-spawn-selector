
# Spawn Selector – Config Guide

This file controls **which starting locations are allowed per map**.

## 📍 Config file:
"mod-folder"/lua/SpawnSelector/config/DEFAULT.json

---

## 🧠 How it works

- Only maps listed in the config are affected
- Any map **not listed** → uses vanilla spawn logic

---

## ➕ Adding a new map

### 1. Make a copy of the example block
```json
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
```
### 2. Replace it with your map and real tech point names
```json
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
```
### 3. Watch your commas

- If the map block is **not** the last one → keep the comma
- If it **is** the last one → remove the comma

---

## 🧱 Rule format
```
| Field         | Description                             |
| `name`        | Tech point (must match in-game exactly) |
| `team`        | `"Aliens"`, `"Marines"` or `"Both"`     |
| `weight`      | Chance weight (leave as `1`)            |
| `enemyspawns` | Allowed enemy start locations           |
```
If multiple enemy spawns are allowed, list them in the same array:
```json
"enemyspawns": ["Cafeteria", "Terminal"]
```
---

## 🎯 Examples

### Fixed marine spawn

Aliens → 2 options
Marines → always 1
```json
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
```
### Random marine spawn

Aliens pick 1 → Marines get 2 possible
```json
{
  "name": "Generator",
  "team": "Aliens",
  "weight": 1,
  "enemyspawns": ["Cafeteria", "Terminal"]
}
```
---

## 🔁 Editing existing maps

Find the map block
Edit spawnData
Save file
Restart server

---

## 🚫 Disable a map
```
"enabled": false
```
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

Copy an existing working map block
Change only the map name and tech point names
Keep weight as 1 unless you intentionally want weighted randomness
Test one map at a time
Check console logs on map load if you have issues
