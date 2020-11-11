import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.10 as Kirigami
import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
 id: imageRoot
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    
    Image {
        anchors.fill: parent
        source: "./images/error-page.png"
        fillMode: Image.PreserveAspectFit
    }
}
