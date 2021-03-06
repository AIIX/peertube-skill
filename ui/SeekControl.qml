import QtMultimedia 5.12
import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.12 as Controls
import org.kde.kirigami 2.10 as Kirigami
import QtQuick.Templates 2.2 as Templates
import QtGraphicalEffects 1.0

import Mycroft 1.0 as Mycroft

Item {
    id: seekControl
    property bool opened: false
    property int duration: 0
    property int playPosition: 0
    property int seekPosition: 0
    property bool enabled: true
    property bool seeking: false
    property bool backRequested: false
    property var videoControl
    property string title

    property bool smallMode: root.height > root.width ? 1 : 0
    
    clip: true
    implicitHeight: mainLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
    opacity: opened

    Behavior on opacity {
        OpacityAnimator {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }

    onOpenedChanged: {
        if (opened) {
            seekControl.backRequested = false;
            hideTimer.restart();
        }
    }
    
    onFocusChanged: {
        if(focus) {
            backButton.forceActiveFocus()
        }
    }

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: {
            console.log("hide timer triggered")
            if(!seekControl.backRequested) {
                seekControl.opened = false;
                videoRoot.forceActiveFocus();
            }
        }
    }
    
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
        }
        height: parent.height
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
        y: opened ? 0 : parent.height

        Behavior on y {
            YAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
        
        ColumnLayout {
            id: mainLayout
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: infoLayout.implicitHeight
                
                GridLayout {
                    id: infoLayout
                    anchors.fill: parent
                    columns: smallMode ? 1 : 2
                        
                    Kirigami.Heading {
                        id: vidTitle
                        level: smallMode ? 3 : 2
                        Layout.minimumWidth: parent.width / 2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        visible: true
                        text: "Title: " + videoTitle
                        z: 100
                    }
                    
                    Kirigami.Heading {
                        id: vidCount
                        level: smallMode ? 3 : 2
                        Layout.minimumWidth: parent.width / 2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        visible: true
                        Layout.alignment: smallMode ? Qt.AlignLeft : Qt.AlignRight
                        horizontalAlignment: smallMode ? Qt.AlignLeft : Qt.AlignRight
                        text: "Views: " + getViewCount(videoViewCount)
                        z: 100
                    }
                        
                    Kirigami.Heading {
                        id: vidAuthor
                        level: smallMode ? 3 : 2
                        Layout.minimumWidth: parent.width / 2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        visible: true
                        text: "Published By: " + videoAuthor
                        z: 100
                    }
                        
                    Kirigami.Heading {
                        id: vidPublishDate
                        level: smallMode ? 3 : 2
                        Layout.minimumWidth: parent.width / 2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        visible: true
                        Layout.alignment: smallMode ? Qt.AlignLeft : Qt.AlignRight
                        horizontalAlignment: smallMode ? Qt.AlignLeft : Qt.AlignRight
                        text: "Published: " + setPublishedDate(videoPublishDate)
                        z: 100
                    }
                }
            }
            
            Kirigami.Separator {
                Layout.fillWidth: true
                height: 1
            }
            
            RowLayout {
                id: mainLayout2
                Layout.fillWidth: true
                Layout.fillHeight: true
                Controls.RoundButton {
                    id: backButton
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Layout.preferredWidth
                    highlighted: focus ? 1 : 0
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: backButton.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                        radius: width / 2
                        border.color: Kirigami.Theme.textColor
                        border.width: 1
                        
                        Image {
                            source: "images/simple-previous.svg"
                            width: Kirigami.Units.iconSizes.medium
                            height: Kirigami.Units.iconSizes.medium
                            anchors.centerIn: parent
                        }
                    }
                    z: 1000
                    onClicked: {
                        seekControl.backRequested = true;
                        root.parent.backRequested();
                        video.stop();
                    }
                    KeyNavigation.up: video
                    KeyNavigation.right: button
                    Keys.onReturnPressed: {
                        clicked()
                    }
                    onFocusChanged: {
                        if(!seekControl.backRequested){
                            hideTimer.restart();
                        }
                    }
                }
                Controls.RoundButton {
                    id: button
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Layout.preferredWidth
                    highlighted: focus ? 1 : 0
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: button.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                        radius: width / 2
                        border.color: Kirigami.Theme.textColor
                        border.width: 1
                        
                        Image {
                            source: videoControl.playbackState === MediaPlayer.PlayingState ? "images/simple-pause.svg" : "images/simple-play.svg"
                            width: Kirigami.Units.iconSizes.medium
                            height: Kirigami.Units.iconSizes.medium
                            anchors.centerIn: parent
                        }
                    }
                    
                    z: 1000
                    onClicked: {
                        seekControl.backRequested = false;
                        video.playbackState === MediaPlayer.PlayingState ? video.pause() : video.play();
                        hideTimer.restart();
                    }
                    KeyNavigation.up: video
                    KeyNavigation.left: backButton
                    KeyNavigation.right: slider
                    Keys.onReturnPressed: {
                        clicked()
                    }
                    onFocusChanged: {
                        if(!backRequested){
                            hideTimer.restart();
                        }
                    }
                }

                Templates.Slider {
                    id: slider
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: Kirigami.Units.gridUnit
                    value: seekControl.playPosition
                    from: 0
                    to: seekControl.duration
                    z: 1000
                    property bool navSliderItem
                    property int minimumValue: 0
                    property int maximumValue: 20
                    onMoved: {
                        seekControl.seekPosition = value;
                        hideTimer.restart();
                    }
                    
                    onNavSliderItemChanged: {
                        if(slider.navSliderItem){
                            recthandler.color = "red"
                        } else if (slider.focus) {
                            recthandler.color = Kirigami.Theme.linkColor
                        }
                    }
                    
                    onFocusChanged: {
                        if(!slider.focus){
                            recthandler.color = Kirigami.Theme.textColor
                        } else {
                            recthandler.color = Kirigami.Theme.linkColor
                        }
                    }
                    
                    handle: Rectangle {
                        id: recthandler
                        x: slider.position * (parent.width - width)
                        implicitWidth: Kirigami.Units.gridUnit
                        implicitHeight: implicitWidth
                        radius: width
                        color: Kirigami.Theme.textColor
                    }
                    background: Item {
                        Rectangle {
                            id: groove
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: parent.right
                            }
                            radius: height
                            height: Math.round(Kirigami.Units.gridUnit/3)
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                radius: height
                                color: Kirigami.Theme.highlightColor
                                width: slider.position * (parent.width - slider.handle.width/2) + slider.handle.width/2
                            }
                        }

                        Controls.Label {
                            anchors {
                                left: parent.left
                                top: groove.bottom
                                topMargin: Kirigami.Units.smallSpacing
                            }
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            text: formatTime(playPosition)
                            color: "white"
                        }

                        Controls.Label {
                            anchors {
                                right: parent.right
                                top: groove.bottom
                                topMargin: Kirigami.Units.smallSpacing
                            }
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            text: formatTime(duration)
                        }
                    }
                KeyNavigation.up: video
                KeyNavigation.left: button
                Keys.onReturnPressed: {
                    hideTimer.restart();
                    if(!navSliderItem){
                            navSliderItem = true   
                        } else {
                            navSliderItem = false
                        }
                    }
                
                Keys.onLeftPressed: {
                        console.log("leftPressedonSlider")
                        hideTimer.restart();
                        if(navSliderItem) {
                            video.seek(video.position - 5000)
                        } else {
                            button.forceActiveFocus()
                        }
                }
                
                Keys.onRightPressed: {
                        hideTimer.restart();
                        if(navSliderItem) {
                            video.seek(video.position + 5000)
                        }
                    }
                }
            }
        }
    }

    function formatTime(timeInMs) {
        if (!timeInMs || timeInMs <= 0) return "0:00"
        var seconds = timeInMs / 1000;
        var minutes = Math.floor(seconds / 60)
        seconds = Math.floor(seconds % 60)
        if (seconds < 10) seconds = "0" + seconds;
        return minutes + ":" + seconds
    }
}
