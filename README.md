# collectathon
Collectable items for FiveM. 

This is a framework agnostic version of `esx_collectables`. Completely rewritten with major optimization, fixes and new additions.

## Features
* Framework agnostic
* Includes all 187 collectables from the main game
* Reward players for finding and completing collectables
* Easily add your own custom collectables
* Collectables are spawned locally so all players can have their own collectable hunt.
* Option to walk over collectable to pick it up or manually pick it up via prompt
* Player progress is saved in your database or in a `json` file if required

## Videos
* [Auto Collection](https://streamable.com/0h3glt)
* [Manual Collection (Prompt)](https://streamable.com/oywgzj)
* [Manual Collection (3D Prompt)](https://streamable.com/bcq1bz)
* [Completed](https://streamable.com/vdqrl6)

## Table of Contents

* [Requirements](#requirements)
* [Installation](#installation)
* [Global Config](#global-config)
* [Per-Quest Config](#per-quest-config)
* [Custom Quest Example](#custom-quest-example)
* [Videos](#videos)
* [Contributing](#contributing)
* [Legal](#legal)

---

## Requirements

* [ghmattimysql](https://github.com/GHMatti/ghmattimysql) (optional)
* [fivem-mysql-async](https://github.com/brouznouf/fivem-mysql-async) (optional)

By default this uses `ghmattimysql`, but if you want to use `fivem-mysql-async` then

* Set `Config.MySQLLib = 'fivem-mysql-async'` in `config.lua`
* Uncomment `'@mysql-async/lib/MySQL.lua'` in `fxmanifest.lua`

You can also use this resource without a database by utilising `json`:

* Set `Config.MySQLLib = 'json'` in `config.lua`

This will create `collectathon.json` in your root directory

---

## Installation
* Drag the `collectathon` directory into your `resources` directory
* Import `collectathon.sql` into your database
* Add `ensure collectathon` in your `server.cfg`

**Note**: If you already have the `user_collectables` table in your database from `esx_collectables` then importing the new `collectathon.sql` will drop it.

---

## Global Config

#### `MySQLLib`
##### type: `string` | default: `'ghmattimysql'`
##### options: `'ghmattimysql'`, `'fivem-mysql-async'`, `'json'`

Sets the saving method.

Setting to `'json'` will create `collectathon.json` in your root directory where players progress is saved.

---

#### `Debug`
##### type: `boolean` | default: `false`

Enables / disabled debug mode. Debug mode shows hidden collectables on the map and a marker above the item.

---

#### `DrawDistance`
##### type: `integer` | default: `50`

Sets the distance before spawning and checks are made on an item.
Decreasing values will be more performant, but may mean items won't spawn until the play is close.
Auto-spawning when within this distance can be overriden by the `immediate` option.

---

#### `PickupSound`
##### type: `boolean` | default: `true`

Enables or disables the pick up sound

---
#### `PickupType`
##### type: `string` | default: `'auto'`
##### options: `'auto'` | `'manual'`

When set to `'auto'` the player needs to walk / drive over the item to retrieve it
When set to `'manual'` the player needs to hit `E` to retrieve the item

---

#### `PickupPrompt`
##### type: `string`
##### options: `'help'` | `'floating'`

When set to `'help'` a standard help notification will appear in the top left
When set to `'floating'` 3d text will float over the item

Used only when `PickupType` is set to `manual`

---

#### `PickupMessage`
##### type: `boolean` | default: `true`

Enable / disable the on-screen messages

---

## Per-Quest Config

#### `Enabled`
##### type: `boolean` | default: `true`

Enable disable the quest

---

#### `Title`
##### type: `string`

The title of the quest

---

#### `Name`
##### type: `string`

The name of the quest items.

Can be included in the individual item to override this.

---

#### `Prop`
##### type: `string`

The prop to use for the quest items.

Can be included in the individual item to override this.

---

#### `Revolve`
##### type: `boolean`

Enable / disable revolving props.

This option can add `0.03ms` when near an item.

Can be included in the individual item to override this.

---

#### `Immediate`
##### type: `boolean`

Disables auto-spawning of the prop when player is in range.

Can be included in the individual item to override this.

---

#### `Grounded`
##### type: `boolean`

When enabled, this option places the item on the ground. When disabled, it is frozen to the defined `Coords`.

Can be included in the individual item to override this.

---

#### `OnCollect`
##### type: `function`

User-defined callback fired when an item is collected.

Can be included in the individual item to override this.

---

#### `OnComplete`
##### type: `function`

User-defined callback fired when a quest is completed.

---

#### `Items`
##### type: `table`

A list of quest items.

Each item must have a unique `integer` `ID` as well as the `Coords`.

```lua
Items = {
        { ID = 1, Coords = vector3(-1020.60, -2969.14, 12.95) },
        { ID = 2, Coords = vector3(-1015.70, -2971.60, 12.95) },
        { ID = 3, Coords = vector3(-1018.10, -2975.98, 12.95) },
        ...
}
```

Each item can take the `Name`, `Prop`, `Revolve`, `Immediate`, `Grounded` and `OnCollect` options to override the quest options:

```lua
    {
        ID = 1, -- unique `integer` ID
        Name = 'Hammer', -- Name of the collectable
        Prop = 'prop_tool_hammer', -- The prop to spawn
        Revolve = true, -- Set item to revolve
        Immediate = true, -- Spawn immediately or automatically when player is near
        Grounded = false, -- Set the item on the ground or leave it floating               
        Coords = vector3(-43.04, -1096.50, 25.40), -- The position on the map
        OnCollect = function(item, quest)
            -- do something when an item is collected
        end
    },
```
---

## Custom Quest Example

```lua
LostTools = {
    Enabled = true,
    Title = "Lost Tools",
    Revolve = true,
    Items = {
        {
            ID = 1,
            Name = 'Hammer',
            Prop = 'prop_tool_hammer',
            Coords = vector3(-43.04, -1096.50, 25.40)
        },
        {
            ID = 2,
            Name = 'Screwdriver',
            Prop = 'prop_tool_screwdvr01',
            Coords = vector3(-43.59, -1097.57, 25.40)
        },
        {
            ID = 3,
            Name = 'Pliers',
            Prop = 'prop_pliers_01',
            Coords = vector3(-44.39, -1099.10, 25.40)
        },
        {
            ID = 4,
            Name = 'Drill',
            Prop = 'xs_prop_x18_drill_01a',
            Coords = vector3(-45.07, -1100.46, 25.40)
        },
    },
    OnCollect = function(item, quest)
        -- do something when an item is collected
    end,    
    OnComplete = function(item, quest)
        -- do something when quest is completed
    end    
}
```

---

## Contributing
Pull requests welcome.

---

## Legal

### License

collectathon - Collectable items for FiveM

Copyright (C) 2021 Mobius1

This program Is free software: you can redistribute it And/Or modify it under the terms Of the GNU General Public License As published by the Free Software Foundation, either version 3 Of the License, Or (at your option) any later version.

This program Is distributed In the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty Of MERCHANTABILITY Or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License For more details.

You should have received a copy Of the GNU General Public License along with this program. If Not, see http://www.gnu.org/licenses/.