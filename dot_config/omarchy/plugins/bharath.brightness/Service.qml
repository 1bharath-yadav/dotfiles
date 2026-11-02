import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var shell: null
  property string direction: ""

  PersistentProperties {
    id: persisted
    reloadableId: "bharath-brightness"
    property int gamma: 100
  }

  readonly property int gammaLowerLimit: 25

  function changeBrightness(step) {
    if (probe.running) return
    direction = step
    probe.running = true
  }

  function applyGamma(value) {
    const next = Math.max(gammaLowerLimit, Math.min(100, value))
    persisted.gamma = next
    gammaProcess.command = ["bash", "-lc",
      "pgrep -x hyprsunset >/dev/null || { setsid uwsm-app -- hyprsunset >/dev/null 2>&1 & sleep 1; }; " +
      "hyprctl hyprsunset gamma " + next]
    gammaProcess.running = true
  }

  function handleBrightness(current, maximum) {
    if (!(maximum > 0) || !(current >= 0)) return
    const minimum = Math.max(1, Math.floor(maximum * 0.01))
    const step = Math.max(1, Math.round(maximum * 0.05))

    if (direction === "down") {
      if (current > minimum) {
        setProcess.command = ["brightnessctl", "--class", "backlight", "set", String(Math.max(minimum, current - step))]
        setProcess.running = true
      } else {
        applyGamma(persisted.gamma - 5)
      }
    } else if (direction === "up") {
      if (persisted.gamma < 100) {
        applyGamma(persisted.gamma + 5)
      } else {
        setProcess.command = ["brightnessctl", "--class", "backlight", "set", String(Math.min(maximum, current + step))]
        setProcess.running = true
      }
    }
  }

  Process {
    id: probe
    command: ["bash", "-lc", "printf '%s %s\\n' \"$(brightnessctl --class backlight get)\" \"$(brightnessctl --class backlight max)\""]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const values = text.trim().split(/\s+/).map(Number)
        if (values.length === 2 && values.every(Number.isFinite))
          root.handleBrightness(values[0], values[1])
      }
    }
  }

  Process { id: setProcess }
  Process { id: gammaProcess }

  IpcHandler {
    target: "brightness"
    function decrement(): string { root.changeBrightness("down"); return "ok" }
    function increment(): string { root.changeBrightness("up"); return "ok" }
    function status(): string {
      return JSON.stringify({ gamma: persisted.gamma, gammaLowerLimit: root.gammaLowerLimit })
    }
  }
}
