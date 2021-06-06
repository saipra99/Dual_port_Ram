
`include "uvm_macros.svh"
import uvm_pkg::*;

`define ADDR_WIDTH 8
`define DATA_WIDTH 16
`define DEPTH 256


//*****************************SEQUENCE_ITEM**********************

class reg_item extends uvm_sequence_item;
  
  
  rand bit [`ADDR_WIDTH-1:0]  	addrA;
  rand bit [`ADDR_WIDTH-1:0]  	addrB;
  rand bit [`DATA_WIDTH-1:0] 	wdataA;
  rand bit [`DATA_WIDTH-1:0] 	wdataB;
  
  rand bit[`DATA_WIDTH-1:0] wr_data;
  rand bit 	wr;
  bit [`DATA_WIDTH-1:0] 		rdataA; 
  bit [`DATA_WIDTH-1:0] 		rdataB;
  

  // Use utility macros to implement standard functions
  // like print, copy, clone, etc
  `uvm_object_utils_begin(reg_item)
  `uvm_field_int (addrA, UVM_DEFAULT)
  `uvm_field_int (wdataA, UVM_DEFAULT)
  `uvm_field_int (rdataA, UVM_DEFAULT)
  `uvm_field_int (addrB, UVM_DEFAULT)
  `uvm_field_int (wdataB, UVM_DEFAULT)
  `uvm_field_int (rdataB, UVM_DEFAULT)
  `uvm_field_int (wr, UVM_DEFAULT)
  `uvm_object_utils_end
  
  
  constraint PATTERN{ foreach(wr_data[i]){if(i) wr_data[i] == wr_data[i-1] <<1; else wr_data[i] ==`DATA_WIDTH'b1;}}
    
  constraint addressA {addrA inside { 'h76 ,'h12, 'h30, 'h34,'hEE,'h00,'h72};}
  
  
  constraint addressB {addrB inside {'h21, 'hCD ,'hCC ,'h8A , 'h32,'hFF,'h54};}
  
  
  constraint seq_3 { wr dist {0:=50,1:=50};}

                                           
  
  virtual function string convert2str();
    return $sformatf("addrA=0x%0h addrB=0x%0h wr=0x%0h wdataA=0x%0h wrdataB=0x%0h rdataA 0x%0h rdataB 0x%0h", addrA,addrB, wr, wdataA,wdataB,rdataA,rdataB);
  endfunction
  
  function new(string name = "reg_item");
    super.new(name);
  endfunction
endclass

//***************************SEQUENCE*************************
                                              //1) Writes and reads on different constrained address to check whether the latest value are updated or not
                                            //2) Boundary check for RAM writing and reading from RAM size boundary addresses.


class gen_item_seq extends uvm_sequence;
  `uvm_object_utils(gen_item_seq)
  function new(string name="gen_item_seq");
    super.new(name);
  endfunction
  
  rand int num; 	// Config total number of items to be sent
  
  constraint c1 {  num inside {[20:50]}; }
  
  virtual task body();
    reg_item m_item = reg_item::type_id::create("m_item");
    m_item.seq_3.constraint_mode(0);
    for (int i = 0; i < num; i ++) begin
    	start_item(m_item);
      m_item.randomize();
      `uvm_info("SEQ", $sformatf("Generate new item: %s", m_item.convert2str()), UVM_LOW)
      	finish_item(m_item);
    end
    `uvm_info("SEQ", $sformatf("Done generation of %0d items", num), UVM_LOW)
  endtask
endclass



//***********************SEQUENCE2****************************

                                             //3)Writing walking ones,alternating ones and zeros in to the memory address and checking for design correctness.

class wr_sequence extends uvm_sequence#(reg_item);
  
  `uvm_object_utils(wr_sequence)
  
  function new(string name="wr_sequence");
    super.new(name);
  endfunction
  
  //int n=2;
  
  virtual task body();
    
    reg_item wr_item=reg_item::type_id::create("wr_item");
    wr_item.seq_3.constraint_mode(0);
    
    for(int i=0;i<7;i=i+1)
      
      begin
        
      start_item(wr_item);
      
        wr_item.randomize() with {wdataA=='hF0F0; wdataB=='hF0F0; wr==1; };
      
      finish_item(wr_item);
    end
`uvm_info(get_type_name(),$sformatf("Walking ones and zeros successful"),UVM_LOW)
  endtask
endclass

//****************SEQUENCE3***********************

                                                          //4) Consecutive read followed by writes on same address and write followed by read on same address

class sequence_3 extends uvm_sequence#(reg_item);
  
  `uvm_object_utils(sequence_3)
  
  function new(string name="sequence_3");
    super.new(name);
  endfunction
  
  //int num;

  
  //constraint seq_3{seq_item.wr dist {1:=50,0:=50}; }
  
  
  virtual task body();
    
    reg_item seq_item=reg_item::type_id::create("seq_item");
    seq_item.seq_3.constraint_mode(1);
    
    `uvm_info(get_type_name(),$sformatf("Starting consecutive write on same address"),UVM_LOW)

    
    for(int i=0;i<4;i=i+1)
      begin
        
       start_item(seq_item);
        
       seq_item.randomize() with {addrA=='h76; addrB=='hCC;};
        
       finish_item(seq_item);
        
      end
    `uvm_info(get_type_name(),$sformatf("Consecutive write successful"),UVM_LOW)
  endtask
endclass

//***********************SEQUENCE4**************************

class walking_ones_seq extends uvm_sequence#(write_xtn);
  
  `uvm_object_utils(walking_ones_seq)
  
  function new(string name="walking_ones_seq");
    super.new(name);
  endfunction
  
  task body();
    req = REQ::type_id::create("req");
    
    req.addressA.constraint_mode(0);
    
    `uvm_info(get_type_name(),"About to start walking one's pattern",UVM_LOW)
    
    for(int i=0;i<`DEPTH;i=i+1)
      begin
        start_item(req);
        assert(req.randomize() with {wr==1;addrA==i;wdataA==wr_data[i % 8];});
        finish_item(req);  
      end
    
  endtask
   
endclass

//***********************SEQUENCE5*********************

class walking_zeroes_seq extends uvm_sequence#(write_xtn);
  
  `uvm_object_utils(walking_zeroes_seq)
  
  function new(string name="walking_zeroes_seq");
    super.new(name);
  endfunction
  
  task body();
    
    req = REQ::type_id::create("req");
    
    req.addressB.constraint_mode(0);
    
    `uvm_info(get_type_name(),"About to start walking zeroes pattern",UVM_LOW)
    
    for(int j=0;j<`DEPTH;j++)
      begin
        start_item(req);
        assert(req.randomize() with { wr==1;addrB=j; wdataA == ~(wr_data[j%8]);});
        finish_item(req);
      end
  endtask
   
endclass


//*************************DRIVER******************************

class driver extends uvm_driver #(reg_item);              
  `uvm_component_utils(driver)
  function new(string name = "driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual reg_if vif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", vif))
      `uvm_fatal("DRV", "Could not get vif")
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      reg_item m_item;
      `uvm_info("DRV", $sformatf("Wait for item from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(m_item);
      drive_item(m_item);
      seq_item_port.item_done();
    end
  endtask
  
  virtual task drive_item(reg_item m_item);
      vif.sel <= 1;
      vif.addrA <= m_item.addrA;
      vif.addrB	<= m_item.addrB;
      vif.wr 	<= m_item.wr;
      vif.wdataA <= m_item.wdataA;
      vif.wdataB <= m_item.wdataB;
      @ (posedge vif.clk);
      while (!vif.ready)  begin
        `uvm_info("DRV", "Wait until ready is high", UVM_LOW)
        @(posedge vif.clk);
      end
      
      vif.sel <= 0;  
  endtask
endclass


//**********************MONITOR******************************
    
    
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  function new(string name="monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  uvm_analysis_port  #(reg_item) mon_analysis_port;
  virtual reg_if vif;
  semaphore sema4;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", vif))
      `uvm_fatal("MON", "Could not get vif")
    sema4 = new(1);
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      @ (posedge vif.clk);
      if (vif.sel) begin
        reg_item item = reg_item::type_id::create("item");
        item.addrA = vif.addrA;
        item.addrB =vif.addrB;
        item.wr = vif.wr;
        item.wdataA= vif.wdataA;
        item.wdataB= vif.wdataB;

        if (!vif.wr) begin
          @(posedge vif.clk);
        	item.rdataA = vif.rdataA;
            item.rdataB =vif.rdataB;
        end
        `uvm_info(get_type_name(), $sformatf("Monitor found packet %s", item.convert2str()), UVM_LOW)
        mon_analysis_port.write(item);
      end
    end
  endtask
endclass


 //***********************SCOREBOARD********************************
    
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  uvm_analysis_imp #(reg_item,scoreboard) mon_analy_imp;
  
  reg_item refq[`DEPTH];
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_analy_imp=new("mon_analy_imp",this);
  endfunction
  
  virtual function void write(reg_item item);
    if(item.wr)
      begin
        if(refq[item.addrA]==null ||refq[item.addrB]==null)
          begin
          refq[item.addrA]=new;
           refq[item.addrA]=item;
           refq[item.addrB]=new;
           refq[item.addrB]=item;
            
            `uvm_info(get_type_name(),$sformatf("Store addrA 0x%0h addrB 0x%0h wrdataA 0x%0h wrdataB  0x%0h ", item.addrA,item.addrB,item.wdataA, item.wdataB),UVM_LOW)
        
          end
     
        
        /*else if(item.addrA==item.addrB)
          begin
              `uvm_info(get_type_name(),$sformatf("Prioritizing address pointed by A port addrA 0x%0h addrB 0x%0h wrdataA 0x%0h wrdataB 0x%0h", item.addrA,item.addrB,item.wdataA, item.wdataB),UVM_LOW)
          end*/
        
        else
          begin
            refq[item.addrA]=item;
            refq[item.addrB]=item;
            
               `uvm_info(get_type_name(),$sformatf("Updating value addrA 0x%0h addrB 0x%0h wrdataA 0x%0h wrdataB  0x%0h ", item.addrA,item.addrB,item.wdataA, item.wdataB),UVM_LOW)
          end
      end
    

    if(!item.wr)
       begin
         if(refq[item.addrA]==null)
           begin
             if(item.rdataA !='h2567)
               `uvm_error(get_type_name(),$sformatf("addrA 0x%0h actA 'h2567 expA 0x%0h ",item.addrA,item.rdataA))
             
             else
               
               `uvm_info(get_type_name(),$sformatf("PASS at first time addrA 0x%0h  act 'h2567 expA 0x%0h",item.addrA,item.rdataA),UVM_LOW)
              
               end
               
               else begin 
                 if(item.rdataA!=refq[item.addrA].wdataA)
                   
                   `uvm_error(get_type_name(),$sformatf("FAIL! addrA 0x%0h act dataA 0x%0h exp_dataA 0x%0h",item.addrA,refq[item.addrA].wdataA,item.rdataA))
                  
                   else 
                     
                     `uvm_info(get_type_name(),$sformatf("PASS! addrA 0x%0h act dataA 0x%0h exp_dataA 0x%0h",item.addrA,refq[item.addrA].wdataA,item.rdataA),UVM_LOW)
                      
                   end
                     
         if(refq[item.addrB]==null)
                 begin
                   if(item.rdataB !='h2567)
                     `uvm_error(get_type_name(),$sformatf("addrB 0x%0h  act 'h2567  expB 0x%0h",item.addrB,item.rdataB))
             
             else
               
               `uvm_info(get_type_name(),$sformatf("PASS at first time addrB 0x%0h act 'h2567  expB 0x%0h",item.addrB,item.rdataB),UVM_LOW)
               
               end
               
             else begin 
               if(item.rdataB!=refq[item.addrB].wdataB)
                   
                 `uvm_error(get_type_name(),$sformatf("FAIL! addrB 0x%0h   act dataB 0x%0h exp_dataB 0x%0h",item.addrB, refq[item.addrB].wdataB,item.rdataB))
                  
                   else     
                     `uvm_info(get_type_name(),$sformatf("PASS! addrB 0x%0h   act dataB 0x%0h exp_dataB 0x%0h",item.addrB, refq[item.addrB].wdataB,item.rdataB),UVM_LOW)
                      
                  end
                     
                     end
               
        endfunction
endclass
             
 //**************************AGENT*************************             

class agent extends uvm_agent;
  `uvm_component_utils(agent)
  function new(string name="agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  driver 		d0; 		// Driver handle
  monitor 		m0; 		// Monitor handle
  uvm_sequencer #(reg_item)	s0; 		// Sequencer Handle

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    s0 = uvm_sequencer#(reg_item)::type_id::create("s0", this);
    d0 = driver::type_id::create("d0", this);
    m0 = monitor::type_id::create("m0", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d0.seq_item_port.connect(s0.seq_item_export);
  endfunction

endclass
               
//***********************COVERAGE*****************************
               
               
 class my_coverage extends uvm_subscriber #(reg_item);
   
   `uvm_component_utils(my_coverage)
   
  
 reg_item t;
   
 real cov;
  
  covergroup cg_addr;
    option.per_instance=1;
    
    ADDRESS_A:  coverpoint t.addrA 
               {
                 bins addressA[] = {'h76 ,'h12, 'h30,'hEE,'h00,'h72};
               }
    ADDRESS_B: coverpoint t.addrB
                {
                  bins addressB[] = {'h21, 'hCD ,'hCC ,'h8A ,'hFF,'h54}; 
                }
    READ_WRITE: coverpoint t.wr
                {
                  bins read_write[]={0,1};
                }
   WRITE_DATAa: coverpoint t.wdataA{option.auto_bin_max=64;}
               
   WRITE_DATAb: coverpoint t.wdataB{option.auto_bin_max=32;}
        
   ADDAxADDB:   cross ADDRESS_A,ADDRESS_B;
    
   ADDAxADDBxRD: cross ADDRESS_A,ADDRESS_B,READ_WRITE;
    
  endgroup
   
       
 
   function new(string name= "my_coverage",uvm_component p=null);
    super.new(name,p);
    cg_addr=new();
  endfunction
  
  
  
   virtual function void write(reg_item t);
     this.t=t;
     cg_addr.sample();
  endfunction 
   
   function void extract_phase(uvm_phase phase);
     super.extract_phase(phase);
     cov= cg_addr.get_inst_coverage();
   endfunction
   
   function void report_phase(uvm_phase phase);
     super.report_phase(phase);
     `uvm_info(get_type_name(),$sformatf("Coverage is: %0.2f",cov),UVM_LOW)
   endfunction
   
    
endclass   
               
//What if it writes/reads on/from two same Address
            
               
//**********************ENVIRONMENT************************
               
class env extends uvm_env;
  `uvm_component_utils(env)
  
  agent 		a0; 		// Agent handle
  scoreboard	sb0;   // Scoreboard handle
  my_coverage      cb0;
  
   function new(string name="env", uvm_component parent=null);
     super.new(name, parent);
  endfunction
  
    
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a0 = agent::type_id::create("a0", this);
    sb0 = scoreboard::type_id::create("sb0", this);
    cb0 = my_coverage ::type_id::create("cb0",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a0.m0.mon_analysis_port.connect(sb0.mon_analy_imp);
    a0.m0.mon_analysis_port.connect(cb0.analysis_export);
  endfunction
endclass


//**********************TEST*********************
               
class test extends uvm_test;
  `uvm_component_utils(test)
  
    my_coverage cb0;
  
  function new(string name = "test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  env e0;
  virtual reg_if vif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e0 = env::type_id::create("e0", this);
    if (!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", vif))
      `uvm_fatal("TEST", "Did not get vif")
      
      uvm_config_db#(virtual reg_if)::set(this, "e0.a0.*", "reg_vif", vif);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    
    gen_item_seq seq = gen_item_seq::type_id::create("seq");
    wr_sequence wr_seq=wr_sequence::type_id::create("wr_seq");
    sequence_3  cs_wr=sequence_3::type_id::create("cs_wr");
    
    phase.raise_objection(this);
    apply_reset();
    
    void'(  seq.randomize() with {num inside {[40:60]}; });
    fork
      
    wr_seq.start(e0.a0.s0);
    seq.start(e0.a0.s0);
  
      
    join
    
    
    cs_wr.start(e0.a0.s0);
    
    #200;
      
    phase.drop_objection(this);
  endtask
  
  virtual task apply_reset();
    vif.rstn <= 0;
    repeat(5) @ (posedge vif.clk);
    vif.rstn <= 1;
    repeat(10) @ (posedge vif.clk);
  endtask
endclass

//**************************INTERFACE********************
               
interface reg_if (input bit clk);
  logic rstn;
  logic [7:0] addrA;
  logic [7:0] addrB;
  logic [15:0] wdataA;
  logic [15:0] wdataB;
  logic [15:0] rdataA;
  logic[15:0] rdataB;
  logic 		wr;
  logic 		sel;
  logic 		ready;
endinterface
    
//*****************TOP**********************************
module tb;
  reg clk;
  
  always #10 clk =~ clk;
  reg_if _if (clk);
  
  dual_port u0 (.clk (clk),
               .addrA (_if.addrA),
               .addrB(_if.addrB),
               .rstn(_if.rstn),
               .sel  (_if.sel),
               .wr (_if.wr),
               .wdataA (_if.wdataA),
               .wdataB(_if.wdataB),
               .rdataA (_if.rdataA),
               .rdataB(_if.rdataB),
            .ready (_if.ready));
  
  test t0;
  
  initial begin
    clk <= 0;
    uvm_config_db#(virtual reg_if)::set(null, "uvm_test_top", "reg_vif", _if);
    run_test("test");
  end
endmodule
