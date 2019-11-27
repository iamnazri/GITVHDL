//---------------------------------------------------------------------
//    Copyright (C) 2019, AVI Systems GmbH (http://www.avi-systems.eu)
//
//    Author: Yasin Görgülü (yasin.goerguelue@avi-systems.eu)
//---------------------------------------------------------------------

#pragma once
#include "parser.h"

int calculateHeaderSize(packetStruct p);

int calcPayload(packetStruct p);

int calculateHeaderComplexSize(complexPacketStruct p);

void createByteStreamComplex(int size, complexPacketStruct p);