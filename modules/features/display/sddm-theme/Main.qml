import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: root

    width: Screen.width
    height: Screen.height
    color: config.BackgroundColor || "#080d10"

    property color panelColor: config.PanelColor || "#111820"
    property color textColor: config.TextColor || "#edf4ef"
    property color mutedTextColor: config.MutedTextColor || "#8d9b9b"
    property color accentColor: config.AccentColor || "#76d6b8"
    property color warmAccentColor: config.WarmAccentColor || "#f2c66d"
    property color dangerColor: config.DangerColor || "#ff6f61"
    property string errorText: ""
    property real uiScale: Number(config.LoginScale || 1.25)

    function scaled(value) {
        return Math.round(value * uiScale)
    }

    function attemptLogin() {
        errorText = ""
        sddm.login(userName.text, password.text, sessionBox.currentIndex)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#080d10" }
            GradientStop { position: 0.55; color: "#101820" }
            GradientStop { position: 1.0; color: "#15120d" }
        }
    }

    Rectangle {
        width: parent.width * 0.42
        height: parent.height * 1.3
        x: parent.width * -0.08
        y: parent.height * -0.15
        rotation: -10
        opacity: 0.72
        color: "#13261f"
        border.color: "#27453b"
        border.width: 1
    }

    Rectangle {
        width: parent.width * 0.32
        height: parent.height * 1.4
        x: parent.width * 0.78
        y: parent.height * -0.2
        rotation: 13
        opacity: 0.6
        color: "#2a2415"
        border.color: "#4d4124"
        border.width: 1
    }

    Repeater {
        model: 16
        Rectangle {
            x: root.width * 0.06 + index * root.width * 0.07
            y: root.height * 0.08
            width: 1
            height: root.height * 0.84
            color: index % 3 === 0 ? root.accentColor : "#23303a"
            opacity: index % 3 === 0 ? 0.12 : 0.08
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Math.max(root.scaled(28), Math.min(root.width, root.height) * 0.06)
        spacing: Math.max(root.scaled(28), root.width * 0.06)

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: root.scaled(320)

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.scaled(22)
                width: Math.min(parent.width, root.scaled(560))

                Text {
                    text: config.HostLabel || "ThinkPad T480"
                    color: root.textColor
                    font.pixelSize: Math.max(root.scaled(46), Math.min(root.scaled(82), root.width * 0.055 * root.uiScale))
                    font.weight: Font.DemiBold
                    lineHeight: 0.92
                }

                Rectangle {
                    width: Math.min(parent.width, root.scaled(420))
                    height: root.scaled(2)
                    color: root.accentColor
                    opacity: 0.9
                }

                Text {
                    width: parent.width
                    text: config.SessionLabel || "Niri + Noctalia"
                    color: root.warmAccentColor
                    font.pixelSize: root.scaled(22)
                    font.weight: Font.Medium
                }

                Text {
                    width: parent.width
                    text: Qt.formatDateTime(new Date(), "dddd, d MMMM  yyyy")
                    color: root.mutedTextColor
                    font.pixelSize: root.scaled(18)
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: Math.min(root.scaled(430), Math.max(root.scaled(350), root.width * 0.28))
            Layout.maximumWidth: root.scaled(460)
            Layout.minimumWidth: root.scaled(330)
            Layout.alignment: Qt.AlignVCenter
            radius: root.scaled(18)
            color: Qt.rgba(0.07, 0.1, 0.12, 0.92)
            border.color: "#2f3d44"
            border.width: root.scaled(1)
            implicitHeight: loginColumn.implicitHeight + root.scaled(56)

            ColumnLayout {
                id: loginColumn

                anchors.fill: parent
                anchors.margins: root.scaled(28)
                spacing: root.scaled(16)

                Text {
                    Layout.fillWidth: true
                    text: "Sign in"
                    color: root.textColor
                    font.pixelSize: root.scaled(28)
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: sddm.hostName
                    color: root.mutedTextColor
                    font.pixelSize: root.scaled(14)
                }

                TextField {
                    id: userName

                    Layout.fillWidth: true
                    text: userModel.lastUser
                    placeholderText: "Username"
                    selectByMouse: true
                    color: root.textColor
                    placeholderTextColor: root.mutedTextColor
                    font.pixelSize: root.scaled(16)
                    Layout.minimumHeight: root.scaled(48)

                    background: Rectangle {
                        radius: root.scaled(10)
                        color: "#162027"
                        border.color: userName.activeFocus ? root.accentColor : "#2d3a42"
                        border.width: root.scaled(1)
                    }
                }

                TextField {
                    id: password

                    Layout.fillWidth: true
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    selectByMouse: true
                    color: root.textColor
                    placeholderTextColor: root.mutedTextColor
                    font.pixelSize: root.scaled(16)
                    Layout.minimumHeight: root.scaled(48)
                    focus: true
                    Keys.onReturnPressed: root.attemptLogin()
                    Keys.onEnterPressed: root.attemptLogin()

                    background: Rectangle {
                        radius: root.scaled(10)
                        color: "#162027"
                        border.color: password.activeFocus ? root.accentColor : "#2d3a42"
                        border.width: root.scaled(1)
                    }
                }

                ComboBox {
                    id: sessionBox

                    Layout.fillWidth: true
                    model: sessionModel
                    textRole: "name"
                    currentIndex: Math.max(0, sessionModel.lastIndex)
                    font.pixelSize: root.scaled(14)
                    Layout.minimumHeight: root.scaled(44)

                    contentItem: Text {
                        leftPadding: root.scaled(12)
                        rightPadding: root.scaled(30)
                        text: sessionBox.displayText
                        color: root.textColor
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        radius: root.scaled(10)
                        color: "#162027"
                        border.color: sessionBox.activeFocus ? root.accentColor : "#2d3a42"
                        border.width: root.scaled(1)
                    }

                    delegate: ItemDelegate {
                        id: sessionDelegate

                        width: sessionBox.width
                        highlighted: sessionBox.highlightedIndex === index

                        contentItem: Text {
                            text: model.name
                            color: sessionDelegate.highlighted ? "#07110e" : root.textColor
                            font.pixelSize: root.scaled(14)
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            radius: root.scaled(8)
                            color: sessionDelegate.highlighted ? root.accentColor : "#111820"
                        }
                    }

                    popup: Popup {
                        y: sessionBox.height + root.scaled(6)
                        width: sessionBox.width
                        implicitHeight: contentItem.implicitHeight + 8
                        padding: root.scaled(4)

                        contentItem: ListView {
                            clip: true
                            implicitHeight: Math.min(contentHeight, root.scaled(220))
                            model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                            currentIndex: sessionBox.highlightedIndex
                        }

                        background: Rectangle {
                            radius: root.scaled(12)
                            color: "#111820"
                            border.color: "#2d3a42"
                            border.width: root.scaled(1)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.errorText
                    color: root.dangerColor
                    font.pixelSize: root.scaled(14)
                    visible: root.errorText.length > 0
                    wrapMode: Text.WordWrap
                }

                Button {
                    id: unlockButton

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.scaled(48)
                    text: "Unlock"
                    font.pixelSize: root.scaled(16)
                    font.weight: Font.DemiBold
                    onClicked: root.attemptLogin()

                    contentItem: Text {
                        text: unlockButton.text
                        color: "#07110e"
                        font: unlockButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: root.scaled(12)
                        color: unlockButton.down ? "#58b99d" : root.accentColor
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.scaled(10)

                    Button {
                        id: suspendButton

                        Layout.fillWidth: true
                        text: "Suspend"
                        font.pixelSize: root.scaled(13)
                        enabled: sddm.canSuspend
                        onClicked: sddm.suspend()

                        contentItem: Text {
                            text: suspendButton.text
                            color: suspendButton.enabled ? root.textColor : root.mutedTextColor
                            font: suspendButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            radius: root.scaled(10)
                            color: suspendButton.down ? "#263840" : suspendButton.hovered ? "#1e2b31" : "#162027"
                            border.color: suspendButton.enabled ? "#2d3a42" : "#1e262b"
                            border.width: root.scaled(1)
                            opacity: suspendButton.enabled ? 1 : 0.45
                        }
                    }

                    Button {
                        id: rebootButton

                        Layout.fillWidth: true
                        text: "Reboot"
                        font.pixelSize: root.scaled(13)
                        enabled: sddm.canReboot
                        onClicked: sddm.reboot()

                        contentItem: Text {
                            text: rebootButton.text
                            color: rebootButton.enabled ? root.textColor : root.mutedTextColor
                            font: rebootButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            radius: root.scaled(10)
                            color: rebootButton.down ? "#263840" : rebootButton.hovered ? "#1e2b31" : "#162027"
                            border.color: rebootButton.enabled ? "#2d3a42" : "#1e262b"
                            border.width: root.scaled(1)
                            opacity: rebootButton.enabled ? 1 : 0.45
                        }
                    }

                    Button {
                        id: powerButton

                        Layout.fillWidth: true
                        text: "Power off"
                        font.pixelSize: root.scaled(13)
                        enabled: sddm.canPowerOff
                        onClicked: sddm.powerOff()

                        contentItem: Text {
                            text: powerButton.text
                            color: powerButton.enabled ? root.textColor : root.mutedTextColor
                            font: powerButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            radius: root.scaled(10)
                            color: powerButton.down ? "#263840" : powerButton.hovered ? "#1e2b31" : "#162027"
                            border.color: powerButton.enabled ? "#2d3a42" : "#1e262b"
                            border.width: root.scaled(1)
                            opacity: powerButton.enabled ? 1 : 0.45
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.scaled(28)
        text: Qt.formatDateTime(new Date(), "HH:mm")
        color: root.textColor
        opacity: 0.88
        font.pixelSize: root.scaled(42)
        font.weight: Font.Light
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.errorText = "Login failed"
            password.text = ""
            password.forceActiveFocus()
        }
    }
}
