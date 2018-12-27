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
iframe_io=0; AD_io=0; CBE_io=0; iready_io=0; tready_io=0; devsel_io=0;
iframe_reg=1; iready_reg=1; tready_reg=1; devsel_reg=1;
AD_reg=0;
CBE_reg=0;
memory [0]=1;
memory [1]=1;
memory [2]=1;
memory [3]=1;
memory [4]=1;
memory [5]=1;
memory [6]=1;
memory [7]=1;
memory [8]=1;
memory [9]=1; 
memory_counter=0;
data_buffer=3;
end


initial 
begin 
dev_address <= device_address;
memory_counter <= 0;
end


always @ (posedge clk)
begin
    if (force_req)
    begin // inititor mode
        //$display("\nIN FORCE REQ , device with add::%d",device_address);
        request <= 0; // send request to Arbiter
        if (!grant) // granted, start using bus as initiator
        begin
            if (BE==4'b1000) // write operation
            begin
           // $display("\n IN INITIATOR WRITE\ndevice with add::%d    ,BE is::%b      AD_io:::%d ", device_address , BE , AD_io);            
                //if ((tready && devsel) && iready == 1'b1) // at the beginning of a transaction and need to communicate with a target device first.  (target & initiator not ready)
                //begin
                    #1 
                    // start taking over the bus as initiator in write mode 
                    iframe_io <= 1'b1; AD_io <= 1'b1; CBE_io <= 1'b1; iready_io <= 1'b1; // make them output    , this specific device becomes initiator
                    tready_io <= 1'b0; devsel_io <= 1'b0; // input  (not this device that sets tready & devSel)
                    iframe_reg <= 1'b0; // activate it, indicate to take over the bus
                    AD_reg <= contactAddress; // put the address of the target device on the AD lines.
                    CBE_reg <= 4'b1000; // means write
                    #1
                    iready_reg <= 0; // at this point target is ready to transfer data over the data lines.
                    
                    // THIS WILL BE ON THE RISING EDGE OF A NEW CLOCK CYCLE , SO SHOULDN'T WE REMOVE THIS PART ? IT WILL BE HANDELED IN THE NEXT ELSE IF CASE
                    AD_reg <= data;                                 
                    //$display("BE is :: %b",BE);
                    CBE_reg <= BE;
                //end
                /*else*/ if(!tready && !devsel) // this condition means: initiator contacted target device by putting its address
                begin
//                    #1
                    AD_reg <= data;
                    CBE_reg <= BE;  
                end
            end // end of initiator mode -- write 
                /********** End of Master write -> except for some corner cases [if target is not ready case, and finish data transfer case] ****************************************/
        
            else if (CBE==4'b0000) // master read
            begin



          //      $display("\n IN INITIATOR READ\ndevice with add::%d    ,BE is::%b      AD_io:::%d ", device_address , BE , AD_io);
                if (BE!=CBE_reg)begin               //this happens for the first and last BE==0000 times in a transaction (start and end of transaction , we just want the start)
                    
                    iframe_io <= 1'b1; AD_io <= 1'b1; CBE_io <= 1'b1; iready_io <= 1'b1; // make them output
                    tready_io <= 1'b1; devsel_io <= 1'b1; // input
                    tready_reg<=1'b1;   devsel_reg<= 1'b1;
                    iframe_reg <= 1'b0; // activate it, indicate to take over the bus
                    AD_reg <= contactAddress; // put the address of the target device on the AD lines.
                    CBE_reg <= 4'b0000; // means read

                end
                else begin
                    
                    iframe_io <= 1'b1; AD_io <= 1'b1; CBE_io <= 1'b1; iready_io <= 1'b1; // make them output
                    tready_io <= 1'b0; devsel_io <= 1'b0; // input
                    tready_reg<=1'b1;   devsel_reg<= 1'b1;
                end

//                if ((tready && devsel) && iready == 1'b1) // at the beginning of a transaction and need to communicate with a target device first.
//                begin
/*                    iframe_io <= 1'b1; AD_io <= 1'b1; CBE_io <= 1'b1; iready_io <= 1'b1; // make them output
                    tready_io <= 1'b0; devsel_io <= 1'b0; // input

                    
                    iready_reg <= 0; // at this point target is ready to transfer data over the data lines.
                    //memory_counter <= 0;
//                end // end of master read device selecting phase
  */              /*else*/ if ((!tready && !devsel) && iready == 1'b0) // target device responded, and we are ready 
                begin 
                    AD_io <= 1'b0; // make it input to read from AD bus
                    //$display("\nreading in initiaor , so leaving bus ZZZ");
                    data_buffer <= AD; // taking data from the bus, and storing it in internal memory register.         //WHY INCREMENTAL MEMORY STORAGING , 
                    //BUFFER IS WHAT SHOULD WORK INCREMENTALLY , AND MEMORY SHALL BE ADDRESSED BY SPECIFYING ITS WORD TO ADDRESS;
                    memory[memory_counter] <= data_buffer;
                    memory_counter <= memory_counter + 1; // increment counter
                    if (memory_counter == 9)
                        memory_counter <= 0;
                end // end of master read data receiving
                /*
                * to be added: 
                * cancel or pause transaction if force request = 0
                */
            
            
            
            
            end // end of master read mode.
        end
    end
    else if (!force_req)
    begin // not initiator 
        
        request <= 1'b1; // send cancel request to Arbiter.
        iframe_io <= 1'b0; AD_io <= 1'b0; CBE_io <= 1'b0; iready_io <= 1'b0; // make them input.
        //tready_io <= 1'b0; devsel_io <= 1'b0; // make them input
       
        if (!iframe) // some device has taken over the bus
        begin
            //$display("\nAD::%b      dev_address:::%b",AD,dev_address);                                              //
            if (AD == dev_address)
            begin
            //$display("target identified");                                              //
                tready_io <= 1'b1; devsel_io <= 1'b1; // output.     
              //  memory_counter <= 0;
                if (CBE == 4'b1000) // write mood, receive data and store it.
                begin
  //              $display("\n IN TARGET WRITE\ndevice with add::%d    ,BE is::%b      AD_io:::%d ", device_address , BE , AD_io);
                    #1
                    tready_reg <= 1'b0;
                    devsel_reg <= 1'b0;
                    data_buffer <= AD; // taking data from the bus, and storing it in internal memory register.
                    memory[memory_counter] <= data_buffer;
/*                    $display("\nDevice with Address::",device_address);
                    $display("memory counter = %d\ndataBuffer::%b",memory_counter,data_buffer);
                    $display("\nmemory0:::%b\nmemory1:::%b\nmemory2:::%b\nmemory3:::%b\nmemory4:::%b\nmemory5:::%b\nmemory6:::%b\nmemory7:::%b\nmemory8:::%b\nmemory9:::%b",
                    memory[0],memory[1],memory[2],memory[3],memory[4],memory[5],memory[6],memory[7],memory[8],memory[9]
                    );
*/                    memory_counter <= memory_counter + 1; // increment counter
  
                    if (memory_counter == 9) memory_counter <= 0; // reset counter.   
                end // end of target write mood.                
                else if (CBE == 4'b0000) // read mood, send data till iready or iframe are deactivated.
                begin // this section needs to be examined carefully
              //      $display("\n IN TARGET READ\ndevice with add::%d    ,BE is::%b      AD_io:::%d ", device_address , BE , AD_io);
                    tready_io <= 1'b1; devsel_io <= 1'b1;
                    if (tready && devsel)
                    begin
                    tready_reg <= 1'b0;
                    devsel_reg <= 1'b0;
                    //$display("AD_io becomes 1");
                    AD_io <= 1'b1; // output to write on it.
                    end  
                    /*=
                    FLOW OF DATA HERE SHALL BE FROM TARGET TO INITIATOR , SO DATA TO BE PUT ON AD_reg SHALL BE MEMORY[i] , WHERE i IS SPECIFIED INITIALLY ON THE 'AD'
                    */
                    AD_io <= 1'b1; // output to write on it.
                    //$display("AD_io becomes 1111");
                    AD_reg <= data;
                    //$monitor("ADREG = %b\n", AD_reg);
                    //$monitor("AD = %b\n", AD);


                    

                    

                end // end of target read mood
//                $display("\n device with add::%d    ,BE is::%b      AD_io:::%d ", device_address , BE , AD_io);
                
            end // target mood end
        end // end of iframe if checking
    end // end of initiator mood if 

end // end of always block 
endmodule





module ARBITER(grants,requests,frame,iReady,clk);
input [4:0] requests;
output [4:0] grants;
input frame,iReady,clk;
reg [4:0] intRequests;			//internal , meaning inside module , they are invert of the externals , to make it easier for me
reg [4:0] intGrants;

assign grants=~intGrants;
/*
initial begin
    intGrants=0;
end
*/
always @ (posedge clk)begin

	
	intRequests=~requests;
    if (intRequests[4]==1)begin
    //    $display("\nrequests are::%b\n",requests); 
        intGrants=16;
    end
    else if (intRequests[3]==1)begin
//        if (frame!==0 || (frame!==1&& intGrants[4]!=1))begin
        //    $display("\nrequests are::%b\n",requests);
            intGrants<=8;
//        end
    end
    else if (intRequests[2]==1)begin
//        if (frame!==0 || (frame!==1&& intGrants[4]!=1 && intGrants[3]!=1 ))begin
        //    $display("\nreqs are::%b\n",requests);
            intGrants<=4;
//        end
    end
    else if (intRequests[1]==1)begin
//    //    $display("\nreqs are::%b\n",requests);

//        if (frame!==0 || (frame!==1&& intGrants < 4 ))begin
        //    $display("\nreqs are::%b\n",requests);
            intGrants<=2;
//        end
    end
    else if (intRequests==1)begin
//        //    $display("\nreqs are::%b\n",requests);
//            if (frame!==0)begin
          //    $display("\nreqs are::%b\n",requests);
                intGrants<=1;
//            end
    end
    else if (intRequests==0)begin
        if (frame!==0)begin
            intGrants<=0;
//        //    $display("\nNO BODY WANTS A GRANT");
        end
    end
	
end

always @(requests)begin
    //$display($time,"\nreqs are::%b     &&     intGrants are::%b     && intRequests are::%b",requests,intGrants,intRequests);
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
reg rw;
reg  [4:0] force_req;
wire [4:0] request , grant;
wire [3:0] CBE;
reg [31: 0] contactAddress;
reg [31: 0] data1,data2,data3;
reg [3: 0] BE2,BE3,BE1,BE4,BE5;
wire [31: 0] AD;
wire  iframe, iready, tready, devsel;
integer f;

ARBITER arbiter (grant[4:0],{2'b11,request[2:0]},iframe,iready,clk);
//ARBITER arbiter (grant[4:0],request[4:0],iframe,iready,clk);

device  C        (request[0], iframe, AD, CBE, iready, tready, devsel, grant[0], force_req[0] , rw , contactAddress, 30 , data1, BE1,  clk);
device  B        (request[1], iframe, AD, CBE, iready, tready, devsel, grant[1], force_req[1] , rw , contactAddress, 20 , data2, BE1,  clk);
device  A        (request[2], iframe, AD, CBE, iready, tready, devsel, grant[2], force_req[2] , rw , contactAddress, 10 , data3, BE1,  clk);
//device  dev4            (request[3], iframe, AD, CBE, iready, tready, devsel, grant[3], force_req[3] , rw, contactAddress, 40 , data, BE4,  clk);
//device  dev5            (request[4], iframe, AD, CBE, iready, tready, devsel, grant[4], force_req[4] , rw, contactAddress, 50 , data, BE5,  clk);



initial 
begin

f = $fopen("./GUI App/sc1.txt","w");
//AD<=32'b00000000000000000000000000010100; 
//$monitor ($time,"\nAD = %b      iframe = %b     CBE = %b    iready = %b   tready = %b   devsel = %b   grant = %b    request=%b", AD, iframe,CBE,iready,tready, devsel , grant , request  );
//AD, iframe,CBE,iready,tready, devsel , rw ,grant , request
//test write
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);
data1=32'd255;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2

data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd254;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);



#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);


#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);


#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);



#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=5;contactAddress=30;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=5;contactAddress=30;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=5;contactAddress=30;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=5;contactAddress=30;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=5;contactAddress=30;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);


#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
////////////////////////////////////////////////////////////////////////////////////////DEVICE C SENT TO A , NOW WANTS TO SEND TO B
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

////////////////////////////////////////////////////////////////////////////////////////END OF C SENDING TO A
#2
data1=32'd253;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=0;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
$fwrite(f,"%b,%b,%b,%b\n",iframe,iready,tready, devsel);

/*
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//$monitor($time,"\ngrants:::::%b         requests::::::%b",grant,request);
#2
data1=32'd255;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req= 1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd254;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req= 1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1025;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd253;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1026;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd252;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=3;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd252;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;
*/
/********************************************************************DEV3 REQUESTS******************************************************************/

/*
#2
data1=32'd253;
data2=32'b11100000000000000000000000000000;
data3=127;
rw=1;force_req=1;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1026;data2=32'b11100000000000000000000000000000;
data3=127;
rw=1;force_req=4;contactAddress=10;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd252;
data2=32'b11100000000000000000000000000000;
data3=127;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=127;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=127;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd252;
data2=32'b11100000000000000000000000000000;
data3=127;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=127;
rw=1;force_req=4;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=127;
rw=1;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;BE3=4'b0000;

*/
//AD<=32'b00000000000000000000000000010100;
/****************************************************************READ******************************************************************************/
/*

#2
data1=32'd253;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=1;contactAddress=10;BE1=4'b0000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1026;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=10;BE1=4'b0000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd252;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=20;BE1=4'b0000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=20;BE1=4'b0000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;


#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=3;contactAddress=20;BE1=4'b0000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd252;
data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=20;BE1=4'b0000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=2;contactAddress=20;BE1=4'b0000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

#2
data1=32'd1024;data2=32'b11100000000000000000000000000000;
data3=128;
rw=1;force_req=0;contactAddress=20;BE1=4'b0000;BE2=4'b0000;BE3=4'b0000;
//AD<=32'b00000000000000000000000000010100;

*/
$display("\nAD: %b",AD);


/*
#2
data1=32'b01110data2=32'b11100000000000000000000000000000;0110011001110111011001100111;
rw=0;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;
#2
data=32'b01110110011001110111011001100000;
rw=1;force_req=1;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;
#2
data=32'b01110110011001110111011001111111;
rw=1;force_req=2;contactAddress=20;BE1=4'b1000;BE2=4'b0001;
//AD<=32'b00000000000000000000000000010100;
#2
data=32'b01110110011001110111011001111111;
rw=1;force_req=3;contactAddress=20;BE1=4'b1000;BE2=4'b0001;
//AD<=32'b00000000000000000000000000010100;
#2
data=32'b01110110011001110111011001111111;
rw=1;force_req=3;contactAddress=20;BE1=4'b1000;BE2=4'b0001;
//AD<=32'b00000000000000000000000000010100;
#2
data=32'b01110110011001110111011001111111;
rw=1;force_req=2;contactAddress=20;BE1=4'b1000;BE2=4'b0001;
//AD<=32'b00000000000000000000000000010100;
#10 
data = 32'b00001111000011110000111100001111;
rw=1;force_req=1;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;
#10 
data = 32'b00000000111111110000000011111111;
rw=1;force_req=2;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;
#2 
data= 32'b11111111111111110000000000000000;
rw<=1;force_req=3;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;
#2 
data= 32'b11111111111111110000000000000000;
rw<=1;force_req=0;contactAddress=20;BE1=4'b1000;BE2=4'b0000;
//AD<=32'b00000000000000000000000000010100;
*/
  $fclose(f);  
end 
initial 
begin  
clk<=1;
end
always begin 
#1
clk<=~clk;
end


//device  secondeDev      (request[1], iframe, AD, CBE, iready, tready, devsel, grant[1], force_req[1] , rw, contactAddress, 32'b20 , data, BE2,  clk);

endmodule

