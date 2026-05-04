# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\JJM\260504_MicroBlaze_SPI_I2C\workspace\SPI_system\_ide\scripts\debugger_spi-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\JJM\260504_MicroBlaze_SPI_I2C\workspace\SPI_system\_ide\scripts\debugger_spi-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183BE0E33A" && level==0 && jtag_device_ctx=="jsn-Basys3-210183BE0E33A-0362d093-0"}
fpga -file D:/JJM/260504_MicroBlaze_SPI_I2C/workspace/SPI/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Basys3 210183BE0E33A" && jtag_device_ctx=="jsn-Basys3-210183BE0E33A-0362d093-0"}
loadhw -hw D:/JJM/260504_MicroBlaze_SPI_I2C/workspace/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Basys3 210183BE0E33A" && jtag_device_ctx=="jsn-Basys3-210183BE0E33A-0362d093-0"}
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Basys3 210183BE0E33A" && jtag_device_ctx=="jsn-Basys3-210183BE0E33A-0362d093-0"}
dow D:/JJM/260504_MicroBlaze_SPI_I2C/workspace/SPI/Debug/SPI.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Basys3 210183BE0E33A" && jtag_device_ctx=="jsn-Basys3-210183BE0E33A-0362d093-0"}
con
