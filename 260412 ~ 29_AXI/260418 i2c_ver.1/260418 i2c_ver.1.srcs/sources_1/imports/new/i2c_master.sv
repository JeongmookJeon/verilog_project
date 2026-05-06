`timescale 1ns / 1ps

module i2c_master_top (
    input logic clk,
    input logic reset,  // 보드 초기화 버튼
    input logic btn_send,  // 전송 시작 버튼
    input  logic [7:0] sw,        // 8개의 스위치 입력 (보낼 데이터 및 R/W 모드)
    output logic scl,  // I2C SCL 출력 (외부 핀으로 연결)
    inout logic sda,  // I2C SDA 입출력 (외부 핀으로 연결)

    // FND 출력을 위한 외부 핀 선언
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);

    localparam SLAVE_ADDR = 7'h5A;  // 타겟 슬레이브 주소

    logic w_btn_send_tick;

    // 디바운싱: 버튼을 누르는 순간 1클럭만 High(1)가 나오는 Trigger 신호
    btn_debounce U_BTN_DEBOUNCE (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_send),
        .o_btn(w_btn_send_tick)
    );

    logic cmd_start, cmd_write, cmd_read, cmd_stop;
    logic [7:0] m_tx_data;
    logic       ack_in;
    logic [7:0] rx_data;  // I2C 모듈에서 나오는 수신 데이터
    logic       m_done;
    logic       ack_out;
    logic       m_busy;

    // ★ 누락되었던 수신 데이터 유지용 레지스터 선언
    logic [7:0] rx_data_reg;

    I2C_MASTER U_I2C_MASTER (
        .clk      (clk),
        .reset    (reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (m_tx_data),
        .ack_in   (ack_in),
        .rx_data  (rx_data),    // 모듈 출력 연결
        .done     (m_done),
        .ack_out  (ack_out),
        .busy     (m_busy),
        .scl      (scl),
        .sda      (sda)
    );

    typedef enum logic [2:0] {
        S_IDLE,
        S_START,
        S_ADDR,
        S_DATA,
        S_STOP
    } state_e;

    state_e state, next_state;

    // ★ FSM 상태 업데이트 및 수신 데이터 캡처 (Multiple Driver 충돌 방지를 위해 통합)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            rx_data_reg <= 8'h00;  // 리셋 시 FND 표시값 0으로 초기화
        end else begin
            state <= next_state;

            // 상태가 S_DATA이고, Read 모드(sw[0]==1)이며, I2C 모듈이 처리를 완료(m_done)했을 때!
            if (state == S_DATA && sw[0] == 1'b1 && m_done) begin
                rx_data_reg <= rx_data; // 들어온 데이터를 레지스터에 찰칵! 저장
            end
        end
    end

    // FND 컨트롤러 연결
    fnd_controller u_fnd_controller (
        .clk        (clk),
        .reset      (reset),
        // 캡처된 레지스터 값을 FND에 연결 (상위 6비트는 0으로 채움)
        .fnd_in_data({6'd0, rx_data_reg}),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

    // FSM 다음 상태 및 제어 신호 출력
    always_comb begin
        // 기본값 세팅
        next_state = state;
        cmd_start  = 0;
        cmd_write  = 0;
        cmd_read   = 0;
        cmd_stop   = 0;
        ack_in     = 0;
        m_tx_data  = 8'h00;

        case (state)
            S_IDLE: begin
                if (w_btn_send_tick) next_state = S_START;
            end

            S_START: begin
                // ★ 수정: 처리가 완료되지 않았을 때만 명령 유지 (중복 트리거 방지)
                if (!m_done) cmd_start = 1;
                if (m_done) next_state = S_ADDR;
            end

            S_ADDR: begin
                if (!m_done) cmd_write = 1;
                m_tx_data = {SLAVE_ADDR, sw[0]};

                if (m_done) begin
                    // ★ 수정: 슬레이브가 응답하지 않으면(NACK) 즉시 통신 중단(S_STOP)
                    if (ack_out == 1'b1) next_state = S_STOP;
                    else next_state = S_DATA;
                end
            end

            S_DATA: begin
                if (!m_done) begin
                    if (sw[0] == 1'b0) begin
                        cmd_write = 1;
                        m_tx_data = sw;
                    end else begin
                        cmd_read = 1;
                        ack_in   = 1'b1;
                    end
                end

                if (m_done) next_state = S_STOP;
            end

            S_STOP: begin
                if (!m_done) cmd_stop = 1;
                if (m_done) next_state = S_IDLE;
            end
        endcase
    end
endmodule

module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);

    //clock divider for debounce shift register
    //100Mhz -> 100Khz  100,000을 나누먄 됨.
    //counter = 100를 100K = 1000
    // 100mhz의 클럭을 1khz마다 한번씩 신호를 발생시키는 분주기 로직 즉 1khz 틱생성 
    parameter CLK_DIV = 100_000;  //10; //100_000;
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg CLK_100khz_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            CLK_100khz_reg <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                CLK_100khz_reg <= 1'b1;
            end else begin
                CLK_100khz_reg <= 1'b0;
            end
        end

    end

    wire o_btn_down_u, o_btn_down_d;  // 디바운싱된 신호를 담을 전선

    //series 8 tap F/F   8개 짜리 플립플롭 사용(검증하기 위함)

    reg [7:0] q_reg, q_next;
    wire debounce;
    //SL
    always @(posedge CLK_100khz_reg, posedge reset) begin
        if (reset) begin
            q_reg <= 0;  // 초기값 생성
        end else begin
            //register 생성
            q_reg <= q_next;
            //debounce_reg <= {i_btn, debounce_reg[7:1]};
        end
    end
    // next CL
    always @(*) begin
        q_next = {i_btn, q_reg[7:1]};  // shift register 동작.

    end

    //debounce 신호, 8bit input, And gate활용
    assign debounce = &q_reg; // 비트별로 전부 and한다라는 뜻. q_reg가 8비트이기 대문에
    reg edge_reg;
    //edge detection
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = debounce & (~edge_reg);  // 반전된 reg와 and함.

endmodule


module I2C_MASTER (
    input  logic       clk,
    input  logic       reset,
    //command port
    input  logic       cmd_write,
    input  logic       cmd_start,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    input  logic       ack_in,
    //internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    //external i2c port
    output logic       scl,
    inout  logic       sda         //in out port
);
    logic sda_o, sda_i;


    //tri state buffer
    assign sda_i = sda; //sda_i는 내부 입력 port, sda는 외부에서 오는 신호
    assign sda = sda_o ? 1'bz : 1'b0;  //tri state buffer

    i2c_master U_i2c_master (
        .clk(clk),
        .reset(reset),
        .cmd_write(cmd_write),
        .cmd_start(cmd_start),
        .cmd_read(cmd_read),
        .cmd_stop(cmd_stop),
        .tx_data(tx_data),
        .ack_in(ack_in),
        .rx_data(rx_data),
        .done(done),
        .ack_out(ack_out),
        .busy(busy),
        .scl(scl),
        .sda_o(sda_o),
        .sda_i(sda_i)
    );

endmodule

module i2c_master (
    input  logic       clk,
    input  logic       reset,
    //command port
    input  logic       cmd_write,
    input  logic       cmd_start,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    input  logic       ack_in,
    //internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    //external i2c port
    output logic       scl,
    output logic       sda_o,
    input  logic       sda_i
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;

    i2c_state_e       state;
    logic       [7:0] div_cnt;
    logic             qtr_tick;
    logic scl_r, sda_r;
    logic [1:0] step;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;
    logic       is_read;
    logic       ack_in_r;


    assign scl   = scl_r;
    assign sda_o = sda_r;
    // IDEL이 아니면 '1' (조건연산자)
    assign busy  = (state != IDLE);

    // 100Khz tick = qtr_tick
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_cnt  <= 0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == 250 - 1) begin  // scl(clk) : 100Khz
                div_cnt  <= 0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 1;
                qtr_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            // I2C에 스펙에 따르면 처음에 1로 나가야함. 
            scl_r        <= 1'b1;
            // I2C에 스펙에 따르면 처음에 1로 나가야함. 
            sda_r        <= 1'b1;
            // busy         <= 1'b0;
            step         <= 0;
            done         <= 1'b0;
            tx_shift_reg <= 8'b0;
            rx_shift_reg <= 8'b0;
            is_read      <= 1'b0;
            bit_cnt      <= 0;
            ack_in_r     <= 1'b1;  //초기 nack상태
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    scl_r <= 1'b1;
                    sda_r <= 1'b1;
                    // busy  <= 1'b0;
                    if (cmd_start) begin
                        state <= START;
                        step  <= 0;
                        //busy  <= 1'b1;
                    end
                end
                // wave form 참고 // qtr_tick 당 400Khz
                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                step  <= 2'd0;
                                done  <= 1'b1;  // tb의 wait(done)이야!!!
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                //[ADDRESS frame] rw포함해서 8bit를 전부 보낸다.
                WAIT_CMD: begin
                    step <= 0;
                    if (cmd_write) begin
                        //write 신호일 때
                        tx_shift_reg <= tx_data;  //저장해(address +r/w)
                        bit_cnt <= 0;
                        is_read <= 1'b0;  //read신호가 아니야 flag 역할
                        state <= DATA;
                    end else if (cmd_read) begin
                        //read 신호일 때
                        rx_shift_reg <= 0;
                        bit_cnt <= 0;
                        is_read <= 1'b1;  //read신호야 flag 역할
                        ack_in_r <= ack_in; // slave의 data를 계속 받을건지?
                        state <= DATA;
                    end else if (cmd_stop) begin
                        state <= STOP;
                    end else if (cmd_start) begin
                        state <= START;
                    end

                end
                //[data frame]data 송수신 구간.(보내거나(write), sampling 하거나(read))
                DATA: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                //read가 아닐때(write라는 뜻!!!!) MSB를 내보내겠다. 
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (is_read) begin
                                    //수신 받음.(sampling)
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                if (!is_read) begin //read가 아니면 shift시키겠다.
                                    //shift, 다음 bit준비. 
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                                step <= 2'd0;
                                if (bit_cnt == 7) begin
                                    state <= DATA_ACK;
                                end else begin
                                    bit_cnt = bit_cnt + 1;
                                end
                            end
                        endcase
                    end
                end
                //ack 보내고(다 받음 or 다 전송)
                DATA_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r = 1'b0;
                                if (is_read) begin
                                    //들어온 ack신호를 reg로 해서 latching
                                    //바로 나갈 수 있기 떄문에 잠시 저장
                                    sda_r <= ack_in_r;
                                end else begin
                                    sda_r <= 1'b1;  // sda input 설정, sda high impedence 설정
                                end
                                step <= 2'd1;
                            end
                            2'd1: begin
                                scl_r = 1'b1;
                                step <= 2'd2;
                            end
                            2'd2: begin
                                scl_r = 1'b1;
                                //ack 수신
                                if (!is_read) begin
                                    //마스터가 host(CPU)에  보내는 신호
                                    ack_out <= sda_i;
                                end
                                if (is_read) begin
                                    rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                done  <= 1'b1;  //tb의 두번째 wait(done)!!!!
                                step  <= 2'd0;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                sda_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
                            end
                        endcase
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end


endmodule
