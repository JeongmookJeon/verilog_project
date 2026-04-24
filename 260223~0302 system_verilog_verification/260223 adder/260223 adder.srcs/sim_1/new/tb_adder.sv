`timescale 1ns / 1ps


interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] s;
    logic        c;
    logic        mode;

endinterface  //adder_interface




class transaction;
    rand bit [31:0] a;  //random 값이라고 알려줌
    rand bit [31:0] b;  //random 값이라고 알려줌 아직 생성 아님
    bit             mode;
endclass  //transcation

class generator;
    //variable declaration : data type transcation
    transaction tr;  // 랜덤 수 생성
    virtual adder_interface adder_interf_gen;
    function new(virtual adder_interface adder_interf_ext);  // 왼쪽은 내부, 오른쪽은 외부에서 가져와섭 붙일애
        adder_interf_gen = adder_interf_ext;
        tr = new();
    endfunction


    task run();
        tr.randomize(); // 랜덤 수 생성, 위에 rand 라고 써져있는 애들만
        tr.mode = 0;
        adder_interf_gen.a = tr.a;
        adder_interf_gen.b = tr.b;
        adder_interf_gen.mode = tr.mode;

        //drive : 시간을 보내는 것 task는 시간 관리가능하다. task가 시간 관리가 가능하다
        #10;


    endtask



endclass  //generator



module tb_adder_sv ();
    //logic [31:0] a, b, s;    adder_interf를 생성하고 나서 없애버린다.
    //logic c, mode;

    adder_interface adder_interf ();  // interface 실체화
    generator gen;

    adder dut (
        .a(adder_interf.a),
        .b(adder_interf.b),
        .mode(adder_interf.mode),
        .s(adder_interf.s),
        .c(adder_interf.c)
    );
    initial begin
        //class generator를 생성.
        //generator class의 function new가 실행됨.
        gen = new(adder_interf);
        gen.run();
        $stop;
    end


endmodule
