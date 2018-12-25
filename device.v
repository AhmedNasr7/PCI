/* file contains device module */

module device(request, iframe, AD, CBE, iready, tready, devsel, grant, force_req, rw, contactAddress, data, BE,  clk);

/*********** inputs - Outputs *******************/

input clk, grant, force_req, rw;
input [31: 0] contactAddress;
input [31: 0] data;
input [3: 0] BE;
output reg request;
inout [31: 0] AD;
inout iframe, CBE, iready, tready, devsel;

/************** Internal Wires - registers ***********************/

reg iframe_io, AD_io, CBE_io, iready_io, tready_io, devsel_io;
reg iframe_reg, iready_reg, tready_reg, devsel_reg;
reg [31: 0] AD_reg;
reg [3: 0] CBE_reg;

reg [31: 0] dev_address; // contains device internal address
reg [31: 0] memory [9: 0]; // 10 rows (words) of memory
reg [3: 0] memory_counter; // to store the memory row that is in turn
reg [31: 0] data_buffer;

/** GUIDELINES - CONTROL SIGNALS ***** 
* Control signal consists of 4 bits, The MSB indicates the read/write operation, W = 1, R = 0 
* The 3 other bits, the LSBs, indicate number of word you wanna write or read in current transaction.
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

/** To be added: 
* initiator code:
* target code
*/


always @ (posedge clk)
begin
    if (force_req) // inititor mode
        #1
        request <= 0; // send request to Arbiter
        if (!grant) // granted, start using bus as initiator
        begin
            if (rw) // write operation
               if ((tready && devsel) && iready == 1'b1) // at the beginning of a transaction and need to communicate with a target device first.
               begin
                     #1 
                // start taking over the bus as initiator in write mode 
                iframe_io <= 1'b1; AD_io <= 1'b1; CBE_io <= 1'b1; iready_io <= 1'b1; // make them output
                iframe_reg <= 1'b0; // activate it, indicate to take over the bus
                AD_reg <= contactAddress; // put the address of the target device on the AD lines.
                CBE_reg <= 4'b1000; // means write
                #1
                iready_reg <= 0; // at this point target is ready to transfer data over the data lines.
                AD_reg <= data;
                CBE_reg <= BE;
               end
            else if(!tready && !devsel) // this condition means: initiator contacted target device by putting its address
                begin
                #1
                AD_reg <= data;
                CBE_reg <= BE;  
                end
                
                /********** End of Master write -> except for some corner cases [if target is not ready case] ****************************************/
                

                


            

        end

end




endmodule
