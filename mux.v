module mux(S, D, d, Y);
  output reg Y;
  input D, d, S;
  always @(*) begin
    Y = S ? d : D;
  end
endmodule