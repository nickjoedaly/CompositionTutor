import QtQuick 2.15
import MuseScore 3.0

MuseScore {
    version: "1.0"
    title: "Composition Tutor Test"
    description: "Minimal test"
    categoryCode: "composing-arranging-tools"
    pluginType: "dialog"
    
    width: 400
    height: 300
    
    Component.onCompleted: {
        console.log("=== PLUGIN STARTED ===")
        console.log("Width: " + width)
        console.log("Height: " + height)
    }
    
    Rectangle {
        id: mainRect
        anchors.fill: parent
        color: "red"
        
        Text {
            anchors.centerIn: parent
            text: "TEST"
            color: "white"
            font.pixelSize: 48
        }
    }
}
