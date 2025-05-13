`include "uvm_macros.svh"
 import uvm_pkg::*;

//-----------------------------------------------------------------------------------------------------
//                                       Transaction 

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  
   
    rand logic [16:0] baud;
    rand logic rst;
    logic tx_clk;
    real period;
    
  constraint baud_c   { baud inside {4800,9600,14400,19200,38400,57600}; }
  constraint rst_dist { rst dist {1 := 1, 0 := 99};}

  function new(string name = "transaction");
    super.new(name);
  endfunction

endclass 

//-----------------------------------------------------------------------------------------------------
//                                   Variable baud rate                        

class generator extends uvm_sequence#(transaction);
  `uvm_object_utils(generator)
  
  transaction tr;

  function new(string name = "variable_baud");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(10)
      begin
        tr = transaction::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize);
        `uvm_info("Gen",$sformatf("Baud : %0d  , rst : %0d",tr.baud , tr.rst ), UVM_NONE);
        finish_item(tr);
      end
  endtask
  

endclass
//-----------------------------------------------------------------------------------------------------
//                                          Driver 


class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  virtual clk_if vif;
  transaction tr;
  
  
  function new(input string path = "drv", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
 virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     tr = transaction::type_id::create("tr");
      
   if(!uvm_config_db#(virtual clk_if)::get(this,"","vif",vif)) 
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  
   virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(tr);
      
      vif.rst  <= tr.rst;
      vif.baud <= tr.baud;
      
      `uvm_info("DRV",$sformatf("Baud : %0d , rst : %0d ",tr.baud, tr.rst), UVM_NONE);
                  
      repeat(2)@(posedge vif.tx_clk);
          
      seq_item_port.item_done();
    end
  endtask
  
endclass
//-------------------------------------------------------------------------------------------------------
//                                        Monitor 

class mon extends uvm_monitor;
`uvm_component_utils(mon)

  uvm_analysis_port#(transaction) send;  //  send  to  SCO 

transaction tr;
virtual clk_if vif;

  real ton  = 0;
  real toff = 0;
  
      function new(input string inst = "mon", uvm_component parent = null);
    super.new(inst,parent);
    endfunction
  
    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      send = new("send", this);
      
      tr = transaction::type_id::create("tr");
      
      if(!uvm_config_db#(virtual clk_if)::get(this,"","vif",vif)) 
          `uvm_error("mon","Unable to access Interface");
    endfunction
  
      
    virtual task run_phase(uvm_phase phase);
    forever begin
    @(posedge vif.clk);
      if(vif.rst)
        begin
          tr.rst = 0;
          ton    = 0;
          toff   = 0;
        `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
        send.write(tr);
        end
      else
         begin
          tr.baud = vif.baud;
          ton     = 0;
          toff    = 0; 
           @(posedge vif.tx_clk);
           ton = $realtime;
           @(posedge vif.tx_clk);
           toff = $realtime;
           tr.period = toff - ton;
           
           `uvm_info("MON",$sformatf("Baud : %0d Period:%0f",tr.baud,tr.period), UVM_NONE);
           send.write(tr);

         end

    end
 endtask
  
endclass
//----------------------------------------------------------------------------------------------------
//                                        Scoreboard 

 class sco extends uvm_scoreboard;
`uvm_component_utils(sco)

  real count = 0;
  real baudcount = 0;
  uvm_analysis_imp#(transaction,sco) recv;

    function new(input string inst = "sco", uvm_component parent = null);
    super.new(inst,parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
    endfunction
    
    
  virtual function void write(transaction tr);
    count =  tr.period / 20;
    baudcount = count;
    `uvm_info("SCO", $sformatf("BAUD:%0d count:%0f bcount:%0f", tr.baud,count, baudcount), UVM_NONE);
    case(tr.baud)
      
      4800: begin
        if(baudcount == 10418)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
      end
          
          
      9600: begin
        if(baudcount == 5210)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED") 
        
      end
          
      14400: begin
        if(baudcount == 3474)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
      end
        
      19200: begin
        if(baudcount == 2606)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
        
      end
        
      38400: begin
        if(baudcount == 1304)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
        
      end
        
      57600: begin
        if(baudcount == 870)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
      end
          
          endcase  
          $display("-------------------------------------------------------------------------------------");

  endfunction

endclass
//-------------------------------------------------------------------------------------------------------
//                                           Agent

                  
                  
class agent extends uvm_agent;
`uvm_component_utils(agent)
  
  

function new(input string inst = "agent", uvm_component parent = null);
super.new(inst,parent);
endfunction

 driver d;
 uvm_sequencer#(transaction) seqr;
 mon m;


virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
   m = mon::type_id::create("m",this);
   d = driver::type_id::create("d",this);
   seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
  
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
endfunction

endclass
//-----------------------------------------------------------------------------------------------------
//                                     Enviroment 
 
class env extends uvm_env;
`uvm_component_utils(env)

function new(input string inst = "env", uvm_component c);
super.new(inst,c);
endfunction

agent a;
sco s;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  a = agent::type_id::create("a",this);
  s = sco::type_id::create("s", this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
 a.m.send.connect(s.recv);
endfunction

endclass

//-------------------------------------------------------------------------------------------------------
//                                          Test 

class test extends uvm_test;
`uvm_component_utils(test)

  env e;
  generator gen;

   
function new(input string inst = "test", uvm_component c);
super.new(inst,c);
endfunction
  
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
 
  e   =  env::type_id::create("env",this);  
  gen = generator::type_id::create("gen");
  
endfunction

virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
gen.start(e.a.seqr);
#50;
phase.drop_objection(this);
endtask
endclass  

//-----------------------------------------------------------------------------------------------------    
//                                       TestBench 


module tb;
  
  
  clk_if vif();
  
  clk_gen dut (.clk(vif.clk),.rst(vif.rst), .baud(vif.baud), .tx_clk(vif.tx_clk));
  

  initial begin
    vif.clk <= 0;
  end

  always #10 vif.clk <= ~vif.clk; //  if  your  clock  is  50Mhz--->T=20ns

  
  
  initial begin
    uvm_config_db#(virtual clk_if)::set(null, "*", "vif", vif);
    run_test("test");
   end
  
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  
endmodule
