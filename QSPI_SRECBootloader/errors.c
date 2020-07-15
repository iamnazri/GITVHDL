/*
 * errors.c
 *
 *  Created on: 13.07.2020
 *      Author: NAB
 */

#include "errors.h"
#include "xil_types.h"
#include "xil_io.h"

uint32_t qspi_check_control(void)
{

	uint32_t reg_ctrl = 0, status = 0, result = 0;
	reg_ctrl = Xil_In32(QSPI_BASEADDR + AXI_QSPI_SPISR);

	if (reg_ctrl & LoopbackMode){
		result += LoopbackMode;
	}

	if (reg_ctrl & SpiSysEnable){
		result += SpiSysEnable;
	}

	if (reg_ctrl & MasterSPI){
		result += MasterSPI;
	}

	if (reg_ctrl & ClockPolarity){
		result += ClockPolarity;
	}

	if (reg_ctrl & ClockPhase){
		result += ClockPhase;
	}

	if (reg_ctrl & TxFifoReset){
		result += TxFifoReset;
	}

	if (reg_ctrl & RxFifoReset){
		result += RxFifoReset;
	}

	if (reg_ctrl & ManualSlaveSelectAssertionEnable){
		result += ManualSlaveSelectAssertionEnable;
	}

	if (reg_ctrl & MasterTransactionInhibit){
		result += MasterTransactionInhibit;
	}

	if (reg_ctrl & LSBFirst){
		result += LSBFirst;
	}


	return result;

}


int qspi_print_control(uint32_t result)
{
	for (int i = 0; i < 10; i++){
		switch(result & ((u32)1<<i) ){
		case LoopbackMode:
			xil_printf("Local loopback mode enabled!\n\r");
			break;
		case SpiSysEnable:
			xil_printf("SPI System enabled!\n\r");
			break;
		case MasterSPI:
			xil_printf("Master Configuration set!\n\r");
			break;
		case ClockPolarity:
			xil_printf("Active Low Clock\n\r");
			break;
		case ClockPhase:
			xil_printf("Clock\n\r");
			break;
		case TxFifoReset:
			xil_printf("Reset transmit fifo pointer\n\r");
			break;
		case RxFifoReset:
			xil_printf("Reset receive FIFO Pointer\n\r");
			break;
		case ManualSlaveSelectAssertionEnable:
			xil_printf("Slave select output follows data in slave select reg\n\r");
			break;
		case MasterTransactionInhibit:
			xil_printf("Master Transaction is disabled\n\r");
			break;
		case LSBFirst:
			xil_printf("LSB data transfer format \n\r");
			break;
		}

		switch(!result & ((u32)1<<i)) {
		case LoopbackMode:
			xil_printf("SPI operating in non-loopback Mode\n\r");
			break;
		case ClockPolarity:
			xil_printf("Active high clock\n\r");
			break;
		case MasterTransactionInhibit:
			xil_printf("MasterTransaction is enabled!\n\r");
			break;
		case LSBFirst:
			xil_printf("MSB data transfer format\n\r");
			break;
		default:
			break;
		}

	}
	xil_printf("\n\r");
	return 0;
}

uint32_t qspi_check_status(void)
{
	uint32_t reg_status = 0, status = 0, result = 0;
	reg_status = Xil_In32(QSPI_BASEADDR + AXI_QSPI_SPICR);

	if (reg_status & RxEmpty){
		result += RxEmpty;
	}

	if (reg_status & RxFull){
		result += RxFull;
	}

	if (reg_status & TxEmpty){
		result += TxEmpty;
	}

	if (reg_status & TxFull){
		result += TxFull;
	}

	if (reg_status & ModeFaultError){
		result += ModeFaultError;
	}

	if (reg_status & SlaveModeSelect){
		result += SlaveModeSelect;
	}

	if (reg_status & ClockPhaseAndPolarityError){
		result += ClockPhaseAndPolarityError;
	}

	if (reg_status & SlaveModeError){
		result += SlaveModeError;
	}

	if (reg_status & MSBError){
		result += MSBError;
	}

	if (reg_status & Cmderror){
		result += Cmderror;
	}

	return result;
}

