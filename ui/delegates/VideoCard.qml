import QtQuick 2.9
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.3
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.components 2.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft

PlasmaComponents3.ItemDelegate {
    id: delegate
        
    property int borderSize: Kirigami.Units.smallSpacing
    property int baseRadius: 3
    
    readonly property Flickable listView: {
        var candidate = parent;
        while (candidate) {
            if (candidate instanceof Flickable) {
                return candidate;
            }
            candidate = candidate.parent;
        }
        return null;
    }

    
    readonly property bool isCurrent: {//print(text+index+" "+listView.currentIndex+activeFocus+" "+listView.moving)
        listView.currentIndex == index && activeFocus && !listView.moving
    }

    
    leftPadding: Kirigami.Units.largeSpacing * 2
    topPadding: Kirigami.Units.largeSpacing * 2
    rightPadding: Kirigami.Units.largeSpacing * 2
    bottomPadding: Kirigami.Units.largeSpacing * 2

    leftInset: Kirigami.Units.largeSpacing
    topInset: Kirigami.Units.largeSpacing
    rightInset: Kirigami.Units.largeSpacing
    bottomInset: Kirigami.Units.largeSpacing

    implicitWidth: parent.cellWidth
    height: parent.height

        background: Item {
        id: background

        readonly property Item highlight: Rectangle {
            parent: delegate
            z: 1
            anchors {
                fill: parent
            }
            color: "transparent"
            border {
                width: delegate.borderSize
                color: delegate.Kirigami.Theme.highlightColor
            }
            opacity: delegate.isCurrent || delegate.highlighted
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration/2
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Rectangle {
            id: frame
            anchors {
                fill: parent
            }
            radius: delegate.baseRadius
            color: delegate.Kirigami.Theme.backgroundColor
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: false
                horizontalOffset: 1.25
                verticalOffset: 1
            }

            states: [
                State {
                    when: delegate.isCurrent
                    PropertyChanges {
                        target: delegate
                        leftInset: 0
                        rightInset: 0
                        topInset: 0
                        bottomInset: 0
                    }
                    PropertyChanges {
                        target: background.highlight.anchors
                        margins: 0
                    }
                    PropertyChanges {
                        target: frame
                        // baseRadius + borderSize preserves the original radius for the visible part of frame
                        radius: delegate.baseRadius + delegate.borderSize
                    }
                    PropertyChanges {
                        target: background.highlight
                        // baseRadius + borderSize preserves the original radius for the visible part of frame
                        radius: delegate.baseRadius + delegate.borderSize
                    }
                },
                State {
                    when: !delegate.isCurrent
                    PropertyChanges {
                        target: delegate
                        leftInset: Kirigami.Units.largeSpacing
                        rightInset: Kirigami.Units.largeSpacing
                        topInset: Kirigami.Units.largeSpacing
                        bottomInset: Kirigami.Units.largeSpacing
                    }
                    PropertyChanges {
                        target: background.highlight.anchors
                        margins: Kirigami.Units.largeSpacing
                    }
                    PropertyChanges {
                        target: frame
                        radius: delegate.baseRadius
                    }
                    PropertyChanges {
                        target: background.highlight
                        radius: delegate.baseRadius
                    }
                }
            ]

            transitions: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "leftInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "rightInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "topInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "bottomInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "radius"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "margins"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Item {
            id: imgRoot
            //clip: true
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.topMargin: -delegate.topPadding + delegate.topInset + extraBorder
            Layout.leftMargin: -delegate.leftPadding + delegate.leftInset + extraBorder
            Layout.rightMargin: -delegate.rightPadding + delegate.rightInset + extraBorder
            // Any width times 0.5625 is a 16:9 ratio
            // Adding baseRadius is needed to prevent the bottom from being rounded
            Layout.preferredHeight: width * 0.5625 + delegate.baseRadius
            // FIXME: another thing copied from AbstractDelegate
            property real extraBorder: 0

            layer.enabled: true
            layer.effect: OpacityMask {
                cached: true
                maskSource: Rectangle {
                    x: imgRoot.x;
                    y: imgRoot.y
                    width: imgRoot.width
                    height: imgRoot.height
                    radius: delegate.baseRadius
                }
            }

            Image {
                id: img
                source: "https://" + modelData.channel.host + modelData.thumbnail_path
                anchors {
                    fill: parent
                    // To not round under
                    bottomMargin: delegate.baseRadius
                }
                opacity: 1
                fillMode: Image.PreserveAspectCrop

                Rectangle {
                    id: videoDurationTime
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Kirigami.Units.largeSpacing
                    anchors.right: parent.right
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    // FIXME: kind of hacky to get the padding around the text right
                    width: durationText.width + Kirigami.Units.largeSpacing
                    height: Kirigami.Units.gridUnit
                    radius: delegate.baseRadius
                    visible: modelData.duration ? 1 : 0
                    color: Qt.rgba(0, 0, 0, 0.8)

                    PlasmaComponents.Label {
                        id: durationText
                        anchors.centerIn: parent
                        text: timeSanitize(modelData.duration)
                        color: Kirigami.Theme.textColor
                    }
                }
            }
            
            states: [
                State {
                    when: delegate.isCurrent
                    PropertyChanges {
                        target: imgRoot
                        extraBorder: delegate.borderSize
                    }
                },
                State {
                    when: !delegate.isCurrent
                    PropertyChanges {
                        target: imgRoot
                        extraBorder: 0
                    }
                }
            ]
            transitions: Transition {
                onRunningChanged: {
                    // Optimize when animating the thumbnail
                    img.smooth = !running
                }
                NumberAnimation {
                    property: "extraBorder"
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Compensate for blank space created from not rounding thumbnail bottom corners
            Layout.topMargin: -delegate.baseRadius
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                id: videoLabel
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                wrapMode: Text.Wrap
                level: 3
                maximumLineCount: 1
                elide: Text.ElideRight
                color: PlasmaCore.ColorScope.textColor
                Component.onCompleted: {
                    text = modelData.name
                }
            }

            PlasmaComponents.Label {
                id: videoChannelName
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                maximumLineCount: 1
                elide: Text.ElideRight
                color: PlasmaCore.ColorScope.textColor
                text: modelData.channel.display_name
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    id: videoViews
                    Layout.alignment: Qt.AlignLeft
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    elide: Text.ElideRight
                    color: PlasmaCore.ColorScope.textColor
                    text: modelData.views
                }

                PlasmaComponents.Label {
                    id: videoUploadDate
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    color: PlasmaCore.ColorScope.textColor
                    text: setPublishedDate(modelData.published_at)
                }
            }
        }
    }
    
    Keys.onReturnPressed: {
        clicked()
    }

    onClicked: {
        busyIndicatorPop.open()
        triggerGuiEvent("PeerTube.WatchVideo", modelData)
    }
}
