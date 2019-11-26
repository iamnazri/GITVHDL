----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
--
-- Copyright 2017 AVIrail Systems GmbH. All Rights Reserved.
--
----------------------------------------------------------------------------------------------------------------------------------
-- Module Name: cnt_pkg
-- Target Devices: --- 
-- Dependencies: 
-- $URL: https://redmine.prod.avirail.de/svn/entwicklung.alles/Projects_internal/RIVL/vhdl/trunk/rtl/cnt_pkg.vhd $:
-- $Revision:: 1118                                      $:  Revision der letzten Übertragung 
-- $Author:: TGL                                         $:  Autor der letzten Übertragung    
-- $Date:: 2017-09-29 14:55:23 +0200 (Fr, 29 Sep 2017)   $:  Datum der letzten Übertragung    
-- TestTrack Tag: HDLC-384
-- Description: Die Komponente "cnt" realisiert einen einfachen Zähler. Es wird bis zu Null zurück gezählt, danach wird für einen Takt ausgegeben das die Null erreicht wurde und der Zähler wird automatisch wieder auf den Startwert zurück gesetzt.
--! @file
--! @author Torsten Gloeckner
--! @version 1.0
--! @date 02.08.2016
----------------------------------------------------------------------------------------------------------------------------------


--! @cond DUMMY 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--! @endcond


--!  Komponenten Deklaration von cnt
package cnt_pkg is
    component cnt
  generic (
                                                                    --! @f[cnt\_width \in \mathbb{N}@f]
                                                                    --! @f[D_{cnt\_width} = \{1, ..., 31\}@f]
        cnt_width       : natural := 28;                            --! Definiert die Breite des Zählers [1...31 Bit]

                                                                    --! @f[cnt\_dflt \in \mathbb{N}@f]
                                                                    --! @f[D_{cnt\_dflt} = \{1, ..., 2^{cnt\_width}-1\}@f]
        cnt_dflt        : unsigned := to_unsigned(200000000, 28)    --! Startwert des Zählers
  );
  Port (
                                                                    --! @f[clk\_i \in \mathbb{Z}@f]
                                                                    --! @f[D_{clk\_i} = \{0, 1\}@f]
        clk_i           : in std_logic;                             --! Arbeitstakt des Zählers

                                                                    --! @f[rst\_i \in \mathbb{Z}@f]
                                                                    --! @f[D_{rst\_i} = \{0, 1\}@f]
        rst_i           : in std_logic;                             --! Reset um Komponente komplett zurück zu setzen

                                                                    --! @f[run\_i \in \mathbb{Z}@f]
                                                                    --! @f[D_{run\_i} = \{0, 1\}@f]
        run_i           : in std_logic;                             --! Signal, dass Zähler arbeiten soll
        
                                                                    --! @f[load\_dflt\_i \in \mathbb{Z}@f]
                                                                    --! @f[D_{load\_dflt\_i} = \{0, 1\}@f]
        load_dflt_i     : in std_logic;                             --! Signal, dass Zähler seinen Startwert laden soll

                                                            
                                                                    --! @f[(clk\_i, rst\_i, run\_i, load\_dflt\_i) \to zero\_o@f]
                                                                    --! @f[zero\_o \in \mathbb{Z}, W_{zero\_o} = \{0, 1\}@f]
        zero_o          : out std_logic                             --! Signal, dass der Zahler die Null erreicht hat
  );
    end component cnt;
end package;

