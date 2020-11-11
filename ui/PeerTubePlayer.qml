import QtMultimedia 5.12
import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.12 as Controls
import org.kde.kirigami 2.10 as Kirigami
import QtGraphicalEffects 1.0

import Mycroft 1.0 as Mycroft

import "." as Local

Mycroft.Delegate {
    id: root

    property var videoSource: sessionData.video_stream
    property var videoStatus: sessionData.video_status
    property var videoThumb: "https://" + sessionData.video_meta.channel.host + sessionData.video_meta.thumbnail_path
    property var videoTitle: sessionData.video_meta.name
    property var videoAuthor: sessionData.video_meta.channel.name
    property var videoViewCount: sessionData.video_meta.views
    property var videoPublishDate: sessionData.video_meta.published_at
    property bool busyIndicate: false
    
    //The player is always fullscreen
    fillWidth: true
    background: Rectangle {
        color: "black"
    }
    leftPadding: 0
    topPadding: 0
    rightPadding: 0
    bottomPadding: 0

    onEnabledChanged: syncStatusTimer.restart()
    onVideoSourceChanged: syncStatusTimer.restart()
    Component.onCompleted: {
        syncStatusTimer.restart()
    }
    
    function changePage(){
        delay(3500, function() {
            parent.parent.parent.currentIndex++
            parent.parent.parent.currentItem.contentItem.forceActiveFocus()
        })
    }
    
    onVideoThumbChanged: {
        if(videoThumb == ""){
            busyIndicatorPop.open()
        } else {
            busyIndicatorPop.close()
        }
    }
    
    Keys.onDownPressed: {
        controlBarItem.opened = true
        controlBarItem.forceActiveFocus()
    }
            
    onFocusChanged: {
        if(focus){
            video.forceActiveFocus();
        }
    }
    
    Connections {
        target: window
        onVisibleChanged: {
            if(video.playbackState == MediaPlayer.PlayingState) {
                videoStatus = "stop"
                video.stop()
            }
        }
    }
    
    function getViewCount(value){
        return value.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')
    }
    
    function setPublishedDate(publishDate) {
        var date1 = new Date(publishDate).getTime();
        var date2 = new Date().getTime();
        console.log(date1)
        console.log(date2)
        
        var msec = date2 - date1;
        var mins = Math.floor(msec / 60000);
        var hrs = Math.floor(mins / 60);
        var days = Math.floor(hrs / 24);
        var yrs = Math.floor(days / 365);
        mins = mins % 60;
        hrs = hrs % 24;
        days = days % 365;
        var result = ""
        if(days == 0 && hrs > 0) {
            result = hrs + " hours, " + mins + " minutes ago"
        } else if (days == 0 && hrs == 0) {
            result = mins + " minutes ago"
        } else {
            result = days + " days, " + hrs + " hours, " + mins + " minutes ago"
        }
        return result
    }

    function listProperty(item) {
        for (var p in item)
        {
            if( typeof item[p] != "function" )
                if(p != "objectName")
                    console.log(p + ":" + item[p]);
        }
    }
    
    // Sometimes can't be restarted reliably immediately, put it in a timer
    Timer {
        id: syncStatusTimer
        interval: 0
        onTriggered: {
            if (enabled && videoStatus == "play") {
                video.play();
            } else if (videoStatus == "stop") {
                video.stop();
            } else {
                video.pause();
            }
        }
    }
    
    Timer {
        id: delaytimer
    }

    function delay(delayTime, cb) {
            delaytimer.interval = delayTime;
            delaytimer.repeat = false;
            delaytimer.triggered.connect(cb);
            delaytimer.start();
    }
    
    controlBar: Local.SeekControl {
        id: seekControl
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        title: videoTitle  
        videoControl: video
        duration: video.duration
        playPosition: video.position
        onSeekPositionChanged: video.seek(seekPosition);
        z: 1000
    }
    
    Item {
        id: videoRoot
        anchors.fill: parent 
            
         Rectangle { 
            id: infomationBar 
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            visible: false
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
            implicitHeight: vidTitle.implicitHeight + Kirigami.Units.largeSpacing * 2
            z: 1001
            
            onVisibleChanged: {
                delay(15000, function() {
                    infomationBar.visible = false;
                })
            }
            
            Kirigami.Heading {
                id: vidTitle
                level: 2
                height: Kirigami.Units.gridUnit * 2
                visible: true
                anchors.verticalCenter: parent.verticalCenter
                text: "Title: " + videoTitle
                z: 100
            }
         }
            
        Image {
            id: thumbart
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: root.videoThumb 
            enabled: root.videoStatus == "stop" ? 1 : 0
            visible: root.videoStatus == "stop" ? 1 : 0
        }
        
        Controls.Popup {
            id: busyIndicatorPop
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            
            background: Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
            }
            closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutsideParent
            
            RowLayout {
                anchors.centerIn: parent

                Controls.BusyIndicator {
                    running: busyIndicate
                }
                
                Kirigami.Heading {
                    level: 2
                    text: "Searching Video"
                }
            }
            
            onOpened: {
                busyIndicate = true
            }
            
            onClosed: {
                busyIndicate = false
            }
        }
        
        Video {
            id: video
            anchors.fill: parent
            focus: true
            autoLoad: true
            autoPlay: false
            Keys.onSpacePressed: video.playbackState == MediaPlayer.PlayingState ? video.pause() : video.play()
            KeyNavigation.up: closeButton
            source: videoSource
            readonly property string currentStatus: root.enabled ? root.videoStatus : "pause"
            
            onCurrentStatusChanged: {print("OOO"+currentStatus)
                switch(currentStatus){
                    case "stop":
                        video.stop();
                        break;
                    case "pause":
                        video.pause()
                        break;
                    case "play":
                        video.play()
                        busyIndicatorPop.close()
                        delay(6000, function() {
                            infomationBar.visible = false;
                        })
                        break;
                }
            }
            
            Keys.onReturnPressed: {
                video.playbackState == MediaPlayer.PlayingState ? video.pause() : video.play()
            }
                    
            Keys.onDownPressed: {
                controlBarItem.opened = true
                controlBarItem.forceActiveFocus()
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: { 
                    controlBarItem.opened = !controlBarItem.opened 
                }
            }
            
            onStatusChanged: {
                console.log(status)
                if(status == 7) {
                    changePage()
                }
            }
        }
    }
}
