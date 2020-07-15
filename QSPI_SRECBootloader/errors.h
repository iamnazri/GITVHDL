/******************************************************************************
*
* Copyright (C) 2004 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
#ifndef BL_ERRORS_H
#define BL_ERRORS_H

#include <stdio.h>
#include <stdint.h>
#include "qspi.h"
#include "xparameters.h"

#define LD_MEM_WRITE_ERROR  1
#define LD_SREC_LINE_ERROR  2
#define SREC_PARSE_ERROR    3
#define SREC_CKSUM_ERROR    4

#define QSPI_BASEADDR		XPAR_SPI_0_BASEADDR

#define AXI_QSPI_IPISR		0x20
#define AXI_QSPI_SPISR		0x60
#define AXI_QSPI_SPICR		0x64
#define AXI_QSPI_SPIDTR		0x68 //write only
#define AXI_QSPI_SPIDRR		0x6C
#define AXI_QSPI_SPISSR		0x70
#define AXI_QSPI_TXFIFO		0x74
#define AXI_QSPI_RXFIFO		0x78

uint32_t qspi_check_status(void);
int qspi_print_status(uint32_t);
uint32_t qspi_check_control(void);
int qspi_print_control(uint32_t);
uint32_t qspi_check_irstatus(void);
int qspi_print_irstatus(uint32_t);

#endif /* BL_ERRORS_H */
