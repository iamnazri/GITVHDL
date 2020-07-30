///////////////////////////////28 Mar 2012 robn//////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2009 Xilinx, Inc. All Rights Reserved.
//
// You may copy and modify these files for your own internal use solely with
// Xilinx programmable logic devices and  Xilinx EDK system or create IP
// modules solely for Xilinx programmable logic devices and Xilinx EDK system.
// No rights are granted to distribute any files unless they are distributed in
// Xilinx programmable logic devices.
//
/////////////////////////////////////////////////////////////////////////////////

/*
 *      Simple SREC Bootloader
 *      This simple bootloader is provided with Xilinx EDK for you to easily re-use in your
 *      own software project. It is capable of booting an SREC format image file 
 *      (Mototorola S-record format), given the location of the image in memory.
 *      In particular, this bootloader is designed for images stored in non-volatile flash
 *      memory that is addressable from the processor. 
 *
 *      Please modify the define "FLASH_IMAGE_BASEADDR" in the blconfig.h header file 
 *      to point to the memory location from which the bootloader has to pick up the 
 *      flash image from.
 *
 *      You can include these sources in your software application project in SDK and 
 *      build the project for the processor for which you want the bootload to happen.
 *      You can also subsequently modify these sources to adapt the bootloader for any
 *      specific scenario that you might require it for.
 *
 *		Modified: 15072020 		NAB
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xintc.h"
#include "xspi.h"
#include "blconfig.h"
#include "portab.h"
#include "errors.h"
#include "srec.h"
#include "commands.h"
//#include <xilisf.h>		/* Serial Flash Library header file */

/* Defines */
#define CR       13

/* Comment the following line, if you want a smaller and faster bootloader which will be silent */
//#define VERBOSE

/* Declarations */
static void display_progress (uint32_t lines);
static uint8_t load_exec ();
static uint8_t flash_get_srec_line (uint8_t *buf);
__attribute__ ((gnu_inline))inline void copy_srec_line();
static int SetupInterruptSystem(XSpi *SpiPtr);
void SpiHandler(void *CallBackRef, u32 StatusEvent, unsigned int ByteCount);
extern void init_stdout();
int SpiFlashWaitForFlashReady(void);
int SpiFlashGetStatus(XSpi *SpiPtr);
int SpiFlashWriteEnable(XSpi *SpiPtr);
int SpiFlashRead(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 ReadCmd);
int SpiFlashQuadEnable(XSpi *SpiPtr);



/* Declarations for ISF/SPI */
#warning "Set your Device ID here, as defined in xparameters.h"
#define SPI_DEVICE_ID			XPAR_SPI_0_DEVICE_ID
#define INTC_DEVICE_ID			XPAR_INTC_0_DEVICE_ID
#define SPI_INTR_ID			XPAR_INTC_0_SPI_0_VEC_ID

/*
 * The following constant defines the slave select signal that is used to
 * to select the Flash device on the SPI bus, this signal is typically
 * connected to the chip select of the device.
 */
#define SPI_SELECT		0x01

/*
 * Number of bytes per page in the flash device.
 */
#define PAGE_SIZE		256

/*
 * Buffer Additional Size
 */
#define BUFFER_PADDING 	128

/*
 * The instances to support the device drivers are global such that they
 * are initialized to zero each time the program runs. They could be local
 * but should at least be static so they are zeroed.
 */
static XIntc InterruptController;
static XSpi Spi;


/*
 * The following variable tracks any errors that occur during interrupt
 * processing.
 */

static int ErrorCount;

/*
 * Buffer used during Read and Write transactions.
 */
static u8 ReadBuffer[PAGE_SIZE + READ_EXTRA_BYTES + BUFFER_PADDING ];
static u8 WriteBuffer[PAGE_SIZE + READ_EXTRA_BYTES + BUFFER_PADDING];

extern int srec_line;

#ifdef __cplusplus
extern "C" {
#endif

extern void outbyte(char c); 

#ifdef __cplusplus
}
#endif

/* Data structures */
static srec_info_t srinfo;
static uint8_t sr_buf[SREC_MAX_BYTES + BUFFER_PADDING];
static uint8_t sr_data_buf[SREC_DATA_MAX_BYTES];

static uint8_t *flbuf;

#ifdef VERBOSE
static int8_t *errors[] = { 
    "",
    "Error while copying executable image into RAM",
    "Error while reading an SREC line from flash",
    "SREC line is corrupted",
    "SREC has invalid checksum."
};
#endif

/* We don't use interrupts/exceptions. 
   Dummy definitions to reduce code size on MicroBlaze */
