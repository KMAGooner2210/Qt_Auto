import QtQuick
import QtQuick.Window

Window {
	id: rootWindow
	width: 800
	height: 480
	visible: true
	title: "Chap 3 - Bai 3.3: Custom Component"
	color: "#0f0f0f"

	GaugeRing {
		id: speedGauge
		ringColor: "#2196f3"
		ringText: "Speedometer\n(Blue Gauge)"
		
		anchors.left: parent.left
		anchors.leftMargin: parent.width * 0.05
		anchors.verticalCenter: parent.verticalCenter
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

		Column {
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

	GaugeRing {
		id: rpmGauge
		ringColor: "#ff5722"
		ringText: "Tachometer\n(Orange-Red Gauge)"
		anchors.right: parent.right
		anchors.rightMargin: parent.width * 0.05
		anchors.verticalCenter: parent.verticalCenter
	}
}
