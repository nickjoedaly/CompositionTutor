import QtQuick 2.15
import QtQuick.Controls 2.15
import Muse.UiComponents 1.0
import MuseScore 3.0

MuseScore {
    version: "1.0"
    title: "Composition Tutor"
    description: "Guided diagnostic tool for compositional problem-solving"
    categoryCode: "composing-arranging-tools"
    pluginType: "dialog"
    
    width: 600
    height: 700
    
    Component.onCompleted: {
        console.log("=== Composition Tutor Loaded ===")
        console.log("Window size: " + width + "x" + height)
    }
    
    // Simplified UI to test rendering
    Rectangle {
        anchors.fill: parent
        color: "#2e2e2e"
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "Composition Tutor"
                color: "white"
                font.pixelSize: 24
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "If you can see this, the plugin is working!"
                color: "#4a9eff"
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            StyledButton {
                text: "Test Button"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    console.log("Button clicked!")
                    testLabel.text = "Button works!"
                }
            }
            
            Text {
                id: testLabel
                text: ""
                color: "white"
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
