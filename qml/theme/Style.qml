pragma Singleton
import QtQuick

QtObject {
    // Backgrounds
    readonly property color bgBase: "#1e1e2e"
    readonly property color bgSurface: "#181825"
    readonly property color bgCard: "#313244"
    readonly property color bgCardHover: "#3b3d54"
    readonly property color bgCardSelected: "#45475a"

    // Accent & Status Colors
    readonly property color primary: "#89b4fa"
    readonly property color primaryHover: "#b4befe"
    readonly property color success: "#a6e3a1"
    readonly property color danger: "#f38ba8"
    readonly property color warning: "#f9e2af"
    readonly property color teal: "#26a69a"

    // Text Colors
    readonly property color textMain: "#cdd6f4"
    readonly property color textMuted: "#a6adc8"
    readonly property color textSubtle: "#6c7086"
    readonly property color textDark: "#11111b"

    // Borders & Grid Lines
    readonly property color borderBase: "#45475a"
    readonly property color borderActive: "#585b70"
    readonly property color gridLine: "#212234"

    // Spacing & Radius
    readonly property int radiusSm: 4
    readonly property int radiusMd: 8
    readonly property int radiusLg: 14

    // Typography
    readonly property string fontFamily: "sans-serif"
    readonly property int fontSm: 10
    readonly property int fontMd: 11
    readonly property int fontLg: 13
    readonly property int fontTitle: 24
}