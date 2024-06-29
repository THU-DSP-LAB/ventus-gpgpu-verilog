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

+define+FSDB

-top test_gpu_top

//===================
//  Testbench
//===================


//===================
//  Include
//===================
+incdir+../../../src/define/

//===================
//  RTL
//===================
-f ../testbench/file_list.f
