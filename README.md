Instructions for Installation:

## What you will require:
  - The content (https://steamcommunity.com/sharedfiles/filedetails/?id=3673650056)
  - A database (for local host/development use XAMPP instead of a production database)
  - The framework (monarch)
  - A schema (see monarch-ebrp)

## Installation:
  - Install content pack
  - Setup a database and plug in values to the Config.DBInfo table in modules/server/sv_sql.lua
  - Configure the default operator and other important values (default operator will give the player with the corresponding steamid superadmin)
  - Press Play!
  - All in game config (map config, loot, etc.) can be done at run-time as most map and other info is saved and loaded from JSON files or the Database.

## Contribution:
  - Please follow the code style used in the framework
  - Please direct all pull requests to the [dev branch](https://github.com/Ashfall-Studios/monarch-main/tree/dev)

If you run into issues or have questions, please join [our discord](https://discord.com/invite/cNhv8f3Upu)
