I have tried to verify dual port ram by constrained random verification using System verilog based UVM where I also have checked for the functional correctness of the design and extracted coverage metrics.

Some of the functionalities that I have tried to look for are as follows:

1) Performed reads and writes in different constrained address and checked for the same.
2) Checked whether the values are updated in the memory when overwritten.
3) Reads followed by writes on same address location.
4) Writes followed by reads on same address location.
5) Checked for RAM boundary size reads and writes.
6) Consecutive reads and writes on same address (addrA)


To check:

1)Behaviour when data is written to same address i.e addrA,addrB 

Coverage:

1)Looked whether randomization has walked through all the constrained random address / covered all my address space and also cross coverage b/w two addresses.
2) Read and write hits per instance 
