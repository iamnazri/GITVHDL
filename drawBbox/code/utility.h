//---------------------------------------------------------------------
//    Copyright (C) 2019, AVI Systems GmbH (http://www.avi-systems.eu)
//
//    Author: Yasin Görgülü (yasin.goerguelue@avi-systems.eu)
//---------------------------------------------------------------------

#pragma once
#include "parser.h"
#include <stdio.h>

void printFourCC(fourCC* struct_ptr);

void printTwoCC(twoCC* struct_ptr);

void printTwoII(twoCC struct_ptr);

void printObj2D(pObject2D obj);

void printComplexHeader(complexHeaderStruct* header);

void printPayloadHeader(pStruct payload);

void printPacket(packetStruct p);

void printComplexPacket(complexPacketStruct packet);

void addObj2D(unsigned char* objList, int* index);

void createComplexHeader(unsigned char* objList, int* index, int payload);

void testDataBasic(unsigned char* objList);