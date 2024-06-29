-assert svaext
+v2k
-2012
+libext+.v+.V+.vlib+.vc
-sverilog +systemverilog+.sv +systemverilogext+.v
-debug_acc+dmptf+all -debug_region+cell+encrypt
-debug_access+all
+bus_conflict_off
+notimingcheck
+nospecify

// t28 mem enable
//+define+T28_MEM

//===================
//  Top
//===================
-top test_gpu_axi_top

//===================
//  Testbench
//===================
-f ../common/file_list.f

//===================
//  Include
//===================
+incdir+../../../src/define/

//===================
//  RTL
//===================
-f ../../../src/gpgpu_top/model_list 

//===================
//  t28 Mem
//===================
//-f ../../../t28_mem/model_list
