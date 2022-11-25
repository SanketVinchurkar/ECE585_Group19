
package cache_Defs; 
/* Bus Operation types */
parameter READ=1; /* Bus Read */
parameter WRITE=2; /* Bus Write */
parameter INVALIDATE=3; /* Bus Invalidate */
parameter RWIM=4; /* Bus Read With Intent to Modify */
/* Snoop Result types */
parameter NOHIT=0; /* No hit */
parameter HIT=1; /* Hit */
parameter HITM=2; /* Hit to modified line */
/* L2 to L1 message types */
parameter GETLINE=1; /* Request data for modified line in L1 */
parameter SENDLINE=2;/* Send requested cache line to L1 */
parameter INVALIDATELINE=3; /* Invalidate a line in L1 */
parameter EVICTLINE=4; /* Evict a line from L1 */

int nb_byte_offset=6;// nb=no. of bits
int nb_index=15;//8-way set associative
int nb_tag_field=11;

bit[5:0] byte_offset;
bit [14:0]index;
bit [10:0] tag_field;
bit [10:0]tag_array[262144:0];

logic[31:0] hexaddress;

function bit split(logic[31:0] hexaddress);
begin
assign tag_field=hexaddress[31:21];
assign index=hexaddress[20:6];
assign byte_offset=hexaddress[5:0];

$display("tag fields:%b",tag_field);
$display("index:%b",index);
$display("byte_offset:%b",byte_offset);
return tag_field;
return index;
return byte_offset;
end
endfunction

endpackage
