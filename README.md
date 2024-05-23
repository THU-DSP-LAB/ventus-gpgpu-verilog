![](https://github.com/THU-DSP-LAB/ventus-gpgpu-verilog/blob/docs/docs/images/ChinaCore_logo.jpg)

# Ventus GPGPU(Verilog Edition)

GPGPU processor supporting RISCV-V extension, developed with Verilog.

Copyright (c) 2023-2024 C\*Core Technology Co.,Ltd,Suzhou.

这是“乘影”的Verilog版本，原版（Chisel HDL）链接在[这里](https://github.com/THU-DSP-LAB/ventus-gpgpu)

乘影开源GPGPU项目网站：[opengpgpu.org.cn](https://opengpgpu.org.cn/)

目前乘影在硬件设计上还有很多不足，如果您有意愿参与到“乘影”的开发中，欢迎在github上pull request

## Architecture

乘影的硬件架构文档在[这里](https://github.com/THU-DSP-LAB/ventus-gpgpu-verilog/blob/docs/docs/ventus-gpgpu-verilog-release-v1.0-spec.pdf)

承影的硬件结构框图如下所示:

![](https://github.com/THU-DSP-LAB/ventus-gpgpu-verilog/blob/docs/docs/images/ventus_verilog_arch1.png)

SM核的硬件结构框图如下所示:

![](https://github.com/THU-DSP-LAB/ventus-gpgpu-verilog/blob/docs/docs/images/ventus_verilog_arch2.png)

## Getting started

以gassian用例为例，进入`testcase/test_gpgpu_axi_top/tc_gaussian`:

- 打开`tc.v`,选择case的warp数和thread数

> 在`modules/define/define.v`目录下，修改`NUM_THREAD`，可以更改warp内的thread数量

- 用VCS仿真:

```shell
make run-vcs
```
- 结果会显示`passed`或`failed`

- 用Verdi查看波形

```shell
make verdi
```

- 如果不需要对外的AXI接口，则进入`testcase/test_gpgpu_top/tc_gaussian`，步骤同上

## Case Description

<table>
<tr>
<th>测试集</th>
<th>warp/thread数</th>
<th>是否通过</th>
<th>说明</th>
</tr>
<tr>
<td rowspan=4>vecadd</td>
<td>4w16t</td>
<td>pass</td>
<td rowspan=4>向量加</td>
</tr>
<tr>
<td>4w8t</td>
<td>pass</td>
</tr>
<tr>
<td>4w32t</td>
<td>pass</td>
</tr>
<tr>
<td>8w4t</td>
<td>pass</td>
</tr>
<tr>
<td rowspan=3>matadd</td>
<td>1w16t</td>
<td>pass</td>
<td rowspan=3>矩阵加</td>
</tr>
<tr>
<td>2w8t</td>
<td>pass</td>
</tr>
<tr>
<td>4w4t</td>
<td>pass</td>
</tr>
<tr>
<td rowspan=5>nn</td>
<td>2w16t</td>
<td>pass</td>
<td rowspan=5>最近邻内插法</td>
</tr>
<tr>
<td>4w8t</td>
<td>pass</td>
</tr>
<tr>
<td>4w16t</td>
<td>pass</td>
</tr>
<tr>
<td>8w4t</td>
<td>pass</td>
</tr>
<tr>
<td>8w8t</td>
<td>pass</td>
</tr>
<tr>
<td rowspan=4>gassian</td>
<td>1w16t</td>
<td>pass</td>
<td rowspan=4>高斯消元</td>
</tr>
<tr>
<td>2w8t</td>
<td>pass</td>
</tr>
<tr>
<td>4w4t</td>
<td>pass</td>
</tr>
<tr>
<td>4w8t</td>
<td>pass</td>
</tr>
<tr>
<td rowspan=4>bfs</td>
<td>2w16t</td>
<td>pass</td>
<td rowspan=4>宽度优先搜索算法</td>
</tr>
<tr>
<td>4w8t</td>
<td>pass</td>
</tr>
<tr>
<td>4w32t</td>
<td>pass</td>
</tr>
<tr>
<td>8w4t</td>
<td>pass</td>
</tr>
</table>

## Acknowledgement

We refer to some open-source design when developing Ventus GPGPU.

| Sub module                | Source                                                                                       | Detail                                                                             |
|---------------------------|----------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| CTA scheduler             | [MIAOW](https://github.com/VerticalResearchGroup/miaow)                                      | Our CTA scheduler module is based on MiaoW ultra-threads dispatcher                |
| L2Cache                   | [block-inclusivecache-sifive](https://github.com/sifive/block-inclusivecache-sifive)         | Our L2Cache design is inspired by Sifive's block-inclusivecache                    |
| FPU                       | [XiangShan](https://github.com/OpenXiangShan/XiangShan)                                      | We reused Array Multiplier in XiangShan. FPU design is also inspired by XiangShan  |
| SFU                       | [openhwgroup](https://github.com/pulp-platform/fpu_div_sqrt_mvp)                             | Our SFU module is based on pulp-platform                                           |
| Config, ...               | [rocket-chip](https://github.com/chipsalliance/rocket-chip)                                  | Some modules are sourced from RocketChip                                           |
