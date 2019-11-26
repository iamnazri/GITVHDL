----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
--
-- Copyright 2017 AVIrail Systems GmbH. All Rights Reserved.
--
----------------------------------------------------------------------------------------------------------------------------------
-- Module Name: cnt
-- Target Devices: --- 
-- Dependencies: 
-- $URL:: https://redmine.prod.avirail.de/svn/entwicklun#$:
-- $Revision:: 1118                                      $:  Revision der letzten Übertragung 
-- $Author:: TGL                                         $:  Autor der letzten Übertragung    
-- $Date:: 2017-09-29 14:55:23 +0200 (Fr, 29 Sep 2017)   $:  Datum der letzten Übertragung    
-- TestTrack Tag: HDLC-384
-- Description: Die Komponente "cnt" realisiert einen einfachen Zähler. Es wird bis zu Null zurück gezählt, danach wird für einen Takt ausgegeben das die Null erreicht wurde und der Zähler wird automatisch wieder auf den Startwert zurück gesetzt.
--! @file
--! @author Torsten Gloeckner
--! @version 1.0
--! @date 02.08.2016
--! @vhdlflow cnt
----------------------------------------------------------------------------------------------------------------------------------

--! @cond DUMMY 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--! @endcond


--!  Zähler der von einem Startwert bis Null zählt.
--!  Die Komponente "cnt" realisiert einen einfachen Zähler. Es wird bis zu Null zurück gezählt, danach wird für einen Takt ausgegeben das die Null erreicht wurde und der Zähler wird automatisch wieder auf den Startwert zurückgesetzt. 
entity cnt is
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
end cnt;


--! Design von cnt
architecture rtl_cnt of cnt is

    type reg_t is record
        cnt        : unsigned(cnt_width - 1 downto 0);
        run        : std_logic;
        zero       : std_logic;
        load_dflt  : std_logic;
    end record;
    
    constant dflt_reg_c : reg_t := (
        cnt         => cnt_dflt - 1,
        run         => '0',
        zero        => '0',
        load_dflt   => '0'
    );
    
    signal r, rin : reg_t := dflt_reg_c;

begin
--! Bei einem "1" an run_i soll von einem Startwert bis Null gezählt werden. Bei Erreichen von Null wird dies für einen Takt signalisiert und anschließend der Zähler wieder auf den Startwert zurückgesetzt. Zusätzlich kann der Zähler jeder zeit über load_dflt_i zurückgesetzt werden.
--! @dotfile "cnt" "Zustandsdiagramm von \"cnt\"" width=8cm
comb : process(r, run_i, load_dflt_i)
    variable v : reg_t;
    begin
        v := r;
        v.run := run_i;
        v.load_dflt := load_dflt_i;
        v.zero := '0';

        if (r.run = '1') then
            v.cnt := r.cnt - 1;
        end if;
        if (r.cnt = 0) then
            v.cnt := cnt_dflt - 1;
            v.zero := '1';
        elsif (r.load_dflt = '1') then
            v.cnt := cnt_dflt - 1;
        end if;
        


        
        zero_o      <= r.zero;
        rin         <= v;
    end process;


--! Prozess um die sequentielle Abarbeitung synchron zu clk_i umzusetzen inklusive eines asynhronen Resets
--! @dotfile "sequ_cnt_clk" "Prinzip der sequentiellen Wertübernahme durch sequ_cnt_clk" width=8cm
sequ : process (clk_i, rst_i) begin
        if (rst_i = '1') then
            r <= dflt_reg_c;
        elsif rising_edge(clk_i ) then
            r <= rin;
        end if;
    end process;

end rtl_cnt;