int qspi_print_status(uint32_t result)
{

	for (int i = 0; i < 12; i++){
		switch(result & ((u32)1<<i) ){
		case RxEmpty:
			xil_printf("Receive Fifo empty!\n\r");
			break;
		case RxFull:
			xil_printf("Receive Fifo Full!\n\r");
			break;
		case TxEmpty:
			xil_printf("Trannsmit Fifo empty!\n\r");
			break;
		case TxFull:
			xil_printf("Transmit Fifo Full\n\r");
			break;
		case ModeFaultError:
			xil_printf("Mode Error Condition detected!\n\r");
			break;
		case SlaveModeSelect:
			xil_printf("QSPI in slave mode OR master SPI core asserted the chip select pin!\n\r");
			break;
		case ClockPhaseAndPolarityError:
			xil_printf("CPOL and CPHA are set to 01 or 10.\n\r");
			//also set when mem is chosen as micron, soansion or micronix
			// only applicable when core in dual or quad legacy or enchanced axi4
			break;
		case SlaveModeError:
			xil_printf("Slave Mode error. SPI is in Dual or quad mode OR master is set to 0 in SPICR\n\r");
			break;
		case MSBError:
			xil_printf("MSB Error. SPI in dual or quad mode AND LSB first is set in the spiCR\n\r");
			break;
		case LoopbackError:
			xil_printf("Loopback error\n\r");
			break;
		case Cmderror:
			xil_printf("Command error. First entry in the spi dtr fifo after reset \n\rdo not match with the supported cmd list for the particular memory\n\r");
			break;
		default:
			break;

		}

	}
	xil_printf("\n\r");
	return 0;
}

uint32_t qspi_check_irstatus(void)
{
	uint32_t reg_status = 0, status = 0, result = 0;
	reg_status = Xil_In32(QSPI_BASEADDR + AXI_QSPI_IPISR);

	if (reg_status & SlaveModeFault){
		result += SlaveModeFault;
	}

	if (reg_status & DTREmpty){
		result += DTREmpty;
	}

	if (reg_status & DTRUnderrun){
		result += DTRUnderrun;
	}

	if (reg_status & DRRFull){
		result += DRRFull;
	}

	if (reg_status & DRROverrun){
		result += DRROverrun;
	}

	if (reg_status & TxFifoHalfEmpty){
		result += TxFifoHalfEmpty;
	}

	if (reg_status & SlaveSelMode){
		result += SlaveSelMode;
	}

	if (reg_status & DRRNotEmpty){
		result += DRRNotEmpty;
	}

	if (reg_status & ClockPolPhaseError){
		result += ClockPolPhaseError;
	}

	if (reg_status & IntSlaveModeError){
		result += SlaveModeError;
	}

	if (reg_status & IntMSBError){
		result += IntMSBError;
	}


	if (reg_status & IntLoopbackError){
		result += LoopbackError;
	}

	if (reg_status & CmdError){
		result += CmdError;
	}

	return result;
}

int qspi_print_irstatus(uint32_t result)
{

	for (int i = 0; i < 12; i++){
		switch(result & ((u32)1<<i) ){
		case SlaveModeFault:
			xil_printf("SlaveModeFault!\n\r");
			break;
		case DTREmpty:
			xil_printf("DTREmpty!\n\r");
			break;
		case DTRUnderrun:
			xil_printf("DTRUnderrun!\n\r");
			break;
		case DRRFull:
			xil_printf("DRRFull\n\r");
			break;
		case DRROverrun:
			xil_printf("DRROverrun!\n\r");
			break;
		case TxFifoHalfEmpty:
			xil_printf("TxFifoHalfEmpty!\n\r");
			break;
		case SlaveSelMode:
			xil_printf("SlaveSelMode\n\r");
			break;
		case DRRNotEmpty:
			xil_printf("DRRNotEmpty\n\r");
			break;
		case ClockPolPhaseError:
			xil_printf("ClockPolPhaseError\n\r");
			break;
		case IntSlaveModeError:
			xil_printf("SlaveModeError\n\r");
			break;
		case IntMSBError:
			xil_printf("IntMSBError\n\r");
			break;
		case IntLoopbackError:
			xil_printf("LoopbackError\n\r");
			break;
		case CmdError:
			xil_printf("CmdError\n\r");
			break;
		default:
			break;

		}

	}
	xil_printf("\n\r");
	return 0;
}

