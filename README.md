# CS2 and CounterStrikeSharp on Pterodactyl

Docker image and Pterodactyl egg to run CS2 servers on [Valve's SteamRT3 platform](https://gitlab.steamos.cloud/steamrt/sniper/platform). The main feature of this egg is the ability to run CS2 servers with automatic updates and installation of [CounterStrikeSharp](https://github.com/roflmuffin/CounterStrikeSharp) once enabled in the server settings.

Everything else is completely based on the original CS2 egg by [1zc](https://github.com/1zc/CS2-Pterodactyl). Full credit goes to him for the original egg.

The underlying Docker image is based on Valve's Steam Runtime 3 (Sniper), which should be able to run both CS:GO and CS2 without any issues. The image also can be rebuilt easily as soon as Valve updates their base SteamRT3 image, so we can stay on top of their updates without worrying too much about it.

The CS2 image also ensures the `gameinfo.gi` file is configured for MetaMod automatically on server restart, which should be convenient for modded servers.

## How to use

- Download egg(s) from the `/pterodactyl` directory.
  - `cs2.json`: Egg for CS2
- Import into your Pterodactyl nest of choice. [Read here if you need a guide on how to do this.](https://github.com/parkervcp/eggs#how-to-import-an-egg)
