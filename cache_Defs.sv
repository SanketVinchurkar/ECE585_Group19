package cache_Defs; 
/* Bus Operation types */
parameter READ=1; /* Bus Read */
parameter WRITE=2; /* Bus Write */
parameter INVALIDATE=3; /* Bus Invalidate */
parameter RWIM=4; /* Bus Read With Intent to Modify */
/* Snoop Result types */
/* L2 to L1 message types */
parameter GETLINE=1; /* Request data for modified line in L1 */
parameter SENDLINE=2;/* Send requested cache line to L1 */
parameter INVALIDATELINE=3; /* Invalidate a line in L1 */
parameter EVICTLINE=4; /* Evict a line from L1 */

parameter nb_byte_offset=6;// nb=no. of bits
parameter nb_index=15;//8-way set associative
parameter nb_tag_field=11;
parameter associativity = 8;// It shows set associativity of the LLC.
parameter totalSets=2**nb_index;



//bit c;// signal which will indicate E or S state

bit[nb_byte_offset-1:0] byte_offset;
bit [nb_index-1:0]index;
bit [nb_tag_field-1:0] tag_field; 


typedef enum logic[1:0] {M = 2'b00, E = 2'b01, S = 2'b10,  I = 2'b11}states;
typedef enum logic[1:0] {NOHIT = 2'b00, HIT = 2'b01, HITM = 2'b10}snoopstate;

typedef struct packed {
states mesi;
logic [10:0] tag;
} line;


typedef struct packed {
line [associativity-1:0] lc;
logic [6:0] PLRU;
} set;
set [totalSets-1:0]s;


int j;
int m;// internal counter for checking tag bits
int w;

snoopstate snoopresult;
int re=0,wr=0,hit=0,miss=0;

function int GetSnoopResult(logic [31:0]address);
begin
if (address[1:0] == 2'b10 || address[1:0] == 2'b11)
snoopresult = NOHIT;
else if (address[1:0] == 2'b01)
snoopresult = HITM;
else if (address[1:0] == 2'b00)
snoopresult = HIT;
end
return snoopresult;
endfunction

function int PutSnoopResult(logic [31:0]address,flag); 
begin
if (!flag)
$display("SnoopAddress address=%h  SnoopResult snoopresult=%s", address,snoopresult);
end
endfunction

/* Used to simulate communication to our upper level cache */
function void MessageToCache(string message,logic [31:0]address,flag); 
begin
if (!flag)
$display("message from L2 to L1 message=%s  address of the message address=%h", message,address);
end
endfunction

function void BusOperation(string busop,logic [31:0]address,flag); 
begin
int snoopingresult; 
snoopingresult= GetSnoopResult(address);
if (!flag)
$display("busop: %s, address: %h Snoop Result: %s",busop,address,snoopresult);
end
endfunction


function void c_read([10:0]tag_field,[14:0]index,logic [31:0]address,flag); //cache READ
begin
m=1;
 for(j=0;j<8;j++)
 begin
 if (s[index].lc[j].tag == tag_field && s[index].lc[j].mesi != I)//checking for hit
 begin
 hit=hit+1;
m=0;
//$display("hit = %d miss = %d j=%d ind=%15b",hit,miss,j,index);
     MessageToCache("SENDLINE",address[31:0],flag); 
//     $display("SENDLINE");
//$display("j value is %d",j);
     update_LRU();
//     $display("%b",s[index].PLRU);
     break;
   end
end
if (m)   // I state (MISS)
 begin
for(j=0;j<8;j++)
  begin
//$display("MESI_0=%d",s[index].lc[0].mesi);
if (s[index].lc[j].mesi == I) begin
miss=miss+1; 
m=0;
//$display("hit = %d miss = %d j=%d ind=%15b",hit,miss,j,index);

//$display("MESI=%d",s[index].lc[j].mesi);
	BusOperation("READ",address[31:0],flag);
        MessageToCache("SENDLINE",address[31:0],flag);

s[index].lc[j].tag = tag_field;
//$display("tag=%11b",s[index].lc[j].tag);
if(GetSnoopResult(address[31:0])==1 || GetSnoopResult(address[31:0])==2)
begin
s[index].lc[j].mesi = S;
end

if(GetSnoopResult(address[31:0])==0)
begin
s[index].lc[j].mesi = E;
end
//$display("MESI=%d",s[index].lc[j].mesi);
//$display("j value is %d",j);
 update_LRU();
//$display("%b",s[index].PLRU);

break;
end 
end
end
if(m)
begin 
//$display("%b",s[index].PLRU);
get_LRU(); 
if(s[index].lc[j].mesi == M) begin
MessageToCache("GETLINE",address[31:0],flag);
BusOperation("WRITE",address[31:0],flag);
end
MessageToCache("EVICTLINE",address[31:0],flag);
s[index].lc[j].tag=tag_field;
//$display("tag=%11b",s[index].lc[0].tag);
update_LRU();
if(GetSnoopResult(address[31:0])==1 || GetSnoopResult(address[31:0])==2)
begin
s[index].lc[j].mesi = S;
end

if(GetSnoopResult(address[31:0])==0)
begin
s[index].lc[j].mesi = E;
end
m=0;

miss = miss+1;
//$display("hit = %d miss = %d",hit,miss);
// if c is low data will be in S
end
end
endfunction

function void c_write([10:0]tag_field,[14:0]index,logic [31:0]address,flag); //cache write
begin
m=1;
 for(j=0;j<8;j++)
 begin
 if ((s[index].lc[j].tag == tag_field)&&(s[index].lc[j].mesi!=I))
 begin
  hit=hit+1;
  update_LRU();
  MessageToCache("SENDLINE",address[31:0],flag);
  s[index].lc[j].mesi = M;
m=0;
break;
end
end
if(m)begin
 for(j=0;j<8;j++)
	begin
if (s[index].lc[j].mesi == I) // I state (MISS)
  begin
	miss=miss+1;
	BusOperation("RWIM",address[31:0],flag);
        MessageToCache("SENDLINE",address[31:0],flag);
	update_LRU();
	s[index].lc[j].tag = tag_field;
      s[index].lc[j].mesi = M;
m=0;
break;
end
 end
  end
	
if(m)begin
get_LRU();
if(s[index].lc[j].mesi == M) begin
MessageToCache("GETLINE",address[31:0],flag);
BusOperation("WRITE",address[31:0],flag);
end
MessageToCache("EVICTLINE",address[31:0],flag);
s[index].lc[j].tag = tag_field;
update_LRU();
//	$display("tag=%11b",s[index].lc[0].tag);
	BusOperation("RWIM",address[31:0],flag);
        MessageToCache("SENDLINE",address[31:0],flag);
        s[index].lc[j].mesi = M;
m=0;
miss=miss+1;
end
end
endfunction

function void update_LRU(); //updates LRU
begin
if (j == 0)
begin
s[index].PLRU[1:0] = 2'b00;
s[index].PLRU[3] = 0;
end

else if(j == 1)
begin
s[index].PLRU[1:0] = 2'b00;
s[index].PLRU[3] = 1;
end

else if(j == 2)
begin
s[index].PLRU[0] = 0;
s[index].PLRU[1] = 1;
s[index].PLRU[4] = 0;
end

else if(j == 3)
begin
s[index].PLRU[0] = 0;
s[index].PLRU[1] = 1;
s[index].PLRU[4] = 1;
end

else if(j == 4)
begin
s[index].PLRU[0] = 1;
s[index].PLRU[2] = 0;
s[index].PLRU[5] = 0;
end

else if(j == 5)
begin
s[index].PLRU[0] = 1;
s[index].PLRU[2] = 0;
s[index].PLRU[5] = 1;
end

else if(j == 6)
begin
s[index].PLRU[0] = 1;
s[index].PLRU[2] = 1;
s[index].PLRU[6] = 0;
end

else if (j == 7)
begin
s[index].PLRU[0] = 1;
s[index].PLRU[2] = 1;
s[index].PLRU[6] = 1;
end
end
endfunction

function void get_LRU();
begin


if(s[index].PLRU[0] == 0 && s[index].PLRU[2] == 0 && s[index].PLRU[6]== 0)
j = 7;

else if(s[index].PLRU[0] == 0 && s[index].PLRU[2] == 0 && s[index].PLRU[6]== 1)
j = 6;

else if(s[index].PLRU[0] == 0 && s[index].PLRU[2] == 1 && s[index].PLRU[5] == 0)
j = 5;

else if(s[index].PLRU[0] == 0 && s[index].PLRU[2] == 1 && s[index].PLRU[5] == 1)
j = 4;

else if(s[index].PLRU[0] == 1 && s[index].PLRU[1] == 0 && s[index].PLRU[4] == 0)
j = 3;

else if(s[index].PLRU[0] == 1 && s[index].PLRU[1] == 0 && s[index].PLRU[4] == 1)
j = 2;

else if(s[index].PLRU[0] == 1 && s[index].PLRU[2] == 1 && s[index].PLRU[3] == 0)
j = 1;

else if(s[index].PLRU[0] == 1 && s[index].PLRU[2] == 1 && s[index].PLRU[3] == 1)
j = 0;
end
endfunction

function void LLC_cache_design(input logic [31:0] hexaddress,input logic [3:0]n,input logic mode);
begin


real hitratio,hit1,miss1;

int m;//checks for misses if m = 1 there is a miss, if m = 0 there is a hit
int count,cread;
// initialising the values 



byte_offset[5:0]=hexaddress[5:0];
index[14:0]=hexaddress[20:6];
tag_field[10:0]=hexaddress[31:21];
/*for ( int i = 0; i < totalSets; i++) begin
s[i].PLRU = 'x; 
for (int  k = 0; k < 8; k++) begin
s[i].lc[k].tag = 'x;
s[i].lc[k].mesi = 2'b11;
end
end*/

if(n==0||n==2)
re=re+1;//counts reads
else

if(n==1)
wr=wr+1;//counts writes
if(n == 0)
begin
c_read(tag_field[10:0],index[14:0],hexaddress[31:0],mode);
end

else if(n == 1)
begin
c_write(tag_field[10:0],index[14:0],hexaddress[31:0],mode);
end

else if(n == 2)
begin
c_read(tag_field[10:0],index[14:0],hexaddress[31:0],mode);

end

else if(n == 3)
begin
for (int i=0;i<8;i++) begin
if (s[index].lc[i].tag == tag_field) begin
//update_LRU(j);
case (s[index].lc[i].mesi)
M: s[index].lc[i].mesi= I; 
E: s[index].lc[i].mesi= I;
S: s[index].lc[i].mesi= I;
I: s[index].lc[i].mesi= I;
default: s[index].lc[i].mesi = I;
endcase
MessageToCache("INVALIDATELINE",hexaddress[31:0],mode);
end
end

end
else if(n == 4)
begin
for (int i=0;i<8;i++) begin
if (s[index].lc[i].tag == tag_field) begin
//update_LRU(j);
case (s[index].lc[i].mesi)
M: s[index].lc[i].mesi= S; // need to write flush
E: s[index].lc[i].mesi= S;
S: s[index].lc[i].mesi= S;
I: s[index].lc[i].mesi= S;
default: s[index].lc[i].mesi= S;

endcase 
end
end

end
else if(n==5)
begin
for (int i=0;i<8;i++) begin
if (s[index].lc[i].tag == tag_field) begin
//update_LRU(k);
case (s[index].lc[i].mesi)
M: s[index].lc[i].mesi= I; 
E: s[index].lc[i].mesi= I;
S: s[index].lc[i].mesi= I;
I: s[index].lc[i].mesi= I;
default: s[index].lc[i].mesi=I;
endcase 
end
end
end

else if(n==6)
begin
for (int i=0;i<8;i++) begin
if (s[index].lc[i].tag == tag_field) begin
//update_LRU(k);
case (s[index].lc[i].mesi)
M: s[index].lc[i].mesi= I;
E: s[index].lc[i].mesi= I;
S: s[index].lc[i].mesi= I;
I: s[index].lc[i].mesi= I;
default: s[index].lc[i].mesi= I;
endcase 
if(s[index].lc[j].mesi == M) begin
MessageToCache("GETLINE",hexaddress[31:0],mode);
BusOperation("WRITE",hexaddress[31:0],mode);
end
MessageToCache("EVICTLINE",hexaddress[31:0],mode);
end
end
end

else if(n == 8)
begin 
for ( int i = 0; i < totalSets; i++) begin;
for (int  k = 0; k < 8; k++) begin;
s[i].lc[k].tag = 'x;
s[i].lc[k].mesi =I;
                s[i].PLRU = 'x; 
end
end
end

else if(n == 9)
begin
$display("***********************************************************\n");
for ( int i = 0; i < totalSets; i++) begin
for (int  k = 0; k < 8; k++) begin
if(s[i].lc[k].mesi == M || s[i].lc[k].mesi == E || s[i].lc[k].mesi == S)
begin
$display("Tag=%p Index=%d Mesi=%s",s[i].lc[k].tag,i,s[i].lc[k].mesi);
end
end
end
end
end
endfunction

endpackage







