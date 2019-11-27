//---------------------------------------------------------------------
//    Copyright (C) 2019, AVI Systems GmbH (http://www.avi-systems.eu)
//
//    Author: Yasin Görgülü (yasin.goerguelue@avi-systems.eu)
//---------------------------------------------------------------------

#include "serializer.h"

int calculateHeaderSize(packetStruct p)
{
	int headerSize = sizeof(p.header.format)
		+ sizeof(p.header.imageId)
		+ sizeof(p.header.sensorId)
		+ sizeof(p.header.control)
		+ sizeof(p.header.lineNumber)
		+ sizeof(p.header.length);
	return headerSize;
}

int calcPayload(packetStruct p)
{
	int sizePayload = 0;

	for (size_t i = 0; i < p.pixel.numberOfElem; i++)
	{
		sizePayload += sizeof(p.pixel.RGB[i].r)
			+ sizeof(p.pixel.RGB[i].g)
			+ sizeof(p.pixel.RGB[i].b);
	}

	return sizePayload;
}

int calculateHeaderComplexSize(complexPacketStruct p)
{
	int headerSize = sizeof(p.header.format)
		+ sizeof(p.header.version)
		+ sizeof(p.header.source)
		+ sizeof(p.header.frameId)
		+ sizeof(p.header.packetId)
		+ sizeof(p.header.packetCount)
		+ sizeof(p.header.fragId)
		+ sizeof(p.header.fragCount)
		+ sizeof(p.header.payload);
	return headerSize;
}

int calcObjSize(pObject2D obj)
{
	int sizePayload = 0;
	sizePayload += 2; //payload-size
	sizePayload += 2; //type
	sizePayload += 2; //version

	sizePayload += sizeof(obj.classAtr) +
		sizeof(obj.classConf) +
		sizeof(obj.conf) +
		sizeof(obj.objectness) +
		sizeof(obj.subClass) +
		sizeof(obj.subClassConf) +
		sizeof(obj.position.x) +
		sizeof(obj.position.y) +
		sizeof(obj.position.height) +
		sizeof(obj.position.width);

	return sizePayload;
}

int calculateSize(payloadStruct p)
{
	int sizePayload = 0;

	if (p.confs.numberOfElem)
	{
		//printf("number of Elements confs %d \n", p.confs.numberOfElem);
		for (size_t i = 0; i < p.confs.numberOfElem; i++)
		{
			//For each frame one payload header
			sizePayload += 2; //payload-size
			sizePayload += 2; //type
			sizePayload += 2; //version
			sizePayload += sizeof(p.confs.conf[i]);
		}
	}

	if (p.calibs.numberOfElem)
	{
		//printf("number of Elements calibs %d \n", p.calibs.numberOfElem);
		for (size_t i = 0; i < p.calibs.numberOfElem; i++)
		{
			//For each frame one payload header
			//sizePayload += 2; //payload-size
			//sizePayload += 2; //type
			//sizePayload += 2; //version
			//printf("sizePayload %d \n", sizeof(p.frames.frame[i]));
			//sizePayload += sizeof(p.calibs.calib[i]);
		}
	}

	if (p.sNumbers.numberOfElem)
	{
		//printf("number of Elements snumbers %d \n", p.sNumbers.numberOfElem);
		for (size_t i = 0; i < p.sNumbers.numberOfElem; i++)
		{
			sizePayload += 2; //payload-size
			sizePayload += 2; //type
			sizePayload += 2; //version
			sizePayload += 32;
		}
	}

	if (p.netConfs.numberOfElem)
	{
		//printf("number of Elements netconfig %d \n", p.netConfs.numberOfElem);
		for (size_t i = 0; i < p.netConfs.numberOfElem; i++)
		{
			sizePayload += 2; //payload-size
			sizePayload += 2; //type
			sizePayload += 2; //version
			sizePayload += sizeof(p.netConfs.netConfig[i]);
		}
	}

	if (p.filters.numberOfElem)
	{
		//printf("number of Elements filters %d \n", p.filters.numberOfElem);
		for (size_t i = 0; i < p.filters.numberOfElem; i++)
		{
			sizePayload += 2; //payload-size
			sizePayload += 2; //type
			sizePayload += 2; //version
			sizePayload += sizeof(p.filters.filter[i]);
		}
	}

	if (p.bias.numberOfElem)
	{
		//printf("number of Elements bias %d \n", p.bias.numberOfElem);
		for (size_t i = 0; i < p.bias.numberOfElem; i++)
		{
			sizePayload += 2; //payload-size
			sizePayload += 2; //type
			sizePayload += 2; //version
			sizePayload += sizeof(p.bias.bias);
		}
	}

	if (p.swVersions.numberOfElem)
	{
		//printf("number of Elements swVersion %d \n", p.swVersions.numberOfElem);
		for (size_t i = 0; i < p.swVersions.numberOfElem; i++)
		{
			sizePayload += 2; //payload-size
			sizePayload += 2; //type
			sizePayload += 2; //version
			sizePayload += sizeof(p.swVersions.version[i]);
		}
	}

	if (p.updates.numberOfElem)
	{
		//printf("number of Elements updates %d \n", p.updates.numberOfElem);
		for (size_t i = 0; i < p.updates.numberOfElem; i++)
		{
			//sizePayload += 2; //payload-size
			//sizePayload += 2; //type
			//sizePayload += 2; //version
			//sizePayload += sizeof(p.updates.update);
		}
	}

	if (p.rtis.numberOfElem)
	{
		//printf("number of Elements rtis %d \n", p.rtis.numberOfElem);
		for (size_t i = 0; i < p.rtis.numberOfElem; i++)
		{
			sizePayload += 2; //payload-size
			sizePayload += 2; //type
			sizePayload += 2; //version
			sizePayload += sizeof(p.rtis.rtiState[i]);
		}
	}

	if (p.objs.numberOfElem)
	{
		//printf("number of Elements objs %d \n", p.objs.numberOfElem);
		for (size_t i = 0; i < p.objs.numberOfElem; i++)
		{
			sizePayload += calcObjSize(p.objs.obj[i]);
		}
	}

	if (p.errors.numberOfElem)
	{
		//printf("number of Elements erors %d \n", p.errors.numberOfElem);
		for (size_t i = 0; i < p.errors.numberOfElem; i++)
		{
			sizePayload += 2; //payload-size
			sizePayload += 2; //type
			sizePayload += 2; //version
			sizePayload += sizeof(p.errors.error[i]);
		}
	}
	return sizePayload;
}

