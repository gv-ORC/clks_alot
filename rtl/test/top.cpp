#include <bits/chrono.h>
#include <limits>
#include <Chatty.h>
#include <Checkpoint.hpp>
#include <Run.hpp>
#include <WrappedDevice.hpp>
#include <sstream>
#include <stdlib.h>
#include <string>
#include <verilated.h>
#include <verilated_fst_c.h>
#include <Vtop_tb.h>

class Top : public WrappedDevice<Vtop_tb>
{
public:
    Top(const int argc, const char **argv)
        : Top(argc, argv, 0) {}

    Top(const int argc, const char **argv, const int seed)
        : WrappedDevice<Vtop_tb>(argc, argv, seed)
    {
        device_->clk = 1;
        device_->clk_en = 0;
        device_->sync_rst = 0;
    }

    void full_reset()
    {
        flip_clock();
        eval();

        flip_reset();

        for (size_t i = 0; i < 2; i++) {
            flip_clock();
            eval();
        }

        flip_reset();

        for (size_t i = 0; i < 6; i++) {
            flip_clock();
            eval();
        }

        flip_clock_enable();
    }

protected:
    void flip_clock() {
        device_->clk ^= 1;
    }

    void flip_clock_enable() {
        device_->clk_en ^= 1;
    }

    void flip_reset() {
        device_->sync_rst ^= 1;
    }

    int get_status_code() {
        return device_->ERROR;
    }
};

int main(int argc, const char** argv, char** env)
{
    chat(0, "hello"); 

    const size_t num_retries = 1;

    const size_t trace_duration = 1000; // In cycles - only captures after the initial simulation
    const size_t simulation_duration = 1; // In cycles

    auto successes = std::vector<size_t>(num_retries);

    for (size_t i = 0; i < num_retries; i++) {
        printf("Running attempt %lu\n", i);

        std::stringstream trace_to;
        trace_to << "sim_" << i << ".fst";

        tracing_t tracing(trace_to.str().c_str());

        Top wrapped(argc, argv, i);
        wrapped.full_reset();

        int code = run(
            (simulation_duration*2),
            &wrapped);

        auto exited_at = wrapped.get_time();
        run_tracing((trace_duration*2),
                    &tracing,
                    &wrapped);
        chat(exited_at, "Exited with code '%d' :D Here's your trace!", code);
    }

    return 0;
}