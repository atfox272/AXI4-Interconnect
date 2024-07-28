onerror {resume}
quietly set dataset_list [list sim vsim]
if {[catch {datasetcheck $dataset_list}]} {abort}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Master[0]}
add wave -noupdate -expand -group {m_AW_channel[0]} -label {m_AWID[0]} {sim:/axi_interconnect_tb/dut/m_AWID[0]}
add wave -noupdate -expand -group {m_AW_channel[0]} -label {m_AWADDR[0]} {sim:/axi_interconnect_tb/m_AWADDR[0]}
add wave -noupdate -expand -group {m_AW_channel[0]} -label {m_AWLEN[0]} {sim:/axi_interconnect_tb/dut/m_AWLEN[0]}
add wave -noupdate -expand -group {m_AW_channel[0]} -label {m_AWSIZE[0]} {sim:/axi_interconnect_tb/dut/m_AWSIZE[0]}
add wave -noupdate -expand -group {m_AW_channel[0]} -label {m_AWVALID[0]} {sim:/axi_interconnect_tb/dut/m_AWVALID[0]}
add wave -noupdate -expand -group {m_AW_channel[0]} -label {m_AWREADY[0]} {sim:/axi_interconnect_tb/dut/m_AWREADY[0]}
add wave -noupdate -group {m_W_channel[0]} -label {m_WVALID[0]} {sim:/axi_interconnect_tb/dut/m_WVALID[0]}
add wave -noupdate -group {m_W_channel[0]} -label {m_WREADY[0]} {sim:/axi_interconnect_tb/dut/m_WREADY[0]}
add wave -noupdate -group {m_W_channel[0]} -label {m_WLAST[0]} {sim:/axi_interconnect_tb/dut/m_WLAST[0]}
add wave -noupdate -group {m_W_channel[0]} -label {m_WDATA[0]} {sim:/axi_interconnect_tb/dut/m_WDATA[0]}
add wave -noupdate -group {m_B_channel[0]} -label {m_BREADY[0]} {sim:/axi_interconnect_tb/dut/m_BREADY[0]}
add wave -noupdate -group {m_B_channel[0]} -label {m_BVALID[0]} {sim:/axi_interconnect_tb/dut/m_BVALID[0]}
add wave -noupdate -group {m_B_channel[0]} -label {m_BRESP[0]} {sim:/axi_interconnect_tb/dut/m_BRESP[0]}
add wave -noupdate -divider {Master[1]}
add wave -noupdate -expand -group {m_AW_channel[1]} -label {m_AWADDR[1]} {sim:/axi_interconnect_tb/dut/m_AWADDR[1]}
add wave -noupdate -expand -group {m_AW_channel[1]} -label {m_AWLEN[1]} {sim:/axi_interconnect_tb/dut/m_AWLEN[1]}
add wave -noupdate -expand -group {m_AW_channel[1]} -label {m_AWVALID[1]} {sim:/axi_interconnect_tb/dut/m_AWVALID[1]}
add wave -noupdate -expand -group {m_AW_channel[1]} -label {m_AWREADY[1]} {sim:/axi_interconnect_tb/dut/m_AWREADY[1]}
add wave -noupdate -expand -group {m_W_channel[1]} -label {m_WDATA[1]} {sim:/axi_interconnect_tb/dut/m_WDATA[1]}
add wave -noupdate -expand -group {m_W_channel[1]} -label {m_WLAST[1]} {sim:/axi_interconnect_tb/dut/m_WLAST[1]}
add wave -noupdate -expand -group {m_W_channel[1]} -label {m_WVALID[1]} {sim:/axi_interconnect_tb/dut/m_WVALID[1]}
add wave -noupdate -expand -group {m_W_channel[1]} -label {m_WREADY[1]} {sim:/axi_interconnect_tb/dut/m_WREADY[1]}
add wave -noupdate -label sa_WREADY_i {sim:/axi_interconnect_tb/dut/genblk4[1]/dispatcher/sa_WREADY_i}
add wave -noupdate -label AW_W_slv_id {sim:/axi_interconnect_tb/dut/genblk4[1]/dispatcher/write_channel/WDATA_channel/dsp_AW_slv_id_i}
add wave -noupdate -label AW_W_disable {sim:/axi_interconnect_tb/dut/genblk4[1]/dispatcher/write_channel/WDATA_channel/dsp_AW_disable_i}
add wave -noupdate -divider {Master[2]}
add wave -noupdate -expand -group {m_AW_channel[2]} -label {m_AWADDR[2]} {sim:/axi_interconnect_tb/dut/m_AWADDR[2]}
add wave -noupdate -expand -group {m_AW_channel[2]} -label m_AWLEN {sim:/axi_interconnect_tb/dut/m_AWLEN[2]}
add wave -noupdate -expand -group {m_AW_channel[2]} -label m_AWVALID {sim:/axi_interconnect_tb/dut/m_AWVALID[2]}
add wave -noupdate -expand -group {m_AW_channel[2]} -label m_AWREADY {sim:/axi_interconnect_tb/dut/m_AWREADY[2]}
add wave -noupdate -expand -group {m_W_channel[2]} -label {m_WDATA[2]} {sim:/axi_interconnect_tb/dut/m_WDATA[2]}
add wave -noupdate -expand -group {m_W_channel[2]} -label {m_WLAST[2]} {sim:/axi_interconnect_tb/dut/m_WLAST[2]}
add wave -noupdate -expand -group {m_W_channel[2]} -label {m_WVALID[2]} {sim:/axi_interconnect_tb/dut/m_WVALID[2]}
add wave -noupdate -expand -group {m_W_channel[2]} -label {m_WREADY[2]} {sim:/axi_interconnect_tb/dut/m_WREADY[2]}
add wave -noupdate -label AW_W_disable {sim:/axi_interconnect_tb/dut/genblk4[2]/dispatcher/write_channel/AW_W_disable}
add wave -noupdate -label sa_WREADY_i -expand {sim:/axi_interconnect_tb/dut/genblk4[2]/dispatcher/write_channel/sa_WREADY_i}
add wave -noupdate -format Literal -label AW_W_slv_id {sim:/axi_interconnect_tb/dut/genblk4[2]/dispatcher/write_channel/AW_W_slv_id}
add wave -noupdate -label {sa[1]_fifo_wdata_full} -expand {sim:/axi_interconnect_tb/dut/genblk5[1]/slave_arbitration/WDATA_channel/fifo_wdata_full}
add wave -noupdate -label {sa[1]_fifo_wdata_empty} {sim:/axi_interconnect_tb/dut/genblk5[1]/slave_arbitration/WDATA_channel/fifo_wdata_empt}
add wave -noupdate -divider {Master[3]}
add wave -noupdate -group {m_W_channel[3]} -label {m_WDATA[3]} {sim:/axi_interconnect_tb/dut/m_WDATA[3]}
add wave -noupdate -group {m_W_channel[3]} -label {m_WLAST[3]} {sim:/axi_interconnect_tb/dut/m_WLAST[3]}
add wave -noupdate -group {m_W_channel[3]} -label {m_WVALID[3]} {sim:/axi_interconnect_tb/dut/m_WVALID[3]}
add wave -noupdate -group {m_W_channel[3]} -label {m_WREADY[3]} {sim:/axi_interconnect_tb/dut/m_WREADY[3]}
add wave -noupdate -divider {Slave[0]}
add wave -noupdate -expand -group {s_AW_channel[0]} -label {s_AWID[0]} {sim:/axi_interconnect_tb/s_AWID[0]}
add wave -noupdate -expand -group {s_AW_channel[0]} -label {s_AWADDR[0]} {sim:/axi_interconnect_tb/s_AWADDR[0]}
add wave -noupdate -expand -group {s_AW_channel[0]} -label {s_AWLEN[0]} {sim:/axi_interconnect_tb/s_AWLEN[0]}
add wave -noupdate -expand -group {s_AW_channel[0]} -label {s_AWSIZE[0]} {sim:/axi_interconnect_tb/s_AWSIZE[0]}
add wave -noupdate -expand -group {s_AW_channel[0]} -label {s_AWVALID[0]} {sim:/axi_interconnect_tb/s_AWVALID[0]}
add wave -noupdate -expand -group {s_AW_channel[0]} -label {s_AWREADY[0]} {sim:/axi_interconnect_tb/s_AWREADY[0]}
add wave -noupdate -expand -group {s_W_channel[0]} -label {s_WDATA[0]} {sim:/axi_interconnect_tb/dut/s_WDATA[0]}
add wave -noupdate -expand -group {s_W_channel[0]} -label {s_WLAST[0]} {sim:/axi_interconnect_tb/dut/s_WLAST[0]}
add wave -noupdate -expand -group {s_W_channel[0]} -label {s_WVALID[0]} {sim:/axi_interconnect_tb/dut/s_WVALID[0]}
add wave -noupdate -expand -group {s_W_channel[0]} -label {s_WREADY[0]} {sim:/axi_interconnect_tb/dut/s_WREADY[0]}
add wave -noupdate -expand -group {s_B_channel[0]} -label {s_BID[0]} {sim:/axi_interconnect_tb/s_BID[0]}
add wave -noupdate -expand -group {s_B_channel[0]} -label {s_BVALID[0]} {sim:/axi_interconnect_tb/s_BVALID[0]}
add wave -noupdate -expand -group {s_B_channel[0]} -label {s_BREADY[0]} {sim:/axi_interconnect_tb/s_BREADY[0]}
add wave -noupdate -label fifo_order_empty {sim:/axi_interconnect_tb/dut/genblk5[0]/slave_arbitration/WDATA_channel/fifo_order_empt}
add wave -noupdate -label {dsp_slv_sel_i[0]} {sim:/axi_interconnect_tb/dut/genblk5[0]/slave_arbitration/WDATA_channel/dsp_slv_sel_i}
add wave -noupdate -label fifo_order_full {sim:/axi_interconnect_tb/dut/genblk5[0]/slave_arbitration/WDATA_channel/fifo_order_full}
add wave -noupdate -label fifo_wdata_full {sim:/axi_interconnect_tb/dut/genblk5[0]/slave_arbitration/WDATA_channel/fifo_wdata_full}
add wave -noupdate -label fifo_wdata_empty -expand {sim:/axi_interconnect_tb/dut/genblk5[0]/slave_arbitration/WDATA_channel/fifo_wdata_empt}
add wave -noupdate -label Ax_mst_id_valid {sim:/axi_interconnect_tb/dut/genblk5[0]/slave_arbitration/WDATA_channel/Ax_mst_id_valid}
add wave -noupdate -divider {Slave[1]}
add wave -noupdate -expand -group {s_AW_channel[1]} -label {s_AWID[1]} {sim:/axi_interconnect_tb/s_AWID[1]}
add wave -noupdate -expand -group {s_AW_channel[1]} -label {s_AWADDR[1]} {sim:/axi_interconnect_tb/s_AWADDR[1]}
add wave -noupdate -expand -group {s_AW_channel[1]} -label {s_AWLEN[1]} {sim:/axi_interconnect_tb/s_AWLEN[1]}
add wave -noupdate -expand -group {s_AW_channel[1]} -label {s_AWSIZE[1]} {sim:/axi_interconnect_tb/s_AWSIZE[1]}
add wave -noupdate -expand -group {s_AW_channel[1]} -label {s_AWVALID[1]} {sim:/axi_interconnect_tb/s_AWVALID[1]}
add wave -noupdate -expand -group {s_AW_channel[1]} -label {s_AWREADY[1]} {sim:/axi_interconnect_tb/s_AWREADY[1]}
add wave -noupdate -expand -group {s_W_channel[1]} -color Yellow -label {s_WDATA[1]} {sim:/axi_interconnect_tb/s_WDATA[1]}
add wave -noupdate -expand -group {s_W_channel[1]} -color Yellow -label {s_WLAST[1]} {sim:/axi_interconnect_tb/s_WLAST[1]}
add wave -noupdate -expand -group {s_W_channel[1]} -color Gold -label {s_WVALID[1]} {sim:/axi_interconnect_tb/s_WVALID[1]}
add wave -noupdate -expand -group {s_W_channel[1]} -label {s_WREADY[1]} {sim:/axi_interconnect_tb/s_WREADY[1]}
add wave -noupdate -group {s_B_channel[1]} -label {s_BID[1]} {sim:/axi_interconnect_tb/s_BID[1]}
add wave -noupdate -group {s_B_channel[1]} -label {s_BRESP[1]} {sim:/axi_interconnect_tb/s_BRESP[1]}
add wave -noupdate -group {s_B_channel[1]} -label {s_BVALID[1]} {sim:/axi_interconnect_tb/s_BVALID[1]}
add wave -noupdate -group {s_B_channel[1]} -label {s_BREADY[1]} {sim:/axi_interconnect_tb/s_BREADY[1]}
add wave -noupdate -label {sa[1]_ff_wdata_full} {sim:/axi_interconnect_tb/dut/genblk5[1]/slave_arbitration/WDATA_channel/fifo_wdata_full}
add wave -noupdate -label {sa[1]_ff_wdata_empty} -expand {sim:/axi_interconnect_tb/dut/genblk5[1]/slave_arbitration/WDATA_channel/fifo_wdata_empt}
add wave -noupdate -label m_AWADDR sim:/axi_interconnect_tb/dut/m_AWADDR
add wave -noupdate -label m_AWLEN sim:/axi_interconnect_tb/dut/m_AWLEN
add wave -noupdate -label m_AWVALID sim:/axi_interconnect_tb/dut/m_AWVALID
add wave -noupdate -label m_AWREADY sim:/axi_interconnect_tb/dut/m_AWREADY
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20056781 ps} 0} {{Cursor 5} {20524647 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 157
configure wave -valuecolwidth 52
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {20484872 ps} {20572705 ps}
