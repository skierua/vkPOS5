import QtQuick
import QtQuick.Controls

Button {
    id: btn
    readonly property var paletteList:  // textcolor, active, hovered, pressed
        [
        {"text": "#37474f", "active": "#eceff1"},  // basic
        {"text": "#FFFFFF", "active": "#3B82F6"},  // blue
        {"text": "#FFFFFF", "active": "#4caf50"},  // green
        {"text": "#FFFFFF", "active": "#EF4444"},  // red
        {"text": "#B22222", "active": "#FFC0CB"},  // pink FireBrick/Pink, for negative Bind amnt
        {"text": "#000080", "active": "#87CEFA"},  // skyblue Navy/LightSkyBlue, for positive Bind amnt
    ]
    property string palette: "basic"

    readonly property var crntPalette:{
        let colorText = "";
        let colorActive = "";
        if (btn.enabled){
            const paletteVal = String(palette || "").toLocaleLowerCase();
            if (paletteVal === "blue") { colorText = paletteList[1]?.text || "#37474f"; colorActive = paletteList[1]?.active || "#eceff1"; }
            else if (paletteVal === "green") { colorText = paletteList[2]?.text || "#37474f"; colorActive = paletteList[2]?.active || "#eceff1"; }
            else if (paletteVal === "red") { colorText = paletteList[3]?.text || "#37474f"; colorActive = paletteList[3]?.active || "#eceff1"; }
            else if (paletteVal === "pink") { colorText = paletteList[4]?.text || "#37474f"; colorActive = paletteList[4]?.active || "#eceff1"; }
            else if (paletteVal === "skyblue") { colorText = paletteList[5]?.text || "#37474f"; colorActive = paletteList[5]?.active || "#eceff1"; }
            else { colorText = paletteList[0]?.text || "#37474f"; colorActive = paletteList[0]?.active || "#eceff1"; }
            return {
                "text" : colorText,
                "active" : colorActive,
                "hovered": Qt.darker(colorActive, 1.1),
                "pressed": Qt.darker(colorActive, 1.4),
            }
        } else {
            return {
                "text" : Qt.lighter("#37474f",1.8),
                "active" : "#eceff1",
                "hovered": "#eceff1",
                "pressed": Qt.darker("#eceff1", 1.2),
            }
        }
    }
    property string toolTip
    hoverEnabled: enabled ? true : false; // !!toolTip
    ToolTip{ visible: !!toolTip && parent.hovered; delay: 800; timeout: 4000; text: btn.toolTip; }

    // text: ""
    font.pixelSize: 14
    font.bold: true

    background: Rectangle {
        id: btnBackground
        // property int paletteId: 0
        // color: btn.pressed
        //        ? btn.crntPalette?.[3] || "#b0bec5"
        //        : (btn.hovered
        //           ? btn.crntPalette?.[2] || "#cfd8dc"
        //           : btn.crntPalette?.[1] || "#eaedf0")
        color: btn.pressed
               ? btn.crntPalette?.pressed || "#b0bec5"
               : (btn.hovered
                  ? btn.crntPalette?.hovered || "#cfd8dc"
                  : btn.crntPalette?.active || "#eaedf0")
        radius: height/5 //8
        // border.color: Qt.darker(btn.crntPalette?.[1] || "#eaedf0", 1.5);
        border.color: btn.crntPalette?.pressed || "#b0bec5";
        border.width: 1;
    }

    contentItem: Text {
        id: btnText
        text: parent.text;
        font: parent.font;
        color: btn.crntPalette?.text || "#78909c"
        horizontalAlignment: Text.AlignHCenter;
        verticalAlignment: Text.AlignVCenter
    }
}
