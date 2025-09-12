# rbx-asset-jailbreak

This is a tool / workflow that allows bypassing roblox's constraints regarding the of use other people's assets with editable images / editable meshes. Note that this only works in studio.

As per the documentation:
> To prevent misuse, Create Editable APIs will only allow you to load and assets:
> - That are owned by the creator of the experience (if the experience is owned by an individual).
> - That are owned by a group (if the experience is owned by the group).
> - That are owned by the logged in Studio user (if the place file has not yet been saved or published to Roblox).

It was mainly written to allow me to fiddle with a number of test-cases quickly and easily.

This is likely not of significant use beyond learning purposes / debugging.

## How does it work?

In short, there are two parts to this tool.

The first is a plugin component which does some sanity checks / probing and then sends a request via the http service to lune (the second component). Lune then downloads a copy of the asset and puts it in your studio content folder. From there the plugin can now reference that file via the `rbxasset://` scheme which roblox considers a local asset and thus lets you load as an editable mesh / image.

## TODO

- Use a open cloud api key instead of the logged in cookie / legacy api
- Support more asset types (?)