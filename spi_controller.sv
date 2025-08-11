//`include "spi_master.sv" (Para o Icarus Verilog)

module spi_controller (
    input clk, n_rst, ctrl_en, MISO, // Clock, reset, input de habilitação e pino MISO
    input [7:0] word_0_in, // Palavras a serem transmitidas (8 bits cada) 
    input [7:0] word_1_in,
    input [7:0] word_2_in,
    input [7:0] word_3_in,
    output SCK, SS, MOSI, // Sinais de saída do SPI
    output [7:0] word_0_out, // Palavras recebidas do dispositivo escravo
    output [7:0] word_1_out,
    output [7:0] word_2_out,
    output [7:0] word_3_out
);

    // Declaração dos estados simbólicos
    localparam reg [2:0]
    idle        = 3'b000,
    load_buffer = 3'b001, // Estava tendo um problema de timing, colocando essa "fase" da máquina, consigo acertar o timing do módulo SPI
    first_data  = 3'b010, 
    second_data = 3'b011,
    third_data  = 3'b100,
    fourth_data = 3'b101;

    // Declaração dos registradores da máquina de estados
    reg [2:0] state, next_state;
    reg next_spi_en;
    reg [7:0] word_in_reg;
    reg [7:0] next_word_in;
    reg [7:0] word_0_out_reg, word_1_out_reg, word_2_out_reg, word_3_out_reg;

    // Sinais para controle do módulo spi
    reg spi_en;
    reg [7:0] data_in;
    reg ready_out, valid_out;
    reg [7:0] data_out;

    // Instância do módulo spi_master
    spi_master #(.DATA_BITS(8), .CPOL(0), .CPHA(1), .BRDV(2), .LSBF(0)) spi_unit (
        .clk(clk),
        .n_rst(n_rst),
        .spi_en(spi_en),
        .tied_SS(1'b1),
        .MISO(MISO),
        .data_in(data_in),
        .data_words(6'b000100),
        .SCK(SCK),
        .SS(SS),
        .MOSI(MOSI),
        .ready_out(ready_out),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    // Bloco sequencial: atualiza estado e registradores a cada borda de clock
    always_ff @(posedge clk) begin : sequential_logic
        if(~n_rst) begin
            state <= idle;
            spi_en <= 1'b0;
            word_in_reg <= word_0_in;
            word_0_out_reg <= 8'b00000000;
            word_1_out_reg <= 8'b00000000;
            word_2_out_reg <= 8'b00000000;
            word_3_out_reg <= 8'b00000000;
        end
        else begin
            state <= next_state;
            spi_en <= next_spi_en;
            word_in_reg <= next_word_in;
        end
    end

    // Bloco combinacional
    always_comb begin : combinacional_logic
        next_state = state;
        next_spi_en = spi_en;
        next_word_in = word_in_reg;
        case (state)
            idle:  // Aguarda habilitação (ctrl_en) e o módulo SPI master estar pronto (ready_out)
                if (ctrl_en)
                    if (ready_out) begin
                        next_spi_en = 1'b1;       // Habilita o SPI
                        next_word_in = word_0_in; // Carrega primeiro byte a enviar
                        next_state = load_buffer; // Avança para carregar buffer
                    end
            load_buffer: begin // Prepara o segundo byte enquanto o primeiro já está no SPI
                next_word_in = word_1_in;
                next_state = first_data; 
            end
            first_data: begin
                if (valid_out) begin
                    next_word_in = word_2_in;  // Prepara o próximo byte a enviar
                    word_0_out_reg = data_out; // Guarda o byte recebido do 1º envio do escravo
                    next_state = second_data;
                end
            end
            second_data: begin
                if (valid_out) begin
                    next_word_in = word_3_in;  // Prepara o próximo byte a enviar
                    word_1_out_reg = data_out; // Guarda o byte recebido do 2º envio do escravo
                    next_state = third_data;
                end            
            end
            third_data: begin
                if (valid_out) begin
                    next_spi_en = 1'b0;        // Desabilita o SPI
                    next_word_in = word_0_in;
                    word_2_out_reg = data_out; // Guarda o byte recebido do 3º envio do escravo
                    next_state = fourth_data;
                end
            end
            fourth_data: begin
                if (valid_out) begin
                    word_3_out_reg = data_out; // Guarda o byte recebido do 4º envio do escravo
                    next_state = idle;
                end
            end
            default:
                next_state = idle;
        endcase
    end

    // Conexões das saídas
    assign data_in = word_in_reg;
    assign word_0_out = word_0_out_reg;
    assign word_1_out = word_1_out_reg;
    assign word_2_out = word_2_out_reg;
    assign word_3_out = word_3_out_reg;

endmodule