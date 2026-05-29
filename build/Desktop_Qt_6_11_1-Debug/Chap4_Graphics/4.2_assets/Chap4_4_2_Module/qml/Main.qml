import QtQuick
import QtQuick.Window

Window {
    id: rootWindow
    width: 800
    height: 480
    visible: true
    title: "Chap 4 - Bai 4.2: QRC Assets"
    color: "#0a0a0c"

    Text {
        id: titleText
        text: "Automotive Tell-Tales (Embedded QRC Assets)"
        color: "#ffffff"
        font.pixelSize: 24
        font.bold: true
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // KHỐI HIỂN THỊ CẢNH BÁO LỖI ĐỘNG CƠ (Tell-Tale Symbol)
    Item {
        width: 150
        height: 150
        anchors.centerIn: parent

        // 1. GỌI ẢNH TỪ BỘ NHỚ NHÚNG QRC (Đường dẫn bắt đầu bằng qrc:/)
        Image {
            id: warningIcon
            source: "../icons/engine_warning.svg" // Ảnh nhúng thẳng vào file chạy!
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit

            // 2. HOẠT ẢNH NHẤP NHÁY (Pulsing Animation) CẢNH BÁO NGUY HIỂM
            SequentialAnimation on opacity {
                loops: Animation.Infinite // Chạy vòng lặp vô hạn
                
                NumberAnimation {
                    to: 0.2
                    duration: 600 // Mờ dần trong 600ms
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: 1.0
                    duration: 600 // Sáng dần trong 600ms
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    Text {
        text: "WARNING: ENGINE SYSTEM FAULT DETECTED"
        color: "#ffcc00" // Màu vàng cảnh báo lỗi
        font.pixelSize: 18
        font.bold: true
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
