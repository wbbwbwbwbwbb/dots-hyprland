import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    // Never steal keyboard focus from the focused surface (matters when embedded in the lock screen,
    // where the password field must keep focus so injected keystrokes land in it)
    focusPolicy: Qt.NoFocus
    property var keyData
    property string key: keyData.label
    property string type: keyData.keytype
    property var keycode: keyData.keycode
    property string shape: keyData.shape
    property bool isShift: Ydotool.shiftKeys.includes(keycode)
    // Non-shift modifiers (Ctrl/Alt/Super) behave as sticky one-shot keys
    property bool isMod: root.type == "modkey" && !isShift
    // Caps Lock toggles the keyboard's caps-lock state (same as double-tapping Shift)
    property bool isCaps: root.type == "caps"
    property bool isBackspace: (key.toLowerCase() == "backspace")
    property bool isEnter: (key.toLowerCase() == "enter" || key.toLowerCase() == "return")
    property real baseWidth: 45
    property real baseHeight: 45
    property var widthMultiplier: ({
        "normal": 1,
        "fn": 1,
        "tab": 1.6,
        "caps": 1.9,
        "shift": 2.5,
        "control": 1.3
    })
    property var heightMultiplier: ({
        "normal": 1,
        "fn": 0.7,
        "tab": 1,
        "caps": 1,
        "shift": 1,
        "control": 1
    })
    toggled: isShift ? Ydotool.shiftMode : (isCaps ? (Ydotool.shiftMode == 2) : (isMod ? Ydotool.armedMods.includes(root.keycode) : false))

    enabled: shape != "empty"
    colBackground: shape == "empty" ? ColorUtils.transparentize(Appearance.colors.colLayer1) : Appearance.colors.colLayer1
    buttonRadius: Appearance.rounding.small
    implicitWidth: baseWidth * widthMultiplier[shape] || baseWidth
    implicitHeight: baseHeight * heightMultiplier[shape] || baseHeight
    Layout.fillWidth: shape == "space" || shape == "expand"

    Connections {
        target: Ydotool
        enabled: isShift
        function onShiftModeChanged() {
            if (Ydotool.shiftMode == 0) {
                capsLockTimer.hasStarted = false;
            }
        }
    }

    Timer {
        id: capsLockTimer
        property bool hasStarted: false
        property bool canCaps: false
        interval: 300
        function startWaiting() {
            hasStarted = true;
            canCaps = true;
            start();
        }
        onTriggered: {
            canCaps = false;
        }
    }

    downAction: () => {
        // Sticky modifiers and Caps Lock are handled on release, not held down here
        if (root.isMod || root.isCaps) return;
        if (root.type == "normal" && Ydotool.armedMods.length > 0) return;
        Ydotool.press(root.keycode);
        if (isShift && Ydotool.shiftMode == 0) Ydotool.shiftMode = 1;
    }
    releaseAction: () => {
        if (root.type == "normal") {
            if (Ydotool.armedMods.length > 0) {
                Ydotool.tapWithMods(root.keycode); // e.g. Super+1, Ctrl+Alt+Del
            } else {
                Ydotool.release(root.keycode);
            }
            if (Ydotool.shiftMode == 1) {
                Ydotool.releaseShiftKeys()
            }
        } else if (isShift) {
            if (Ydotool.shiftMode == 1) {
                if (!capsLockTimer.hasStarted) {
                    capsLockTimer.startWaiting();
                } else {
                    if (capsLockTimer.canCaps) {
                        Ydotool.shiftMode = 2; // Caps lock mode
                    } else {
                        Ydotool.releaseShiftKeys()
                    }
                }
            } else if (Ydotool.shiftMode == 2) {
                Ydotool.releaseShiftKeys();
            }
        } else if (root.isCaps) {
            if (Ydotool.shiftMode == 2) {
                Ydotool.releaseShiftKeys(); // turn caps lock off (resets shiftMode to 0)
            } else {
                if (Ydotool.shiftMode == 0) Ydotool.press(Ydotool.shiftKeys[0]); // hold shift down
                Ydotool.shiftMode = 2;
            }
        } else if (root.isMod) {
            Ydotool.toggleMod(root.keycode); // arm/disarm; never physically held
        }
    }

    contentItem: StyledText {
        id: keyText
        anchors.fill: parent
        font.family: (isBackspace || isEnter) ? Appearance.font.family.iconMaterial : Appearance.font.family.main
        font.pixelSize: root.shape == "fn" ? Appearance.font.pixelSize.small : 
            (isBackspace || isEnter) ? Appearance.font.pixelSize.huge :
            Appearance.font.pixelSize.large
        horizontalAlignment: Text.AlignHCenter
        color: root.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        text: root.isBackspace ? "backspace" : root.isEnter ? "subdirectory_arrow_left" :
            Ydotool.shiftMode == 2 ? (root.keyData.labelCaps || root.keyData.labelShift || root.keyData.label) :
            Ydotool.shiftMode == 1 ? (root.keyData.labelShift || root.keyData.label) : 
            root.keyData.label
    }
}
