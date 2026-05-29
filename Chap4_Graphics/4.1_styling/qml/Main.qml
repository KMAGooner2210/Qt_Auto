import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: rootWindow
    width: 800
    height: 480
    visible: true
    title: "Chap 4 - Bai 4.1: Styling Override"
    color: "#0f0f11"

    Text {
        id: titleText
        text: "Automotive Fuel/Battery Bar (QML Styling)"
        color: "#ffffff"
        font.pixelSize: 24
        font.bold: true
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
    }

    ProgressBar {
        id: fuelBar
        value: testController.value 
        anchors.centerIn: parent

        background: Rectangle {
            implicitWidth: 450
            implicitHeight: 20
            color: "#1a1a1d"
            radius: 10
            border.color: "#2f2f35"
            border.width: 1
        }

        contentItem: Item {
            implicitWidth: 450
            implicitHeight: 20

            Rectangle {
                width: fuelBar.visualPosition * parent.width
                height: parent.height
                radius: 10
                clip: true

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ff3333" }
                    GradientStop { position: 0.4; color: "#ffcc00" }
                    GradientStop { position: 1.0; color: "#00ff66" }
                }
            }
        }
    }

    Text {
        text: "Battery Level: " + Math.round(fuelBar.value * 100) + "%"
        color: fuelBar.value < 0.2 ? "#ff3333" : (fuelBar.value < 0.6 ? "#ffcc00" : "#00ff66")
        font.pixelSize: 18
        font.bold: true
        anchors.bottom: fuelBar.top
        anchors.bottomMargin: 15
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Slider {
        id: testController
        width: 450
        from: 0.0
        to: 1.0
        value: 0.75
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
        text: "Slide to charge/discharge battery"
        color: "#5f5f69"
        font.pixelSize: 14
        anchors.top: testController.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
