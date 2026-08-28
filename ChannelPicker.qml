import QtQuick
import QtQuick.Controls
import qs.Commons

Item {
  id: root

  property var channels: []
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  property alias focusItem: field

  signal activate(string login)
  signal openSettings()
  signal closeRequested()

  property string filterText: ""
  property int selectedIndex: 0
  property var rows: []

  function matches(row, needle) {
    if (!needle) return true
    return (row.login || "").toLowerCase().indexOf(needle) !== -1 ||
           (row.display_name || "").toLowerCase().indexOf(needle) !== -1 ||
           (row.game_name || "").toLowerCase().indexOf(needle) !== -1
  }

  function rebuild() {
    var q = root.filterText.trim().toLowerCase()
    var out = []
    for (var i = 0; i < root.channels.length && out.length < 50; i++) {
      if (matches(root.channels[i], q)) out.push(root.channels[i])
    }
    if (q.length > 0) {
      var exact = false
      for (var j = 0; j < out.length; j++) {
        if ((out[j].login || "").toLowerCase() === q) { exact = true; break }
      }
      if (!exact) {
        out.push({
          login: root.filterText.trim(), display_name: "", viewer_count: -1,
          game_name: "", is_subscribed: false, thumbnail_url: "", isFreeText: true
        })
      }
    }
    root.rows = out
    root.selectedIndex = 0
  }

  onChannelsChanged: rebuild()
  onFilterTextChanged: rebuild()
  Component.onCompleted: rebuild()

  function select(delta) {
    if (rows.length === 0) return
    selectedIndex = (selectedIndex + delta + rows.length) % rows.length
    list.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function activateSelected() {
    if (rows.length === 0) return
    root.activate(rows[selectedIndex].login)
  }

  // Called by Panel.qml on every open. The Loader that hosts this component
  // keeps it alive across close/reopen, so filterText persists on its own --
  // and once the user has typed anything, TextField.text's initial one-way
  // binding to root.filterText is broken (any user edit destroys a
  // declarative binding), so the field itself must be cleared explicitly too.
  function reset() {
    filterText = ""
    field.text = ""
  }

  Column {
    anchors.fill: parent
    spacing: Style.space(8)

    Row {
      width: parent.width
      spacing: Style.space(8)

      TextField {
        id: field
        width: parent.width - gearButton.width - parent.spacing
        placeholderText: "Search live followed channels…"
        text: root.filterText
        onTextEdited: root.filterText = text
        Keys.onEscapePressed: root.closeRequested()
        Keys.onDownPressed: root.select(1)
        Keys.onUpPressed: root.select(-1)
        Keys.onReturnPressed: root.activateSelected()
        Keys.onEnterPressed: root.activateSelected()
      }

      Rectangle {
        id: gearButton
        width: Style.space(28)
        height: Style.space(28)
        radius: Style.space(6)
        color: gearArea.containsMouse ? Qt.alpha(root.foreground, 0.12) : "transparent"

        Text {
          anchors.centerIn: parent
          text: "⚙"
          color: root.foreground
          font.pixelSize: 14
        }

        MouseArea {
          id: gearArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.openSettings()
        }
      }
    }

    ListView {
      id: list
      width: parent.width
      height: parent.height - field.height - parent.spacing
      clip: true
      model: root.rows
      currentIndex: root.selectedIndex
      boundsBehavior: Flickable.StopAtBounds
      spacing: Style.space(2)

      delegate: Rectangle {
        id: rowDelegate
        required property int index
        required property var modelData
        width: ListView.view.width
        height: 64
        radius: Style.space(6)
        color: index === root.selectedIndex ? Qt.alpha(root.foreground, 0.10) : "transparent"

        Row {
          anchors.fill: parent
          anchors.margins: Style.space(8)
          spacing: Style.space(10)

          Image {
            visible: !rowDelegate.modelData.isFreeText && !!rowDelegate.modelData.thumbnail_url
            width: visible ? 78 : 0
            height: parent.height
            source: rowDelegate.modelData.thumbnail_url || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
          }

          Column {
            width: parent.width - (rowDelegate.modelData.isFreeText ? 0 : 88)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              // login/display_name/game_name ultimately come from Twitch API
              // responses -- pin PlainText so none of it is ever interpreted
              // as rich text (AutoText's default behavior).
              textFormat: Text.PlainText
              text: rowDelegate.modelData.isFreeText
                ? ("⌨  Watch “" + rowDelegate.modelData.login + "”")
                : ((rowDelegate.modelData.is_subscribed ? "🟣 " : "🔴 ") + rowDelegate.modelData.login)
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: 13
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              visible: !rowDelegate.modelData.isFreeText
              textFormat: Text.PlainText
              text: rowDelegate.modelData.display_name + " · " + rowDelegate.modelData.viewer_count +
                    " viewers · " + rowDelegate.modelData.game_name
              color: Qt.alpha(root.foreground, 0.65)
              font.family: root.fontFamily
              font.pixelSize: 11
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.selectedIndex = rowDelegate.index; root.activateSelected() }
        }
      }

      Text {
        visible: list.count === 0
        anchors.centerIn: parent
        text: "No one you follow is live right now"
        color: Qt.alpha(root.foreground, 0.5)
        font.family: root.fontFamily
        font.pixelSize: 12
      }
    }
  }
}
