//---------------------------------------------------------------------
//    Copyright (C) 2019, AVI Systems GmbH (http://www.avi-systems.eu)
//
//    Author: Yasin Görgülü (yasin.goerguelue@avi-systems.eu)
//---------------------------------------------------------------------

#include "parser.h"
#include "serializer.h"
#include "utility.h"

int main()
{
	
	int sizeObjectlist = 200;
	unsigned char* objList = (unsigned char*)malloc(sizeof(unsigned char) * sizeObjectlist);
	testDataBasic(objList);
	//testData(objList);
	if (objList[0] == 'A' && objList[1] == 'V' && objList[2] == 'I' && objList[3] == 'O') 
	{
		//Parser
		complexPacketStruct p = complexParser(objList);
		//printComplexPacket(p);
		
		//serializer
		int sizeToAllocate = calculateSize(p.payload) + calculateHeaderComplexSize(p);
		createByteStreamComplex(sizeToAllocate, p);
	}
	else if (objList[0] == 'A' && objList[1] == 'V' && objList[2] == 'I' && objList[3] == 'F')
	{
		//Parser
		packetStruct p = parser(objList);
		printPacket(p);
		//serializer
		int sizeToAllocate = calculateHeaderSize(p) + calcPayload(p); 
		createByteStream(sizeToAllocate, p);
	}
	else 
	{
		printf("No parser available");
	}
}