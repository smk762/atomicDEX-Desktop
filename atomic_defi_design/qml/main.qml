import QtQuick 2.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import QtQuick.Controls.Universal 2.15
import QtQuick.Layouts 1.12
import App 1.0

import "Screens"
import "Components"

DexWindow {
    id: window
    title: API.app_name
    visible: true
    property alias application: app
    property int previousX: 0
    property int previousY: 0
    property int real_visibility
    property bool isOsx: Qt.platform.os == "osx"
    minimumWidth: General.minimumWidth
    minimumHeight: General.minimumHeight
    
    Universal.theme: Style.dark_theme ? Universal.Dark : Universal.Light
    Universal.accent: Style.colorQtThemeAccent
    Universal.foreground: Style.colorQtThemeForeground
    Universal.background: Style.colorQtThemeBackground

    onVisibilityChanged: {
        // 3 is minimized, ignore that
        if(visibility !== 3)
            real_visibility = visibility

        API.app.change_state(visibility)

    }

    background: Item{}
    
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: app.globalTheme.dexBoxBackgroundColor
        border.width: 0
    }

    DexWindowControl { visible: !isOsx }

    Rectangle {
        width: parent.width
        height: 30
        color: app.globalTheme.surfaceColor
        visible: isOsx 
    }
    App {
        id: app
        anchors.fill: parent
        anchors.topMargin: 30
        anchors.margins: 2
    }
    DexPopup
  {
    id: userMenu

    spacing: 8 
    padding: 2
    backgroundColor: app.globalTheme.dexBoxBackgroundColor

    contentItem: Item
    {
      implicitWidth: 130
      implicitHeight: 30
      Rectangle {
        width: parent.width-10
        height: parent.height-5
        anchors.centerIn: parent
        color: logout_area.containsMouse? app.globalTheme.surfaceColor : app.globalTheme.dexBoxBackgroundColor
        DexLabel {
            anchors.centerIn: parent
            text: qsTr('Logout')
        }
        DexMouseArea {
            id: logout_area
            hoverEnabled: true
            anchors.fill: parent
            onClicked:  {
                app.currentWalletName = ""
                API.app.disconnect()
                app.onDisconnect()
                userMenu.close()
            }
        }
      }
      
    }
  }

    DexMacControl { visible: isOsx }
    Item {
        width: _row.width
        height: 30
        Behavior on x {
            NumberAnimation {
                duration: 200
            }
        }
        x: {
            if(!isOsx) {
                if(app.current_page<5){
                    10
                }else {
                    if(app.deepPage===20) {
                        100
                    }
                    else if(app.deepPage===10) {
                        420
                    }
                    else {
                        250
                    }   
                }
                  
            } else {
                0
            }
        }
        anchors.right: isOsx? parent.right: undefined
        anchors.rightMargin: isOsx? 10 : 0
        Row {
            id: _row
            anchors.verticalCenter: parent.verticalCenter
            layoutDirection: isOsx? Qt.RightToLeft : Qt.LeftToRight
            spacing: 6
            Image {
                source: "qrc:/atomic_defi_design/assets/images/dex-tray-icon.png"
                width: 15
                height: 15
                smooth: true
                antialiasing: true
                visible: _label.text === ""
                anchors.verticalCenter: parent.verticalCenter
            }
            DexLabel {
                text: atomic_app_name
                font.family: 'Montserrat'
                font.weight: Font.Medium
                opacity: .5
                leftPadding: 5
                visible: _label.text === ""
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: __row.width+10
                height: __row.height+5
                anchors.verticalCenter: parent.verticalCenter
                visible: _label.text !== ""
                radius: 3
                color: _area.containsMouse? app.globalTheme.dexBoxBackgroundColor : "transparent"
                Row {
                    id: __row
                    anchors.centerIn: parent
                    layoutDirection: isOsx? Qt.RightToLeft : Qt.LeftToRight
                    spacing: 6
                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.accountCircle
                        iconSize: 18
                        visible: _label.text !== ""
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    DexLabel {
                        id: _label
                        text: app.currentWalletName?? ""
                        font.family: 'Montserrat'
                        font.weight: Font.Medium
                        opacity: .7
                        visible: _label.text !== ""
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.menuDown
                        iconSize: 14
                        visible: _label.text !== ""
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                DexMouseArea {
                    id: _area
                    anchors.fill: parent
                    onClicked: {
                        if(userMenu.visible){
                            userMenu.close()
                        }else {
                            userMenu.openAt(mapToItem(Overlay.overlay, width / 2, height), Item.Top)
                        }
                    }
                }
            }
            DexLabel {
                text: " | "
                opacity: .7
                font.family: 'Montserrat'
                font.weight: Font.Medium
                visible: _label.text !== ""
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 2
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                //layoutDirection: isOsx? Qt.RightToLeft : Qt.LeftToRight
                spacing: 6
                
                DexLabel {
                    leftPadding: 2
                    text: qsTr("Balance")
                    font.family: 'Montserrat'
                    font.weight: Font.Medium
                    opacity: .7
                    visible: _label.text !== ""
                    anchors.verticalCenter: parent.verticalCenter
                }
                DexLabel {
                    text: ":"
                    opacity: .7
                    font.family: 'Montserrat'
                    font.weight: Font.Medium
                    visible: _label.text !== ""
                    anchors.verticalCenter: parent.verticalCenter
                }
                DexLabel {
                    text: General.formatFiat("", API.app.portfolio_pg.balance_fiat_all,API.app.settings_pg.current_currency)
                    font.family: 'lato'
                    font.weight: Font.Medium
                    visible: _label.text !== ""
                    color: window.application.globalTheme.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    DexMouseArea {
                        anchors.fill: parent
                        onClicked: {
                            const current_fiat = API.app.settings_pg.current_currency
                            const available_fiats = API.app.settings_pg.get_available_currencies()
                            const current_index = available_fiats.indexOf(
                                                    current_fiat)
                            const next_index = (current_index + 1)
                                             % available_fiats.length
                            const next_fiat = available_fiats[next_index]
                            API.app.settings_pg.current_currency = next_fiat
                        }
                    }
                }
            }
        }
    }
}
