onerror resume
wave tags  F0
wave pane split 0
wave pane activate 0
wave update off
wave zoom range 15799 34072
wave update on
wave top 0
wave pane activate 1
wave update off
wave comment {Master[0]}
wave group {m_AW_channel[0]} -backgroundcolor #004466
wave add -group {m_AW_channel[0]} {axi_interconnect_tb.dut.m_AWID[0]} -tag F0 -label {m_AWID[0]} -radix hexadecimal
wave add -group {m_AW_channel[0]} {axi_interconnect_tb.m_AWADDR[0]} -tag F0 -label {m_AWADDR[0]} -radix hexadecimal
wave add -group {m_AW_channel[0]} {axi_interconnect_tb.dut.m_AWLEN[0]} -tag F0 -label {m_AWLEN[0]} -radix hexadecimal
wave add -group {m_AW_channel[0]} {axi_interconnect_tb.dut.m_AWSIZE[0]} -tag F0 -label {m_AWSIZE[0]} -radix hexadecimal
wave add -group {m_AW_channel[0]} {axi_interconnect_tb.dut.m_AWVALID[0]} -tag F0 -label {m_AWVALID[0]} -radix hexadecimal
wave add -group {m_AW_channel[0]} {axi_interconnect_tb.dut.m_AWREADY[0]} -tag F0 -label {m_AWREADY[0]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave group {m_W_channel[0]} -backgroundcolor #006666
wave add -group {m_W_channel[0]} {axi_interconnect_tb.dut.m_WVALID[0]} -tag F0 -label {m_WVALID[0]} -radix hexadecimal
wave add -group {m_W_channel[0]} {axi_interconnect_tb.dut.m_WREADY[0]} -tag F0 -label {m_WREADY[0]} -radix hexadecimal
wave add -group {m_W_channel[0]} {axi_interconnect_tb.dut.m_WLAST[0]} -tag F0 -label {m_WLAST[0]} -radix hexadecimal
wave add -group {m_W_channel[0]} {axi_interconnect_tb.dut.m_WDATA[0]} -tag F0 -label {m_WDATA[0]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave group {m_B_channel[0]} -backgroundcolor #226600
wave add -group {m_B_channel[0]} {axi_interconnect_tb.dut.m_BREADY[0]} -tag F0 -label {m_BREADY[0]} -radix hexadecimal
wave add -group {m_B_channel[0]} {axi_interconnect_tb.dut.m_BVALID[0]} -tag F0 -label {m_BVALID[0]} -radix hexadecimal
wave add -group {m_B_channel[0]} {axi_interconnect_tb.dut.m_BRESP[0]} -tag F0 -label {m_BRESP[0]} -radix hexadecimal
wave comment -group {m_B_channel[0]} {Master[1]}
wave insertion [expr [wave index insertpoint] + 1]
wave group {m_AW_channel[1]} -backgroundcolor #666600
wave add -group {m_AW_channel[1]} {axi_interconnect_tb.dut.m_AWADDR[1]} -tag F0 -label {m_AWADDR[1]} -radix hexadecimal
wave add -group {m_AW_channel[1]} {axi_interconnect_tb.dut.m_AWLEN[1]} -tag F0 -label {m_AWLEN[1]} -radix hexadecimal
wave add -group {m_AW_channel[1]} {axi_interconnect_tb.dut.m_AWVALID[1]} -tag F0 -label {m_AWVALID[1]} -radix hexadecimal
wave add -group {m_AW_channel[1]} {axi_interconnect_tb.dut.m_AWREADY[1]} -tag F0 -label {m_AWREADY[1]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave group {m_W_channel[1]} -backgroundcolor #664400
wave add -group {m_W_channel[1]} {axi_interconnect_tb.dut.m_WDATA[1]} -tag F0 -label {m_WDATA[1]} -radix hexadecimal
wave add -group {m_W_channel[1]} {axi_interconnect_tb.dut.m_WLAST[1]} -tag F0 -label {m_WLAST[1]} -radix hexadecimal
wave add -group {m_W_channel[1]} {axi_interconnect_tb.dut.m_WVALID[1]} -tag F0 -label {m_WVALID[1]} -radix hexadecimal
wave add -group {m_W_channel[1]} {axi_interconnect_tb.dut.m_WREADY[1]} -tag F0 -label {m_WREADY[1]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave add {axi_interconnect_tb.dut.genblk4[1].dispatcher.sa_WREADY_i} -tag F0 -label {sa_WREADY_i} -radix hexadecimal
wave comment {Master[2]}
wave group {m_AW_channel[2]} -backgroundcolor #660000
wave add -group {m_AW_channel[2]} {axi_interconnect_tb.dut.m_AWADDR[2]} -tag F0 -label {m_AWADDR[2]} -radix hexadecimal
wave add -group {m_AW_channel[2]} {axi_interconnect_tb.dut.m_AWLEN[2]} -tag F0 -label {m_AWLEN} -radix hexadecimal
wave add -group {m_AW_channel[2]} {axi_interconnect_tb.dut.m_AWVALID[2]} -tag F0 -label {m_AWVALID} -radix hexadecimal
wave add -group {m_AW_channel[2]} {axi_interconnect_tb.dut.m_AWREADY[2]} -tag F0 -label {m_AWREADY} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave group {m_W_channel[2]} -backgroundcolor #660066
wave add -group {m_W_channel[2]} {axi_interconnect_tb.dut.m_WDATA[2]} -tag F0 -label {m_WDATA[2]} -radix hexadecimal
wave add -group {m_W_channel[2]} {axi_interconnect_tb.dut.m_WLAST[2]} -tag F0 -label {m_WLAST[2]} -radix hexadecimal
wave add -group {m_W_channel[2]} {axi_interconnect_tb.dut.m_WVALID[2]} -tag F0 -label {m_WVALID[2]} -radix hexadecimal
wave add -group {m_W_channel[2]} {axi_interconnect_tb.dut.m_WREADY[2]} -tag F0 -label {m_WREADY[2]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave add {axi_interconnect_tb.dut.genblk4[2].dispatcher.write_channel.AW_W_disable} -tag F0 -label {AW_W_disable} -radix hexadecimal
wave add {axi_interconnect_tb.dut.genblk4[2].dispatcher.write_channel.sa_WREADY_i} -tag F0 -label {sa_WREADY_i} -radix hexadecimal -expand -subitemconfig { {axi_interconnect_tb.dut.genblk4[2].dispatcher.write_channel.sa_WREADY_i[1]} {-radix hexadecimal} {axi_interconnect_tb.dut.genblk4[2].dispatcher.write_channel.sa_WREADY_i[0]} {-radix hexadecimal} }
wave add {axi_interconnect_tb.dut.genblk4[2].dispatcher.write_channel.AW_W_slv_id} -tag F0 -label {AW_W_slv_id} -radix hexadecimal
wave comment {Master[3]}
wave group {m_W_channel[3]} -backgroundcolor #440066
wave add -group {m_W_channel[3]} {axi_interconnect_tb.dut.m_WDATA[3]} -tag F0 -label {m_WDATA[3]} -radix hexadecimal
wave add -group {m_W_channel[3]} {axi_interconnect_tb.dut.m_WLAST[3]} -tag F0 -label {m_WLAST[3]} -radix hexadecimal
wave add -group {m_W_channel[3]} {axi_interconnect_tb.dut.m_WVALID[3]} -tag F0 -label {m_WVALID[3]} -radix hexadecimal
wave add -group {m_W_channel[3]} {axi_interconnect_tb.dut.m_WREADY[3]} -tag F0 -label {m_WREADY[3]} -radix hexadecimal
wave comment -group {m_W_channel[3]} {Slave[0]}
wave insertion [expr [wave index insertpoint] + 1]
wave group {s_AW_channel[0]} -backgroundcolor #004466
wave add -group {s_AW_channel[0]} {axi_interconnect_tb.s_AWID[0]} -tag F0 -label {s_AWID[0]} -radix hexadecimal
wave add -group {s_AW_channel[0]} {axi_interconnect_tb.s_AWADDR[0]} -tag F0 -label {s_AWADDR[0]} -radix hexadecimal
wave add -group {s_AW_channel[0]} {axi_interconnect_tb.s_AWLEN[0]} -tag F0 -label {s_AWLEN[0]} -radix hexadecimal
wave add -group {s_AW_channel[0]} {axi_interconnect_tb.s_AWSIZE[0]} -tag F0 -label {s_AWSIZE[0]} -radix hexadecimal
wave add -group {s_AW_channel[0]} {axi_interconnect_tb.s_AWVALID[0]} -tag F0 -label {s_AWVALID[0]} -radix hexadecimal
wave add -group {s_AW_channel[0]} {axi_interconnect_tb.s_AWREADY[0]} -tag F0 -label {s_AWREADY[0]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave group {s_W_channel[0]} -backgroundcolor #006666
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.s_WDATA[0]} -tag F0 -label {s_WDATA[0]} -radix hexadecimal
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.s_WLAST[0]} -tag F0 -label {s_WLAST[0]} -radix hexadecimal
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.s_WVALID[0]} -tag F0 -label {s_WVALID[0]} -radix hexadecimal
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.s_WREADY[0]} -tag F0 -label {s_WREADY[0]} -radix hexadecimal
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.genblk5[0].slave_arbitration.W_channel.s_WDATA_o_r} -tag F0 -radix hexadecimal
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.genblk5[0].slave_arbitration.W_channel.s_WVALID_o_r} -tag F0 -radix hexadecimal
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.genblk5[0].slave_arbitration.W_channel.ssb_bwd_ready} -tag F0 -radix hexadecimal
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.genblk5[0].slave_arbitration.W_channel.WDATA_channel_shift_en} -tag F0 -radix hexadecimal
wave add -group {s_W_channel[0]} {axi_interconnect_tb.dut.genblk5[0].slave_arbitration.W_channel.transaction_boot} -tag F0 -radix hexadecimal -select
wave insertion [expr [wave index insertpoint] + 1]
wave group {s_B_channel[0]} -backgroundcolor #226600
wave add -group {s_B_channel[0]} {axi_interconnect_tb.s_BID[0]} -tag F0 -label {s_BID[0]} -radix hexadecimal
wave add -group {s_B_channel[0]} {axi_interconnect_tb.s_BVALID[0]} -tag F0 -label {s_BVALID[0]} -radix hexadecimal
wave add -group {s_B_channel[0]} {axi_interconnect_tb.s_BREADY[0]} -tag F0 -label {s_BREADY[0]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave comment {Slave[1]}
wave group {s_AW_channel[1]} -backgroundcolor #666600
wave add -group {s_AW_channel[1]} {axi_interconnect_tb.s_AWID[1]} -tag F0 -label {s_AWID[1]} -radix hexadecimal
wave add -group {s_AW_channel[1]} {axi_interconnect_tb.s_AWADDR[1]} -tag F0 -label {s_AWADDR[1]} -radix hexadecimal
wave add -group {s_AW_channel[1]} {axi_interconnect_tb.s_AWLEN[1]} -tag F0 -label {s_AWLEN[1]} -radix hexadecimal
wave add -group {s_AW_channel[1]} {axi_interconnect_tb.s_AWSIZE[1]} -tag F0 -label {s_AWSIZE[1]} -radix hexadecimal
wave add -group {s_AW_channel[1]} {axi_interconnect_tb.s_AWVALID[1]} -tag F0 -label {s_AWVALID[1]} -radix hexadecimal
wave add -group {s_AW_channel[1]} {axi_interconnect_tb.s_AWREADY[1]} -tag F0 -label {s_AWREADY[1]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave group {s_W_channel[1]} -backgroundcolor #664400
wave add -group {s_W_channel[1]} {axi_interconnect_tb.s_WDATA[1]} -tag F0 -label {s_WDATA[1]} -radix hexadecimal -foregroundcolor Yellow
wave add -group {s_W_channel[1]} {axi_interconnect_tb.s_WLAST[1]} -tag F0 -label {s_WLAST[1]} -radix hexadecimal -foregroundcolor Yellow
wave add -group {s_W_channel[1]} {axi_interconnect_tb.s_WVALID[1]} -tag F0 -label {s_WVALID[1]} -radix hexadecimal -foregroundcolor Gold
wave add -group {s_W_channel[1]} {axi_interconnect_tb.s_WREADY[1]} -tag F0 -label {s_WREADY[1]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave group {s_B_channel[1]} -backgroundcolor #660000
wave add -group {s_B_channel[1]} {axi_interconnect_tb.s_BID[1]} -tag F0 -label {s_BID[1]} -radix hexadecimal
wave add -group {s_B_channel[1]} {axi_interconnect_tb.s_BRESP[1]} -tag F0 -label {s_BRESP[1]} -radix hexadecimal
wave add -group {s_B_channel[1]} {axi_interconnect_tb.s_BVALID[1]} -tag F0 -label {s_BVALID[1]} -radix hexadecimal
wave add -group {s_B_channel[1]} {axi_interconnect_tb.s_BREADY[1]} -tag F0 -label {s_BREADY[1]} -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave add axi_interconnect_tb.dut.m_AWADDR -tag F0 -label {m_AWADDR} -radix hexadecimal
wave add axi_interconnect_tb.dut.m_AWLEN -tag F0 -label {m_AWLEN} -radix hexadecimal
wave add axi_interconnect_tb.dut.m_AWVALID -tag F0 -label {m_AWVALID} -radix hexadecimal
wave add axi_interconnect_tb.dut.m_AWREADY -tag F0 -label {m_AWREADY} -radix hexadecimal
wave add {axi_interconnect_tb.m_ARADDR[0]} -tag F0 -radix hexadecimal
wave add {axi_interconnect_tb.m_ARVALID[0]} -tag F0 -radix hexadecimal
wave add {axi_interconnect_tb.m_RDATA[0]} -tag F0 -radix hexadecimal
wave add {axi_interconnect_tb.m_RVALID[0]} -tag F0 -radix hexadecimal
wave add {axi_interconnect_tb.m_RREADY[0]} -tag F0 -radix hexadecimal
wave add axi_interconnect_tb.m_ARADDR -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.m_ARADDR[3]} {-radix hexadecimal} {axi_interconnect_tb.m_ARADDR[2]} {-radix hexadecimal} {axi_interconnect_tb.m_ARADDR[1]} {-radix hexadecimal} {axi_interconnect_tb.m_ARADDR[0]} {-radix hexadecimal} }
wave add axi_interconnect_tb.m_RDATA -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.m_RDATA[3]} {-radix hexadecimal} {axi_interconnect_tb.m_RDATA[2]} {-radix hexadecimal} {axi_interconnect_tb.m_RDATA[1]} {-radix hexadecimal} {axi_interconnect_tb.m_RDATA[0]} {-radix hexadecimal} }
wave add axi_interconnect_tb.m_RVALID -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.m_RVALID[3]} {-radix hexadecimal} {axi_interconnect_tb.m_RVALID[2]} {-radix hexadecimal} {axi_interconnect_tb.m_RVALID[1]} {-radix hexadecimal} {axi_interconnect_tb.m_RVALID[0]} {-radix hexadecimal} }
wave add axi_interconnect_tb.m_RREADY -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.m_RREADY[3]} {-radix hexadecimal} {axi_interconnect_tb.m_RREADY[2]} {-radix hexadecimal} {axi_interconnect_tb.m_RREADY[1]} {-radix hexadecimal} {axi_interconnect_tb.m_RREADY[0]} {-radix hexadecimal} }
wave add {axi_interconnect_tb.m_ARREADY[0]} -tag F0 -radix hexadecimal
wave add axi_interconnect_tb.m_ARID -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.m_ARID[3]} {-radix hexadecimal} {axi_interconnect_tb.m_ARID[2]} {-radix hexadecimal} {axi_interconnect_tb.m_ARID[1]} {-radix hexadecimal} {axi_interconnect_tb.m_ARID[0]} {-radix hexadecimal} }
wave add axi_interconnect_tb.m_ARLEN -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.m_ARLEN[3]} {-radix hexadecimal} {axi_interconnect_tb.m_ARLEN[2]} {-radix hexadecimal} {axi_interconnect_tb.m_ARLEN[1]} {-radix hexadecimal} {axi_interconnect_tb.m_ARLEN[0]} {-radix hexadecimal} }
wave add axi_interconnect_tb.m_ARVALID -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.m_ARVALID[3]} {-radix hexadecimal} {axi_interconnect_tb.m_ARVALID[2]} {-radix hexadecimal} {axi_interconnect_tb.m_ARVALID[1]} {-radix hexadecimal} {axi_interconnect_tb.m_ARVALID[0]} {-radix hexadecimal} }
wave add axi_interconnect_tb.m_ARREADY -tag F0 -radix hexadecimal -expand -subitemconfig { {axi_interconnect_tb.m_ARREADY[3]} {-radix hexadecimal} {axi_interconnect_tb.m_ARREADY[2]} {-radix hexadecimal} {axi_interconnect_tb.m_ARREADY[1]} {-radix hexadecimal} {axi_interconnect_tb.m_ARREADY[0]} {-radix hexadecimal} }
wave add axi_interconnect_tb.s_ARADDR -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.s_ARADDR[1]} {-radix hexadecimal} {axi_interconnect_tb.s_ARADDR[0]} {-radix hexadecimal} }
wave add {axi_interconnect_tb.s_ARID[1]} -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.s_ARID[1][6]} {-radix hexadecimal} {axi_interconnect_tb.s_ARID[1][5]} {-radix hexadecimal} {axi_interconnect_tb.s_ARID[1][4]} {-radix hexadecimal} {axi_interconnect_tb.s_ARID[1][3]} {-radix hexadecimal} {axi_interconnect_tb.s_ARID[1][2]} {-radix hexadecimal} {axi_interconnect_tb.s_ARID[1][1]} {-radix hexadecimal} {axi_interconnect_tb.s_ARID[1][0]} {-radix hexadecimal} }
wave add {axi_interconnect_tb.s_ARADDR[1]} -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.s_ARADDR[1][31]} {-radix hexadecimal} {axi_interconnect_tb.s_ARADDR[1][30]} {-radix hexadecimal} {axi_interconnect_tb.s_ARADDR[1][29]} {-radix hexadecimal} {axi_interconnect_tb.s_ARADDR[1][28]} {-radix hexadecimal} {axi_interconnect_tb.s_ARADDR[1][27]} {-radix hexadecimal} {axi_interconnect_tb.s_ARADDR[1][26]} {-radix hexadecimal} {axi_interconnect_tb.s_ARADDR[1][25]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][24]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][23]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][22]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][21]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][20]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][19]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][18]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][17]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][16]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][15]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][14]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][13]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][12]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][11]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][10]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][9]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][8]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][7]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][6]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][5]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][4]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][3]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][2]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][1]} {-radix mnemonic} {axi_interconnect_tb.s_ARADDR[1][0]} {-radix mnemonic} }
wave add {axi_interconnect_tb.s_ARVALID[1]} -tag F0 -radix hexadecimal
wave add {axi_interconnect_tb.dut.genblk5[1].slave_arbitration.AW_channel.xDATA_AxID_o} -tag F0 -radix hexadecimal
wave add {axi_interconnect_tb.s_ARREADY[1]} -tag F0 -radix hexadecimal
wave add axi_interconnect_tb.s_ARVALID -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.s_ARVALID[1]} {-radix hexadecimal} {axi_interconnect_tb.s_ARVALID[0]} {-radix hexadecimal} }
wave add axi_interconnect_tb.s_ARREADY -tag F0 -radix hexadecimal -subitemconfig { {axi_interconnect_tb.s_ARREADY[1]} {-radix hexadecimal} {axi_interconnect_tb.s_ARREADY[0]} {-radix hexadecimal} }
wave update on
wave top 47
