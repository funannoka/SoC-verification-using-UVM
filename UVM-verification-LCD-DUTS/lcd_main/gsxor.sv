//
// This calculates the gray scale value for a pixel component
//
module gsxor(input logic [19:0] gc,output logic [3:0] gv);

assign gv[3]= gc[1]^gc[5]^gc[6]^gc[7]^gc[8]^gc[10]^gc[12]^gc[13]^gc[16];
assign gv[2]= gc[2]^gc[6]^gc[7]^gc[8]^gc[9]^gc[11]^gc[13]^gc[14]^gc[17];
assign gv[1]= gc[0]^gc[3]^gc[7]^gc[8]^gc[9]^gc[10]^gc[12]^gc[14]^gc[15]^gc[18];
assign gv[0]= gc[0]^gc[4]^gc[5]^gc[6]^gc[7]^gc[9]^gc[11]^gc[12]^gc[15]^gc[19];

endmodule : gsxor
