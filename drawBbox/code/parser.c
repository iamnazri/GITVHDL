//---------------------------------------------------------------------
//    Copyright (C) 2019, AVI Systems GmbH (http://www.avi-systems.eu)
//
//    Author: Yasin Görgülü (yasin.goerguelue@avi-systems.eu)
//---------------------------------------------------------------------

#include "parser.h"

uint16_t arrayToUint16(uint8_t* input)
{
	uint16_t temp;
	uint8_t* temp2 = &temp;
	temp2[1] = input[0];
	temp2[0] = input[1];
	return temp;
}

uint32_t arrayToUint32(uint8_t* input)
{
	uint32_t temp;
	uint8_t* temp2 = &temp;
	temp2[0] = input[3];
	temp2[1] = input[2];
	temp2[2] = input[1];
	temp2[3] = input[0];
	return temp;
}

uint64_t arrayToUint64(uint8_t* input) {
	uint64_t temp;
	uint8_t* temp2 = &temp;
	temp2[0] = input[7];
	temp2[1] = input[6];
	temp2[2] = input[5];
	temp2[3] = input[4];
	temp2[4] = input[3];
	temp2[5] = input[2];
	temp2[6] = input[1];
	temp2[7] = input[0];
	return temp;
}

void countNumberOfData(unsigned char* objList, int payloadCount, int* countConf, int* countCalib, int* countSerNum, int* countNetConf,
	int* countFilter, int* countBias, int* countSWVer, int* countSWUpdate, int* countRti, int* countObj, int* countErr)
{
	int	index = 22;
	printf("fdsgsdgfsdgds case %d  \n", arrayToUint16(&objList[index + 4]));
	for (int i = 0; i < payloadCount; i++) {
		//printf("here should be payloadsize %d \n", arrayToUint16(&objList[index]));
		switch (arrayToUint16(&objList[index + 4])) {
		case 1:
			//printf("Konfiguration \n");
			(*countConf)++;
			break;
		case 2:
			//printf("Kalibierdaten \n");
			//printf("Wird nachgereicht \n");
			(*countCalib)++;
			break;
		case 4:
			//printf("Serien-Number\n");
			(*countSerNum)++;
			break;
		case 8:
			//printf("Netz-Config\n");
			(*countNetConf)++;
			break;
		case 16:
			//printf("Filter\n");
			(*countFilter)++;
			break;
		case 32:
			//printf("Biaswerte\n");
			(*countBias)++;
			break;
		case 64:
			//printf("SW-Version\n");
			(*countSWVer)++;
			break;
		case 128:
			//printf("SW Update\n");
			//printf("Wird nachgereicht \n");
			(*countSWUpdate)++;
			break;
		case 256:
			//printf("Frame obj\n");
			break;
		case 512:
			//printf("RTI State\n");
			(*countRti)++;
			break;
		case 1024:
			//printf("Obj2D\n");
			(*countObj)++;
			break;
		case 2048:
			//printf("Failcode\n");
			(*countErr)++;
		default:
			printf("default case %d  \n", (arrayToUint16(&objList[index + 3])));
			break;
		}
		index = index + arrayToUint16(&objList[index]);
	}
}

packetStruct parser(unsigned char* objList) {
	packetStruct basicPacket;

	basicPacket.header.format.a = objList[0];
	basicPacket.header.format.b = objList[1];
	basicPacket.header.format.c = objList[2];
	basicPacket.header.format.d = objList[3];
	basicPacket.header.imageId = arrayToUint16(objList + 4);
	basicPacket.header.sensorId = objList[6];
	basicPacket.header.control = objList[7];
	basicPacket.header.lineNumber = arrayToUint16(&objList[8]);
	basicPacket.header.length = arrayToUint16(&objList[10]);
	basicPacket.pixel.numberOfElem = 0;
	basicPacket.pixel.RGB = (RGBStruct*)malloc((basicPacket.header.length) * sizeof(RGBStruct)); ;
	//length / 3 = 1 Pixel 
	for (size_t i = 0; i < basicPacket.header.length; i++)
	{
		RGBStruct rgb;
		if (i % 3 == 0) 
		{
			rgb.r = objList[12 + i];
		}
		else if (i % 3 == 1)
		{
			rgb.g = objList[12 + i];
		}
		else if (i % 3 == 2)
		{
			rgb.b = objList[12 + i];
			basicPacket.pixel.RGB[basicPacket.pixel.numberOfElem]= rgb;
			basicPacket.pixel.numberOfElem++;
		}
	}
	return basicPacket;
}

