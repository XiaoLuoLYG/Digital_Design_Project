#include "Vahb_master.h"
#include <verilated_vcd_c.h>
#include <queue>
#include <iostream>

enum burst
{
    SINGLE = 0,
    INCR,
    WARP4,
    INCR4,
    WARP8,
    INCR8,
    WRAP16,
    INCR16
};

#define READ_TRANS 0
#define WRITE_TRANS 1

int main()
{
    Vahb_master *dut = new Vahb_master;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("ahb_master.vcd");

    vluint64_t time = 0;
    size_t posedge = 0;

    std::vector<int> user_fifo;
    int slave[100];
    int slave_addr;
    for (int i = 0; i < 100; i++)
        slave[i] = i;

    dut->HRESETN = 0;
    dut->HCLK = 0;
    dut->eval();
    dut->HCLK = 1;
    dut->eval();

    dut->HRESETN = 1;
    int i = 0;
    dut->HREADY = 0;

    while (time < 100)
    {
        dut->HCLK ^= 1;
        dut->eval();
        m_trace->dump(time);

        if (dut->HCLK == 1)
        {
            posedge++;

            if (dut->user_fifo_wen)
            {
                user_fifo.push_back(dut->user_fifo_data_o);
            }

            if (dut->user_fifo_ren)
            {
                i++;
                dut->user_fifo_data_i = user_fifo[i];
                dut->eval();
                m_trace->dump(time);
            }

            if (posedge == 3)
            {
                dut->user_req = 1;
                dut->user_addr = 16;
                dut->user_burst = WRAP16;
                dut->user_rw = READ_TRANS;
            }

            if (posedge == 4)
            {
                dut->user_req = 0;
            }

            if (posedge == 30)
            {
                dut->user_req = 1;
                dut->user_addr = 0x0;
                dut->user_burst = INCR16;
                dut->user_rw = WRITE_TRANS;
                dut->user_fifo_data_i = user_fifo[i];
            }

            if (posedge == 31)
            {
                dut->user_req = 0;
            }
        }

        // 下降沿从机响应
        if (dut->HCLK == 0)
        {
            if (posedge == 7)
                dut->HREADY = 1;

            if (posedge == 25)
                dut->HREADY = 0;

            if (posedge == 33)
                dut->HREADY = 1;

            // 从机响应写
            if (dut->HTRANS)
            {
                if (dut->HWRITE)
                {
                    slave[i] = dut->HWDATA;
                }

                // 从机响应读
                else
                {
                    dut->HRDATA = slave[dut->HADDR];
                }
            }
        }

        time++;
    }

    std::cout << "data retrived from AHB: ";

    for (auto var : user_fifo)
        std::cout << var << " ";

    std::cout << "\ndata read from slave: ";

    for (auto var : slave)
        std::cout << var << " ";

    std::cout << std::endl;

    m_trace->close();
}