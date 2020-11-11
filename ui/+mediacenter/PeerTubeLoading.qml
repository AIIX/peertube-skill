import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.11 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
    id: logoLoadingPage
    property string loadingStatus: sessionData.loadingStatus
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    
    onLoadingStatusChanged: {
        loadingStatusArea.text = "Loading: " + loadingStatus
    }

    Control {
        id: statusArea
        anchors.fill: parent
        
        background: Image {
            source: "./images/loading-bg.jpg"
            
            Image {
                source: "./images/pt-logo.png"
                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.gridUnit * 3
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        
        contentItem: Item {
            ProgressBar {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Kirigami.Units.gridUnit
                height: Kirigami.Units.gridUnit * 3
                indeterminate: true
            }
        }
    }
}
