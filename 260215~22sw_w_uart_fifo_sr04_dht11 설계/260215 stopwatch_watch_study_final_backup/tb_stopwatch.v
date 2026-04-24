`timescale 1ns / 1ps

module tb_stopwatch ();
    reg  clk;
    reg  rst;
    reg  mode;
    reg  clear;
    reg  run_stop;
    
    // 출력 연결용 wire
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    // DUT (Device Under Test) 인스턴스
    stopwatch_datapath dut (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    // [핵심!] 시뮬레이션 속도 조절
    // 100_000_000/100 (100만) 번 세야 0.01초가 오르는 걸
    // 시뮬레이션에서는 10번만 세면 0.01초가 오른 것으로 '사기'를 칩니다.
    // 이렇게 해야 분/시간이 올라가는 걸 금방 볼 수 있습니다.
    defparam dut.U_TICK_GEN.F_COUNT = 10; 

    // 100MHz 클럭 생성 (주기 10ns)
    always #5 clk = ~clk;

    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        mode = 0;      // 0: Up count
        clear = 0;
        run_stop = 0;  // 일단 멈춤 상태

        // 리셋 해제
        #20;
        rst = 0;
        
        // 1. 카운트 시작 (Run)
        $display("--- Start Stopwatch (UP) ---");
        run_stop = 1;

        // 시간을 넉넉히 줍니다.
        // F_COUNT를 10으로 줄였으므로, 클럭 10번(100ns)마다 msec가 1씩 오릅니다.
        // sec가 오르려면: 100ns * 100 = 10,000ns
        // min이 오르려면: 10,000ns * 60 = 600,000ns
        
        // 약 2분(simulation time 기준) 정도가 흐르는 것을 지켜봄
        #1500000; 
        
        // 2. 일시 정지 (Stop)
        $display("--- Stop ---");
        run_stop = 0;
        #200;

        // 3. 다시 시작
        $display("--- Resume ---");
        run_stop = 1;
        #10000;

        // 4. 클리어 (Clear) 테스트
        $display("--- Clear ---");
        clear = 1;
        #20;
        clear = 0;
        #500;

        $stop;
    end

    // 시뮬레이션 로그 출력 (변화가 있을 때마다 보여줌)
    // 너무 자주 뜨면 주석 처리하세요.
    /*
    initial begin
        $monitor("Time: %t | M:%d S:%d MS:%d", $time, min, sec, msec);
    end
    */

endmodule