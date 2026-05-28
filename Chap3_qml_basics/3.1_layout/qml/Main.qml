import QtQuick
import QtQuick.Window

Window {
	id: rootWindow
	width: 800
	height: 400
	visible: true
	title: "Chap 3 - Bai 3.1: Visual Layout"
	color: "#0f0f0f"

	Rectangle {
		id: speedRing
		width: parent.height * 0.65
		height: width
		radius: width / 2
		color: "transparent"
		border.color: "#3a3a3a"
		border.width: 4

		anchors.left: parent.left
		anchors.leftMargin: parent.width * 0.05
		anchors.verticalCenter: parent.verticalCenter

		Text {
			anchors.centerIn: parent
			text: "Speedometer\n(Left Area)"
			color: "#888888"
			font.pixelSize: 18
			horizontalAlignment: Text.AlignHCenter
		}
	}
	
	Rectangle {
		id: centerInfo
		width: parent.width * 0.28
		height: parent.height * 0.55
		radius: 15
		color: "#1a1a1a"
		border.color: "#2d2d2d"
		border.width: 2

		anchors.centerIn: parent
		
		Column{
			anchors.centerIn: parent
			spacing: 15
			
			Text {
				text: "READY"
				color: "#00ff66"
				font.pixelSize: 22
				font.bold: true
				anchors.horizontalCenter: parent.horizontalCenter
			}

			
			Text {
				text: "P"
				color: "white"
				font.pixelSize: 45
				font.bold: true
				anchors.horizontalCenter: parent.horizontalCenter
			}

			Text {
				text: "Range: 320 km"
				color: "#aaaaaa"
				font.pixelSize: 16
				anchors.horizontalCenter: parent.horizontalCenter
			}
		}
	}

	Rectangle {
		id: rpmRing
		width: parent.height * 0.65
		height: width
		radius: width / 2
		color: "transparent"
		border.color: "#3a3a3a"
		border.width: 4

		anchors.right: parent.right
		anchors.rightMargin: parent.width * 0.05
		anchors.verticalCenter: parent.verticalCenter
		
		Text {
			anchors.centerIn: parent
			text: "Tachometer\n(Right Area)"
			color: "#888888"
			font.pixelSize: 18
			horizontalAlignment: Text.AlignHCenter
		}
	}
}
