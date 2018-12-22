`timescale 1ns / 1ps



module ARBITER(grants,requests,frame,iReady,clk);
input [4:0] requests;
output [4:0] grants;
input frame,iReady,clk;
reg [4:0] intRequests,intGrants;			//internal , meaning inside module , they are invert of the externals , to make it easier for me

assign grants=~intGrants;


always @ (posedge clk)begin

	
	intRequests=~requests;
	
		if (intRequests>=16)begin
			#1
			intGrants=16;
		end
		else if (intRequests>=8)begin
			if (frame==1 || (frame==0&& intGrants[4]!=1))begin
				#1
				intGrants=8;
			end
		end
		else if (intRequests>=4)begin
			if (frame==1 || (frame==0&& intGrants[4]!=1 && intGrants[3]!=1 ))begin
				#1
				intGrants=4;
			end
		end
		else if (intRequests>=2)begin
			if (frame==1 || (frame==0&& intGrants < 4 ))begin
				#1
				intGrants=2;
				end
		end
		else if (intRequests==1)begin
				if (frame==1)begin
					#1
					intGrants=1;
				end
		end
	
end

endmodule



module ARBITER_TB ();
reg [4:0] REQUESTS;
wire [4:0] GRANTS;
reg FRAME,CLK,IREADY;


ARBITER masterMind(GRANTS,REQUESTS,FRAME,IREADY,CLK);


initial begin 
$monitor($time ,"	grants::%b		requests::%b		frame::%b	   iReady::%b" , GRANTS , REQUESTS , FRAME , IREADY);
CLK=0;IREADY=1;FRAME=1;REQUESTS=5'b11111;		//no requests
REQUESTS=0;
CLK=0;IREADY=1;FRAME=1;REQUESTS=5'b01111;		// highest priority request
#2
REQUESTS=5'b11011;FRAME=1;							// third priority request
#2
REQUESTS=5'b11011;FRAME=1;							// third priority request
#2
REQUESTS=5'b11011;									// third priority request
#2
REQUESTS=5'b10111;									// second priority request
#2
REQUESTS=5'b10111;FRAME=1;							// second priority request
#2
REQUESTS=5'b11011;									// third priority request
#2
REQUESTS=5'b10111;FRAME=0;							// second priority request
#2
REQUESTS=5'b10011;									// seond and third priority requests
#2
REQUESTS=5'b11110;									// least priority request
#2
REQUESTS=5'b11110;FRAME=1;									// least priority request
#2
REQUESTS=5'b01110;FRAME=1;									// least priority request
#2
REQUESTS=5'b11110;									// least priority request

end

always begin
	CLK<=~CLK;
	#1 ;
end
endmodule




/*
module DEVICE(dataBus,frame,iReady,control_ByteEnable,clk,tReady,devSel,GNT,req,force_req,setDeviceAddress);
inout [31:0] dataBus;
inout iReady,tReady,devSel;
inout [3:0] control_ByteEnable;
input clk,GNT,force_req,setDeviceAddress;
output frame,req;
reg [31:0] memory [9:0];
reg [31:0] deviceAddress [9:0];
integer i;
assign req=force_req;

assign deviceAddress [0]= setDeviceAddress ;

initial begin
	for (i=1;i<10;i=i+1)begin
		deviceAddress[i]=setDeviceAddress+i;
	end
end
/*
if frame & iready are zeros , for the first cycle , then we are searching for the device with the address equal to the data that's currently
on the data bus

device shall check if the data on the data bus lies withing device's address range , if so , it shall get ready for transaction . 

frame=0 for n cycles , means master wants n transactions
*-/


always @ (posedge clk)begin
	if (GNT==0)begin				//INITIAOR DEVICE
		



	end
	
//	else if (frame==0 & iReady==0 & deviceAddress[0])
	
	
	
end



endmodule
*/
