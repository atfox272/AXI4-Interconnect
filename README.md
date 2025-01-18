# AXI4 Interconnect

Specification of AXI4 Interconnect

# 1. Introduction

This project contains the RTL code of the AXI4 Interconnect. The Interconnect is used to connect AXI4 components via the AXI4 protocol. The module supports some features such as multiple master, multiple slave, multiple outstanding transactions, etc.

## 1.1. Interface

The number of inputs and outputs of the Interconnect depends on the number of masters and the number of slaves.

There are 2 types of interfaces: 

- AXI4 Master interface
- AXI4 Slave interface

![image.png](/doc/img/image.png)

### 1.1.1. AXI4 Master Interface

 There are 5 channels in the AXI4 Master interface: AW channel, W channel, B channel, AR channel and R channel

![image.png](/doc/img/image%201.png)

### 1.1.2. AXI4 Slave Interface

There are 5 channels in the AXI4 Slave interface: AW channel, W channel, B channel, AR channel and R channel

![image.png](/doc/img/image%202.png)

## 1.2. Feature

The Interconnect provides some features:

- Functional
    - Multiple masters
    - Multiple slaves
    - Support interleaved weighted round-robin arbitration
    - Address mapping mechanism
    - Multiple outstanding transactions
    - Reorder response transfers
    - Support 4KB boundary transaction splitting
- Non-functional
    - Bandwidth: 100%
    - Latency: 3 - 5 cycles (depend on the number of pipeline stages)
- RTL features:
    - Configurable number of masters/slaves
    - Configurable arbitration weight of each master
    - Configurable number of outstanding transactions

## 1.3. Architecture

The top module is AXI4 Interconnect (RTL file: `axi_interconnect.v`)

![image.png](/doc/img/image%203.png)

# 2. Description

## 2.1. Configuration

The user can modify the Interconnect architecture or the internal parameters of the system via parameters in the top module file `axi_interconnect.v`.

Some parameters that the user can configure:

1. **Number of masters/slaves:**
    
    The user can configure the number of master or slaves that connect to the Interconnect via the following parameters in the top module:
    
    - `MST_AMT` parameter: for the number of masters
    - `SLV_AMT` parameter: for the number of slaves
2. **The arbitration weight of each master**:
    
    The weight list of masters can be modified through the `MST_WEIGHT` parameter in the top module. The Interconnect distributes grants to the masters based on the weight of each master.
    
    Each weight in the weight list is a 32-bit integer value, so the user must understand the format of the `MST_WEIGHT` parameter to configure the weight correctly.
    
    The weights of all masters are flattened into 1 parameter as shown in the code below, and the first value will be the weight of Master 0. 
    
    ```verilog
    parameter [0:(MST_AMT*32)-1] MST_WEIGHT = {32'd5, 32'd3, 32'd2, 32'd1}
    ```
    
    According to the above code:
    
    - Weight of the Master 0: **5**
    - Weight of the Master 1:  **3**
    - Weight of the Master 2: **2**
    - Weight of the Master 3: **1**
3. **Number of outstanding transactions**
    
    > **What are multiple outstanding transactions?**
    The AXI4 protocol supports multiple outstanding transactions, meaning a master can issue several transactions without waiting for the previous ones to complete. (*More detail in AXI4 protocol specification*)
    > 
    
    The number of outstanding transactions can be configured through the `OUTSTANDING_AMT` parameter in the top module. This parameter is assigned to both Write and Read channel of the AXI4 Interconnect.
    
4. **Address mapping region**
    
    > **What is address mapping scheme?**
    The AXI4 protocol involves translating logical addresses used by the Master into physical addresses used by the Slave. This Interconnect uses the address ranges assigned to each slave to route transactions (address decoding)
    > 
    
    The Interconnect uses the upper bits of the address to determine which slave to route to. The number of upper bits depends on the number of slaves connected to the Interconnect.
    
    In the RTL of this Interconnect, there are two parameters to select the range of these upper bits:
    
    - `SLV_ID_MSB_IDX` parameter: MSB (Most Significant Bit) index of the address range used to map the slave
    - `SLV_ID_LSB_IDX` parameter: LSB (Least Significant Bit) index of the address range used to map the slave
    
    *Example:*
    
    There are 8 slaves that connect to the Interconnect, so the Interconnect needs 3-bit address to map to all slaves:
    
    - The address range of the Slave 0: **0b000_000…00 - 0b000_111…11**
    - The address range of the Slave 1:  **0b001_000…00 - 0b001_111…11**
    - …
    - The address range of the Slave 7:  **0b111_000…00 - 0b111_111…11**
    
    ```verilog
    parameter SLV_ID_MSB_IDX      = 31,
    parameter SLV_ID_LSB_IDX      = 29,
    ```
    
    ![image.png](/doc/img/image%204.png)
    
5. **Pipeline stage** *(Update later)*
    
    The pipeline stage configuration is not related to the AXI4 protocol. This parameter is used to satisfy the **higher frequency** of the Interconnect, but the trade-off of this improvement is the latency of transfers that go into the Interconnect.
    
    This parameter is currently **not generalized**, and users must change the configuration of each internal component individually.
    

## 2.2. Some special functions:

### 2.2.1. Arbitration

