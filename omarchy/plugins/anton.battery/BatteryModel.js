function batteryPercentage(device) {
  if (!device || !device.isPresent) return -1
  return Math.round(Number(device.percentage || 0) * 100)
}

function isDischarging(device, onBattery, dischargingState) {
  return !!(device && device.isPresent && onBattery && device.state === dischargingState)
}

function shouldWarnLowBattery(device, onBattery, dischargingState, threshold, alreadyNotified) {
  var level = batteryPercentage(device)
  if (level < 0) return { level: level, notify: false, notifiedLowBattery: false }

  var low = isDischarging(device, onBattery, dischargingState) && level <= threshold
  return {
    level: level,
    notify: low && !alreadyNotified,
    notifiedLowBattery: low
  }
}

function evaluateBatteryState(device, onBattery, dischargingState, lowThreshold, criticalThreshold, stepDrop, lastWarnedLevel) {
  var level = batteryPercentage(device)
  var discharging = isDischarging(device, onBattery, dischargingState)

  if (!discharging || level < 0 || level > lowThreshold) {
    return {
      level: level,
      action: "reset",
      nextWarnedLevel: -1
    }
  }

  // Critical battery <= 10%: continuous alarm
  if (level <= criticalThreshold) {
    return {
      level: level,
      action: "critical",
      nextWarnedLevel: level
    }
  }

  // Low battery (11% to 20%): alert on first drop into threshold or every step drop (3%)
  if (lastWarnedLevel === -1 || (lastWarnedLevel - level) >= stepDrop) {
    return {
      level: level,
      action: "warn",
      nextWarnedLevel: level
    }
  }

  return {
    level: level,
    action: "none",
    nextWarnedLevel: lastWarnedLevel
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    batteryPercentage: batteryPercentage,
    isDischarging: isDischarging,
    shouldWarnLowBattery: shouldWarnLowBattery,
    evaluateBatteryState: evaluateBatteryState
  }
}
