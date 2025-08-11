module spi_master #(parameter DATA_BITS=8, CPOL=0, CPHA=1, BRDV=2, LSBF=0)(
    input clk, n_rst, spi_en, tied_SS, MISO,
    input [DATA_BITS-1:0] data_in,
    input [5:0] data_words, // limite máximo de 32 palavras sequenciais
    output SCK, SS, MOSI, ready_out, valid_out,
    output [DATA_BITS-1:0] data_out
);

// Declaração dos estados simbólicos
localparam reg [1:0]
idle = 2'b00,
data = 2'b01,
trail = 2'b10;

// Declaração dos registradores
reg [1:0] state, next_state;
/* $clog2(.) = arredondamento superior da função logarítmica de (.) na base 2, usado
para determinar a quantidade mínima de bits necessária para expressar o valor de (.) */
reg [$clog2(BRDV)-1:0] clk_cnt, next_clk;
reg [$clog2(DATA_BITS)-1:0] bit_cnt, next_bit;
reg [4:0] word_cnt, next_word;
reg SCK_reg, next_SCK;
reg SS_reg, next_SS;
reg [DATA_BITS-1:0] spi_data_reg, next_spi_data;
reg MISO_reg, next_MISO;
reg ready_reg, next_ready;
reg valid_reg, next_valid;

// Registradores da máquina de estados para o módulo SPI master
always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        state <= idle;
        clk_cnt <= 0;
        bit_cnt <= 0;
        word_cnt <= 0;
        SCK_reg <= CPOL;
        SS_reg <= 1'b1;
        spi_data_reg <= '0;
        ready_reg <= 1'b0;
        valid_reg <= 1'b0;
        MISO_reg <= 1'b0;
    end
    else begin
        state <= next_state;
        clk_cnt <= next_clk;
        bit_cnt <= next_bit;
        word_cnt <= next_word;
        SCK_reg <= next_SCK;
        spi_data_reg <= next_spi_data;
        SS_reg <= next_SS;
        ready_reg <= next_ready;
        valid_reg <= next_valid;
        MISO_reg <= next_MISO;
    end
end

// Lógica combinacional para a transição entre estados
always_comb begin    
    next_state = state;
    next_clk = clk_cnt;
    next_bit = bit_cnt;
    next_word = word_cnt;
    case (state)
    idle: begin
        if (word_cnt > 0) begin
            if (clk_cnt == (BRDV/2)-1) begin
                next_clk = 0;
                next_bit = 0;
                next_state = data;
            end            
            else
            next_clk = clk_cnt + 1;
        end
        else if (spi_en) begin
            next_clk = 0;
            next_bit = 0;
            next_word = 0;
            next_state = data;
        end
    end
    data: begin
        if (clk_cnt == BRDV-1) begin
            next_clk = 0;
            if (bit_cnt == DATA_BITS-1) begin
                next_state = trail;
                if (word_cnt == data_words-1)
                next_word = 0;
                else
                next_word = word_cnt + 1;
            end            
            else
            next_bit = bit_cnt + 1;
        end
        else
        next_clk = clk_cnt + 1;
    end
    trail: begin
        if (clk_cnt == (BRDV/2)-1) begin
            next_clk = 0;
            next_state = idle;
        end
        else
        next_clk = clk_cnt + 1;
    end
    endcase
end

// Lógica combinacional para o clock serial
always_comb begin
    next_SCK = SCK_reg;
    case (state)
    idle: next_SCK = CPOL;
    data: begin
        if (clk_cnt == (BRDV/2)-1 || clk_cnt == BRDV-1)
        next_SCK = ~SCK_reg;
    end
    trail: next_SCK = SCK_reg;
    endcase
end

// Lógica combinacional para os registradores de dados e para os sinais ready_out, valid_out e SS
always_comb begin
    next_SS = SS_reg;
    next_spi_data = spi_data_reg;
    next_ready = ready_reg;
    next_valid = valid_reg;
    next_MISO = MISO_reg;
    case (state)
    idle: begin
        next_valid = 1'b0;
        if (word_cnt > 0) begin
            if (clk_cnt == (BRDV/2)-1) begin
                next_SS = 1'b0;
                next_spi_data = data_in;
            end   
        end
        else begin
            next_ready = 1'b1;            
            if (spi_en) begin
                next_ready = 1'b1;
                next_SS = 1'b0;
                next_spi_data = data_in;
            end
        end
    end
    data: begin
        if (clk_cnt == (BRDV/2)-1) begin
            if (CPHA == 0)
            next_MISO = MISO;
            else if (bit_cnt > 0) begin
                if (LSBF == 0)
                next_spi_data = {spi_data_reg[DATA_BITS-2:0], MISO_reg};
                else
                next_spi_data = {MISO_reg, spi_data_reg[DATA_BITS-1:1]};
            end
        end
        if (clk_cnt == BRDV-1) begin
            if (CPHA == 0) begin                
                if (LSBF == 0)
                next_spi_data = {spi_data_reg[DATA_BITS-2:0], MISO_reg};
                else
                next_spi_data = {MISO_reg, spi_data_reg[DATA_BITS-1:1]};
            end
            else
            next_MISO = MISO;
        end
    end
    trail: begin
        if (clk_cnt == (BRDV/2)-1) begin
            if (tied_SS == 1'b1 && word_cnt > 0)
            next_SS = SS_reg;
            else
            next_SS = 1'b1;
            if (CPHA == 1) begin                
                if (LSBF == 0)
                next_spi_data = {spi_data_reg[DATA_BITS-2:0], MISO_reg};
                else
                next_spi_data = {MISO_reg, spi_data_reg[DATA_BITS-1:1]};
            end
            next_valid = 1'b1;
        end
    end
    endcase
end

// Direcionamento dos registradores para as saídas
assign SCK = SCK_reg;
assign data_out = spi_data_reg;
assign SS = SS_reg;
assign MOSI = LSBF == 0 ? spi_data_reg[DATA_BITS-1] : spi_data_reg[0];
assign ready_out = ready_reg;
assign valid_out = valid_reg;

endmodule