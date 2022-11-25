import cache_Defs::*;
module test();
bit [10:0]tag_1;
logic [14:0]index_1;
bit clk,valid,dirty;

always@(posedge clk)
begin
split(32'b00010010001101000101011001111000);//32'b 
index_1<=index;
tag_1<=tag_field;
valid<=1;

split(32'b00010010001101000101011001111000);//32'b 
if (index_1==index && tag_1==tag_field)
	$display("Hit:%d",Hit);
else 
$display("Miss:%b",NoHit);
end
endmodule 