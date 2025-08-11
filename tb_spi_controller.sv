`timescale 1ns/1ns
//`include "spi_controller.sv" (Para o Icarus Verilog)

module tb_spi_controller;

    // Período do clock
    localparam T = 2;

    // Sinais do módulo controlador
    // Entradas
    reg clk, n_rst, ctrl_en, MISO;
    reg [7:0] word_0_in;
    reg [7:0] word_1_in;
    reg [7:0] word_2_in;
    reg [7:0] word_3_in;
    // Saídas
    reg SCK, SS, MOSI;
    reg [7:0] word_0_out;
    reg [7:0] word_1_out;
    reg [7:0] word_2_out;
    reg [7:0] word_3_out;

    // Instância do módulo controlador
    spi_controller uut (
        .clk(clk),
        .n_rst(n_rst),
        .ctrl_en(ctrl_en),
        .MISO(MISO),
        .word_0_in(word_0_in),
        .word_1_in(word_1_in),
        .word_2_in(word_2_in),
        .word_3_in(word_3_in),
        .SCK(SCK),
        .SS(SS),
        .MOSI(MOSI),
        .word_0_out(word_0_out),
        .word_1_out(word_1_out),
        .word_2_out(word_2_out),
        .word_3_out(word_3_out)
    );

    // Definições dos arquivos para visualizar as formas de onda
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_spi_controller);
    end

    // Definição do clock
    always begin
        clk = '0;
        forever #(T/2) clk = ~clk;
    end

    // Definição do reset
    initial begin
        n_rst = '1;
        #(T*3) n_rst = '0;
        #(T) n_rst = '1;
    end

    // Simulação da transmissão de dados
    initial begin

        // O testbench inicia com as entradas do módulo zeradas
        ctrl_en = 1'b0;
        MISO = 1'b0;
        word_0_in = 8'b11111010; // Transmite o byte 11111010 (8'hFA) para o escravo (MOSI)
        word_1_in = 8'b11111011; // Transmite o byte 11111011 (8'hFB) para o escravo (MOSI)
        word_2_in = 8'b11111100; // Transmite o byte 11111100 (8'hFC) para o escravo (MOSI)
        word_3_in = 8'b11111110; // Transmite o byte 11111110 (8'hFE) para o escravo (MOSI)
        
        // Começa a primeira transmissão de dados após 6 períodos de clock (12 ns)
        #(T*6);
        ctrl_en = 1'b1; // Habilita o controlador por 1 ciclo de clock
        #(T);
        ctrl_en = 1'b0;
        #(T);

        // Transmite o byte 11111110 (8'hFE) para o master (MISO)
        #(T/2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b0;
        #(T*2);

        // Transmite o byte 11111100 (8'hFC) para o master (MISO)
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b0;
        #(T*2) MISO = 1'b0;
        #(T*2);

        // Transmite o byte 11111011 (8'hFB) para o master (MISO)
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b0;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2);

        // Transmite o byte 11111010 (8'hFA) para o master (MISO)
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b0;
        #(T*2) MISO = 1'b1;
        #(T*2) MISO = 1'b0;
        #(T*2);
        
        // Espera um pouco para finalizar a simulação
        #(T*20) $finish;
    end

endmodule

// Comandos para o Icarus Verilog
// iverilog -g2012 -o vars_spi_controller tb_spi_controller.sv
// vvp vars_spi_controller
// gtkwave