# Ventus GPGPU(Verilog Edition)

GPGPU processor supporting RISCV-V extension, developed with Verilog.

Copyright (c) 2023-2024 C\*Core Technology Co.,Ltd,Suzhou.

这是“乘影”的Verilog版本，原版（Chisel HDL）链接在[这里](https://github.com/THU-DSP-LAB/ventus-gpgpu)

乘影开源GPGPU项目网站：[opengpgpu.org.cn](https://opengpgpu.org.cn/)

目前乘影在硬件设计上还有很多不足，如果您有意愿参与到“乘影”的开发中，欢迎在github上pull request

## Architecture

乘影的硬件架构文档在[这里](https://github.com/THU-DSP-LAB/ventus-gpgpu-verilog/blob/main/docs/ventus-gpgpu-verilog-release-v1.0-spec.pdf)

承影的硬件结构框图如下所示:

![](https://github.com/THU-DSP-LAB/ventus-gpgpu-verilog/blob/main/docs/images/ventus_verilog_arch1.png)

SM核的硬件结构框图如下所示:

![](https://github.com/THU-DSP-LAB/ventus-gpgpu-verilog/blob/main/docs/images/ventus_verilog_arch2.png)

## Getting started

In `testcase/test_gpgpu_top`:

- choose testcase(`tc_vecadd`,`tc_matadd`,`tc_gaussian`,`tc_nn`,`tc_bfs`)

> 可以更换不同数量的warp和thread

- use VCS to compile RTL:

```shell
make run-vcs
```
- the testbench will print the comparison result between software and hardware,`pass` or `fail`

## Acknowledgement

We refer to some open-source design when developing Ventus GPGPU.

| Sub module                | Source                                                                                       | Detail                                                                             |
|---------------------------|----------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| CTA scheduler             | [MIAOW](https://github.com/VerticalResearchGroup/miaow)                                      | Our CTA scheduler module is based on MiaoW ultra-threads dispatcher                |
| L2Cache                   | [block-inclusivecache-sifive](https://github.com/sifive/block-inclusivecache-sifive)         | Our L2Cache design is inspired by Sifive's block-inclusivecache                    |
| FPU                       | [XiangShan](https://github.com/OpenXiangShan/XiangShan)                                      | We reused Array Multiplier in XiangShan. FPU design is also inspired by XiangShan  |
| SFU                       | [openhwgroup](https://github.com/pulp-platform/fpu_div_sqrt_mvp)                             | Our SFU module is based on pulp-platform                                           |
| Config, ...               | [rocket-chip](https://github.com/chipsalliance/rocket-chip)                                  | Some modules are sourced from RocketChip                                           |

