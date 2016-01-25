# Duplicate weapon locator for Team Fortress 2

Just a little script to help me identify weapons to smelt or trade for scrap.

Needs a Steam ID and [Steam API](https://steamcommunity.com/dev) key to get the
needed data from Steam. Can pass these to get_items or put them in env variables
STEAM_ID and STEAM_API_KEY.

Two json files are saved locally and then parsed and sorted. I only uncomment
the get_items call when I know I want to re-download my current inventory. No
need to re-download the same thing while I'm developing and testing this script.

I have it showing only weapons, sorting by quality and then index (so identical
  weapons should be grouped together with Unique quality at the bottom of each
  group) and then listing:

- If they have Non-Tradable flag (possibly temporary, but my script doesn't try to1 find out)
- Quality
- Level (meaningless in-game, but some people care)
- Name (I don't think it will show custom names; I don't have anything tagged)
- Origin (Achievement, timed drop, etc.)
