import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "BatteryModel.js" as BatteryModel

Item {
  id: root

  property var shell: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  readonly property int lowThreshold: 20
  readonly property int criticalThreshold: 10
  readonly property int stepDrop: 3
  property string pendingPowerSource: ""

  PersistentProperties {
    id: persisted
    reloadableId: "omarchy-battery"
    property int lastWarnedLevel: -1
  }

  function batteryPercentage() {
    return BatteryModel.batteryPercentage(UPower.displayDevice)
  }

  function isDischarging() {
    return BatteryModel.isDischarging(UPower.displayDevice, UPower.onBattery, UPowerDeviceState.Discharging)
  }

  function checkBattery() {
    var res = BatteryModel.evaluateBatteryState(
      UPower.displayDevice,
      UPower.onBattery,
      UPowerDeviceState.Discharging,
      lowThreshold,
      criticalThreshold,
      stepDrop,
      persisted.lastWarnedLevel
    )
    persisted.lastWarnedLevel = res.nextWarnedLevel

    if (res.action === "critical") {
      startCriticalAlarm(res.level)
    } else if (res.action === "warn") {
      sendLowBatteryWarning(res.level)
    } else if (res.action === "reset") {
      stopCriticalAlarm()
    }
  }

  function sendLowBatteryWarning(level) {
    if (warningProcess.running) return
    warningProcess.command = [
      "omarchy-battery-low",
      String(level)
    ]
    warningProcess.running = true
  }

  function startCriticalAlarm(level) {
    if (alarmProcess.running) return
    alarmProcess.command = [
      "omarchy-battery-alarm",
      "start",
      String(level)
    ]
    alarmProcess.running = true
  }

  function stopCriticalAlarm() {
    if (alarmProcess.running) return
    alarmProcess.command = [
      "omarchy-battery-alarm",
      "reset"
    ]
    alarmProcess.running = true
  }

  function applyPowerProfile() {
    pendingPowerSource = UPower.onBattery ? "battery" : "ac"
    if (!powerProfileProcess.running) runPendingPowerProfile()
  }

  function runPendingPowerProfile() {
    powerProfileProcess.command = ["omarchy-powerprofiles-set", pendingPowerSource]
    pendingPowerSource = ""
    powerProfileProcess.running = true
  }

  Process { id: warningProcess }
  Process { id: alarmProcess }

  Process {
    id: powerProfileProcess
    onExited: if (root.pendingPowerSource !== "") root.runPendingPowerProfile()
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkBattery()
  }

  Connections {
    target: UPower
    function onOnBatteryChanged() {
      root.checkBattery()
      root.applyPowerProfile()
    }
  }
}
