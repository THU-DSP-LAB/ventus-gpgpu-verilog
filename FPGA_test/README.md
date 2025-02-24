### FPGA test框架    

![输入图片说明](https://github.com/ICer-cxc/ventus-gpgpu-verilog/blob/main/FPGA_test/docs/images/FPGA_test_framework.jpg)   

**MDM**：Microblaze 的 debug 模块，通过  JTAG 接口进行连接，配合 SDK 对 microblaze 调试。  
**Microblaze**：软核处理器，系统的控制单元。  
**Microblaze Local Memory**：软核的本地内存。
**Microblaze AXI periph**：桥接口，用于连接 Microblaze 与外设。  
**CDMA**：中央直接内存访问（CDMA）控制器，能够高效地在 AXI 总线上执行内存读写操作。  
**GPGPU**：适应axi协议的 GPGPU。  
**GPIO**：通用输入输出接口，用来控制外部设备（LED）的状态。  
**Uartlite**：串行通信接口，输出调试信息。  
**AXI smc**：高性能的 AXI 互连架构，用于连接多个 AXI 主设备和从设备，管理不同计算单元和内存之间的数据流。  
**DDR4 SDRAM**： DDR4 内存。  
**GPGPU memory**：DDR 最大从 0x80000000 开始，根据架构划分补充0x70000000 开始的 2M 内存作为 local memory，如下图根据内存空间分配和映射分配地址。   

![输入图片说明](https://github.com/ICer-cxc/ventus-gpgpu-verilog/blob/main/FPGA_test/docs/images/memory_model.jpg)  
  
开发工具 SDK 编译的驱动程序最终生成 .elf 的可执行文件（包括 Miceroblaze 处理器上的指令和数据），通过 JTAG 接口，SDK 将 .elf 通过 MDM 上传到 Microblaze 内存（Microblaze local memory）中。Microblaze 开始执行，向DDR、gpu、CDMA 等外设写数据和指令。GPGPU 和 CMDA 通过 AXI smc能访问到固定范围的 DDR，GPGPU 执行完后，Microblaze 读取存放结果的地址进行验证后，控制 GPIO 将 LED 点亮。  
### 如何创建vivado项目
1.下载 [ventus-gpgpu-verilog](https://github.com/THU-DSP-LAB/ventus-gpgpu-verilog) 仓下的`src` 文件夹，根据不同测例需修改 `define.v` 文件里面的 warp 和 thread 数
2.在 Vivado 的 Tcl 窗口输入，这将耗费很长时间生成比特流  
`source ventus_fpga.tcl`  
3. vivado 里 launch SDK  
4.创建一个项目，并将 `driver` 文件夹中的文件导入  
5. FPGA 上运行程序
