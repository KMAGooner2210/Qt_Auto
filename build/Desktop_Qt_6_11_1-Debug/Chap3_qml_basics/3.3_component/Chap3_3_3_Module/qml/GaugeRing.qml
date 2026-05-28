import QtQuick
import QtQuick.Shapes // BẮT BUỘC: Thư viện vẽ hình học Vector cấp cao của Qt 6

Item {
    id: ringRoot
    
    property color ringColor: "white"
    property string ringText: "Gauge"

    // Kích thước co giãn chuẩn
    width: parent.height * 0.58
    height: width

    // ========================================================
    // 1. VẼ VÒNG CUNG ĐỒNG HỒ 270 ĐỘ (Automotive Arc Shape)
    // ========================================================
    Shape {
        id: arcShape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4 // Khử răng cưa (Anti-aliasing) giúp nét vẽ siêu mịn

        ShapePath {
            strokeColor: ringColor
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap // Bo tròn 2 đầu của vòng cung

            // Thuật toán vẽ vòng cung từ góc -225 độ, quét một góc 270 độ
            PathAngleArc {
                centerX: ringRoot.width / 2
                centerY: ringRoot.height / 2
                radiusX: (ringRoot.width / 2) - 15
                radiusY: radiusX
                startAngle: -225 
                sweepAngle: 270  
            }
        }
    }

    // ========================================================
    // 2. TỰ ĐỘNG VẼ 11 VẠCH CHIA ĐỘ (Tick Marks) BẰNG LƯỢNG GIÁC
    // ========================================================
    Repeater {
        model: 11 // Vẽ 11 vạch từ 0% đến 100%
        delegate: Rectangle {
            width: 2
            // Vạch chính (0, 50, 100) sẽ dài 12px, vạch phụ dài 6px
            height: index % 5 === 0 ? 12 : 6 
            color: ringColor
            opacity: index % 5 === 0 ? 0.8 : 0.4 // Vạch chính sáng hơn vạch phụ
            
            x: ringRoot.width / 2 - width / 2
            y: 20 // Khoảng cách từ vạch đến viền ngoài
            
            // Thuật toán xoay vạch chia độ hướng tâm quay quanh tâm đồng hồ
            transformOrigin: Item.Bottom
            transform: Rotation {
                angle: -135 + (index * 27) // Chia đều góc 270 độ thành 10 khoảng (mỗi khoảng 27 độ)
                origin.x: width / 2
                origin.y: ringRoot.height / 2 - 20
            }
        }
    }

    // Chữ hiển thị thông số ở tâm
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: parent.height * 0.1 // Đẩy chữ dịch xuống dưới tâm một chút
        text: ringText
        color: ringColor
        font.pixelSize: 15
        font.bold: true
        opacity: 0.8
        horizontalAlignment: Text.AlignHCenter
    }
}