The arbitration mechanism of the arbiter is **Interleaved Weighted Round-Robin (IWRR)**

1. **Theory**
    
    In weighted round-robin (WRR), each master is assigned a weight, and the arbiter serves a number of transactions equal to the weight of the master consecutively.
    
    In IWRR, the arbiter interleaves the transactions of different masters within the same round to ensure that no single master can dominate the service for an extended period.
    
2. **Mechanism**:
    
    *Arbitration only occurs when multiple masters want to access the same slave*
    
    *The Read and Write channels are independent, so there are two separate arbiters for the Read and Write channels.*
    
    **Request mechanism** of masters to the arbiter: When a master issues an AW/AR transfer to the Interconnect, it is considered a request.
    
    **Grant mechanism** of the arbiter to a master: When a master is granted on the AW/AR channel, other channels such as W, R, or B channels also follow the order of that grant. The grant only considers the current weight of that master and **does not consider the length of the entire transaction**, which can be a limitation as transactions with length = 1 and transactions with length = 255 have the same priority.
    

> The structure for setting up the arbiters will be described more detail in the *section Design Note.*
> 

### 2.2.2. Multiple outstanding transactions

The AXI4 protocol supports multiple outstanding transactions, meaning a master can issue several transactions without waiting for the previous ones to complete. 

Due to the Interconnect supporting outstanding transactions, issues such as Out-of-Order and Interleaving can occur. Therefore, the Interconnect must support additional mechanisms to handle these issues.

1. **Out-of-Order**
    
    When multiple slaves are involved, each slave can **process transactions at different speeds**. This can lead to transactions completed in an order different from the one in which they were issued, especially if the transactions are directed to different slaves.
    
    Therefore, the out-of-order can occur in B channel or R channel.
    
    *Read more in the AXI4 specification:* https://developer.arm.com/documentation/102202/0300/Transfer-behavior-and-transaction-ordering
    
2. **Reorder**
    
    The Interconnect has 2 reorder buffers placed on the R and B channels for each master to reorder the B/R transfers to match the order of the AW/AR channels.
    
    *Example:*
    
    1. One master writes data to three slaves corresponding to three address regions A, B, and C through the Interconnect as shown in the diagram below.
        - The slaves cause out-of-order on the B channel as shown in the timing diagram below.
            
            ![image.png](/doc/img/image%205.png)
            
        - The Interconnect will reorder the B transfers as shown in the timing diagram below.
            
            ![image.png](/doc/img/image%206.png)
            
    2. One master reads data from three slaves corresponding to three address regions A, B, and C through the Interconnect as shown in the diagram below.
        - The slaves cause out-of-order on the R channel as shown in the timing diagram below.
            
            ![image.png](/doc/img/image%207.png)
            
        - The Interconnect will reorder the R transfers as shown in the timing diagram below.
            
            ![image.png](/doc/img/image%208.png)
            

# 3. Design Note

## 3.1. Design schematic

*In this section, I will describe it in a Top-Down approach*.

### 3.1.1. Architecture

The Interconnect contains 2 main sub-modules:

- Dispatcher
- Slave arbitration

![image.png](/doc/img/image%209.png)

### 3.1.2. Block diagram

1. **Dispatcher block**:
    
    ![image.png](/doc/img/image%2010.png)
    
2. **Slave arbitration block**
    
    ![image.png](/doc/img/image%2011.png)
    
    1. For AW channel:
        
        ![image.png](/doc/img/image%2012.png)
        
    2. For W channel
        
        ![image.png](/doc/img/image%2013.png)
        
    3. For B channel
        
        ![image.png](/doc/img/image%2014.png)
        
    4. For AR channel
        
        ![image.png](/doc/img/image%2015.png)
        
    5. For R channel
        
        ![image.png](/doc/img/image%2016.png)
        

## 3.2. RTL file structure

![image.png](/doc/img/image%2017.png)

# 4. Verification

This section describes the automated test environment for the AXI4 Interconnect.

The top testbench file is `axi_interconnect_tb.v`.

The verification environment creates 4 AXI4 Master drivers and 2 AXI4 Slave drivers connected to the AXI4 Interconnect as shown in the following model:

![image.png](/doc/img/image%2018.png)

- Each Master driver receives transaction information from the Sequencer with transactions generated **automatically** and **randomly**, each transaction includes the following information:
    - Write/Read Transaction’s ID
    - Write/Read Address
    - Write/Read Length
    - Write/Read Size
    
    > For each set of parameters (ID, Address, Length, Size), **only one corresponding DATA set** is generated.
    > 
- Then, the Master driver issues transfers, corresponding to the transaction information received from the Sequencer, to the Interconnect.
- When the transfers reach the Slave through the Interconnect, they include the information in the parameter set (ID, Address, Length, Size).
    - For Write transfers: the slave compares the DATA set from the W channel of the Interconnect with the DATA set generated from the (ID, Address, Length, Size) set of the AW channel.
    - For Read transfers: the slave will generate the DATA set from the (ID, Address, Length, Size) set of the AR channel to respond to the R channel of the Interconnect.
- When the response transfers reach the Master from the Slave through the Interconnect,
    - For Write response transfers:
    - For Read response transfers: the master compares the DATA set from the R channel of the Interconnect with the initial DATA set (when generating the AR transfer).