#ifdef __MICROBLAZE__
void _interrupt_handler () {}
void _exception_handler () {}
void _hw_exception_handler () {}
#endif


int main()
{
    int Status;
	uint8_t ret;
	XSpi_Config *ConfigPtr;
#ifdef VERBOSE    
	print ("\r\nSREC SPI Bootloader\r\n");
#endif

	/* reset cycle 4x4 AXI Clock*/
	for (int i = 0; i < 4; i++)
	{
		Xil_Out32(XPAR_SPI_0_BASEADDR + 0x40, (u32)0xa);
		usleep(100);
	}

	/*
	 * Initialize the SPI driver so that it's ready to use,
	 * specify the device ID that is generated in xparameters.h.
	 */
	ConfigPtr = XSpi_LookupConfig(SPI_DEVICE_ID);
	if (ConfigPtr == NULL) {
		return XST_DEVICE_NOT_FOUND;
	}
    /*
     * Initialize the SPI driver so that it's ready to use,
     * specify the device ID that is generated in xparameters.h.
     */
	Status = XSpi_CfgInitialize(&Spi, ConfigPtr,
					  ConfigPtr->BaseAddress);
	if(Status != XST_SUCCESS) {
			return XST_FAILURE;
	}

	/*
	 * Set the SPI device as a master and in manual slave select mode such
	 * that the slave select signal does not toggle for every byte of a
	 * transfer, this must be done before the slave select is set.
	 */
	Status = XSpi_SetOptions(&Spi, XSP_MASTER_OPTION
				);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Select the quad flash device on the SPI bus, so that it can be
	 * read and written using the SPI bus.
	 */
	Status = XSpi_SetSlaveSelect(&Spi, SPI_SELECT);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	/*
	 * Start the SPI driver so that interrupts and the device are enabled.
	 */
	XSpi_Start(&Spi);

	/*
	 * Disable Global interrupt to use polled mode operation.
	 */
	XSpi_IntrGlobalDisable(&Spi);

	/*
	 * Set the Quad Enable (QE) bit in the flash device, so that Quad
	 * operations can be performed on the flash.
	 */
	Status = SpiFlashQuadEnable(&Spi);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Initialize the Serial Flash Library.
	 */

    init_stdout();

#ifdef VERBOSE    
    print ("Loading SREC image from flash @ address: ");    
    putnum (FLASH_IMAGE_BASEADDR);
    print ("\r\n");        
#endif

    flbuf = (uint8_t*)FLASH_IMAGE_BASEADDR;
    ret = load_exec ();

    /* If we reach here, we are in error */
    
#ifdef VERBOSE
    if (ret > LD_SREC_LINE_ERROR) {
        print ("ERROR in SREC line: ");
        putnum (srec_line);
        print (errors[ret]);    
    } else {
        print ("ERROR: ");
        print (errors[ret]);
    }
#endif

    return ret;
}

#ifdef VERBOSE
static void display_progress (uint32_t count)
{
    /* Send carriage return */
    outbyte (CR);  
    print  ("Bootloader: Processed (0x)");
    putnum (count);
    print (" S-records");
}
#endif

static uint8_t load_exec ()
{
    uint8_t ret;

    void (*laddr)();
    int8_t done = 0;
    
    srinfo.sr_data = sr_data_buf;
    
    while (!done) {

        if ((ret = flash_get_srec_line (sr_buf)) != 0)
            {
        		xil_printf("Get srec line returns zero ");
        		return ret;
            }

        /* count occurences of S ( cant be more than 16 s records)*/
        uint8_t *ptr;
        uint8_t addrIncr = 0;
        ptr = sr_buf;

        while ( *ptr != '\0' && !done){
			if (*ptr == 'S') {
				addrIncr = ptr - sr_buf;
				ret = decode_srec_line (sr_buf + addrIncr, &srinfo);
        		switch (ret){
        		case SREC_CKSUM_ERROR:
        			xil_printf("Checksum Error in decoding \r\n");
					return ret;
        			break;
        		case 0:
#ifdef VERBOSE
					display_progress (srec_line);
#endif
					switch (srinfo.type) {
						case SREC_TYPE_0:
							break;
						case SREC_TYPE_1:
						case SREC_TYPE_2:
						case SREC_TYPE_3:
							memcpy ((void*)srinfo.addr, (void*)srinfo.sr_data, srinfo.dlen);
							break;
						case SREC_TYPE_5:
							break;
						case SREC_TYPE_7:
						case SREC_TYPE_8:
						case SREC_TYPE_9:
							laddr = (void (*)())srinfo.addr;
							done = 1;
							ret = 0;
							break;
					}
				break;

				default:
					xil_printf("Error in decoding\r\n");
					break;
        		}

        		ptr++;
			} else {
				ptr++;
			}

        }

        

    }

#ifdef VERBOSE
    print ("\r\nExecuting program starting at address: ");
    putnum ((uint32_t)laddr);
    print ("\r\n");
#endif

    (*laddr)();                 
  
    /* We will be dead at this point */
    return 0;
}


