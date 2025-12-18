`include "uvm_macros.svh"
import uvm_pkg::*;



///configuration of environment///
class fifo_config extends uvm_object;
    `uvm_object_utils(fifo_config)
    
    function new(input string path = "fifo_config");
        super.new(path);
    endfunction
    
    uvm_active_passive_enum agent_type = UVM_ACTIVE;
endclass



///transaction class///
class transaction extends uvm_sequence_item;
    `uvm_object_utils(transaction)
    
    rand bit wr;
    rand bit rd;
    rand bit[7:0] din;
    
    bit rst;
    bit[7:0] dout;
    bit empty;
    bit full;
    bit overflow;
    bit underflow;
    
    function new(input string path = "transaction");
        super.new(path);
    endfunction
endclass



///generator -> write only, read only (underflow), write then read, overflow, simultaneous write and read///

///write only sequence///
class write_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(write_seq)
    
    transaction t;
    
    function new(input string path = "write_seq");
        super.new(path);
    endfunction
    
    virtual task body();
        repeat(16) begin
            t = transaction :: type_id :: create("t");
            start_item(t);
                assert(t.randomize());
                t.wr = 1'b1;            //write flag set
                t.rd = 1'b0;
            finish_item(t);
        end
    endtask 
endclass


//read only sequence//
class read_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(read_seq)
    
    transaction t;
    
    function new(input string path = "read_seq");
        super.new(path);
    endfunction
    
    virtual task body();
        repeat(16) begin
            t = transaction :: type_id :: create("t");
            start_item(t);
                t.wr = 1'b0;
                t.rd = 1'b1;            //read flag set
            finish_item(t);
        end
    endtask 
endclass

//write then read//
class write_read_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(write_read_seq)
    
    transaction t;
    
    function new(input string path = "write_read_seq");
        super.new(path);
    endfunction
    
    virtual task body();
        repeat(16) begin
            t = transaction :: type_id :: create("t");
            start_item(t);
                assert(t.randomize());
                t.wr = 1'b1;
                t.rd = 1'b0;            
            finish_item(t);
        end
        
        repeat(16) begin
            t = transaction :: type_id :: create("t");
            start_item(t);
                assert(t.randomize());
                t.wr = 1'b0;
                t.rd = 1'b1;            
            finish_item(t);
        end
    endtask 
endclass

//overflow
class overflow_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(overflow_seq)
    
    transaction t;
    
    function new(input string path = "overflow_seq");
        super.new(path);
    endfunction
    
    virtual task body();
        repeat(20) begin
            t = transaction :: type_id :: create("t");
            start_item(t);
                assert(t.randomize());
                t.wr = 1'b1;            //write flag set
                t.rd = 1'b0;
            finish_item(t);
        end
    endtask 
endclass

//simultaneous write and read
class simultaneous_rw_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(simultaneous_rw_seq)

    transaction t;
    
    function new(input string path = "simultaneous_rw_seq");
        super.new(path);
    endfunction

    task body();
        repeat (10) begin
            t = transaction::type_id::create("t");
            start_item(t);
                t.wr = 1'b1;
                t.rd = 1'b1;
                assert(t.randomize());
            finish_item(t);
        end
    endtask
endclass



///driver///
class driver extends uvm_driver #(transaction);
    `uvm_component_utils(driver)
    
    virtual fifo_if vif;
    transaction t;
    
    function new(input string path = "driver", uvm_component parent = null);
        super.new(path, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        t = transaction :: type_id :: create("t");
        if(!uvm_config_db #(virtual fifo_if) :: get(this, "", "vif", vif))
            `uvm_error("DRV", "Unable to access virtual interface");
    endfunction
    
    task reset_dut();
        repeat(2)
            begin
                vif.rst <= 1'b1;
                vif.wr <= 1'b0;
                vif.rd <= 1'b0;
                vif.din <= 1'b0;
                `uvm_info("DRV", "FIFO Reset", UVM_NONE)
                @(posedge vif.clk);
                vif.rst <= 1'b0;
            end
    endtask     
    
    task drive();
        reset_dut();
        forever begin
            seq_item_port.get_next_item(t);
                vif.rst <= 1'b0;
                vif.wr <= t.wr;
                vif.rd <= t.rd;
                vif.din <= t.din;
                `uvm_info("DRV", $sformatf("wr=%0d | rd=%0d | din=%0d",t.wr, t.rd, t.din), UVM_NONE)
                @(posedge vif.clk);
            seq_item_port.item_done(t);
        end
    endtask
    
    virtual task run_phase(uvm_phase phase);
        drive();
    endtask 
      
endclass



///monitor///
class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)
    
    transaction t;
    virtual fifo_if vif;
    uvm_analysis_port #(transaction) send;
    
    function new(input string path = "monitor", uvm_component parent = null);
        super.new(path, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        t = transaction :: type_id :: create("t");
        send = new("send", this);
        if(!uvm_config_db #(virtual fifo_if) :: get(this, "", "vif", vif))
            `uvm_error("MON", "Unable to access virtual interface");
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            t.wr = vif.wr;
            t.rd = vif.rd;
            t.din = vif.din;
            t.dout = vif.dout;
            t.empty = vif.empty;
            t.full = vif.full;
            t.overflow = vif.overflow;
            t.underflow = vif.underflow;
            `uvm_info("MON",
              $sformatf("wr=%0d rd=%0d din=%0d dout=%0d empty=%0d full=%0d ovf=%0d udf=%0d",
                        t.wr, t.rd, t.din, t.dout,
                        t.empty, t.full, t.overflow, t.underflow),
              UVM_LOW)
            send.write(t);
        end
    endtask
endclass



///scoreboard///
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  uvm_analysis_imp #(transaction, scoreboard) recv;

  // Reference model of FIFO
  byte fifo_model[$];

  function new(input string path = "scoreboard", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
  endfunction

  
  virtual function void write(transaction t);

    // Handle reset
    if (t.rst) begin
      fifo_model.delete();
      `uvm_info("SCO", "FIFO model reset", UVM_MEDIUM)
      return;
    end

    // WRITE ONLY
    if (t.wr && !t.rd) begin
      if (fifo_model.size() < 16) begin
        fifo_model.push_back(t.din);
      end
      else begin
        // FIFO full → overflow expected
        if (!t.overflow)
          `uvm_error("SCO", "Expected OVERFLOW, but overflow flag not asserted")
      end
    end

    // READ ONLY
    else if (t.rd && !t.wr) begin
      if (fifo_model.size() > 0) begin
        byte exp_data;
        exp_data = fifo_model.pop_front();

        if (t.dout !== exp_data)
          `uvm_error("SCO",
            $sformatf("DATA MISMATCH: Expected %0d, Got %0d",
                      exp_data, t.dout))
        else
          `uvm_info("SCO", "READ DATA MATCH", UVM_LOW)
      end
      else begin
        // FIFO empty → underflow expected
        if (!t.underflow)
          `uvm_error("SCO", "Expected UNDERFLOW, but underflow flag not asserted")
      end
    end

    // SIMULTANEOUS READ WRITE
    else if (t.wr && t.rd) begin
      if (fifo_model.size() > 0 && fifo_model.size() < 16) begin
        byte exp_data;
        exp_data = fifo_model.pop_front();
        fifo_model.push_back(t.din);

        if (t.dout !== exp_data)
          `uvm_error("SCO",
            $sformatf("SIMUL RW MISMATCH: Expected %0d, Got %0d",
                      exp_data, t.dout))
      end
    end

    // CHECK FLAGS
    if ((fifo_model.size() == 0) && !t.empty)
      `uvm_error("SCO", "EMPTY flag incorrect")

    if ((fifo_model.size() == 16) && !t.full)
      `uvm_error("SCO", "FULL flag incorrect")

    $display("-----------------------------------------------");
  endfunction
endclass



///agent///
class agent extends uvm_agent;
    `uvm_component_utils(agent)
    
    fifo_config cfg;
    driver d;
    monitor m;
    uvm_sequencer #(transaction) seqr;
    
    function new(string name="agent", uvm_component parent=null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = fifo_config :: type_id :: create("cfg");
        m = monitor :: type_id :: create("m", this);
        
        if (cfg.agent_type == UVM_ACTIVE) begin
            d = driver :: type_id :: create("d", this);
            seqr = uvm_sequencer#(transaction):: type_id :: create("seqr", this);
        end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.agent_type == UVM_ACTIVE) begin
            d.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass




///environment///
class env extends uvm_env;
    `uvm_component_utils(env)
    
    agent a;
    scoreboard s;
    
    function new(input string path = "env", uvm_component parent = null);
        super.new(path, parent);
    endfunction 
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a = agent :: type_id :: create("a", this);
        s = scoreboard :: type_id :: create("s", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a.m.send.connect(s.recv);
    endfunction
endclass



///test///
class test extends uvm_test;
  `uvm_component_utils(test)

  env e;

  write_seq wseq;
  read_seq rseq;
  write_read_seq wrseq;
  overflow_seq ovseq;
  simultaneous_rw_seq simseq;

  function new(string name="test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    e      = env::type_id::create("e", this);

    wseq   = write_seq          ::type_id::create("wseq");
    rseq   = read_seq           ::type_id::create("rseq");
    wrseq  = write_read_seq     ::type_id::create("wrseq");
    ovseq  = overflow_seq       ::type_id::create("ovseq");
    simseq = simultaneous_rw_seq::type_id::create("simseq");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
        wseq.start(e.a.seqr);
        #20;
    phase.drop_objection(this);
  endtask
endclass



///top////
module tb;

  fifo_if vif();

  FIFO dut (
    .clk       (vif.clk),
    .rst       (vif.rst),
    .wr        (vif.wr),
    .rd        (vif.rd),
    .din       (vif.din),
    .dout      (vif.dout),
    .empty     (vif.empty),
    .full      (vif.full),
    .overflow  (vif.overflow),
    .underflow (vif.underflow)
  );

  initial vif.clk = 1'b0;
  always #10 vif.clk = ~vif.clk;

  initial begin
    uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);
    run_test("test");
  end
endmodule
