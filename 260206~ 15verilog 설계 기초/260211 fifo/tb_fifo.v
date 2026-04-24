`timescale 1ns / 1ps

module tb_fifo ();

    reg clk, rst, push, pop;
    reg  [7:0] push_data;
    wire [7:0] pop_data;
    wire full, empty;


    reg rand_pop, rand_push;
    reg [7:0] rand_data;
    reg [7:0] compare_data[0:3];
    reg [1:0] push_cnt, pop_cnt;


    integer i, pass_cnt, fail_cnt;

    fifo dut (
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        .push_data(push_data),
        .pop_data(pop_data),
        .full(full),
        .empty(empty)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        push_data = 0;
        push = 0;
        pop = 0;

        i = 0;
        pass_cnt = 0;
        fail_cnt = 0;
        rand_push = 0;
        rand_pop = 0;
        rand_data = 0;
        push_data = 0;
        pop_cnt = 0;
        push_cnt = 0;
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        //push 5 time
        for (i = 0; i < 5; i = i + 1) begin
            push = 1;
            push_data = 8'h61 + i;  // 'a'
            @(negedge clk);
        end
        // 1. abcde depth=4인 fifo인데 5번 push  5번쨰 push 무시 (full이라서)
        push = 0;

        //pop 5 time
        for (i = 0; i < 5; i = i + 1) begin
            pop = 1;
            @(negedge clk);
        end
        pop = 0;
        // 2. 5번쨰 pop 무시
        //push
        push = 1; 
        push_data = 8'haa; // 3. aa하나 저장/ 초기화 이후 재동작 확인용
        @(negedge clk);
        push = 0;
        @(negedge clk); // 4.pushpop 동시 16번 wptr,rptr올라가는거 확인
        for (i = 0; i < 16; i = i + 1) begin
            push = 1;
            pop = 1;
            push_data = i;
            @(negedge clk);
        end

        push = 0;
        pop  = 1; // 5. pop만 연속 수행(남으네 데이터 비움)
        @(negedge clk);
        @(negedge clk);
        pop = 0;
        @(negedge clk);

        for (i = 0; i < 256; i = i + 1) begin // 랜덤 256회
            //random test
            rand_push = $random % 2;
            rand_pop = $random % 2;
            rand_data = $random % 256;
            push = rand_push;
            pop = rand_pop;
            push_data = rand_data;

            #4;

            if (!full && push) begin // comparedata
                compare_data[push_cnt] = rand_data;
                push_cnt = push_cnt + 1;
            end
            if (!empty && pop == 1) begin
                if (pop_data == compare_data[pop_cnt]) begin
                    $display("%t : pass, pop_data = %h, compare_data = %h",
                             $time, pop_data, compare_data[pop_cnt]);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("%t : fail, pop_data = %h, compare_data = %h",
                             $time, pop_data, compare_data[pop_cnt]);
                    fail_cnt = fail_cnt + 1;
                end
                pop_cnt = pop_cnt + 1;
            end

            @(negedge clk);
        end
        $display("%t : pass_count = %d, fail_count = %d", $time, pass_cnt,
                 fail_cnt);

        //@(posedge clk);




        repeat (5) @(negedge clk);
        $stop;
    end



endmodule
