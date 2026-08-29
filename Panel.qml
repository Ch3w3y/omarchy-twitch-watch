import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.ch3w3y.twitch-watch"
  ipcTarget: "io.github.ch3w3y.twitch-watch"
  manageIpc: false

  // Injected by the shell loader when declared on the entry-point root --
  // the plugin's own directory, so the bundled scripts/ are found regardless
  // of the user's home directory or exact plugin id.
  property string omarchyPath: ""
  readonly property string scriptsDir: (root.omarchyPath.length > 0
    ? root.omarchyPath
    : (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/io.github.ch3w3y.twitch-watch") + "/scripts"

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string configPath: (Quickshell.env("HOME") || "") + "/.config/twitch-watch/config.json"

  property var config: ({})
  function cfg(key, fallback) {
    var v = root.config ? root.config[key] : undefined
    return (v === undefined || v === null) ? fallback : v
  }
  readonly property int refreshIntervalSec: cfg("refresh_interval_sec", 60)

  property var channels: []
  property bool settingsOpen: false

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    settingsOpen = false
    if (!liveProc.running) liveProc.running = true
    Qt.callLater(function() {
      if (!root.opened || !contentLoader.item) return
      if (typeof contentLoader.item.reset === "function") contentLoader.item.reset()
      if (contentLoader.item.focusItem) contentLoader.item.focusItem.forceActiveFocus()
    })
  }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try { root.config = JSON.parse(text()) } catch (e) { root.config = {} }
    }
    onLoadFailed: root.config = {}
    onFileChanged: reload()
  }

  function saveConfig(patch) {
    var next = Object.assign({}, root.config, patch)
    root.config = next
    configFile.setText(JSON.stringify(next, null, 2) + "\n")
  }

  Process {
    id: liveProc
    command: [root.scriptsDir + "/twitch-followed-live"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.channels = JSON.parse(text) } catch (e) { /* keep stale list */ }
      }
    }
    // The script writes its diagnostics to stderr; without this every auth and
    // API failure is invisible and the sweep just silently retries forever.
    stderr: StdioCollector {
      onStreamFinished: if (text && text.trim() !== "") console.warn("twitch-watch:", text.trim())
    }
  }

  Timer {
    // This lives in the bar widget, so it runs once per monitor. While the popup
    // is shut the bar only needs a live-channel count, so back right off.
    interval: Math.max(15, root.refreshIntervalSec) * 1000 * (root.opened ? 1 : 5)
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!liveProc.running) liveProc.running = true
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰐷"
    // Red (activeColor, defaults to Color.urgent) when any followed channel
    // is live, default foreground otherwise -- no separate count badge.
    active: root.channels.length > 0
    onPressed: function(buttonCode) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: contentLoader.item ? contentLoader.item.focusItem : null
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(Style.space(460), Style.space(560))

    Loader {
      id: contentLoader
      anchors.fill: parent
      sourceComponent: root.settingsOpen ? settingsComponent : pickerComponent
    }
  }

  Component {
    id: pickerComponent
    ChannelPicker {
      channels: root.channels
      foreground: root.foreground
      fontFamily: root.fontFamily
      onActivate: function(login) {
        root.close()
        Quickshell.execDetached([root.scriptsDir + "/twitch-watch", login])
      }
      onOpenSettings: root.settingsOpen = true
      onCloseRequested: root.close()
    }
  }

  Component {
    id: settingsComponent
    SettingsView {
      config: root.config
      foreground: root.foreground
      fontFamily: root.fontFamily
      onSave: function(patch) { root.saveConfig(patch) }
      onBack: root.settingsOpen = false
      onCloseRequested: root.close()
    }
  }
}
