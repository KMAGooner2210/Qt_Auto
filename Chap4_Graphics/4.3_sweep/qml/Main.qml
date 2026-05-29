import QtQuick
import QtQuick.Window

Window {
	id: rootWindow
	width: 800
	height: 480
	visible: true
	title: "Chap 4 - Bai 4.3: Sweep Animation"
	color: "#0f0f11"

	property real speedValue: 0.0
	
	Text {
		id: titleText
		text: "Automotive Startup Sweep Animation"
		color: "#ffffff"
		font.pixelSize: 24
		font.bold: true
		anchors.top: parent.top
		anchors.topMargin: 40
		anchors.horizontalCenter: parent.horizontalCenter
	}

	GaugeRing {
		id: speedometer
		ringColor: "#2196f3"
		ringText: Math.round(speedValue) + "\nkm/h"
		anchors.centerIn: parent

		Image {
			id: needle
			source: "../icons/needle.svg"
			width: 16
			height: 120
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.bottom: parent.verticalCenter
			anchors.bottomMargin: -20
			transformOrigin: Item.Bottom
			rotation: -135 + (speedValue / 240.0) * 270
		}
	}

	SequentialAnimation {
		running: true
		loops: 1
		
		NumberAnimation {
			target: rootWindow
			property: "speedValue"
			from: 0.0
			to: 240.0
			duration: 800
			easing.type: Easing.OutQuint
		}
		
		PauseAnimation { duration: 150 }
		
		NumberAnimation {
			target: rootWindow
			property: "speedValue"
			from: 240.0
			to: 0.0
			duration: 1200
			easing.type: Easing.InOutQuad
		}
	}
}
