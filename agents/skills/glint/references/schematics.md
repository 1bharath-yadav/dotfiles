# Hardware Schematics & Wiring (`drawio-diagram`)

Distilled from `drawio-skill` for transparent circuit and architecture overlays.

> **Deep Tooling Fallback:** If you require automated Terraform, Kubernetes, SQL ERD, or GraphQL schema-to-diagram generators, tubemap subway layouts, or visual diff reviews, load `~/.agents/skills/drawio-skill/`.

---

## 1. Core mxGraph XML Invariants

Glint renders standard mxGraph XML directly into hardware-accelerated interactive SVG with pan, zoom, and click-to-ask integration.

1. **Root Hierarchy**: Every schematic must have root nodes `<mxCell id="0"/>` and `<mxCell id="1" parent="0"/>`.
2. **Minimal Palette**:
   - Surface background: Dark neutral `#1e293b`
   - Stroke colors:
     - Microcontroller / CPU: Emerald `#10b981` (strokeWidth=2)
     - Power Rails: Sky `#38bdf8` (strokeWidth=2)
     - I2C / Serial Bus: Amber `#f59e0b` (strokeWidth=1.5)
     - Sensors / Displays: Purple `#a855f7` (strokeWidth=1.5)
   - Text color: Light neutral `#f8fafc`, subtitle `#94a3b8`

---

## 2. Minimal Working Hardware Wiring Schematic

```xml
<mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1100" pageHeight="850">
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    
    <!-- 1. Power Supply Module -->
    <mxCell id="power_supply" value="Buck Converter&#xa;5V / 3A DC Step-Down" vertex="1" parent="1" style="rounded=1;fillColor=#1e293b;strokeColor=#38bdf8;fontColor=#f8fafc;strokeWidth=1.5;">
      <mxGeometry x="80" y="160" width="170" height="75" as="geometry"/>
    </mxCell>

    <!-- 2. Main ESP32-S3 SoC -->
    <mxCell id="esp32" value="ESP32-S3 Dual Core&#xa;240MHz SoC • WiFi / BLE" vertex="1" parent="1" style="rounded=1;fillColor=#1e293b;strokeColor=#10b981;fontColor=#f8fafc;strokeWidth=2;">
      <mxGeometry x="360" y="140" width="200" height="110" as="geometry"/>
    </mxCell>

    <!-- 3. OLED Display SSD1306 -->
    <mxCell id="oled_display" value="SSD1306 OLED (I2C)&#xa;128x64 px Graphics" vertex="1" parent="1" style="rounded=1;fillColor=#1e293b;strokeColor=#a855f7;fontColor=#f8fafc;strokeWidth=1.5;">
      <mxGeometry x="680" y="90" width="170" height="75" as="geometry"/>
    </mxCell>

    <!-- 4. Environmental Sensor BME280 -->
    <mxCell id="bme280" value="BME280 Temp/Humidity&#xa;Precision Sensor (I2C)" vertex="1" parent="1" style="rounded=1;fillColor=#1e293b;strokeColor=#f59e0b;fontColor=#f8fafc;strokeWidth=1.5;">
      <mxGeometry x="680" y="230" width="170" height="75" as="geometry"/>
    </mxCell>

    <!-- Edges / Wiring Rails -->
    <mxCell id="edge_power" value="5V VCC Power Rail" edge="1" parent="1" source="power_supply" target="esp32" style="strokeColor=#38bdf8;strokeWidth=2;fontColor=#94a3b8;">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <mxCell id="edge_i2c_oled" value="I2C (SDA=GPIO8, SCL=GPIO9)" edge="1" parent="1" source="esp32" target="oled_display" style="strokeColor=#a855f7;strokeWidth=2;fontColor=#94a3b8;">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

    <mxCell id="edge_i2c_sensor" value="I2C Data Bus (0x76)" edge="1" parent="1" source="esp32" target="bme280" style="strokeColor=#f59e0b;strokeWidth=2;fontColor=#94a3b8;">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

---

## 3. Dispatching to Glint

```json
{
  "name": "glint_draw",
  "arguments": {
    "adapter": "drawio-diagram",
    "title": "ESP32 Sensor Bus Schematic",
    "payload": {
      "xml": "<mxGraphModel>...</mxGraphModel>"
    }
  }
}
```
