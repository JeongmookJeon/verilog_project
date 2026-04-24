`timescale 1ns / 1ps

module tb_watch;

    // Inputs
    reg clk;
    reg rst;
    reg change;
    reg sel_display;
    reg up_r;
    reg up_l;
    reg down_r;
    reg down_l;

    // Outputs
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    // DUT (Device Under Test) 연결
    watch_datapath dut (
        .clk(clk),
        .rst(rst),
        .change(change),
        .sel_display(sel_display),
        .up_r(up_r),
        .up_l(up_l),
        .down_r(down_r),
        .down_l(down_l),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    // [핵심] 시뮬레이션 속도 10만 배 가속
    // tick_gen_100hz 내부의 F_COUNT 파라미터를 강제로 10으로 줄임
    defparam dut.U_TICK.F_COUNT = 10;

    // 100MHz 클럭 생성
    always #5 clk = ~clk;

    initial begin
        // 0. 초기화
        clk = 0;
        rst = 1;
        change = 0;
        sel_display = 0;
        up_r = 0; up_l = 0;
        down_r = 0; down_l = 0;

        // 리셋 해제
        #20;
        rst = 0;

        // 1. 일반 시계 동작 확인 (Normal Run)
        $display("--- 1. Watch Running ---");
        // defparam 덕분에 msec가 아주 빨리 올라갑니다.
        // 약 2000ns 정도면 숫자가 바뀌는 걸 볼 수 있습니다.
        #5000; 

        // 2. 시간 설정 모드 진입 (Change Mode)
        $display("--- 2. Enter Change Mode ---");
        change = 1; 
        // change=1이 되면 시계 흐름은 멈춰야 합니다. (설계 의도상)
        #100; 

        // 3. [초/msec] 수정 테스트 (sel_display = 0)
        // 설계상 sel_display가 0이면 sec_counter, msec_counter가 선택됨
        $display("--- 3. Edit Seconds (sel_display=0) ---");
        sel_display = 0;

        // UP_R 버튼 누르기 (초 증가 예상)
        // 주의: 시뮬레이션에서 버튼은 '클럭 한 주기'만 딱 눌렀다 떼야 1만 올라갑니다.
        // 계속 누르고 있으면 엄청난 속도로 올라갑니다.
        up_r = 1; #10; up_r = 0; // 1초 증가
        #20;
        up_r = 1; #10; up_r = 0; // 1초 증가
        #20;
        
        // DOWN_L 버튼 누르기 (초 감소 예상 - sec_counter 연결 확인)
        down_l = 1; #10; down_l = 0; // 1초 감소
        #50;

        // 4. [분/시] 수정 테스트 (sel_display = 1)
        // 설계상 sel_display가 1이면 min_counter, hour_counter가 선택됨
        $display("--- 4. Edit Min/Hour (sel_display=1) ---");
        sel_display = 1;
        
        // UP_R 버튼 누르기 (분 증가 예상 - min_counter 연결 확인)
        up_r = 1; #10; up_r = 0; 
        #20;
        
        // UP_L 버튼 누르기 (시 증가 예상 - hour_counter 연결 확인)
        up_l = 1; #10; up_l = 0;
        #20;

        // 5. 설정 모드 종료 및 재가동
        $display("--- 5. Exit Change Mode & Resume ---");
        change = 0;
        #5000; // 변경된 시간에서 다시 시간이 흐르는지 확인

        $stop;
    end

endmodule