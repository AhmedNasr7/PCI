/* file contains device module */
/*COMMENTS ON LINES 21,23,84, 115-116 ,132-135 , 137 , 164*/
module device(request, iframe, AD, CBE, iready, tready, devsel, grant, force_req, rw, contactAddress, device_address, data, BE,  clk);

/* request: output send to Arbiter to request the Bus [Active low]. 
*  grant: input from the arbiter to inform the device that he has the bus now [Active low].
*  force_req: input from tb to make the device send request to the arbiter and take over the bus [Active high]
*  rw: input to decide reading or writing: specified in the master mode, W: 1, R: 0.
*  contactAddress: input to specify the target device address, only for master mode.
*  data: data to be sent: master write or read from target.
*  BE: Byte enable bits input: only for master mode [used to specify which bytes to be read by the target].
*  clk: reading data from the bus with posedge clk, writing data to the bus with negede clk [toggling every 1 time unit].
*/ 

/*********** Module inputs - Outputs *******************/

input clk, grant, force_req, rw;
input [31: 0] contactAddress;
input [31: 0] data;
input [31: 0] device_address;
input [3: 0] BE;                                                ///SHOULD BECOME OF TYPE INOUT ? // YOU MISMIXED IT WITH CBE , RIGHT ?
output reg request;
inout [31: 0] AD;
inout iframe, iready, tready, devsel;                        
inout [3: 0] CBE;

/************** Internal Wires - registers ***********************/

reg iframe_io, AD_io, CBE_io, iready_io, tready_io, devsel_io;
reg iframe_reg, iready_reg, tready_reg, devsel_reg;
reg [31: 0] AD_reg;
reg [3: 0] CBE_reg;

reg [31: 0] dev_address; // contains device internal address
reg [31: 0] memory [0: 9]; // 10 rows (words) of memory
reg [3: 0] memory_counter; // to store the memory row that is in turn
reg [31: 0] data_buffer;

/** GUIDELINES - CONTROL SIGNALS ***** 
* Control signal consists of 4 bits, The MSB indicates the read/write operation, W = 1, R = 0 
* The 3 other bits, the LSBs, indicate number of word you wanna write or read in current transaction.       //HOW DID YOU GET THIS PIECE OF INFO ?
* That means you can read or write up to 8 words in a single transaction.
*/

/************* inout control ******************/ 

assign iframe = iframe_io? iframe_reg: 1'bz; 
assign iready = iready_io? iready_reg: 1'bz; 
assign tready = tready_io? tready_reg: 1'bz; 
assign devsel = devsel_io? devsel_reg: 1'bz;

assign AD = AD_io? AD_reg: 32'hzzzz_zzzz; 
assign CBE = CBE_io? CBE_reg: 4'bzzzz; 

//assign data_buffer = AD;

initial begin
iframe_io<=0; AD_io<=0; CBE_io<=0; iready_io<=0; tready_io<=0; devsel_io<=0;
iframe_reg<=0; iready_reg<=0; tready_reg<=0; devsel_reg<=0;
AD_reg=0;
CBE_reg=0;

dev_address<=0;
memory [0]<=0;
memory [1]<=0;
memory [2]<=0;
memory [3]<=0;
memory [4]<=0;
memory [5]<=0;
memory [6]<=0;
memory [7]<=0;
memory [8]<=0;
memory [9]<=0; 
memory_counter<=0;
data_buffer<=0;
end


initial 
begin 
dev_address <= device_address;
end


