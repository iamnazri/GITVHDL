/*
 * qspi.h
 *
 *  Created on: 13.07.2020
 *      Author: NAB
 */

#ifndef SRC_QSPI_H_
#define SRC_QSPI_H_

enum{
	LoopbackMode = 1,
	SpiSysEnable = 2,
	MasterSPI = 4,
	ClockPolarity = 8,
	ClockPhase = 16,
	TxFifoReset = 32,
	RxFifoReset = 64,
	ManualSlaveSelectAssertionEnable = 128,
	MasterTransactionInhibit = 256,
	LSBFirst = 512
} qspi_cr_t;

enum{
	RxEmpty = 1,
	RxFull = 2,
	TxEmpty = 4,
	TxFull = 8,
	ModeFaultError = 16,
	SlaveModeSelect = 32,
	ClockPhaseAndPolarityError = 64,
	SlaveModeError = 128,
	MSBError = 256,
	LoopbackError = 512,
	Cmderror = 1024
} qspi_sr_t;

enum{
	SlaveModeFault = 1,
	DTREmpty = 2,
	DTRUnderrun = 4,
	DRRFull = 8,
	DRROverrun = 16,
	TxFifoHalfEmpty = 32,
	SlaveSelMode = 64,
	DRRNotEmpty = 128,
	ClockPolPhaseError = 256,
	IntSlaveModeError = 512,
	IntMSBError = 1024,
	IntLoopbackError = 2048,
	CmdError = 4096
}qspi_ipisr_t;

#endif /* SRC_QSPI_H_ */
