import QtQuick
import QtQuick.Shapes

Item {
	id: ringRoot
	property color ringColor: "white"
	property string ringText: "Gauge"
	
	width: parent.height * 0.58
	height: width

	Shape {
		id: arcShape
		anchors.fill: parent
		layer.enabled: true
		layer.samples: 4
	
		ShapePath {
			strokeColor: ringColor
			strokeWidth: 3
			fillColor: "transparent"
			capStyle: ShapePath.RoundCap

			PathAngleArc {
				centerX: ringRoot.width / 2
				centerY: ringRoot.height / 2
  				radiusX: (ringRoot.width / 2) - 15
				radiusY: radiusX
				startAngle: -255
				sweepAngle: 270
			}
		}
	}


	Repeater {
		model: 11
		delegate: Rectangle {
			width: 2
			height: index % 5 === 0 ? 12 : 6
			color: ringColor
			opacity:index % 5 === 0 ? 0.8 : 0.4
			
			x: ringRoot.width / 2 - width / 2
			y: 20

			transformOrigin: Item.Bottom
			transform: Rotation {
				angle: -135 + (index * 27)
				origin.x: width / 2
				origin.y: ringRoot.height / 2 - 20
			}
		}
	}

	Text {
		anchors.centerIn: parent
		anchors.verticalCenterOffset: parent.height * 0.1
		text: ringText
		color: ringColor
		font.pixelSize: 15
		font.bold: true
		opacity: 0.8
		horizontalAlignment: Text.AlignHCenter
	}
}
