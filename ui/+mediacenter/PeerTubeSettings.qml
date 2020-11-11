/*
 * Copyright 2020 by Aditya Mehra <aix.m@outlook.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.2
import org.kde.kirigami 2.8 as Kirigami
import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
    id: configurePage
    property var instances_model: sessionData.instances_model
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
        
    function getCurrentIndex(list, element) {
        if (list && element) {
            for (var i = 0; i < list.length; i++) {
                console.log(list[i], i)
                if (list[i] === element) {
                    return i 
                }
            }
        }
            return -1
    }
    
    onFocusChanged: {
        if(focus){
            instanceSelectorArea.forceActiveFocus()
        }
    }
    
    Rectangle {
        color: "black"
        anchors.fill: parent
            
        Item {
            id: contactsPageHeading
            width: parent.width
            height: Kirigami.Units.gridUnit * 3
            
            Button {
                id: backButton
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.verticalCenter: parent.verticalCenter
                KeyNavigation.down: instanceSelectorArea
                height: Kirigami.Units.gridUnit * 3
                width: height
                
                background: Rectangle {
                    color: "transparent"
                    radius: Kirigami.Units.gridUnit
                    border.width: backButton.activeFocus ? 1 : 0
                    border.color: backButton.activeFocus ? Kirigami.Theme.linkColor : "transparent"
                }
                
                contentItem: Item {
                    Image {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.medium
                        height: width
                        source: "./images/back.png"
                    }
                }
                
                Keys.onReturnPressed: {
                    clicked()
                }

                onClicked: {
                    triggerGuiEvent("PeerTube.SettingsPage", {"settings_open": false})
                }
            }
            
            Kirigami.Heading  {
                anchors.left: parent.left
                anchors.right: parent.right
                height: Kirigami.Units.gridUnit * 3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                text: "Configure"
                color: Kirigami.Theme.highlightColor
            }
        }
            
        Kirigami.Separator {
            id: headerSept
            anchors.top: contactsPageHeading.bottom
            anchors.topMargin: Kirigami.Units.largeSpacing
            width: parent.width
            height: 1
        }
        
        Kirigami.Heading {
            level: 2
            id: instanceHeaderLabel
            anchors.top: headerSept.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Kirigami.Units.largeSpacing
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: "Select Instance"
            color: Kirigami.Theme.highlightColor
        }
            
        Rectangle {
            id: instanceSelectorArea
            anchors.top: instanceHeaderLabel.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.largeSpacing
            height: Kirigami.Units.gridUnit * 4
            KeyNavigation.up: backButton
            KeyNavigation.down: cmbBxApplyBtn
            color: "transparent"
            border.width: instanceSelectorArea.activeFocus ? 1 : 0
            border.color: instanceSelectorArea.activeFocus ? Kirigami.Theme.linkColor : "transparent"
            
            Keys.onReturnPressed: {
                cmbBx.forceActiveFocus()
            }
            
            ComboBox {
                id: cmbBx
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                textRole: "hostname"
                valueRole: "hosturl"

                Keys.onBackPressed: {
                    instanceSelectorArea.forceActiveFocus()
                }
                
                Keys.onEscapePressed: {
                    instanceSelectorArea.forceActiveFocus()
                }
    
                model: instances_model
                
                Component.onCompleted: {
                    currentIndex = getCurrentIndex(sessionData.instance_string_model, sessionData.current_instance)
                }
            }
        }
        
            
        Button {
            id: cmbBxApplyBtn
            anchors.top: instanceSelectorArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.largeSpacing
            KeyNavigation.up: instanceSelectorArea
            KeyNavigation.down: backButton
            height: Kirigami.Units.gridUnit * 3
            
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
                radius: Kirigami.Units.gridUnit
                border.width: cmbBxApplyBtn.activeFocus ? 1 : 0
                border.color: cmbBxApplyBtn.activeFocus ? Kirigami.Theme.linkColor : "transparent"
            }
            
            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: "./images/apply.png"
                }
            } 
            
            onClicked: {
                triggerGuiEvent("PeerTube.ConfigureHost", {"selected_instance": cmbBx.currentValue})
            }
            
            Keys.onReturnPressed: {
                clicked()
            }
        }
    }
}
 
 
