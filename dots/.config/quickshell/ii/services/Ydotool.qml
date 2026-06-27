pragma Singleton

import qs.modules.common
import Quickshell

Singleton {
    id: root
    property int shiftMode: 0 // 0: off, 1: on, 2: lock
    property list<int> shiftKeys: [42, 54] // Keycodes for Shift keys (left and right)
    property list<int> altKeys: [56, 100] // Keycodes for Alt keys (left and right)
    property list<int> ctrlKeys: [29, 97] // Keycodes for Ctrl keys (left and right)
    // Sticky modifiers (Ctrl/Alt/Super): armed by tapping, applied to the next key, never held.
    // Holding them down instead would let Hyprland's Super+mousedown bind drag windows on every tap.
    property list<int> armedMods: []

    function toggleMod(keycode) {
        const i = root.armedMods.indexOf(keycode);
        if (i >= 0) {
            const a = root.armedMods.slice();
            a.splice(i, 1);
            root.armedMods = a;
        } else {
            root.armedMods = [...root.armedMods, keycode];
        }
    }

    function clearMods() {
        root.armedMods = [];
    }

    // Tap a key with all armed modifiers applied atomically (press mods, tap key, release mods),
    // then clear them, so modifiers are never held across mouse events.
    function tapWithMods(keycode) {
        const seq = [];
        for (const m of root.armedMods) seq.push(`${m}:1`);
        seq.push(`${keycode}:1`, `${keycode}:0`);
        for (let i = root.armedMods.length - 1; i >= 0; --i) seq.push(`${root.armedMods[i]}:0`);
        Quickshell.execDetached(["ydotool", "key", "--key-delay", "0", ...seq]);
        root.armedMods = [];
    }

    function releaseAllKeys() {
        const keycodes = Array.from(Array(249).keys());
        Quickshell.execDetached([
            "ydotool",
            "key", "--key-delay", "0",
            ...keycodes.map(keycode => `${keycode}:0`)
        ])
        root.shiftMode = 0; // Reset shift mode
        root.armedMods = []; // Reset sticky modifiers
    }

    function releaseShiftKeys() {
        Quickshell.execDetached([
            "ydotool",
            "key", "--key-delay", "0",
            ...root.shiftKeys.map(keycode => `${keycode}:0`)
        ])
        root.shiftMode = 0; // Reset shift mode
    }

    function press(keycode) {
        Quickshell.execDetached([
            "ydotool",
            "key", "--key-delay", "0",
            `${keycode}:1`
        ]);
    }

    function release(keycode) {
        Quickshell.execDetached([
            "ydotool",
            "key", "--key-delay", "0",
            `${keycode}:0`
        ]);
    }
}
