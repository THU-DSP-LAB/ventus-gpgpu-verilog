#include "xil_types.h"
#include "xil_io.h"
#include "xparameters.h"
#include "xstatus.h"
#include "stdlib.h"
//DDR
#define DDR_BASE_ADDRESS    0x80000000
//GPGPU address
#define GPU_BASEADDR                0x20000000
#define GPU_HIGHADDR                0x3fffffff
/*************PARAM OFFSETS**********************/
#define GPU_VALID_OFFSET                     0x00        // host -> gpu
#define GPU_WG_ID_OFFSET                        0x04
#define GPU_NUM_WF_OFFSET               0x08
#define GPU_WF_SIZE_OFFSET              0x0c
#define GPU_START_PC_OFFSET                    0x10
#define GPU_VGPR_SIZE_T_OFFSET          0x14
#define GPU_SGPR_SIZE_T_OFFSET          0x18
#define GPU_LDS_SIZE_OFFSET                    0x1c
#define GPU_VGPR_SIZE_WF_OFFSET         0x20
#define GPU_SGPR_SIZE_WF_OFFSET         0x24
#define GPU_DATA_BASEADDR_OFFSET        0x28        // dcache
#define GPU_PC_BASEADDR_OFFSET          0x2c        // icache
#define HOST_REQ_CSR_KNL                0x30
#define HOST_REQ_KERNEL_SIZE_3d         0x34
#define GPU_WG_ID_DONE_OFFSET           0x38
#define GPU_WG_VALID_OFFSET             0x3c
/*************CONSTANTS**************************/
#define GPU_SEND_TIMEOUT                8


#define Gpu_ReadReg(BaseAddress, RegOffset)             \
        Xil_In32((BaseAddress) + (u32)(RegOffset))
#define Gpu_WriteReg(BaseAddress, RegOffset, Data)      \
        Xil_Out32((BaseAddress) + (u32)(RegOffset), (u32)(Data))

#define GPU_ADDR_WIDTH              32

typedef struct{
    u32* Instr;
    u32* Data;
    int ISize;              // word
    int DSize;              // word
}TaskMemory;

typedef struct{
    UINTPTR BaseAddr;       // GPU Base Address
    int Initialized;
    int AddrWidth;
}Gpu;

typedef struct{
    u32 WgId;
    u32 NumWf;
    u32 WfSize;
    u32 StartPC;
    u32 VgprSizeTotal;
    u32 SgprSizeTotal;
    u32 LdsSize;
    u32 VgprSizePerWf;
    u32 SgprSizePerWf;
    u32 metaDataBaseAddr;
    u32 Host_req_pds_baseaddr;
    TaskMemory Mem;
}TaskConfig;

u32 GpuInit(Gpu* GpuInstance, UINTPTR BaseAddr){
    GpuInstance->AddrWidth = 32;
    GpuInstance->BaseAddr = BaseAddr;
    GpuInstance->Initialized = 1;
    return XST_SUCCESS;
}

// init and load memory for task
// ISize DSize = IMem DMem size (in words)
u32 GpuTaskMemoryInit(TaskMemory* Mem, int ISize, int DSize){
    u32* Instr = (u32*)malloc(ISize * sizeof(u32));
    u32* Data = (u32*)malloc(DSize * sizeof(u32));
    if(Instr == NULL || Data == NULL){
        xil_printf("Failed to allocate memory.\r\n");
        return XST_FAILURE;
    }
    xil_printf("Instr: %08x[%d], Data: %08x[%d].\r\n", Instr, ISize, Data, DSize);
    Mem->Instr = Instr;
    Mem->Data = Data;
    Mem->ISize = ISize;
    Mem->DSize = DSize;
    return XST_SUCCESS;
}

