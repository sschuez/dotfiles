import iterm2
import os


async def main(connection):
    # Get the selected theme
    selected_theme = os.getenv("THEME")

    try:
        # Fetch the color preset by name
        preset = await iterm2.ColorPreset.async_get(connection, selected_theme)

        # Check if the preset was found
        if preset is None:
            print(f"Preset '{selected_theme}' not found.")
            return

        # Get the list of all profiles
        profiles = await iterm2.PartialProfile.async_query(connection)

        for partial in profiles:
            profile = await partial.async_get_full_profile()
            await profile.async_set_color_preset(preset)

        print(f"Applied iTerm2 theme: {selected_theme}")

    except iterm2.colorpresets.ListPresetsException:
        print(
            f"Error: Preset '{selected_theme}' not found in iTerm2. Please ensure the preset is imported and available."
        )


# Establish the connection and run the script
iterm2.run_until_complete(main, retry=True)
