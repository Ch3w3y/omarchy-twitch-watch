import QtQuick
import qs.Commons

Item {
  id: root

  property var config: ({})
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  readonly property Item focusItem: root
  focus: true
  Keys.onEscapePressed: root.closeRequested()

  signal save(var patch)
  signal back()
  signal closeRequested()

  function cfg(key, fallback) {
    var v = root.config ? root.config[key] : undefined
    return (v === undefined || v === null) ? fallback : v
  }

  readonly property var qualities: ["best", "1080p60", "720p60", "480p"]

  Column {
    anchors.fill: parent
    spacing: Style.space(16)

    Row {
      width: parent.width
      spacing: Style.space(8)

      Rectangle {
        width: 60
        height: 26
        radius: Style.space(6)
        color: backArea.containsMouse ? Qt.alpha(root.foreground, 0.12) : "transparent"
        Text {
          anchors.centerIn: parent
          text: "← Back"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: 11
        }
        MouseArea {
          id: backArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.back()
        }
      }

      Text {
        text: "Twitch Watch settings"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: 13
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(4)

      Text {
        text: "Default stream quality"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: 12
      }

      Row {
        spacing: Style.space(6)
        Repeater {
          model: root.qualities
          delegate: Rectangle {
            required property string modelData
            readonly property bool active: root.cfg("default_quality", "best") === modelData
            width: qtext.implicitWidth + Style.space(16)
            height: 28
            radius: Style.space(6)
            color: active ? Color.accent : (qArea.containsMouse ? Qt.alpha(root.foreground, 0.12) : Qt.alpha(root.foreground, 0.06))
            Text {
              id: qtext
              anchors.centerIn: parent
              text: parent.modelData
              color: parent.active ? "white" : root.foreground
              font.family: root.fontFamily
              font.pixelSize: 11
            }
            MouseArea {
              id: qArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.save({ default_quality: parent.modelData })
            }
          }
        }
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(4)

      Text {
        text: "Chat pane width (px)"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: 12
      }

      Row {
        spacing: Style.space(10)

        Rectangle {
          width: 28; height: 28; radius: Style.space(6)
          color: minusArea.containsMouse ? Qt.alpha(root.foreground, 0.12) : Qt.alpha(root.foreground, 0.06)
          Text { anchors.centerIn: parent; text: "−"; color: root.foreground; font.pixelSize: 14 }
          MouseArea {
            id: minusArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.save({ chat_width: Math.max(250, root.cfg("chat_width", 420) - 10) })
          }
        }

        Text {
          text: root.cfg("chat_width", 420) + "px"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 28; height: 28; radius: Style.space(6)
          color: plusArea.containsMouse ? Qt.alpha(root.foreground, 0.12) : Qt.alpha(root.foreground, 0.06)
          Text { anchors.centerIn: parent; text: "+"; color: root.foreground; font.pixelSize: 14 }
          MouseArea {
            id: plusArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.save({ chat_width: Math.min(800, root.cfg("chat_width", 420) + 10) })
          }
        }
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(10)

      Rectangle {
        width: 40
        height: 22
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.cfg("locked", true) ? Color.accent : Qt.alpha(root.foreground, 0.2)

        Rectangle {
          width: 18
          height: 18
          radius: 9
          anchors.verticalCenter: parent.verticalCenter
          x: root.cfg("locked", true) ? parent.width - width - 2 : 2
          color: "white"
          Behavior on x { NumberAnimation { duration: 120 } }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.save({ locked: !root.cfg("locked", true) })
        }
      }

      Text {
        text: "Lock chat width on launch/swap"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(4)

      Text {
        text: "Refresh interval (seconds)"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: 12
      }

      Row {
        spacing: Style.space(10)

        Rectangle {
          width: 28; height: 28; radius: Style.space(6)
          color: rMinusArea.containsMouse ? Qt.alpha(root.foreground, 0.12) : Qt.alpha(root.foreground, 0.06)
          Text { anchors.centerIn: parent; text: "−"; color: root.foreground; font.pixelSize: 14 }
          MouseArea {
            id: rMinusArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.save({ refresh_interval_sec: Math.max(15, root.cfg("refresh_interval_sec", 60) - 15) })
          }
        }

        Text {
          text: root.cfg("refresh_interval_sec", 60) + "s"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 28; height: 28; radius: Style.space(6)
          color: rPlusArea.containsMouse ? Qt.alpha(root.foreground, 0.12) : Qt.alpha(root.foreground, 0.06)
          Text { anchors.centerIn: parent; text: "+"; color: root.foreground; font.pixelSize: 14 }
          MouseArea {
            id: rPlusArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.save({ refresh_interval_sec: Math.min(600, root.cfg("refresh_interval_sec", 60) + 15) })
          }
        }
      }
    }
  }
}
