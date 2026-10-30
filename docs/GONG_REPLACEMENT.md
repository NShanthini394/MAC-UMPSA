# Gong replacement
All three active maps contain one gong each. Removed the baked-in gong and stand from each background using built-in imagegen, preserving map size and composition. Prompt: Remove only the freestanding bronze gong and wooden stand; fill its footprint with matching carpet or ground, keep all other map features unchanged.

The shared gong_marker.gd now renders assets/props/gong_reference_transparent.png with the existing black silhouette outline shader. Per-map display offsets align the sprite above the original meeting interaction point. Clicking and proximity rules remain routed through call_meeting(). The former black circle is removed.

Verified all three with Godot-rendered previews and checked script loading and whitespace. Local Godot user-directory logging warnings remain. APK has not been rebuilt.