complexPacketStruct complexParser(unsigned char* objList) {
	complexPacketStruct packet;

	packet.header.format.a = objList[0];
	packet.header.format.b = objList[1];
	packet.header.format.c = objList[2];
	packet.header.format.d = objList[3];
	packet.header.version.a = objList[4];
	packet.header.version.b = objList[5];

	//packet.header.source.a = arrayToUint16(&objList[6]);
	packet.header.source = arrayToUint16(objList + 6);
	packet.header.frameId = arrayToUint32(&objList[8]);
	packet.header.packetId.a = objList[12];
	packet.header.packetId.b = objList[13];
	packet.header.packetCount = arrayToUint16(&objList[14]);
	packet.header.fragId.a = objList[16];
	packet.header.fragId.b = objList[17];
	packet.header.fragCount = arrayToUint16(&objList[18]);
	packet.header.payload = arrayToUint16(&objList[20]);

	int	index = 22;
	int numberOfConf = 0;
	int numberOfObj2D = 0;
	int numberOfRtiState = 0;
	int numberOfError = 0;
	int numberOfSwVersion = 0;
	int numberOfSerNumber = 0;
	int numberOfNetConf = 0;
	int numberOfFilter = 0;
	int numberOfBias = 0;
	int numberCalib = 0;
	int numberSwUpdate = 0;

	countNumberOfData(objList, packet.header.payload, &numberOfConf, &numberCalib, &numberOfSerNumber, &numberOfNetConf, &numberOfFilter, &numberOfBias, &numberOfSwVersion,
		&numberSwUpdate, &numberOfRtiState, &numberOfObj2D, &numberOfError);

	confList confs;
	confs.conf = (pConfig*)malloc(numberOfConf * sizeof(pConfig));
	confs.numberOfElem = 0;

	calibList calibs;
	//Wird nachgereicht
	calibs.numberOfElem = 0;

	sNumberList sNumbers;
	sNumbers.sNumber = (pSerialnumber*)malloc(numberOfSerNumber * sizeof(pSerialnumber));
	sNumbers.numberOfElem = 0;

	netConfList netConfs;
	netConfs.netConfig = (pNetworkConf*)malloc(numberOfNetConf * sizeof(pNetworkConf));
	netConfs.numberOfElem = 0;

	filterList filters;
	filters.filter = (pFilter*)malloc(numberOfFilter * sizeof(pFilter));
	filters.numberOfElem = 0;

	biasList bias;
	bias.bias = (pBias*)malloc(numberOfBias * sizeof(pBias));
	bias.numberOfElem = 0;

	swVersList swVersions;
	swVersions.version = (pSWVersion*)malloc(numberOfSwVersion * sizeof(pSWVersion));
	swVersions.numberOfElem = 0;

	swUpdateList updates;
	//Wird nachgereicht
	updates.numberOfElem = 0;

	rtiList rtis;
	rtis.rtiState = (pRTIState*)malloc(numberOfRtiState * sizeof(pRTIState));
	rtis.numberOfElem = 0;

	obj2DList objs;
	objs.obj = (pObject2D*)malloc(numberOfObj2D * sizeof(pObject2D));
	objs.numberOfElem = 0;

	errorList errors;
	errors.error = (pError*)malloc(numberOfError * sizeof(pError));
	errors.numberOfElem = 0;

	index = 22;
	pHeaderStruct* header = (pHeaderStruct*)malloc((packet.header.payload) * sizeof(pHeaderStruct));
	//pStruct* payload = (pStruct*)malloc((packet.header.payload) * sizeof(pStruct));
	int sizeIns = 22;
	for (int i = 0; i < packet.header.payload; i++)
	{
		header[i].payloadSize = arrayToUint32(&objList[index]);
		header[i].type= arrayToUint16(&objList[index + 4]);
		header[i].version.a = objList[index + 6];
		header[i].version.b = objList[index + 7];

		switch (header[i].type) {
		case 1:
			confs.conf[confs.numberOfElem].targetId.a = objList[index + 8];
			confs.conf[confs.numberOfElem].targetId.b = objList[index + 9];
			confs.conf[confs.numberOfElem].funktionsID = arrayToUint64(&objList[index + 10]);
			confs.numberOfElem++;
			break;
		case 2:
			calibs.numberOfElem++;
			break;
		case 4:
			for (int i = 0; i < 32; i++)
			{
				sNumbers.sNumber[sNumbers.numberOfElem].string[i] = objList[index + 8 + i];
				//printf("%c ", packet.payload[i].data.serialNumber.string[i]);
			}
			sNumbers.numberOfElem++;
			break;
		case 8:
			netConfs.netConfig[netConfs.numberOfElem].partNumber = objList[index + 8];
			netConfs.netConfig[netConfs.numberOfElem].totalParts = objList[index + 9];
			netConfs.numberOfElem++;
			break;
		case 16:
			filters.filter[filters.numberOfElem].partNumber = objList[index + 8];
			filters.filter[filters.numberOfElem].totalParts = objList[index + 9];
			filters.numberOfElem++;
			break;
		case 32:
			bias.bias[bias.numberOfElem].partNumber = objList[index + 8];
			bias.bias[bias.numberOfElem].totalParts = objList[index + 9];
			bias.numberOfElem++;
			break;
		case 64:
			swVersions.version[swVersions.numberOfElem].version = arrayToUint32(&objList[index + 8]);
			swVersions.numberOfElem++;
			break;
		case 128:
			updates.numberOfElem++;
			break;
		case 256:
			break;
		case 512:
			rtis.rtiState[rtis.numberOfElem].sensorTempOne = arrayToUint32(&objList[index + 8]);
			rtis.rtiState[rtis.numberOfElem].sensorTempTwo = arrayToUint32(&objList[index + 12]);
			rtis.rtiState[rtis.numberOfElem].rtiTemp = arrayToUint32(&objList[index + 16]);
			rtis.rtiState[rtis.numberOfElem].fpgaTemp = arrayToUint32(&objList[index + 20]);
			rtis.rtiState[rtis.numberOfElem].environmentBrightness = objList[index + 21];
			rtis.rtiState[rtis.numberOfElem].gps.a = arrayToUint32(&objList[index + 22]);
			rtis.rtiState[rtis.numberOfElem].gps.b = arrayToUint32(&objList[index + 26]);
			rtis.rtiState[rtis.numberOfElem].gps.c = arrayToUint32(&objList[index + 30]);
			rtis.rtiState[rtis.numberOfElem].gps.d = arrayToUint32(&objList[index + 34]);
			rtis.rtiState[rtis.numberOfElem].vibration = arrayToUint32(&objList[index + 38]);
			rtis.rtiState[rtis.numberOfElem].gyroskop.x = arrayToUint32(&objList[index + 42]);
			rtis.rtiState[rtis.numberOfElem].gyroskop.y = arrayToUint32(&objList[index + 46]);
			rtis.rtiState[rtis.numberOfElem].gyroskop.z = arrayToUint32(&objList[index + 50]);
			rtis.numberOfElem++;
			break;
		case 1024:
			objs.obj[objs.numberOfElem].position.x = arrayToUint16(&objList[index + 8]);
			objs.obj[objs.numberOfElem].position.y = arrayToUint16(&objList[index + 10]);
			objs.obj[objs.numberOfElem].position.height = arrayToUint16(&objList[index + 12]);
			objs.obj[objs.numberOfElem].position.width = arrayToUint16(&objList[index + 14]);
			objs.obj[objs.numberOfElem].conf = objList[index + 16];
			objs.obj[objs.numberOfElem].objectness = objList[index + 17];
			objs.obj[objs.numberOfElem].classAtr = arrayToUint16(&objList[index + 18]);
			objs.obj[objs.numberOfElem].classConf = objList[index + 20];
			objs.obj[objs.numberOfElem].subClass = arrayToUint16(&objList[index + 21]);
			objs.obj[objs.numberOfElem].subClassConf = objList[index + 23];
			objs.numberOfElem++;
			break;
		case 2048:
			errors.error[errors.numberOfElem].id = arrayToUint16(&objList[index + 8]);
			errors.error[errors.numberOfElem].type = arrayToUint16(&objList[index + 10]);
			errors.error[errors.numberOfElem].timestamp = arrayToUint64(&objList[index + 12]);
			errors.numberOfElem = 0;
		default:
			printf("default case %d  \n", header[i].type);
			break;
		}
		index = index + header[i].payloadSize;
		//printf("payloadsize %d \n", header[i].payloadSize);
		sizeIns += header[i].payloadSize;
	}
	printf("Groeße des bytestreams %d \n", sizeIns);

	payloadStruct payloadData;
	payloadData.confs = confs;
	payloadData.calibs = calibs;
	payloadData.sNumbers = sNumbers;
	payloadData.netConfs = netConfs;
	payloadData.filters = filters;
	payloadData.bias = bias;
	payloadData.swVersions = swVersions;
	payloadData.updates = updates;
	payloadData.rtis = rtis;
	payloadData.objs = objs;
	payloadData.errors = errors;
	packet.payload = payloadData;
	return packet;
}
