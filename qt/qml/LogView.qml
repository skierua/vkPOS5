import QtQuick
import QtQuick.Controls

// 0-error | 1-warning | 2-info
ListView {
    id: root
    property int level: 10 // error|warning|info
    // property list<color> palette: ["Pink",""]
    property int outdated: 60   // sec
    property bool debug: false


    Timer{
        id: lifeTimer
        interval: root.outdated * 1000
        triggeredOnStart: true
        repeat: false
        running: false
        onTriggered: {
            delOutdated()
        }
    }

    // 0-error | 1-warning | 2-info
    function append(vstr, vid =2) {
        if (Number(vid) < level){
            root.model.append(
                        {
                            "id": Number(vid),
                            "str": vstr,
                            "tm": new Date()
                            // "tm": Qt.formatDateTime(new Date(), "hh:mm:ss")
                        }
                        )
            if (root.debug) console.log(vid + ": " + vstr)
        }
        lifeTimer.start()
    }

    function delOutdated(){
        const d = new Date()

        for (let r = root.count -1; r >=0; --r) {
            // console.log("LogView d=" + Qt.formatDateTime(d, Qt.ISODate)
            //             + " tm=" + Qt.formatDateTime(root.model.get(r).tm, Qt.ISODate)
            //             + " diff=" + (d - root.model.get(r).tm))
            if (root.model.get(r).tm === undefined
                    || root.model.get(r).tm === ""
                    || d - root.model.get(r).tm > root.outdated * 1000){
                root.model.remove(r,1);
                // console.log("LogView remove r="+ r)
            }

        }
        if (root.count && !lifeTimer.running) lifeTimer.start()
    }

    function rowColor(vrow){
        // console.log("LogView vrow="+ vrow + " count=" + root.count)
        if (vrow < 0) return 'Transparent'
        if (root.model.get(vrow).id === 2) return 'AliceBlue'
        else if (root.model.get(vrow).id === 1) return 'PapayaWhip'
        else if (root.model.get(vrow).id === 0) return 'Pink'

        return 'WhiteSmoke'
    }

    spacing: 2

    verticalLayoutDirection: ListView.BottomToTop

    delegate: FocusScope{
        width: root.width
        height: 25
        Rectangle{
            anchors{fill: parent;}
            color: root.rowColor(index)
            Text{
                anchors{fill: parent; margins: 2}
                clip: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                // anchors.verticalCenter: parent.verticalCenter
                text: str
            }
        }
        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            ToolTip.delay: 1000
            ToolTip.timeout: 5000
            ToolTip.visible: containsMouse
            ToolTip.text: str
        }
    }

    model: ListModel{}
}

/*
  [{
  "id": int // 1-error|5-warning|10-info
  "str": string
  "tm": string
}]
  */