always @ (posedge clk)
begin
    if (force_req) // inititor mode
       // $display("\n\n  IN FORCE REQ , device with add::%d \n\n",device_address);
        request <= 0; // send request to Arbiter
        if (!grant) // granted, start using bus as initiator
        begin
            if (rw) // write operation
            begin
                if ((tready && devsel) && iready == 1'b1) // at the beginning of a transaction and need to communicate with a target device first.  (target & initiator not ready)
                begin
                #1 
                // start taking over the bus as initiator in write mode 
                iframe_io <= 1'b1; AD_io <= 1'b1; CBE_io <= 1'b1; iready_io <= 1'b1; // make them output    , this specific device becomes initiator
                tready_io <= 1'b0; devsel_io <= 1'b0; // input  (not this device that sets tready & devSel)
                iframe_reg <= 1'b0; // activate it, indicate to take over the bus
                AD_reg <= contactAddress; // put the address of the target device on the AD lines.
                CBE_reg <= 4'b1000; // means write
                #1              //CLOCK EDGE RISES
                iready_reg <= 0; // at this point target is ready to transfer data over the data lines.
                
                // THIS WILL BE ON THE RISING EDGE OF A NEW CLOCK CYCLE , SO SHOULDN'T WE REMOVE THIS PART ? IT WILL BE HANDELED IN THE NEXT ELSE IF CASE
                AD_reg <= data;                                 
                CBE_reg <= BE;
                end
                else if(!tready && !devsel) // this condition means: initiator contacted target device by putting its address
                begin
                #1
                AD_reg <= data;
                CBE_reg <= BE;  
                end
            end // end of initiator mode -- write 
                /********** End of Master write -> except for some corner cases [if target is not ready case, and finish data transfer case] ****************************************/
        
            else if (!rw) // master read
            begin
                if ((tready && devsel) && iready == 1'b1) // at the beginning of a transaction and need to communicate with a target device first.
                begin
                    #1
                    iframe_io <= 1'b1; AD_io <= 1'b1; CBE_io <= 1'b1; iready_io <= 1'b1; // make them output
                    tready_io <= 1'b0; devsel_io <= 1'b0; // input

                    iframe_reg <= 1'b0; // activate it, indicate to take over the bus
                    AD_reg <= contactAddress; // put the address of the target device on the AD lines.
                    CBE_reg <= 4'b0000; // means read
                    #1
                    iready_reg <= 0; // at this point target is ready to transfer data over the data lines.
                    //memory_counter <= 0;
                end // end of master read device selecting phase
                else if ((!tready && !devsel) && iready == 1'b0) // target device responded, and we are ready 
                begin 
                    AD_io <= 1'b0; // make it input to read from AD bus
                    data_buffer <= AD; // taking data from the bus, and storing it in internal memory register.         //WHY INCREMENTAL MEMORY STORAGING , 
                    //BUFFER IS WHAT SHOULD WORK INCREMENTALLY , AND MEMORY SHALL BE ADDRESSED BY SPECIFYING ITS WORD TO ADDRESS;
                    memory[memory_counter] <= data_buffer;
                    memory_counter <= memory_counter + 1; // increment counter
                if (memory_counter == 9) memory_counter <= 0;
                end // end of master read data receiving
                /*
                * to be added: 
                * cancel or pause transaction if force request = 0
                */
        //$display("\nLEAVING1111\n");
    end // end of master read mode.


    else if (!force_req) // not initiator 
       // $display("\n\n  IN  NO FORCE REQ \n\n");
        
        request <= 1'b1; // send cancel request to Arbiter.
        iframe_io <= 1'b0; AD_io <= 1'b0; CBE_io <= 1'b0; iready_io <= 1'b0; // make them input.
        tready_io <= 1'b1; devsel_io <= 1'b1; // make them input
       
        if (!iframe) // some device has taken over the bus
        begin
            if (AD == dev_address)
            begin
                tready_io <= 1'b1; devsel_io <= 1'b1; // output.     
              //  memory_counter <= 0;
                if (CBE == 4'b1000) // write mood, receive data and store it.
                begin
                    #1
                    tready_reg <= 1'b0;
                    devsel_reg <= 1'b0;
                    data_buffer <= AD; // taking data from the bus, and storing it in internal memory register.
                    memory[memory_counter] <= data_buffer;
                    memory_counter <= memory_counter + 1; // increment counter
                    if (memory_counter == 9) memory_counter <= 0; // reset counter.   
                end // end of target write mood.

                else if (CBE == 4'b0000) // read mood, send data till iready or iframe are deactivated.
                begin // this section needs to be examined carefully
                    #1                                                          //WHY DELAY ??
                    if (tready && devsel)
                    begin
                    tready_reg <= 1'b0;
                    devsel_reg <= 1'b0;
                    AD_io <= 1'b1; // output to write on it.
                    end  
                    /*
                    FLOW OF DATA HERE SHALL BE FROM TARGET TO INITIATOR , SO DATA TO BE PUT ON AD_reg SHALL BE MEMORY[i] , WHERE i IS SPECIFIED INITIALLY ON THE 'AD'
                    */
                    AD_reg <= data;

                end // end of target read mood

            end // target mood end
        end // end of iframe if checking
    //$display("\nLEAVING\n");
    end // end of initiator mood if 

end // end of always block 
endmodule




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


/*
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


*/



/******** TB ***********************/ 


module pci_tb();
reg clk;
reg rwA, rwB;
wire requestA, requestB;
reg  force_reqA; force_reqB;
wire [3:0] CBE;
reg [31: 0] contactAddress;
reg [31: 0] data;
reg [3: 0] BE1;
reg [3: 0] BE2;
wire [31: 0] AD;
wire  iframe, iready, tready, devsel;



always begin 
#1
clk<=~clk;
end




initial 
begin

$monitor ($time,"AD = %b      iframe = %b     \n CBE = %b    iready = %b     tready = %b     devsel = %b    rwA = %b, rwB = %b \n   grantA = %b   grantB = %b  requestA=%b  requestA=%b  ", AD, iframe,CBE,iready,tready, devsel , rwA, rwB,grantA, grantB , requestA, requestB );

clk <= 0;
rw=1;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100; 
//test write 
#2
data=32'b01110110011001110111011001100111;
rw=0;force_req=1;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data=32'b01110110011001110111011001100000;
rw=1;force_req=1;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data=32'b01110110011001110111011001111111;
rw=1;force_req=1;contactAddress=20;BE1=4'b1000;BE2=4'b0001;
//AD<=32'b00000000000000000000000000010100;

#10 
data = 32'b00001111000011110000111100001111;
rw=1;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#10 
data = 32'b00000000111111110000000011111111;
rw=1;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2 
data= 32'b11111111111111110000000000000000;
rw<=1;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;

end 



ARBITER arbiter (grant,request,iframe,iready,clk);

device  A       (requestA, iframe, AD, CBE, iready, tready, devsel, grantA, force_reqA , rwA, contactAddress, 20 , data, BE1,  clk);
device  B   (requestB, iframe, AD, CBE, iready, tready, devsel, grantB, force_reqB , rwB, contactAddress, 10 , 0, BE2,  clk);

endmodule


