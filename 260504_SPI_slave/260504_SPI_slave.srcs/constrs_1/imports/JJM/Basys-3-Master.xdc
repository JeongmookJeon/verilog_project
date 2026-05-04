## Basys3 Constraint File - SPI Slave Board
## 스위치(sw_tx_data)로 Master에 전송할 데이터 입력,
## FND에 Master로부터 수신한 데이터 십진수 표시

## ─── Clock ───────────────────────────────────────────
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports sys_clock]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports sys_clock]

## ─── Reset (BTNC) ────────────────────────────────────
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports reset]

## ─── Switches: SW[7:0] → sw_tx_data (Master에 보낼 값) ──
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {sw_tx_data[0]}]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {sw_tx_data[1]}]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports {sw_tx_data[2]}]
set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports {sw_tx_data[3]}]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports {sw_tx_data[4]}]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports {sw_tx_data[5]}]
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports {sw_tx_data[6]}]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports {sw_tx_data[7]}]

## ─── 7-Segment Display: Cathode (fnd_data) ──────────
## Basys3 기준 세그먼트 핀 (CA~CG + DP)
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[0]}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[1]}]
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[2]}]
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[3]}]
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[4]}]
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[5]}]
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[6]}]
set_property -dict { PACKAGE_PIN V7   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[7]}]

## ─── 7-Segment Display: Anode (fnd_digit) ───────────
## AN[3:0] (Active Low, 4자리)
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[3]}]

## ─── SPI Interface (Pmod JA) ─────────────────────────
## Master 보드의 JA와 교차 연결:
##   Slave MOSI ← Master MOSI  (JA1: J1)
##   Slave MISO → Master MISO  (JA2: L2)
##   Slave CS_N ← Master CS_N  (JA3: J2)
##   Slave SCLK ← Master SCLK  (JA4: G2)
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports mosi]
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports miso]
set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports cs_n]
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports sclk]

## ─── Configuration ───────────────────────────────────
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
