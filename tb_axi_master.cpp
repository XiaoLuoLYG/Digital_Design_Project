#include "Vaxi_master.h"
#include <verilated_vcd_c.h>
#include <queue>
#include <iostream>
#include "axi4_mem.hpp"
#include "axi4_slave.hpp"
#include <assert.h>
#include <vector>

enum burst
{
    FIEXED = 0,
    INCR,
    WRAP,
    RESERVED
};

#define READ_TRANS 0
#define WRITE_TRANS 1

int main()
{
    Vaxi_master *dut = new Vaxi_master;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("axi_master.vcd");

    axi4_mem<32, 64, 4> mem(64 * 200);
    axi4_ptr<32, 64, 4> mem_ptr;
    axi4_ref<32, 64, 4> *mem_ref;
    axi4<32, 64, 4> memsigs;
    axi4_ref<32, 64, 4> memsigs_ref(memsigs);

    uint64_t *slave_mem = (uint64_t *)mem.get_mem();

    // init axi slave mem
    for (int i = 0; i < 100; i++)
        slave_mem[i] = i;

    // connect axi interface to axi slave
    // write address
    mem_ptr.awaddr = &(dut->axi_aw_addr_o);
    mem_ptr.awburst = &(dut->axi_aw_burst_o);
    mem_ptr.awid = &(dut->axi_aw_id_o);
    mem_ptr.awlen = &(dut->axi_aw_len_o);
    mem_ptr.awready = &(dut->axi_aw_ready_i);
    mem_ptr.awsize = &(dut->axi_aw_size_o);
    mem_ptr.awvalid = &(dut->axi_aw_valid_o);
    // write data
    mem_ptr.wdata = &(dut->axi_w_data_o);
    mem_ptr.wlast = &(dut->axi_w_last_o);
    mem_ptr.wready = &(dut->axi_w_ready_i);
    mem_ptr.wstrb = &(dut->axi_w_strb_o);
    mem_ptr.wvalid = &(dut->axi_w_valid_o);
    // write response
    mem_ptr.bid = &(dut->axi_b_id_i);
    mem_ptr.bready = &(dut->axi_b_ready_o);
    mem_ptr.bresp = &(dut->axi_b_resp_i);
    mem_ptr.bvalid = &(dut->axi_b_valid_i);
    // read address
    mem_ptr.araddr = &(dut->axi_ar_addr_o);
    mem_ptr.arburst = &(dut->axi_ar_burst_o);
    mem_ptr.arid = &(dut->axi_ar_id_o);
    mem_ptr.arlen = &(dut->axi_ar_len_o);
    mem_ptr.arready = &(dut->axi_ar_ready_i);
    mem_ptr.arsize = &(dut->axi_ar_size_o);
    mem_ptr.arvalid = &(dut->axi_ar_valid_o);
    // read data
    mem_ptr.rdata = &(dut->axi_r_data_i);
    mem_ptr.rid = &(dut->axi_r_id_i);
    mem_ptr.rlast = &(dut->axi_r_last_i);
    mem_ptr.rready = &(dut->axi_r_ready_o);
    mem_ptr.rresp = &(dut->axi_r_resp_i);
    mem_ptr.rvalid = &(dut->axi_r_valid_i);
    assert(mem_ptr.check());

    mem_ref = new axi4_ref<32, 64, 4>(mem_ptr);
    std::vector<int> user_fifo;
    int posedge = 0;
    int time = 0;
    int i = 0;
    while (1)
    {
        if (dut->clock == 0)
        {
            memsigs.update_input(*mem_ref);
            dut->clock ^= 1;
            dut->eval();
            m_trace->dump(time);
            time++;

            if (dut->axi_r_valid_i)
            {
                user_fifo.push_back(dut->data_read_o);
            }

            if (dut->rfifo_ren)
            {
                i++;
                dut->rw_w_data_i = user_fifo[i];
            }
        }

        if (dut->clock == 1)
        {
            dut->clock ^= 1;
            dut->eval();
            m_trace->dump(time);
            time++;
            posedge++;
            mem.beat(memsigs_ref);
            memsigs.update_output(*mem_ref);
            m_trace->dump(time);

            if (posedge == 3)
            {
                dut->rw_valid_i = 1;
                dut->rw_addr_i = 8 * 0;
                dut->rw_len_i = 15;
                dut->rw_size_i = 1;
                dut->write_req = 0;
                dut->read_req = 1;
            }

            if (posedge == 5)
            {
                dut->rw_valid_i = 0;
                dut->read_req = 0;
                dut->write_req = 0;
            }

            if (posedge == 99)
                dut->rw_w_data_i = user_fifo[i];

            if (posedge == 100)
            {
                dut->rw_valid_i = 1;
                dut->rw_addr_i = 8 * 16;
                dut->rw_len_i = 15;
                dut->rw_size_i = 1;
                dut->write_req = 1;
                dut->read_req = 0;
            }

            if (posedge == 101)
                dut->rw_valid_i = 0;

            if (posedge == 300)
                break;
        }
    }

    std::cout << "data in user fifo: " << std::endl;
    for (auto var : user_fifo)
        std::cout << var << " ";

    std::cout << std::endl;

    std::cout << "data in axi_slave_mem: " << std::endl;
    for (int i = 0; i < 100; i++)
    {
        std::cout << slave_mem[i] << " ";
    }

    std::cout << std::endl;

    m_trace->close();
}