void createByteStream(int size, packetStruct p)
{
	unsigned char* byteStreamOutput = (unsigned char*)malloc(sizeof(unsigned char) * size);

	byteStreamOutput[0] = p.header.format.a;
	byteStreamOutput[1] = p.header.format.b;
	byteStreamOutput[2] = p.header.format.c;
	byteStreamOutput[3] = p.header.format.d;
	uint16_t* iamgeId = (uint16_t*)&byteStreamOutput[4];
	*iamgeId = arrayToUint16(&p.header.imageId);

	byteStreamOutput[6] = p.header.sensorId;
	byteStreamOutput[7] = p.header.control;
	uint16_t* lineNumber = (uint16_t*)&byteStreamOutput[8];
	*lineNumber = arrayToUint16(&p.header.lineNumber);
	uint16_t* length = (uint16_t*)&byteStreamOutput[10];
	*length = arrayToUint16(&p.header.length);

	unsigned int index = 22;

	for (size_t i = 0; i < p.pixel.numberOfElem; i++)
	{
		byteStreamOutput[index] = p.pixel.RGB[i].r;
		byteStreamOutput[index+1] = p.pixel.RGB[i].g;
		byteStreamOutput[index+2] = p.pixel.RGB[i].b;
		index += 3;
	}

	//for (size_t i = 0; i < index; i++)
	//{
	//	printf("value :%d \n", byteStreamOutput[i]);
	//}
}

void createByteStreamComplex(int size, complexPacketStruct p)
{
	unsigned char* byteStreamOutput = (unsigned char*)malloc(sizeof(unsigned char) * size);

	byteStreamOutput[0] = p.header.format.a;
	byteStreamOutput[1] = p.header.format.b;
	byteStreamOutput[2] = p.header.format.c;
	byteStreamOutput[3] = p.header.format.d;
	byteStreamOutput[4] = p.header.version.a;
	byteStreamOutput[5] = p.header.version.b;
	uint16_t* val = (uint16_t*)&byteStreamOutput[6];
	*val = arrayToUint16(&p.header.source);
	uint32_t* valUInt32 = (uint32_t*)&byteStreamOutput[8];
	*valUInt32 = p.header.frameId;
	byteStreamOutput[12] = p.header.packetId.a;
	byteStreamOutput[13] = p.header.packetId.b;
	uint16_t* val1 = (uint16_t*)&byteStreamOutput[14];
	*val1 = p.header.packetCount;
	byteStreamOutput[16] = p.header.fragId.a;
	byteStreamOutput[17] = p.header.fragId.b;
	uint16_t* val2 = (uint16_t*)&byteStreamOutput[18];
	*val2 = p.header.fragCount;
	uint16_t* payload = (uint16_t*)&byteStreamOutput[20];
	*payload = p.header.payload;

	unsigned int index = 22;

	for (size_t i = 0; i < p.payload.objs.numberOfElem; i++)
	{
		uint16_t* hPayloadOb = (uint16_t*)&byteStreamOutput[index];
		*hPayloadOb = calcObjSize(p.payload.objs.obj[i]);
		byteStreamOutput[index + 2] = 0;
		byteStreamOutput[index + 3] = 1;
		byteStreamOutput[index + 4] = 2;
		byteStreamOutput[index + 5] = 2;

		uint16_t* posX = (uint16_t*)&byteStreamOutput[index + 6];
		*posX = p.payload.objs.obj[i].position.x;

		uint16_t* posY = (uint16_t*)&byteStreamOutput[index + 8];
		*posY = p.payload.objs.obj[i].position.y;

		uint16_t* width = (uint16_t*)&byteStreamOutput[index + 10];
		*width = p.payload.objs.obj[i].position.width;

		uint16_t* height = (uint16_t*)&byteStreamOutput[index + 12];
		*height = p.payload.objs.obj[i].position.width;

		byteStreamOutput[index + 14] = p.payload.objs.obj[i].conf;
		byteStreamOutput[index + 15] = p.payload.objs.obj[i].objectness;

		uint16_t* class = (uint16_t*)&byteStreamOutput[index + 16];
		*class = p.payload.objs.obj[i].classAtr;
		byteStreamOutput[index + 18] = p.payload.objs.obj[i].classConf;

		uint16_t* subClass = (uint16_t*)&byteStreamOutput[index + 19];
		*subClass = p.payload.objs.obj[i].classAtr;

		byteStreamOutput[index + 18] = p.payload.objs.obj[i].subClassConf;

		index += *hPayloadOb;
		break;
	}

	//for (size_t i = 0; i < index; i++)
	//{
	//	printf("value :%d \n", byteStreamOutput[i]);
	//}
}
