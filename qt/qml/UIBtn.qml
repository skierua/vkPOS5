import QtQuick
import QtQuick.Controls

Button {
    id: btn
/*    readonly property var old_paletteList:  // textcolor, active, hovered, pressed
        [
        // ["#37474f", "#eaedf0", "#cfd8dc", "#b0bec5"],  // basic
        ["#37474f", "#eceff1", "#e2e8f0", "#cfd8dc"],  // basic
        // ["white", "#0288d1", "#0277bd", "#01579b"],  // blue
        ["white", "#3B82F6", "#3063f0", "#1D4ED8"],  // blue
        // ["white", "#10B981", "#0da371", "#047857"],  // green
        ["white", "#4caf50", "#2e7d32", "#1b5e20"],  // green
        ["white", "#EF4444", "#db3d3d", "#B91C1C"],  // red
    ]*/
    readonly property var paletteList:  // textcolor, active, hovered, pressed
        [
        {"text": "#37474f", "active": "#eceff1"},  // basic
        {"text": "white", "active": "#3B82F6"},  // blue
        {"text": "white", "active": "#4caf50"},  // green
        {"text": "white", "active": "#EF4444"},  // red
        {"text": "FireBrick", "active": "Pink"},  // pink, for negative Bind amnt
        {"text": "Navy", "active": "LightSkyBlue"},  // skyblue, for positive Bind amnt
    ]
    property string palette: "basic"
/*    readonly property var old_crntPalette:{
        if (palette === "blue") return paletteList[1];
        else if (palette === "green") return paletteList[2];
        else if (palette === "red") return paletteList[3];
        else return paletteList[0];
    }*/

    readonly property var crntPalette:{
        let colorText = "";
        let colorActive = "";
        if (palette === "blue") { colorText = paletteList[1]?.text || "#37474f"; colorActive = paletteList[1]?.active || "#eceff1"; }
        else if (palette === "green") { colorText = paletteList[2]?.text || "#37474f"; colorActive = paletteList[2]?.active || "#eceff1"; }
        else if (palette === "red") { colorText = paletteList[3]?.text || "#37474f"; colorActive = paletteList[3]?.active || "#eceff1"; }
        else if (palette === "pink") { colorText = paletteList[4]?.text || "#37474f"; colorActive = paletteList[4]?.active || "#eceff1"; }
        else if (palette === "skyblue") { colorText = paletteList[5]?.text || "#37474f"; colorActive = paletteList[5]?.active || "#eceff1"; }
        else { colorText = paletteList[0]?.text || "#37474f"; colorActive = paletteList[0]?.active || "#eceff1"; }
        const res = {
            "text" : colorText,
            "active" : colorActive,
            "hovered": Qt.darker(colorActive, 1.1),
            "pressed": Qt.darker(colorActive, 1.4),
        }
        return res;
    }
    property string toolTip
    hoverEnabled: true; // !!toolTip
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
