//---------------------------------------------------------------------
//    Copyright (C) 2019, AVI Systems GmbH (http://www.avi-systems.eu)
//
//    Author: Yasin Görgülü (yasin.goerguelue@avi-systems.eu)
//---------------------------------------------------------------------

#pragma once
#include <stdint.h>

/*
uint8_t  : one byte :	8 bits
uint16_t : two bytes:	16 bits
uint32_t : four bytes	32 bits
uint64_t : eight bytes	64 bits

uint128_t : 16 bytes	128 bits
uint256_t : 32 bytes	256 bits
uint512_t : 64 bytes	512 bits
*/

typedef struct {
	uint8_t a;
	uint8_t b;
	uint8_t c;
	uint8_t d;

}fourCC;

typedef struct {
	uint8_t a;
	uint8_t b;
}twoCC;

typedef struct {
	uint32_t x;
	uint32_t y;
	uint32_t z;
}gyroskop;

typedef struct {
	uint16_t x;
	uint16_t y;
	uint16_t width;
	uint16_t height;
}obj2DPosition;

//typedef struct {
//}pCalibrationData;
//
//typedef struct {
//}pSWUpdate;

typedef struct {
	uint16_t  partNumber;
	uint16_t  totalParts;
}pBias;

typedef struct {
	uint16_t  partNumber;
	uint16_t  totalParts;
}pFilter;

typedef struct {
	uint8_t  partNumber;
	uint8_t  totalParts;
}pNetworkConf;

typedef struct {
	char *string[32];
}pSerialnumber;

typedef struct {
	uint16_t version;
}pSWVersion;

typedef struct {
	uint16_t id;
	uint16_t type;
	uint64_t timestamp;
}pError;

typedef struct {
	uint32_t sensorTempOne;
	uint32_t sensorTempTwo;
	uint32_t rtiTemp;
	uint32_t fpgaTemp;
	uint8_t environmentBrightness;
	fourCC gps;
	uint32_t vibration;
	gyroskop gyroskop;
}pRTIState;

typedef struct {
	twoCC targetId;
	uint64_t funktionsID;
}pConfig;

typedef struct {
	obj2DPosition position;
	uint8_t conf;
	uint8_t objectness;
	uint16_t classAtr;
	uint8_t classConf;
	uint16_t subClass;
	uint8_t subClassConf;
}pObject2D;

typedef struct {
	uint32_t payloadSize;
	uint16_t type;
	twoCC version;
}pHeaderStruct;

typedef struct {
	pHeaderStruct header;
}pStruct;

typedef struct {
	fourCC format;
	twoCC version;
	uint16_t source;
	uint32_t frameId;
	twoCC packetId;
	uint16_t packetCount;
	twoCC fragId;
	uint16_t fragCount;
	uint16_t payload;
}complexHeaderStruct;

typedef struct {
	fourCC format;
	uint16_t imageId;
	uint8_t sensorId;
	uint8_t control;
	uint16_t lineNumber;
	uint16_t length;
}headerStruct;

typedef struct {
	pError* error;
	int numberOfElem;
}errorList;

typedef struct {
	pObject2D* obj;
	int numberOfElem;
}obj2DList;

typedef struct {
	pRTIState* rtiState;
	int numberOfElem;
}rtiList;

typedef struct {
	//fehlt
	int numberOfElem;
}swUpdateList;

typedef struct {
	pSWVersion* version;
	int numberOfElem;
}swVersList;

typedef struct {
	pBias* bias;
	int numberOfElem;
}biasList;

typedef struct {
	pFilter* filter;
	int numberOfElem;
}filterList;

typedef struct {
	pNetworkConf*netConfig ;
	int numberOfElem;
}netConfList;

typedef struct {
	pSerialnumber* sNumber;
	int numberOfElem;
}sNumberList;

typedef struct {
	//Fehlt* calib;
	int numberOfElem;
}calibList;

typedef struct {
	pConfig* conf;
	int numberOfElem;
}confList;

typedef struct {
	confList confs;
	calibList calibs; 	//fehlt
	sNumberList sNumbers;
	netConfList netConfs;
	filterList filters;
	biasList bias;
	swVersList swVersions; 
	swUpdateList updates; 	//fehlt
	rtiList rtis;
	obj2DList objs;
	errorList errors;
}payloadStruct;

typedef struct {
	complexHeaderStruct header;
	payloadStruct payload;
}complexPacketStruct;

typedef struct {
	uint8_t r;
	uint8_t g;
	uint8_t b;
}RGBStruct;

typedef struct {
	RGBStruct* RGB;
	int numberOfElem;
}pixelList;

typedef struct {
	headerStruct header;
	pixelList pixel;

}packetStruct;

uint16_t arrayToUint16(uint8_t* input);

uint32_t arrayToUint32(uint8_t* input);

uint64_t arrayToUint64(uint8_t* input);

packetStruct parser(unsigned char* objList);

complexPacketStruct complexParser(unsigned char* objList);