u32 GpuSendTask(Gpu* GpuInstance, TaskConfig* TaskCfg){
//    int wait;

    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_WG_ID_OFFSET, TaskCfg->WgId);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_NUM_WF_OFFSET, TaskCfg->NumWf);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_WF_SIZE_OFFSET, TaskCfg->WfSize);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_START_PC_OFFSET, TaskCfg->StartPC);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_VGPR_SIZE_T_OFFSET, TaskCfg->VgprSizeTotal);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_SGPR_SIZE_T_OFFSET, TaskCfg->SgprSizeTotal);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_LDS_SIZE_OFFSET, TaskCfg->LdsSize);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_VGPR_SIZE_WF_OFFSET, TaskCfg->VgprSizePerWf);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_SGPR_SIZE_WF_OFFSET, TaskCfg->SgprSizePerWf);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_DATA_BASEADDR_OFFSET, (u32)0);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_PC_BASEADDR_OFFSET, TaskCfg->Host_req_pds_baseaddr);
    Gpu_WriteReg(GpuInstance->BaseAddr, HOST_REQ_CSR_KNL, TaskCfg->metaDataBaseAddr);
    Gpu_WriteReg(GpuInstance->BaseAddr, HOST_REQ_KERNEL_SIZE_3d, (u32)0);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_WG_ID_DONE_OFFSET, (u32)0);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_WG_VALID_OFFSET, (u32)0);
    Gpu_WriteReg(GpuInstance->BaseAddr, GPU_VALID_OFFSET, (u32)1);
    return XST_SUCCESS;
}
void init_mem(uint32_t* metadata, uint32_t* data, int metadata_size, int data_size) {

    uint64_t buf_num_soft = (metadata[27] << 32) | metadata[26];

    uint64_t buf_ba_w[16];
    uint64_t buf_size[16];
    uint64_t buf_size_tmp[16];
    uint64_t burst_len[16];
    uint64_t burst_len_div[16];
    uint64_t burst_len_mod[16];
    uint64_t burst_times[16];

    for (int i = 0; i < buf_num_soft; i++) {
        buf_ba_w[i] = (uint64_t)((metadata[i * 2 + 29] << 32) | metadata[i * 2 + 28]);
        buf_size[i] = (uint64_t)((metadata[i * 2 + 29 + buf_num_soft * 2] << 32) | metadata[i * 2 + 28 + buf_num_soft * 2]);
        buf_size_tmp[i] = (buf_size[i] % 4 == 0) ? buf_size[i] : (buf_size[i] / 4) * 4 + 4;
        burst_len[i] = buf_size_tmp[i] / 4;
        burst_len_div[i] = burst_len[i] / 16;
        burst_len_mod[i] = burst_len[i] % 16;
        burst_times[i] = (burst_len_mod[i] == 0) ? burst_len_div[i] : burst_len_div[i] + 1;
    }

    int m = 0;
    for (int j = 0; j < buf_num_soft; j++) {
        uint64_t addr = buf_ba_w[j];

        for (int k = 0; k < burst_times[j]; k++) {
            uint64_t burst_data = (burst_len_mod[j] == 0) ? 16 : ((k < burst_times[j] - 1) ? 16 : burst_len_mod[j]);
            for (int l = 0; l < burst_data; l++) {
                Xil_Out32(addr, data[m]);
                addr += 4;
                m++;
            }
            addr += 16 * 4 - burst_data * 4;
        }
    }
}

//result
void process_data(uint32_t *mem_tmp_1, uint32_t *sum_32_pass) {
        for (int j = 0; j < 32; j++) {
            if (mem_tmp_1[j] == 0x42000000) {
                sum_32_pass[j] = 0xF0;  // pass
            } else {
                sum_32_pass[j] = 0x01;  // fail
            }
        }
}
// clear the memory
void GpuDeleteTask(TaskConfig* TaskCfg){
    TaskCfg->Mem.Instr = 0;
    TaskCfg->Mem.Data = 0;
    free(TaskCfg->Mem.Instr);
    free(TaskCfg->Mem.Data);
    return;
}


