//---------------------------------------------------------------------
//    Copyright (C) 2019, AVI Systems GmbH (http://www.avi-systems.eu)
//
//    Author: Yasin Görgülü (yasin.goerguelue@avi-systems.eu)
//---------------------------------------------------------------------

#include "utility.h"

void printFourCC(fourCC* struct_ptr) {
	printf("First character....:%c\n", struct_ptr->a);
	printf("Second character...:%c\n", (*struct_ptr).b);
	printf("Third character....:%c\n", (*struct_ptr).c);
	printf("Fourth character...:%c\n", (*struct_ptr).d);
}

void printTwoCC(twoCC* struct_ptr) {
	printf("First character....:%c\n", struct_ptr->a);
	printf("Second character...:%c\n", struct_ptr->b);
}

void printTwoII(twoCC struct_ptr) {
	printf("First character....:%d\n", struct_ptr.a);
	printf("Second character...:%d\n", struct_ptr.b);
}

void printObj2D(pObject2D obj)
{
	printf("Pos x...........:%d\n", obj.position.x);
	printf("Pos y...........:%d\n", obj.position.y);
	printf("Pos height......:%d\n", obj.position.height);
	printf("Pos width.......:%d\n", obj.position.width);
	printf("Confidence......:%d\n", obj.conf);
	printf("Objectness......:%d\n", obj.objectness);
	printf("Class...........:%d\n", obj.classAtr);
	printf("Classconf.......:%d\n", obj.classConf);
	printf("Subclass........:%d\n", obj.subClass);
	printf("Subclassconf....:%d\n", obj.subClassConf);
	printf("\n");
}

void printComplexHeader(complexHeaderStruct* header)
{
	printf("Format...........:%c%c%c%c\n", header->format.a, header->format.b, header->format.c, header->format.d);
	printf("Version..........:%d.%d\n", header->version.a, header->version.b);
	printf("Format...........:%d\n", header->source);
	printf("Format...........:%d\n", header->frameId);
	printf("Packetid.........:%d.%d\n", header->packetId.a, header->packetId.b);
	printf("Packet count.....:%d\n", header->packetCount);
	printf("Fragment id......:%d.%d\n", header->fragId.a, header->fragId.b);
	printf("Fragment count...:%d\n", header->packetCount);
	printf("Payload..........:%d\n", header->payload);
	printf("\n");
}

void printPayloadHeader(pStruct payload)
{
	printf("Payloadsize......:%d\n", payload.header.payloadSize);
	printf("Type.............:%d %d\n", payload.header.type);
	printf("Version..........:%d.%d\n", payload.header.version.a, payload.header.version.b);
	printf("\n");
}

void printPacket(packetStruct p)
{
	printf("Format...........:%c%c%c%c\n", p.header.format.a, p.header.format.b, p.header.format.c, p.header.format.d);
	printf("Image-ID..........%d\n", p.header.imageId);
	printf("Sensor-ID........:%d\n", p.header.sensorId);
	printf("Control..........:%d\n", p.header.control);
	printf("Linenumber.......:%d\n", p.header.lineNumber);
	printf("length...........:%d\n", p.header.length);
	printf("Number of Pixel..:%d\n", p.pixel.numberOfElem);
	for (size_t i = 0; i < p.pixel.numberOfElem; i++)
	{
		printf("R:%d G:%d B:%d\n", p.pixel.RGB[i].r, p.pixel.RGB[i].r, p.pixel.RGB[i].b);
	}
	printf("\n");
}

void printComplexPacket(complexPacketStruct p)
{
	printf("NumberOfObject2D %d \n", p.payload.objs.numberOfElem);
	printf("NumberOfSerialnumber %d \n", p.payload.sNumbers.numberOfElem);
	//frames.frame = (pFrame*)malloc((frames.numberOfElem) * sizeof(pFrame));
	for (size_t i = 0; i < p.payload.objs.numberOfElem; i++)
	{
		printObj2D(p.payload.objs.obj[i]);
	}
}

void addObj2D(unsigned char* objList, int* index)
{
	//Size
	objList[*index] = 0;
	objList[*index + 1] = 0;
	objList[*index + 2] = 0;
	objList[*index + 3] = 24;
	//Type
	objList[*index + 4] = 4;
	objList[*index + 5] = 0;
	//Payload version
	objList[*index + 6] = 1;
	objList[*index + 7] = 1;

	objList[*index + 8] = 0;
	objList[*index + 9] = 9;
	objList[*index + 10] = 0;
	objList[*index + 11] = 9;
	objList[*index + 12] = 0;
	objList[*index + 13] = 254;
	objList[*index + 14] = 0;
	objList[*index + 15] = 254;
	objList[*index + 16] = 99;
	objList[*index + 17] = 98;
	objList[*index + 18] = 5;
	objList[*index + 19] = 240;
	objList[*index + 20] = 1;
	objList[*index + 21] = 20;
	objList[*index + 22] = 203;
	objList[*index + 23] = 2;
	
	*index += objList[*index + 1];
}

void createComplexHeader(unsigned char* objList, int* index, int payload)
{
	//Header
	objList[*index] = 'A';
	objList[*index + 1] = 'V';
	objList[*index + 2] = 'I';
	objList[*index + 3] = 'O';
	objList[*index + 4] = 5;
	objList[*index + 5] = 2;
	objList[*index + 6] = 20;
	objList[*index + 7] = 203;
	objList[*index + 8] = 127;
	objList[*index + 9] = 255;
	objList[*index + 10] = 46;
	objList[*index + 11] = 153;
	objList[*index + 12] = 0;
	objList[*index + 13] = 0;
	objList[*index + 14] = 0;
	objList[*index + 15] = 0;
	objList[*index + 16] = 0;
	objList[*index + 17] = 0;
	objList[*index + 18] = 0;
	objList[*index + 19] = 0;
	objList[*index + 20] = 0;
	objList[*index + 21] = payload; //payload count
	*index += 22;
}

void createHeader(unsigned char* objList, int* index)
{
	//Header
	objList[*index] = 'A';
	objList[*index + 1] = 'V';
	objList[*index + 2] = 'I';
	objList[*index + 3] = 'F';

	objList[*index + 4] = 0;
	objList[*index + 5] = 1;
	
	objList[*index + 6] = 1;
	objList[*index + 7] = 1;
	
	objList[*index + 8] = 0;
	objList[*index + 9] = 2;
	
	int bildbreite = 50;
	int length = bildbreite * 3;
	objList[*index + 10] = 0;
	objList[*index + 11] = length;
	
	////RGB  = 255, 255, 255
	for (size_t i = 0; i < length; i++)
	{
		if (i % 3 == 0)
		{
			objList[*index + 12 + i] = 250;
		}
		else if (i % 3 == 1)
		{
			objList[*index + 12 + i] = 252;
		}
		else if (i % 3 == 2)
		{
			objList[*index + 12 + i] = 253;
		}
	}
	*index += 12 + length;
}

void testData(unsigned char* objList)
{
	int index = 0;
	int payloadSize = 1;
	createComplexHeader(objList, &index, payloadSize); // 22
	addObj2D(objList, &index); // + 22
	//addObj2D(objList, &index);// +22
	//addObj2D(objList, &index);// +22
}

void testDataBasic(unsigned char* objList)
{
	int index = 0;
	createHeader(objList, &index);
}