/*
 * This function reads a page of memory using quad 4 bytes command read.
 * It was modified from the original spi srec code from xilinx. It uses
 * axi_spi library instead of the xilisf lib which is deprecated since vivado 2019.2
 * This code was modified under the following assumptions:
 * -
 * - the size of one srec line is unknown
 * 		- therefore the last element can incomplete. this is a problem that is handled here
 * - the copying of srec elements may not be repeated
 * 		- the code tries to get the incomplete srec elements in the next loop by counting the bytes
 * 		needed to complete it.
 * -
 *  */
static uint8_t flash_get_srec_line (uint8_t *buf)
{
    int Status;
	uint8_t c;
	uint8_t endFlag = 0;
    int count = 0;
    static int addrIncr = 0, traverseCnt = 0;
    int mode = READ_EXTRA_BYTES;
    static uint32_t readAddress, readNumBytes;

	/*
	 * Set the
	 * - Address in the Serial Flash where the data is to be read from.
	 * - Number of bytes to be read from the Serial Flash.
	 * - Read Buffer to which the data is to be read.
	 */
	readAddress = flbuf + addrIncr*128; // First addr: 0x0, 2nd addr: 0x80, 3rd adr: 0x100
	readNumBytes = PAGE_SIZE; // Reading overlaps
	addrIncr++;

	if (addrIncr == 4)
		usleep(100);

	SpiClearReadBuffer();

	Status = SpiFlashRead(&Spi, readAddress, readNumBytes, SPI_READ_COMMAND);

	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	//qspi_print_control(qspi_check_control());
	//qspi_print_status(qspi_check_status());
	//rfifo = Xil_In32(QSPI_BASEADDR + XSP_RFO_OFFSET);
	//tfifo = Xil_In32(QSPI_BASEADDR + XSP_TFO_OFFSET);
	u32 drr = Xil_In32(QSPI_BASEADDR + AXI_QSPI_SPIDRR); // Displays amount of data that is not yet read


	/* traverse ReadBuffer from the back, and terminate the buffer */
	/* Readbuffer will consist of 9 extra bytes + (256 + addrOffset) of data  */
	for (int i = PAGE_SIZE + READ_EXTRA_BYTES ; i > READ_EXTRA_BYTES - 1; i--){
		if (ReadBuffer[i] == '\r'){
			ReadBuffer[i] = '\0';
			break;
		}
		if (i == READ_EXTRA_BYTES){
			/* The readbuffer is filled */
			xil_printf("End of readBuffer reached\n\r");
		}

	}

	SpiFlashWaitForFlashReady();


	/* Traverse the beginning of the array to find S and remove the extra bytes*/
	/* If beginning is imcomplete, just skip to the next srec elements because
	 * we assume that this is already read. */
	for (int j = READ_EXTRA_BYTES; j < 128 + READ_EXTRA_BYTES; j++){
		if (ReadBuffer[j] == 'S')
		{
			/* Index of SREC Data = CMD Extra bytes + 1 */
			if (j != READ_EXTRA_BYTES + 1)
				//xil_printf("Redundant bytes detected in buffer\r\n");
			mode = j;
			break;
		}
		if (j == 64){
			xil_printf("S search failed\r\n");
			return XST_FAILURE;
		}
	}



    c  = ReadBuffer[mode];

    /* Check if S is found. If it is, then remove extra bytes */
    if (c == 'S') {
		memcpy(buf, (void*)(ReadBuffer+mode), readNumBytes*sizeof(uint8_t));
		//*buf = ReadBuffer+(uint8_t)mode;
		return 0;
    } else {
    	xil_printf("No Srec data found!\r\n");
    	return 1;
    }
}

