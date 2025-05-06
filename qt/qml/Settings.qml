// import QtCore
import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts


Item {
    id: root
    property var dfltTerminal: ({})
    property var dfltAcnt: ({})
    property var dfltREST: ({})
    property var dfltCashDisc: ({})
    property string title: "Налаштування"
    property string codeid: "settings"


    signal vkEvent(string id, var param)

    Item {
        anchors{fill:parent; margins:5,10;}

        ColumnLayout{

            TabBar {
                id: settingBar
                width: parent.width
                TabButton {
                    text: qsTr("Basic")
                    width: implicitWidth
                }
                TabButton {
                    text: qsTr("REST")
                    width: implicitWidth
                }
                TabButton {
                    text: qsTr("CashDesk")
                    width: implicitWidth
                }
                TabButton {
                    text: qsTr("Accounts")
                    width: implicitWidth
                }
            }

            StackLayout {
                width: parent.width
                currentIndex: settingBar.currentIndex
                // Item {
                    // id: basicTab
                    ColumnLayout{
                        id: basicTab
                        RowLayout { //Term code
                            spacing: 10
                            Label{
            //                    minimumPixelSize: 100
                                text: "Term code:"
                            }
                            TextField{
                                id: editTerm
                                text: dfltTerminal.term
                                placeholderText: "terminal code"
                            }
                        }
                        RowLayout {
                            spacing: 10
                            Label{
            //                    minimumPixelSize: 100
                                text: "POS printer:"
                            }
                            TextField{
                                id: editPrinter
                                Layout.fillWidth: true
                                text: dfltTerminal.posPrinter
                                placeholderText: "POS printer"
                            }
                        }
                        RowLayout {
                            spacing: 10
                            Label{
            //                    minimumPixelSize: 100
                                text: "Amount:"
                            }
                            TextField{
                                id: editCheckAmnt
                                text: dfltTerminal.checkAmnt
                                placeholderText: "-1 | 1"
                            }
                        }
                        RowLayout {
                            spacing: 10
                            Label{
                                text: "Autoprint:"
                            }
                            TextField{
                                id: editAutoPrint
                                Layout.fillWidth: true
                                placeholderText: "autoprint 1 | 0"
                                text: dfltTerminal.checkAutoPrint
                            }
                        }
                        RowLayout {
                            spacing: 10
                            Label{
                                text: "Print document:"
                            }
                            TextField{
                                id: editCheckPrintDcm
                                Layout.fillWidth: true
                                text: dfltTerminal.checkPrintDcm
                            }
                        }

                        Button{
                            Layout.alignment: Qt.AlignCenter
                            text: "Ok"
                            // focus: true
                            onClicked: {
                                dfltTerminal =                                     {term: editTerm.text,
                                    posPrinter: editPrinter.text,
                                    checkAmnt: editCheckAmnt.text,
                                    checkAutoPrint: editAutoPrint.text,
                                    checkPrintDcm: editCheckPrintDcm.text
                                    }
                                vkEvent('saveTerminal','')
                                // vkEvent('saveTerminal',
                                //         {term: editTerm.text,
                                //         posPrinter: editPrinter.text,
                                //         checkAmnt: editCheckAmnt.text,
                                //         checkAutoPrint: editAutoPrint.text,
                                //         checkPrintDcm: editCheckPrintDcm.text
                                //         })
                            }
                        }
                    }
                // }
                ColumnLayout {
                    id: restTab
                    RowLayout {
                        spacing: 10
                        Label{ text: "host:" }
                        TextField{
                            id: editUrl
                            placeholderText: "host url"
                            text: dfltREST.resthost === undefined ? "" : dfltREST.resthost
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            text: "api:"
                        }
                        TextField{
                            id: editApi
                            placeholderText: "api"
                            text: dfltREST.restapi === undefined ? "" : dfltREST.restapi
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
        //                    minimumPixelSize: 100
                            text: "Login:"
                        }
                        TextField{
                            id: editLogin
                            // Layout.fillWidth: true
                            placeholderText: "login user"
                            text: dfltREST.restuser === undefined ? "" : dfltREST.restuser
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            minimumPixelSize: 100
                            text: "password:"
                        }
                        TextField{
                            id: editPassword
                            // Layout.fillWidth: true
                            echoMode: TextInput.Password
                            placeholderText: "password"
                            text: dfltREST.restpassword === undefined ? "" : dfltREST.restpassword
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            minimumPixelSize: 100
                            text: "token:"
                        }
                        TextField{
                            id: editToken
                            readOnly: true
                            placeholderText: "token"
                            text: dfltREST.resttoken === undefined ? "" : dfltREST.resttoken
                        }
                    }
                    Button{
                        Layout.alignment: Qt.AlignCenter
                        text: "Login"
                        onClicked: {
                            dfltREST = {resthost: editUrl.text,
                                restapi: editApi.text,
                                restuser: editLogin.text,
                                restpassword: editPassword.text,
                                }
                            vkEvent('loginREST','')
                        }
                    }
                }

                ColumnLayout {
                    id: cdTab
                    RowLayout {
                        spacing: 10
                        Label{ text: "host:" }
                        TextField{
                            id: editCDhost
                            Layout.preferredWidth: 250
                            text: dfltCashDisc.cdhost
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            text: "api:"
                        }
                        TextField{
                            id: editCDprefix
                            text: dfltCashDisc.cdprefix
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            text: "Cash:"
                        }
                        TextField{
                            id: editCDcash
                            text: dfltCashDisc.cdcash
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            // minimumPixelSize: 100
                            text: "Token:"
                        }
                        TextField{
                            id: editCDtoken
                            Layout.preferredWidth: 250
                            text: dfltCashDisc.cdtoken
                        }
                    }
                    Button{
                        Layout.alignment: Qt.AlignCenter
                        text: "Ok"
                        onClicked: {
                            dfltCashDisc = {cdhost: editCDhost.text,
                                cdprefix: editCDprefix.text,
                                cdcash: editCDcash.text,
                                cdtoken: editCDtoken.text,
                                }
                            vkEvent('saveCD','' )
                        }
                    }
                }

                ColumnLayout {
                    id: acntTab
                    RowLayout {
                        spacing: 10
                        Label{ text: "Cash:" }
                        TextField{
                            id: edacntCash
                            text: dfltAcnt.cash
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            text: "Trade:"
                        }
                        TextField{
                            id: edacntTrade
                            text: dfltAcnt.trade
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            text: "Bulk:"
                        }
                        TextField{
                            id: edacntBulk
                            text: dfltAcnt.bulk
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            text: "Incas:"
                        }
                        TextField{
                            id: edacntIncas
                            text: dfltAcnt.incas
                        }
                    }
                    RowLayout {
                        spacing: 10
                        Label{
                            text: "Profit:"
                        }
                        TextField{
                            id: edacntProfit
                            // Layout.preferredWidth: 250
                            text: dfltAcnt.profit
                        }
                    }
                    Button{
                        Layout.alignment: Qt.AlignCenter
                        text: "Ok"
                        // focus: true
                        onClicked: {
                            dfltAcnt = {cash: edacntCash.text,
                                trade: edacntTrade.text,
                                bulk: edacntBulk.text,
                                incas: edacntIncas.text,
                                profit: edacntProfit.text,
                                }
                            vkEvent('saveAcnts','' )
                        }
                    }
                }
            }
        }
    }
}
