import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
	id: rootWindow
	width: 800
	height: 400
	visible: true
	title: "Chap 3 - Bai 3.2: Property Binding"
	color: "#16161a"

	Text {
		id: titleText
		text: "QML Property Binding (Reactive UI)"
		color: "#fffffe"
		font.pixelSize: 24
		font.bold: true
		anchors.top: parent.top
		anchors.topMargin: 30
		anchors.horizontalCenter: parent.horizontalCenter
	}

	Rectangle {
		id: rotatingBox
		width: 150
		height: 150
		radius: 15
		
		anchors.centerIn: parent
		rotation: speedSlider.value * 3.6
		color: speedSlider.value > 80 ? "#ff3333" : "#2cb67d"
		
		border.color: "#fffffe"
		border.width: 2
		
		Text {
			anchors.centerIn: parent
			text: Math.round(speedSlider.value) + "\nkm/h"
			color: "white"
			font.pixelSize: 26
			font.bold: true
			horizontalAlignment: Text.AlignHCenter
		}
	}

	Slider {
		id: speedSlider
		width: parent.width * 0.7
		from: 0
		to: 100
		value: 0

		anchors.bottom: parent.bottom
		anchors.bottomMargin: 50
		anchors.horizontalCenter: parent.horizontalCente
	}

	Text {
		text: speedSlider.value > 80 ? "DANGER: OVER SPEED!" : "Status: Normal"
		color: speedSlider.value > 80 ? "#ff3333" : "#2cb67d"
		font.pixelSize: 18
		font.bold: true
		anchors.bottom: speedSlider.top
		anchors.bottomMargin: 15
		anchors.horizontalCenter: parent.horizontalCenter
	}
}
