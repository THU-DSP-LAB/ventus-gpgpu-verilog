#include "naive_driver.h"
#include "stdio.h"
#include "xgpio.h"
#include "xparameters.h"
#include "microblaze_sleep.h"
#include "metadata.h"
#include "data.h"
//DDR address
#define GPIO_DEVICE_ID     XPAR_GPIO_0_DEVICE_ID  // DEVICE ID
#define GPIO_LED_PIN       1  //  LED PIN

int main(){
                u32 *LED_BASE_ADDRESS=0x40000000;
                u32 *LED_DIR_ADDRESS=0x40000004;
                *(u32 *)LED_DIR_ADDRESS=0X00;
                *(u32 *)LED_BASE_ADDRESS=0X00;


    Gpu TestGpu;
    // TODO: Set GPU_BASEADDR in .h file
    GpuInit(&TestGpu, GPU_BASEADDR);

    TaskMemory TestMem;
    GpuTaskMemoryInit(&TestMem, 128, 1024);
    //host to cta
//    uint64_t noused;
//    uint64_t kernel_id;
//    uint64_t kernal_size0;
//    uint64_t kernal_size1;
//    uint64_t kernal_size2;
    uint64_t wf_size;
    uint64_t wg_size;
    uint64_t metaDataBaseAddr;
//    uint64_t ldsSize;
    uint64_t pdsSize;
    uint64_t sgprUsage;
    uint64_t vgprUsage;
    uint64_t pdsBaseAddr;
//      uint64_t num_buffer;
    uint32_t pds_size;
    //assign metadata
    void assign_metadata_values(uint32_t* Instr) {
//        noused = ((uint64_t)Instr[1] << 32) | (uint64_t)Instr[0];
//        kernel_id = ((uint64_t)Instr[3] << 32) | (uint64_t)Instr[2];
//        kernal_size0 = ((uint64_t)Instr[5] << 32) | (uint64_t)Instr[4];
//        kernal_size1 = ((uint64_t)Instr[7] << 32) | (uint64_t)Instr[6];
//        kernal_size2 = ((uint64_t)Instr[9] << 32) | (uint64_t)Instr[8];
        wf_size = ((uint64_t)Instr[11] << 32) | (uint64_t)Instr[10];
        wg_size = ((uint64_t)Instr[13] << 32) | (uint64_t)Instr[12];
        metaDataBaseAddr = ((uint64_t)Instr[15] << 32) | (uint64_t)Instr[14];
//        ldsSize = ((uint64_t)Instr[17] << 32) | (uint64_t)Instr[16];
        pdsSize = ((uint64_t)Instr[19] << 32) | (uint64_t)Instr[18];
        sgprUsage = ((uint64_t)Instr[21] << 32) | (uint64_t)Instr[20];
        vgprUsage = ((uint64_t)Instr[23] << 32) | (uint64_t)Instr[22];
        pdsBaseAddr = ((uint64_t)Instr[25] << 32) | (uint64_t)Instr[24];
//        num_buffer = ((uint64_t)Instr[27] << 32) | (uint64_t)Instr[26];
        pds_size = 0;
    }
    assign_metadata_values(metadata);
    TaskConfig TestTask = {
            0,   // WgId
        (uint32_t)wg_size,   // NumWf
        (uint32_t)wf_size,   // WfSize
                0x80000000,   // StartPC
                (uint32_t)wg_size*(uint32_t)vgprUsage,   // VgprSizeTotal
                (uint32_t)wg_size*(uint32_t)sgprUsage,   // SgprSizeTotal
        128,   // LdsSize
                (uint32_t)vgprUsage,   // VgprSizePerWf
                (uint32_t)sgprUsage,   // SgprSizePerWf
                (uint32_t)metaDataBaseAddr,//metaDataBaseAddr
                (uint32_t)pdsBaseAddr+pds_size*(uint32_t)wf_size*(uint32_t)wg_size,//Host_req_pds_baseaddr
        TestMem // Mem
    };
    // Data to  DDR
   init_mem(metadata,data,128,1024);
    int retry = 5;
    u32 WarpGroupID;
    while(retry){
        if(GpuSendTask(&TestGpu, &TestTask) == XST_SUCCESS){
                //XGpio_DiscreteWrite(&GpioInstance, 1, 0xF0);//gpio led
            break;
        }
        retry--;
    }
    if(!retry){
        xil_printf("All tries failed. Stopped.\r\n");
        return XST_FAILURE;
    }
    *(u32 *)LED_BASE_ADDRESS=0XFF;

    // TODO: Result Checking
    uint32_t mem_tmp_1[32] = {0};
    uint32_t sum_32_pass[32] = {0};
    for (int i = 0; i < 32; i++) {
            mem_tmp_1[i] = Xil_In32(0x90002000);
    }

    process_data(mem_tmp_1, sum_32_pass);
    for (int j = 0; j < 32; j++) {
            *(u32 *)LED_BASE_ADDRESS=sum_32_pass[j];
            // delay 1s
            sleep_MB(1);
        }
    // End of Checking
    GpuDeleteTask(&TestTask);
    return XST_SUCCESS;
}
