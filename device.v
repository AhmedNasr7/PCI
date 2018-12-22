/* file contains device module */

module device(request, iframe, AD, CBE, iready, tready, devsel, grant, force_req, rw, contact2address, clk);

/*********** inputs - Outputs *******************/

input clk, grant, force_req, rw;
input [31: 0] contact2address;
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
            if (rw) // means write
                #1 
                // start taking over the bus as initiator in write mode 
                iframe_io <= 1'b1; AD_io <= 1'b1; CBE_io <= 1'b1; iready_io <= 1'b1; // make them output
                iframe_reg <= 1'b0; // make it active, indicate to take over the bus
                AD_reg <= contact2address;
                

            

        end

end




endmodule