int SpiFlashWaitForFlashReady(void)
{
	int Status;
		u8 StatusReg;

		while(1) {

			/*
			 * Get the Status Register.
			 */
			Status = SpiFlashGetStatus(&Spi);
			if(Status != XST_SUCCESS) {
				return XST_FAILURE;
			}

			/*
			 * Check if the flash is ready to accept the next command.
			 * If so break.
			 */
			StatusReg = ReadBuffer[1];
			if((StatusReg & FLASH_SR_IS_READY_MASK) == 0) {
				break;
			}
		}

		return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function reads the data from the Winbond Serial Flash Memory
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
* @param	Addr is the starting address in the Flash Memory from which the
*		data is to be read.
* @param	ByteCount is the number of bytes to be read.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		None
*
******************************************************************************/
int SpiFlashRead(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 ReadCmd)
{
	int Status;

	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady();
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Prepare the WriteBuffer. Only for Quad Mode 4 Byte Addressing
	 */
	WriteBuffer[BYTE1] = ReadCmd;
#if FLASH_4BYTES_ADDRESSING
	WriteBuffer[BYTE2] = (u8) (Addr >> 24);
	WriteBuffer[BYTE3] = (u8) (Addr >> 16);
	WriteBuffer[BYTE4] = (u8) (Addr >> 8);
	WriteBuffer[BYTE5] = (u8) Addr;
#else
	WriteBuffer[BYTE2] = (u8) (Addr >> 16);
	WriteBuffer[BYTE3] = (u8) (Addr >> 8);
	WriteBuffer[BYTE4] = (u8) Addr;
#endif

	/*
	 * Initiate the Transfer.
	 */
	Status = XSpi_Transfer( SpiPtr, WriteBuffer, ReadBuffer,
				(ByteCount + READ_EXTRA_BYTES));
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


//	u32 rfifo = Xil_In32(QSPI_BASEADDR + XSP_RFO_OFFSET);
//	u32 tfifo = Xil_In32(QSPI_BASEADDR + XSP_TFO_OFFSET);
//	u32 drr = Xil_In32(QSPI_BASEADDR + AXI_QSPI_SPIDRR);


	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


/*****************************************************************************/
/**
*
* This function reads the Status register of the Winbond Flash.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		The status register content is stored at the second byte pointed
*		by the ReadBuffer.
*
******************************************************************************/
int SpiFlashGetStatus(XSpi *SpiPtr)
{
	int Status;

	/*
	 * Prepare the Write Buffer.
	 */
	WriteBuffer[BYTE1] = COMMAND_STATUSREG_READ;


	Status = XSpi_Transfer(SpiPtr, WriteBuffer, ReadBuffer,
						STATUS_READ_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
//
//	qspi_print_control(qspi_check_control());
//	qspi_print_status(qspi_check_status());
//	qspi_print_irstatus(qspi_check_irstatus());
//	u32 ask = Xil_In32(QSPI_BASEADDR + XSP_RFO_OFFSET);
//	u32 ask2 = Xil_In32(QSPI_BASEADDR + XSP_TFO_OFFSET);
//	drr = Xil_In32(QSPI_BASEADDR + AXI_QSPI_SPIDRR);

	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function reads the Status Flag register of the Winbond Flash.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		The status register content is stored at the second byte pointed
*		by the ReadBuffer.
*
******************************************************************************/
int SpiFlashGetFlagStatus(XSpi *SpiPtr)
{
	int Status;


	/*
	 * Prepare the Write Buffer.
	 */
	WriteBuffer[BYTE1] = COMMAND_STATUSFLAG_READ;


	Status = XSpi_Transfer(SpiPtr, WriteBuffer, ReadBuffer,
						STATUS_READ_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	return XST_SUCCESS;
}



/*****************************************************************************/
/**
*
* This function enables the use of 4 bytes addressing of the Winbond Flash.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		The status register content is stored at the second byte pointed
*		by the ReadBuffer.
*
******************************************************************************/
int SpiFlash4ByteAddressingEnable(XSpi *SpiPtr)
{
	int Status;

	/*
	 * Wait while the Flash is busy.
	 */
//	Status = SpiFlashWaitForFlashReady();
//	if(Status != XST_SUCCESS) {
//		return XST_FAILURE;
//	}

	/*
	 * Prepare the Write Buffer.
	 */
	WriteBuffer[BYTE1] = COMMAND_ENTER_4BYTE_ADDRESS_MODE;



	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL,
						0);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function enables writes to the Winbond Serial Flash memory.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		None
*
******************************************************************************/
int SpiFlashWriteEnable(XSpi *SpiPtr)
{
	int Status;

	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady();
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Prepare the WriteBuffer.
	 */
	WriteBuffer[BYTE1] = COMMAND_WRITE_ENABLE;

	/*
	 * Initiate the Transfer.
	 */
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL,
				WRITE_ENABLE_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}



	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}
/*****************************************************************************/
/**
*
* This function is the handler which performs processing for the SPI driver.
* It is called from an interrupt context such that the amount of processing
* performed should be minimized. It is called when a transfer of SPI data
* completes or an error occurs.
*
* This handler provides an example of how to handle SPI interrupts and
* is application specific.
*
* @param	CallBackRef is the upper layer callback reference passed back
*		when the callback function is invoked.
* @param	StatusEvent is the event that just occurred.
* @param	ByteCount is the number of bytes transferred up until the event
*		occurred.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void SpiHandler(void *CallBackRef, u32 StatusEvent, unsigned int ByteCount)
{
	/*
	 * Indicate the transfer on the SPI bus is no longer in progress
	 * regardless of the status event.
	 */

	/*
	 * If the event was not transfer done, then track it as an error.
	 */
	if (StatusEvent != XST_SPI_TRANSFER_DONE) {
		ErrorCount++;
	}
}

/*****************************************************************************/
/**
*
* This function setups the interrupt system such that interrupts can occur
* for the Spi device. This function is application specific since the actual
* system may or may not have an interrupt controller. The Spi device could be
* directly connected to a processor without an interrupt controller.  The
* user should modify this function to fit the application.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None
*
******************************************************************************/
static int SetupInterruptSystem(XSpi *SpiPtr)
{

	int Status;

	/*
	 * Initialize the interrupt controller driver so that
	 * it's ready to use, specify the device ID that is generated in
	 * xparameters.h
	 */
	Status = XIntc_Initialize(&InterruptController, INTC_DEVICE_ID);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect a device driver handler that will be called when an interrupt
	 * for the device occurs, the device driver handler performs the
	 * specific interrupt processing for the device
	 */
	Status = XIntc_Connect(&InterruptController,
				SPI_INTR_ID,
				(XInterruptHandler)XSpi_InterruptHandler,
				(void *)SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Start the interrupt controller such that interrupts are enabled for
	 * all devices that cause interrupts, specific real mode so that
	 * the SPI can cause interrupts through the interrupt controller.
	 */
	Status = XIntc_Start(&InterruptController, XIN_REAL_MODE);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	/*
	 * Enable the interrupt for the SPI.
	 */
	XIntc_Enable(&InterruptController, SPI_INTR_ID);


	/*
	 * Initialize the exception table.
	 */
	Xil_ExceptionInit();

	/*
	 * Register the interrupt controller handler with the exception table.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				(Xil_ExceptionHandler)XIntc_InterruptHandler,
				&InterruptController);

	/*
	 * Enable non-critical exceptions.
	 */
	Xil_ExceptionEnable();


	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function sets the QuadEnable bit in Winbond flash.
*
* @param	None
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		None.
*
******************************************************************************/
int SpiFlashQuadEnable(XSpi *SpiPtr)
{
	int Status;

	/*
	 * Perform the Write Enable operation.
	 */
	Status = SpiFlashWriteEnable(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady();
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Prepare the WriteBuffer.
	 */
	WriteBuffer[BYTE1] = 0x01;
	WriteBuffer[BYTE2] = 0x00;
	WriteBuffer[BYTE3] = 0x02; /* QE = 1 */

	/*
	 * Initiate the Transfer.
	 */
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, 3);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady();
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Verify that QE bit is set by reading status register 2.
	 */

	/*
	 * Prepare the Write Buffer.
	 */
	WriteBuffer[BYTE1] = 0x35;

	/*
	 * Initiate the Transfer.
	 */
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, ReadBuffer,
						STATUS_READ_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

void SpiClearReadBuffer(){

		/*
		 * Clear the read Buffer.
		 */
		for(int Index = 0; Index < PAGE_SIZE + READ_WRITE_QUAD_4BYTE_EXTRA_BYTES + BUFFER_PADDING; Index++) {
			ReadBuffer[Index] = 0x0;
		}

}

int SpiFlashGetNonVolatileConfigStatus(){

	int Status;

	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady();
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	/*
	 * Prepare the Write Buffer.
	 */
	WriteBuffer[BYTE1] = COMMAND_NONVOLATILE_CONFIGREG_READ;


	Status = XSpi_Transfer(&Spi, WriteBuffer, ReadBuffer,
						2);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return Status;
}


int SpiFlashSetUpperAddressRange(){

	int Status;


	Status = SpiFlashWriteEnable(&Spi);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady();
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Initiate the Transfer.
	 */
	Status = XSpi_Transfer(&Spi, WriteBuffer, NULL, 3);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady();
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Prepare the Write Buffer.
	 */
	WriteBuffer[BYTE1] = 0xC5;
	WriteBuffer[BYTE2] = 0x01;


	Status = XSpi_Transfer(&Spi, WriteBuffer, ReadBuffer,
						1);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return Status;
}

#ifdef __PPC__

#include <unistd.h>

/* Save some code and data space on PowerPC 
   by defining a minimal exit */
void exit (int ret)
{
    _exit (ret);
}
#endif
