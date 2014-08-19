#!/usr/bin/perl



############################################################
# LICENSE                                                  #
############################################################

# Copyright          (c)          2014,          alpenwasser
# (webmaster@alpenwasser.net) All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without  modification,  are  permitted provided  that  the
# following conditions are met:
#
# 1. Redistributions of  source code  must retain  the above
# copyright  notice,   this  list  of  conditions   and  the
# following disclaimer.
#
# 2. Redistributions  in  binary  form  must  reproduce  the
# above copyright  notice, this  list of conditions  and the
# following  disclaimer in  the  documentation and/or  other
# materials provided with the distribution.
#
# 3. Neither the name of the  copyright holder nor the names
# of  its contributors  may be  used to  endorse or  promote
# products derived from this software without specific prior
# written permission.
#
# THIS  SOFTWARE  IS  PROVIDED   BY  THE  COPYRIGHT  HOLDERS
# AND  CONTRIBUTORS  "AS  IS"  AND ANY  EXPRESS  OR  IMPLIED
# WARRANTIES,  INCLUDING, BUT  NOT LIMITED  TO, THE  IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE  DISCLAIMED. IN NO  EVENT SHALL  THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL,  EXEMPLARY, OR  CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED  TO, PROCUREMENT OF SUBSTITUTE
# GOODS  OR SERVICES;  LOSS  OF USE,  DATA,  OR PROFITS;  OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT,  STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF  THE USE  OF  THIS  SOFTWARE, EVEN  IF  ADVISED OF  THE
# POSSIBILITY OF SUCH DAMAGE.



use 5.10.0;
use strict;
use warnings;
use Time::Piece;
use List::Util qw(max sum);



############################################################
# GLOBAL VARIABLES                                         #
############################################################


    ### ONLY EDIT THIS SECTION! ############################
    #
    # Entries  need  not  be   in  order,  the  script  will
    # automatically order  them according to  their capacity
    # in  descending  order. Just make  a  new  line in  the
    # master record  with all the required  fields and input
    # the  data (or  change  existing data  if somebody  has
    # changed their setup).
    #
    # Because  each  user  can   have  multiple  systems  in
    # the  list,  each  system  is  given  a  unique  system
    # identifier. This  also  makes   it  possible  to  have
    # multiple systems  in the  same post  without confusing
    # the script.
    #
    # Sorting  priority: First  by  capacity, then  by  post
    # number.   This  ensures  that systems  with  identical
    # capacities as others get ranked  higher on the list if
    # they were posted before them.
    #
    #
    # NOTES: 
    #
    # - Capacity is in Terabytes. 
    # - Make  sure you use  a unique system  identifyer when
    #   creating    a   new    entry,   this   is  not  done 
    #   automatically, and each system needs to have its own
    #   unique identifier.


my %MASTER_RECORD = (
    "system_1"  => { "post" =>"1230802" , "username" => "dangerous1"      , "capacity" =>  "89.5" , "case" => "Lian Li PC-A70F"                , "os" => "Win 7"      , "storage_sys" => "JBOD"       , "notes" => undef},
    "system_2"  => { "post" =>"1009417" , "username" => "madcow"          , "capacity" =>  "70.0" , "case" => "Supermicro SC846BE26-R920B"     , "os" => "Gentoo"     , "storage_sys" => "mdadm, ZFS" , "notes" => undef},
    "system_3"  => { "post" =>"1653057" , "username" => "Ssoele"          , "capacity" =>  "64.0" , "case" => "Norcotek RPC4216"               , "os" => "WS 2012R2"  , "storage_sys" => "HWRD"       , "notes" => undef},
    "system_4"  => { "post" =>"344524"  , "username" => "raphaex"         , "capacity" =>  "60.0" , "case" => "Norco RPC-4224 4U"              , "os" => "Win 7"      , "storage_sys" => "HWRD, JBOD" , "notes" => undef},
    "system_5"  => { "post" =>"277353"  , "username" => "Rudde"           , "capacity" =>  "50.0" , "case" => "Supermicro SC846TQ-R1200B"      , "os" => "Debian"     , "storage_sys" => "mdadm"      , "notes" => undef},
    "system_6"  => { "post" =>"273858"  , "username" => "RandomNOOB"      , "capacity" =>  "48.0" , "case" => "NorcoTek RPC-4224"              , "os" => "Ubuntu"     , "storage_sys" => "mdadm"      , "notes" => undef},
    "system_7"  => { "post" =>"821520"  , "username" => "Alexdaman"       , "capacity" =>  "64.0" , "case" => "Chieftec Arena 2000-B"          , "os" => "Win 7"      , "storage_sys" => "HWRD, JBOD" , "notes" => "[post=1694520]Upd 1[/post]"},
    "system_8"  => { "post" =>"300520"  , "username" => "Whaler_99"       , "capacity" =>  "48.6" , "case" => "Antec 1200 v3"                  , "os" => "unRAID"     , "storage_sys" => "unRAID"     , "notes" => undef},
    "system_9"  => { "post" =>"1390757" , "username" => "Hellboy"         , "capacity" =>  "38.0" , "case" => "Fractal Design Array R2"        , "os" => "WS 2008R2"  , "storage_sys" => "RD"         , "notes" => undef},
    "system_10" => { "post" =>"273427"  , "username" => "looney"          , "capacity" =>  "48.0" , "case" => "Norcotek RPC4220"               , "os" => "WS 2012"    , "storage_sys" => "FlexRAID"   , "notes" => "[post=2655227]Upd 1[/post]"},
    "system_11" => { "post" =>"896406"  , "username" => "Benjamin"        , "capacity" =>  "28.0" , "case" => "Fractal Design R4"              , "os" => "FreeNAS"    , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_12" => { "post" =>"492994"  , "username" => "MrSmoke"         , "capacity" =>  "28.0" , "case" => "Norcotek RPC4224"               , "os" => "Ubuntu"     , "storage_sys" => "mdadm"      , "notes" => undef},
    "system_13" => { "post" =>"414401"  , "username" => "Ramaddil"        , "capacity" =>  "45.0" , "case" => "Lian Li 343B"                   , "os" => "Win 7"      , "storage_sys" => "HWRD"       , "notes" => "[post=1883660]Upd 1[/post], [post=2418935]2[/post]"},
    "system_14" => { "post" =>"357732"  , "username" => "d33g33"          , "capacity" =>  "26.0" , "case" => "Synology DS1511+, DX510"        , "os" => "Synology"   , "storage_sys" => "SHR"        , "notes" => undef},
    "system_15" => { "post" =>"639745"  , "username" => "Hobobo"          , "capacity" =>  "24.0" , "case" => "Fractal Design Define Mini"     , "os" => "FreeNAS"    , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_16" => { "post" =>"1004232" , "username" => "stevv"           , "capacity" =>  "24.0" , "case" => "LIAN LI PC-V700X"               , "os" => "Win 7"      , "storage_sys" => "HWRD"       , "notes" => "[post=1829858]Upd 1[/post]"},
    "system_17" => { "post" =>"1839515" , "username" => "MrBucket101"     , "capacity" =>  "26.0" , "case" => "Fractal Design Arc Midi"        , "os" => "Ubuntu"     , "storage_sys" => "HWRD"       , "notes" => undef},
    "system_18" => { "post" =>"715292"  , "username" => "Jarsky"          , "capacity" =>  "24.0" , "case" => "Silverstone Lascala LC17B HTPC" , "os" => "WS 2012"    , "storage_sys" => "HWRD, JBOD" , "notes" => undef},
    "system_19" => { "post" =>"1175253" , "username" => "unknownkwita"    , "capacity" =>  "22.0" , "case" => "Silverstone GD08"               , "os" => "Win 8.1"    , "storage_sys" => "StSp"       , "notes" => undef},
    "system_20" => { "post" =>"813545"  , "username" => "bobert"          , "capacity" =>  "21.0" , "case" => "Bitfenix Shinobi"               , "os" => "Win 7"      , "storage_sys" => "FlRD"       , "notes" => undef},
    "system_21" => { "post" =>"1012708" , "username" => "atv127"          , "capacity" =>  "20.5" , "case" => "CM Storm Trooper"               , "os" => "Win 7"      , "storage_sys" => "JBOD"       , "notes" => undef},
    "system_22" => { "post" =>"1135228" , "username" => "falsedell"       , "capacity" =>  "20.0" , "case" => "Cooler Master Cosmos II"        , "os" => "Win 8.1"    , "storage_sys" => "JBOD"       , "notes" => undef},
    "system_23" => { "post" =>"283688"  , "username" => "VictorB"         , "capacity" =>  "19.0" , "case" => "Fractal Design ARC Midi"        , "os" => "ZFSGuru"    , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_24" => { "post" =>"579418"  , "username" => "andi1455"        , "capacity" =>  "18.0" , "case" => "Fractal Define R4"              , "os" => "WS 2008R2"  , "storage_sys" => "HWRD"       , "notes" => undef},
    "system_25" => { "post" =>"570970"  , "username" => "mb2k"            , "capacity" =>  "18.0" , "case" => "Cooler Master CM 690"           , "os" => "WHS 2011"   , "storage_sys" => "JBOD"       , "notes" => undef},
    "system_26" => { "post" =>"420901"  , "username" => "Eric1024"        , "capacity" =>  "18.0" , "case" => "Supermicro CSE-822T-400LPB"     , "os" => "Linux Mint" , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_27" => { "post" =>"302388"  , "username" => "cushy91"         , "capacity" =>  "18.0" , "case" => "XClio Nighthawk"                , "os" => "unRAID"     , "storage_sys" => "unRAID"     , "notes" => undef},
    "system_28" => { "post" =>"368180"  , "username" => "alpenwasser"     , "capacity" =>   "4.3" , "case" => "Fractal Design R4 (custom)"     , "os" => "Arch Linux" , "storage_sys" => "ZFS"        , "notes" => "BotW"},
    "system_29" => { "post" =>"1561286" , "username" => "Hoppa"           , "capacity" =>  "16.0" , "case" => "Bitfenix Phenom M"              , "os" => "FreeNAS"    , "storage_sys" => "ZFS?"       , "notes" => undef},
    "system_30" => { "post" =>"1625820" , "username" => "Chris230291"     , "capacity" =>  "16.0" , "case" => "unknown"                        , "os" => "FreeNAS"    , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_31" => { "post" =>"339263"  , "username" => "swizzle90"       , "capacity" =>  "16.0" , "case" => "NZXT Source 210 Elite"          , "os" => "unRAID"     , "storage_sys" => "unRAID"     , "notes" => undef},
    "system_32" => { "post" =>"1022882" , "username" => "Appleby"         , "capacity" =>  "15.0" , "case" => "Norco RPC4220"                  , "os" => "WS 2012"    , "storage_sys" => "HWRD"       , "notes" => undef},
    "system_33" => { "post" =>"602093"  , "username" => "Jimstah87"       , "capacity" =>  "15.0" , "case" => "Bitfenix Prodigy"               , "os" => "Win 8"      , "storage_sys" => "HWRD"       , "notes" => "BotW"},
    "system_34" => { "post" =>"379664"  , "username" => "AntarticCrash"   , "capacity" =>  "15.0" , "case" => "NZXT Phantom"                   , "os" => "Win 7"      , "storage_sys" => "JBOD"       , "notes" => undef},
    "system_35" => { "post" =>"279789"  , "username" => "Algoat"          , "capacity" =>  "15.0" , "case" => "Silverstone Precision PS08"     , "os" => "FreeNAS"    , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_36" => { "post" =>"277145"  , "username" => "Hellboy"         , "capacity" =>  "15.0" , "case" => "Coolermaster HAF-X"             , "os" => "Win 7"      , "storage_sys" => "JBOD"       , "notes" => undef},
    "system_37" => { "post" =>"1838389" , "username" => "X1XNobleX1X"     , "capacity" =>  "15.0" , "case" => "Synology DS1513+"               , "os" => "Synology"   , "storage_sys" => "SHR"        , "notes" => undef},
    "system_38" => { "post" =>"657061"  , "username" => "tycheleto"       , "capacity" =>  "14.0" , "case" => "Fractal Design Define Mini"     , "os" => "Win 8"      , "storage_sys" => "FlexRAID"   , "notes" => "[post=1852990]Upd 1[/post]"},
    "system_39" => { "post" =>"1404053" , "username" => "Patrick3D"       , "capacity" =>  "12.0" , "case" => "Raidmax Seiran"                 , "os" => "Ubuntu"     , "storage_sys" => "lvm2"       , "notes" => undef},
    "system_40" => { "post" =>"1059401" , "username" => "dalekphalm"      , "capacity" =>  "12.0" , "case" => "Lian Li + SAS Expander Case"    , "os" => "WHS 2011"   , "storage_sys" => "FlexRAID"   , "notes" => undef},
    "system_41" => { "post" =>"559082"  , "username" => "5lay3r"          , "capacity" =>  "10.0" , "case" => "Midi Tower"                     , "os" => "Win 8"      , "storage_sys" => "StSp"       , "notes" => undef},
    "system_42" => { "post" =>"277145"  , "username" => "Hellboy"         , "capacity" =>  "12.0" , "case" => "unknown"                        , "os" => "Win 7"      , "storage_sys" => "JBOD"       , "notes" => undef},
    "system_43" => { "post" =>"277922"  , "username" => "MG2R"            , "capacity" =>   "8.0" , "case" => "K'nex Custom Case"              , "os" => "Debian"     , "storage_sys" => "mdadm"      , "notes" => "[b]K'Nex[/b] Build, BotW"},
    "system_44" => { "post" =>"303666"  , "username" => "cushy91"         , "capacity" =>   "2.0" , "case" => "HP Proliant MicroServer N40L"   , "os" => "unRAID"     , "storage_sys" => "unRAID"     , "notes" => "HP Proliant Microserver"},
    "system_45" => { "post" =>"1933949" , "username" => "Galxy"           , "capacity" =>  "23.0" , "case" => "Antec 1200"                     , "os" => "WS 2012"    , "storage_sys" => "FlexRAID"   , "notes" => undef},
    "system_46" => { "post" =>"2009510" , "username" => "alpenwasser"     , "capacity" =>  "29.0" , "case" => "InWin PP689 (Custom HDD Rack)"  , "os" => "Arch"       , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_47" => { "post" =>"2074049" , "username" => "MoonSpot"        , "capacity" =>  "10.0" , "case" => "Drobo"                          , "os" => "Drobo"      , "storage_sys" => "Drobo"      , "notes" => undef},
    "system_48" => { "post" =>"2126468" , "username" => "Gronnie"         , "capacity" =>  "28.0" , "case" => "Corsair 500R"                   , "os" => "Win 7"      , "storage_sys" => "FlexRAID"   , "notes" => "[post=2688726]Upd 1[/post]"},
    "system_49" => { "post" =>"2195738" , "username" => "2sysel2"         , "capacity" =>   "9.0" , "case" => "Bitfenix Prodigy mITX"          , "os" => "Win 8"      , "storage_sys" => "JBOD"       , "notes" => undef},
    "system_50" => { "post" =>"2210666" , "username" => "overflowsc"      , "capacity" =>  "24.5" , "case" => "Fractal Design Node 804"        , "os" => "Linux Mint" , "storage_sys" => "mdadm"      , "notes" => undef},
    "system_51" => { "post" =>"2210718" , "username" => "electrostatic"   , "capacity" =>  "21.0" , "case" => "Cooler Master HAF 912"          , "os" => "FreeNAS"    , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_52" => { "post" =>"2261402" , "username" => "Graveworm"       , "capacity" =>  "16.0" , "case" => "Lian Li PC-Q35"                 , "os" => "WS 2012"    , "storage_sys" => "HWRD"       , "notes" => undef},
    "system_53" => { "post" =>"2298428" , "username" => "Zerreth"         , "capacity" =>  "11.5" , "case" => "K'nex Custom Case"              , "os" => "Win 8.1"    , "storage_sys" => "JBOD"       , "notes" => "K'nex"},
    "system_54" => { "post" =>"2304876" , "username" => "Dr_Frankenstein" , "capacity" =>  "12.0" , "case" => "Synology DS412+"                , "os" => "Synology"   , "storage_sys" => "SHR"        , "notes" => undef},
    "system_55" => { "post" =>"2386836" , "username" => "kev507"          , "capacity" =>  "32.0" , "case" => "Corsair 750D"                   , "os" => "Win 7"      , "storage_sys" => "HWRD"       , "notes" => undef},
    "system_56" => { "post" =>"2392499" , "username" => "Danny91"         , "capacity" =>  "22.0" , "case" => "Logic Case SC-4324"             , "os" => "Win 7"      , "storage_sys" => "FlexRAID"   , "notes" => undef},
    "system_57" => { "post" =>"2536977" , "username" => "Woodypc"         , "capacity" =>  "10.0" , "case" => "Antec One Hundred"              , "os" => "Win 7"      , "storage_sys" => "StableBit"  , "notes" => undef},
    "system_58" => { "post" =>"2635265" , "username" => "lekro"           , "capacity" =>  "16.0" , "case" => "Fractal Design Arc Midi R2"     , "os" => "FreeNAS"    , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_59" => { "post" =>"2654107" , "username" => "PhantomWarz"     , "capacity" =>  "28.0" , "case" => "Acer R380F2 + Chembro 24 Bay"   , "os" => "NAS4Free"   , "storage_sys" => "ZFS"        , "notes" => undef},
    "system_60" => { "post" =>"829426"  , "username" => "STUdog"          , "capacity" =>  "83.5" , "case" => "Coolermaster Cosmos 2 + Norco"  , "os" => "Win"        , "storage_sys" => "unknown"    , "notes" => undef},
);


    # To  keep   things  a   bit  more  readable,   the  HDD
    # configuration of  each system is stored  in a separate
    # hash %HDD_RECORD.  Furthermore,  each HDD's vendor and
    # size are stored in hash %HDD_TYPES (see below).
    # The key to each HDD type in %HDD_RECORD corresponds to
    # the key according to  %HDD_TYPES. The amount of drives
    # for  each vendor  and  capacity  is the  corresponding
    # value.  We do not  differentiate between different HDD
    # models for a single vendor, only capacity.
    # 
    # Vendor abbreviations:
    # WD => Western Digital Company
    # SG => Seagate
    # HT => Hitachi
    # TS => Toshiba
    # SS => Samsung
    # US => unspecified

my %HDD_RECORD = (
    "system_1"  => { "WD0400" =>  "2", "SG0400" =>  "5", "WD0300" =>  "15", "WD0200" =>  "6", "SG0200" =>  "1", "SS0200" =>  "1", "SG0050" =>  "1" },
    "system_2"  => { "SG0400" => "10", "HT0300" =>  "6", "SG0300" =>  "4" },
    "system_3"  => { "WD0400" => "16" },
    "system_4"  => { "SG0300" => "12", "SG0200" => "12" },
    "system_5"  => { "SS0200" => "10", "SG0300" => "10" }, 
    "system_6"  => { "WD0200" => "24"},
    "system_7"  => { "WD0400" =>  "5", "WD0200" => "14", "SS0200" =>  "5", "SG0300" =>  "2" },
    "system_8"  => { "WD0300" =>  "1", "WD0200" => "14", "WD0100" =>  "2", "HT0200" =>  "2", "SG0100" =>  "5", "SG0150" =>  "1", "WD0050" =>  "3", "WD0064" =>  "1", "SS0050" =>  "1", "SG0050" =>  "5" },
    "system_9"  => { "WD0300" =>  "2", "SG0400" =>  "8" },
    "system_10" => { "SG0200" => "11", "HT0200" =>  "5", "SG0400" =>  "4" },
    "system_11" => { "WD0300" =>  "6", "SS0200" =>  "4", "WD0200" =>  "1" },
    "system_12" => { "TS0300" =>  "4", "SS0200" =>  "6", "SG0200" =>  "2" },
    "system_13" => { "WD0200" => "21", "WD0300" =>  "1" },
    "system_14" => { "WD0200" =>  "5", "WD0300" =>  "4", "WD0400" =>  "1" },
    "system_15" => { "SG0400" =>  "6" },
    "system_16" => { "WD0400" =>  "6" },
    "system_17" => { "SG0300" =>  "8", "WD0200" =>  "1" },
    "system_18" => { "WD0200" =>  "9", "WD0300" =>  "2" },
    "system_19" => { "SG0400" =>  "1", "WD0300" =>  "4", "WD0200" =>  "3" },
    "system_20" => { "SG0300" =>  "3", "TS0300" =>  "4" },
    "system_21" => { "WD0300" =>  "1", "WD0200" =>  "6", "HT0200" =>  "1", "WD0100" =>  "2", "SG0075" =>  "2" },
    "system_22" => { "SG0300" =>  "4", "WD0200" =>  "1", "SG0200" =>  "1", "SG0150" =>  "2", "SG0100" =>  "1"},
    "system_23" => { "WD0300" =>  "6", "SS0050" =>  "2" },
    "system_24" => { "SG0300" =>  "6" },
    "system_25" => { "SG0300" =>  "1", "SG0200" =>  "4", "WD0200" =>  "2", "WD0100" =>  "1", "SG0100" =>  "2" },
    "system_26" => { "WD0300" =>  "6" },
    "system_27" => { "SG0300" =>  "1", "WD0200" =>  "3", "SG0200" =>  "1", "SG0150" =>  "2", "WD0150" =>  "2", "SS0100" =>  "1" },
    "system_28" => { "WD0025" =>  "1", "SS0025" =>  "1", "SS0075" =>  "1", "WD0300" =>  "1" },
    "system_29" => { "WD0400" =>  "4" },
    "system_30" => { "WD0200" =>  "8" },
    "system_31" => { "WD0200" =>  "6", "SG0200" =>  "2" },
    "system_32" => { "SG0200" =>  "5", "WD0100" =>  "5" },
    "system_33" => { "WD0300" =>  "5" },
    "system_34" => { "US0200" =>  "6", "US0100" =>  "3" },
    "system_35" => { "WD0300" =>  "5" },
    "system_36" => { "US0200" =>  "3", "US0300" =>  "3" },
    "system_37" => { "WD0300" =>  "5" },
    "system_38" => { "SG0200" =>  "1", "WD0300" =>  "3", "SG0300" =>  "1" },
    "system_39" => { "WD0300" =>  "1", "WD0200" =>  "1", "WD0100" =>  "1", "SG0400" =>  "1", "SG0200" =>  "1" },
    "system_40" => { "SG0300" =>  "2", "WD0300" =>  "1", "SG0200" =>  "1", "HT0050" =>  "2" },
    "system_41" => { "WD0300" =>  "1", "WD0200" =>  "2", "SG0200" =>  "1", "SS0100" =>  "1" },
    "system_42" => { "US0300" =>  "2", "US0200" =>  "3" },
    "system_43" => { "WD0200" =>  "3", "SG0200" =>  "1" },
    "system_44" => { "WD0050" =>  "1", "SG0050" =>  "1", "SG0100" =>  "1" },
    "system_45" => { "WD0400" =>  "3", "SG0400" =>  "2", "WD0200" =>  "1", "WD0050" =>  "2" },
    "system_46" => { "SS0100" =>  "3", "WD0200" =>  "4", "WD0300" =>  "6" },
    "system_47" => { "WD0200" =>  "5" },
    "system_48" => { "SG0400" =>  "6", "WD0200" =>  "2" },
    "system_49" => { "WD0300" =>  "3" },
    "system_50" => { "SG0400" =>  "5", "SS0200" =>  "1", "WD0200" =>  "1", "SS0050" =>  "1" },
    "system_51" => { "WD0200" =>  "4", "WD0300" =>  "3", "WD0100" =>  "4" },
    "system_52" => { "WD0400" =>  "4" },
    "system_53" => { "WD0400" =>  "2", "WD0200" =>  "1", "WD0150" =>  "1" },
    "system_54" => { "SG0300" =>  "2", "WD0300" =>  "2" },
    "system_55" => { "HT0400" =>  "8" },
    "system_56" => { "TS0300" =>  "3", "WD0300" =>  "3", "SG0200" =>  "1", "WD0200" =>  "1" },
    "system_57" => { "WD0100" =>  "1", "WD0200" =>  "1", "SG0200" =>  "2", "SG0300" =>  "1" },
    "system_58" => { "SG0400" =>  "4" },
    "system_59" => { "HT0200" =>  "2", "SG0200" =>  "1", "WD0200" =>  "3", "WD0100" => "10", "SG0100" =>  "6" },
    "system_60" => { "SG0150" =>  "8", "SG0200" =>  "3", "HT0300" => "10", "HT0200" =>  "7", "US0150" => "11", "US0300" =>  "1", "WD0100" =>  "2" },
);


    # %HDD_TYPES contains  all the  different types  of HDDs
    # used  in the  systems,  differentiated  by vendor  and
    # size.
    #
    # Naming scheme explanation:
    # The  names  consist  of  a  two-letter  vendor  prefix
    # according to this table:
    #
    # WD => Western Digital Company
    # SG => Seagate
    # HT => Hitachi
    # TS => Toshiba
    # SS => Samsung
    # US => unspecified
    #
    # postfixed by a four-digit code indicating the capacity
    # in  10 TB  (so an  HDD with  XX0001 would  have 10  GB
    # capacity, an HDD  of type XX0010 has  100 GB capacity,
    # XX0100 1 TB, XX1000 10 TB).
    #
    # If an HDD type is not (correctly) in %HDD_TYPES but is
    # used in  %HDD_RECORD above,  the script will  throw an
    # error  and die,  which will  give user  the chance  to
    # amend %HDD_TYPES accordingly.
    #
    # It is possible to define HDD types in %HDD_TYPES which
    # are not  actually used in %HDD_RECORD. This  will have
    # no influence on the script output.


my %HDD_TYPES = (
    "WD0025" => { "vendor" => "WD", "size" => "0.25" },
    "WD0050" => { "vendor" => "WD", "size" => "0.5" },
    "WD0064" => { "vendor" => "WD", "size" => "0.64" },
    "WD0100" => { "vendor" => "WD", "size" => "1.0" },
    "WD0150" => { "vendor" => "WD", "size" => "1.5" },
    "WD0200" => { "vendor" => "WD", "size" => "2.0" },
    "WD0300" => { "vendor" => "WD", "size" => "3.0" },
    "WD0400" => { "vendor" => "WD", "size" => "4.0" },
    "WD0500" => { "vendor" => "WD", "size" => "5.0" },
    "WD0600" => { "vendor" => "WD", "size" => "6.0" },
    "SG0050" => { "vendor" => "Seagate", "size" => "0.5" },
    "SG0075" => { "vendor" => "Seagate", "size" => "0.75" },
    "SG0100" => { "vendor" => "Seagate", "size" => "1.0" },
    "SG0150" => { "vendor" => "Seagate", "size" => "1.5" },
    "SG0200" => { "vendor" => "Seagate", "size" => "2.0" },
    "SG0300" => { "vendor" => "Seagate", "size" => "3.0" },
    "SG0400" => { "vendor" => "Seagate", "size" => "4.0" },
    "SG0500" => { "vendor" => "Seagate", "size" => "5.0" },
    "SG0600" => { "vendor" => "Seagate", "size" => "6.0" },
    "HT0050" => { "vendor" => "HGST", "size" => "0.5" },
    "HT0100" => { "vendor" => "HGST", "size" => "1.0" },
    "HT0150" => { "vendor" => "HGST", "size" => "1.5" },
    "HT0200" => { "vendor" => "HGST", "size" => "2.0" },
    "HT0300" => { "vendor" => "HGST", "size" => "3.0" },
    "HT0400" => { "vendor" => "HGST", "size" => "4.0" },
    "HT0500" => { "vendor" => "HGST", "size" => "5.0" },
    "HT0600" => { "vendor" => "HGST", "size" => "6.0" },
    "TS0050" => { "vendor" => "Toshiba", "size" => "0.5" },
    "TS0100" => { "vendor" => "Toshiba", "size" => "1.0" },
    "TS0150" => { "vendor" => "Toshiba", "size" => "1.5" },
    "TS0200" => { "vendor" => "Toshiba", "size" => "2.0" },
    "TS0300" => { "vendor" => "Toshiba", "size" => "3.0" },
    "TS0400" => { "vendor" => "Toshiba", "size" => "4.0" },
    "TS0500" => { "vendor" => "Toshiba", "size" => "5.0" },
    "TS0600" => { "vendor" => "Toshiba", "size" => "6.0" },
    "SS0025" => { "vendor" => "Samsung", "size" => "0.25" },
    "SS0050" => { "vendor" => "Samsung", "size" => "0.5" },
    "SS0075" => { "vendor" => "Samsung", "size" => "0.75" },
    "SS0100" => { "vendor" => "Samsung", "size" => "1.0" },
    "SS0150" => { "vendor" => "Samsung", "size" => "1.5" },
    "SS0200" => { "vendor" => "Samsung", "size" => "2.0" },
    "SS0300" => { "vendor" => "Samsung", "size" => "3.0" },
    "US0050" => { "vendor" => "unspecified", "size" => "0.5" },
    "US0100" => { "vendor" => "unspecified", "size" => "1.0" },
    "US0150" => { "vendor" => "unspecified", "size" => "1.5" },
    "US0200" => { "vendor" => "unspecified", "size" => "2.0" },
    "US0300" => { "vendor" => "unspecified", "size" => "3.0" },
);


    # %CAPACITY_GROUPS must be adjusted accordingly when the
    # capacity  of the  highest  ranked  system exceeds  the
    # highest entry in %CAPACITY_GROUPS.

my %CAPACITY_GROUPS = (
    "10 TB ≤ capacity < 20 TB" => 20,
    "20 TB ≤ capacity < 30 TB" => 30,
    "30 TB ≤ capacity < 40 TB" => 40,
    "40 TB ≤ capacity < 50 TB" => 50,
    "50 TB ≤ capacity < 60 TB" => 60,
    "60 TB ≤ capacity < 70 TB" => 70,
    "70 TB ≤ capacity < 80 TB" => 80,
    "80 TB ≤ capacity < 90 TB" => 90,
);

my $GROUPING_INTERVAL = 10;

    
    # Don't change anything below  this line unless you know
    # what you're doing!
    ########################################################




my $CAPACITY_THRESHOLD = 10;

my $TABLE_TITLE = "[b][size=6]LTT " 
                  . $CAPACITY_THRESHOLD 
                  . " TB+ Storage Rankings[/size][/b]"
                  . "\n[hr]";

my $ABBR_KEY = "\n\n[size=5]Abbreviations Key[/size]"
             . "[hr]\n"
             . "[b]WS[/b]     Windows Server\n"
             . "[b]WHS[/b]    Windows Home Server\n"
             . "[b]SHR[/b]    Synology Hybrid RAID\n"
             . "[b]StSp[/b]   Storage Spaces\n"
             . "[b]RD[/b]     RAID (unspecified if hardware or software)\n"
             . "[b]HWRD[/b]   Hardware RAID\n"
             . "[b]FlRD[/b]   FlexRAID";

my $FOOTER = "Sorting priority: First by capacity descending, then by post date, ascending."
            . " Last updated: ";

my $FONT_OPN = "[font=Courier New,Courier,Monospace]";
my $FONT_END = "[/font]";


my $URL_OPN = "[post=";
my $URL_MID = "]";
my $URL_END = "[/post]";

my $CAPACITY_PADDING_AFTER = "  ";


my %POSTS       = ();
my %USERNAMES   = ();
my %CAPACITIES  = ();
my %OS          = ();
my %STORAGE_SYS = ();
my %NOTES       = ();
my %CASES       = ();




############################################################
# FUNCTIONS                                                #
############################################################


sub get_field_length
{
    # $_[0]: reference to array
    # $_[1]: number of desired padding characters
 

    # The source array might contain undef values because of
    # the  systems which  are below  the capacity  threshold
    # required for  being ranked  and therefore do  not have
    # any ranking numbers assigned  to them. In those cases,
    # we map to 0. However, the end result will be the same,
    # since we want the maximum only.

    return $_[1] + max(map { ($_) ? length($_) : 0 } @{ $_[0] });
}


sub get_ranks
{
    # $_[0]: reference to %POSTS
    # $_[1]: reference to %CAPACITIES


    my $rank;

    return  { map 
                {
                    $rank++;


                    # Evaluate  number of  users, length  of
                    # that number is the  amount of chars to
                    # which $rank needs to be padded so that
                    # units line up with units, tens line up
                    # with tens and so on.
                    $rank = " " . $rank until (length($rank) 
                        == length(scalar(keys(%{ $_[0] }))));


                    # For builds  with capacities  below the
                    # capacity threshold,  we do  not assign
                    # any  ranks, since  they will  be in  a
                    # separate, unranked list.
 
                    $_ => ($_[1]->{$_} < $CAPACITY_THRESHOLD) ? undef: $rank
                }

                # Sort  first  by   storage  capacity,  then
                # by  post  number. Systems  with  identical
                # capacities will  be ranked higher  if they
                # were posted earlier.
                sort {
                         ${ $_[1] }{$b} <=> ${ $_[1] }{$a} 
                         || 
                         ${ $_[0] }{$a} <=> ${ $_[0] }{$b}
                     } keys %{ $_[0] }
            };
}


sub pad_capacities
{
    # $_[0]: reference to %CAPACITIES

    # Adds padding before text.

    return { map
               {
                   my $pad_cap = ${ $_[0] }{$_};
                   $pad_cap = " " . $pad_cap until (length($pad_cap) 
                       == length(max(values %{ $_[0] })));
                   $_ => $pad_cap
               }
               keys %{ $_[0] }
           };
}


sub pad_fields
{
    # $_[0]: reference  to  hash of  elements to  be padded,
    #        values will be padded
    # $_[1]: number of padding chars for longest element

    # Adds padding after text.

    return { map 
               {
                   # The elements to be  padded can be empty
                   # because of the  systems with capacities
                   # below the capacity threshold,  which do
                   # not  get  assigned ranking  numbers. In
                   # that case, we just  pad an empty string
                   # until it's of sufficient length to fill
                   # the field.
                   my $padded = (${ $_[0] }{$_}) ? ${ $_[0] }{$_} : "";


                   $padded .= " " until (length($padded) 
                       == get_field_length( [ values %{ $_[0] } ],$_[1]));

                   $_ => $padded
               }
               keys %{ $_[0] }
           };
}


sub reduce_to_padding
{
    # Reduces strings of form 
    # "expression       " to purely "       "

    # We need the padding to  be separate from the usernames
    # in  order  not  to  have the  hyperlinks  include  the
    # padding, but merely the usernames.

    # $_[0]: reference to non-padded hash: key => non-padded entry
    # $_[1]: reference to padded hash:     key =>     padded entry


    return { map
               {
                   my $padding = ${ $_[1] }{$_};
                   $padding =~ s/${ $_[0] }{$_}//ig;
                   $_ => $padding
               }
               keys %{ $_[0] }
           };
}


sub get_valid_capacities
{
    # return val: reference to @capacities_which_count

    my $capacity_ref = $_[0];

    return [ grep { $_ >= 10 } values %{ $capacity_ref }];
}


sub calculate_total_capacity
{
    # my $capacity_ref = $_[0];
    my $valid_caps_ref = $_[0];

    return sum(@{ $valid_caps_ref });
}


sub get_arithm_mean
{
    # $_[0]: reference to @capacities_which_count
    # $_[1]: total capacity based on valid capacities
    
    my $valid_caps_ref    = $_[0];
    my $total_capacity    = $_[1];

    my $number_of_entries = scalar(@{ $valid_caps_ref });
    return $total_capacity / $number_of_entries;
}


sub get_median
{
    # $_[0]: reference to @capacities_which_count

    my $valid_caps_ref = $_[0];
    my $median;

    my $number_of_entries = scalar(@{ $valid_caps_ref});
    my @sorted_capacities = sort { $a <=> $b } @{ $valid_caps_ref };

    if ($number_of_entries % 2 == 1)
    {
        # Odd number of elements => central element is median.

        use integer;
        my $median_index = $number_of_entries / 2;
        return $sorted_capacities[$median_index];

    } else {
        # Even number of elements => arithmetic mean between
        # two central elements is median.

        # Need to adjust because index of array starts at 0,
        # naturally.
        my $lower_median_index = $number_of_entries / 2 - 1;
        my $upper_median_index = $lower_median_index + 1;

        return ($sorted_capacities[$lower_median_index]
            + $sorted_capacities[$upper_median_index]) / 2;
    }
}


sub get_mode
{
    # $_[0]: reference to @capacities_which_count

    my $valid_caps_ref = $_[0];
    my %counts; 
    my $highest_count;
    my %result;


    # Count each capacity's number of occurrences
    $counts{$_}++ for @{ $valid_caps_ref };
    $highest_count = max(values %counts);

    # Reduce to mode(s), the mode need not be unique,
    # hence a hash instead of a single value.
    # Form of %result: capacity => number of occurrences.

    %result = map { $_ => $counts{$_} } 
        grep { $counts{$_} == $highest_count } keys %counts;
    
    $result{number_of_unique_capacities} = scalar(keys %counts);
    $result{number_of_occurrences} = $highest_count;

    return \%result;
}


sub get_grouped_stats
{
    # $_[0]: reference to @capacities_which_count
    # $_[1]: reference to %stats

    my $valid_caps_ref = $_[0];
    my $stats_ref      = $_[1];

    ${ $stats_ref }{grouped_stats} = \%CAPACITY_GROUPS;


    for my $range (keys %{ ${ $stats_ref }{grouped_stats} })
    {
        my $upper_limit = ${ $stats_ref }{grouped_stats}{$range};

        my @capacities_in_range = grep { 
            $_ >= $upper_limit - $GROUPING_INTERVAL && $_ < $upper_limit } 
            @{ $valid_caps_ref };
 
        ${ $stats_ref }{grouped_stats}{$range} = scalar(@capacities_in_range);
    }
}


sub get_total_drives
{
    # $_[0]: reference to %drive_stats
    
    my $drive_stats_ref = $_[0];
    my $drive_count;

    # Summate total drive count.
    for my $system_ref (keys %HDD_RECORD)
    {
        $drive_count += $_ for (values $HDD_RECORD{$system_ref});
    }

    return $drive_count;
}


sub validate_hdd_types
{
    # Makes  sure that  all  HDD types  used in  %HDD_RECORD
    # are  actually  present   and  correctly  specified  in
    # %HDD_TYPES.  We die if this  is not the case and throw
    # an error message.

    for my $system_ref (keys %HDD_RECORD)
    {
        for (keys $HDD_RECORD{$system_ref})
        {
            if (!$HDD_TYPES{$_}{size} || !$HDD_TYPES{$_}{vendor})
            {
                say "ERROR: the following HDD model has not been defined"
                    . "\ncorrectly  in   %HDD_TYPES.  Please   fill  in  its"
                    . "\nspecifications in order to proceed:\n"
                    . "\n$_\n";
                die;
            }
        }
    }
}


sub get_system_capacity
{
    # $_[0]: reference to system hash

    my $system_ref = $_[0];

    my $system_capacity;

    for (keys %{ $system_ref })
    {
        $system_capacity += $HDD_TYPES{$_}{size} 
            * ${ $system_ref }{$_};
    }
    return $system_capacity;
}


sub remove_small_systems
{
    for my $system (keys %HDD_RECORD)
    {
        if (get_system_capacity($HDD_RECORD{$system}) < $CAPACITY_THRESHOLD)
        {
            delete $HDD_RECORD{$system};
        }
    }
}


sub get_combined_capacity
{
    # $_[0]: reference to %drive_stats
    
    my $drive_stats_ref = $_[0];
    my $combined_capacity;


    for my $system_ref (keys %HDD_RECORD)
    {
        for (keys $HDD_RECORD{$system_ref})
        {
            # Size per HDD times drive count per system.
            $combined_capacity += $HDD_TYPES{$_}{size} 
                * $HDD_RECORD{$system_ref}{$_};
        }
    }

    return $combined_capacity;
}


sub get_avg_drive_cap
{
    # $_[0]: reference to %drive_stats

    my $drive_stats_ref = $_[0];

    return ${ $drive_stats_ref }{combined_capacity} 
        / ${ $drive_stats_ref }{total_drive_count};
}


sub generate_drive_cap_list
{
    # Compiles array of HDD  capacity for every single drive
    # (including  redundancies for  several  drives of  same
    # capacity).

    # $_[0]: reference to %drive_stats

    my $drive_stats_ref = $_[0];

    my @unordered_caps;


    for my $system_ref (keys %HDD_RECORD)
    {
        for my $hdd_type (keys $HDD_RECORD{$system_ref})
        {
            # Create  one  entry on  list  for  each HDD  in
            # every system,  value of  entry is  the drive's
            # capacity.

            for (1 .. $HDD_RECORD{$system_ref}{$hdd_type})
            {
                push @unordered_caps, $HDD_TYPES{$hdd_type}{size};
            }
        }
    }

    return sort { $a <=> $b } @unordered_caps;
}


sub get_median_drive_cap
{
    # $_[0]: reference to %drive_stats
    # $_[1]: reference to @drive_cap_list

    my $drive_stats_ref    = $_[0];
    my $drive_cap_list_ref = $_[1];


    if (${ $drive_stats_ref }{total_drive_count} % 2 == 1)
    {
        # Odd number of elements => central element is median.

        use integer;
        my $median_index = ${ $drive_stats_ref }{total_drive_count} / 2;
        return ${ $drive_cap_list_ref }[$median_index];

    } else {
        # Even number of elements => arithmetic mean between
        # two central elements is median.

        # Need to adjust because index of array starts at 0,
        # naturally.
        my $lower_median_index 
            = ${ $drive_stats_ref }{total_drive_count} / 2 - 1;
        my $upper_median_index = $lower_median_index + 1;

        return (${ $drive_cap_list_ref }[$lower_median_index]
            + ${ $drive_cap_list_ref }[$upper_median_index]) / 2;
    }
}


sub get_cap_stats
{
    # $_[0]: reference to %drive_stats
    # $_[1]: reference to @drive_cap_list

    my $drive_stats_ref    = $_[0];
    my $drive_cap_list_ref = $_[1];

    my %cap_stats;

    $cap_stats{$_}++ for @{ $drive_cap_list_ref };

    return \%cap_stats;
}


sub get_vendor_stats
{
    # $_[0]: reference to %drive_stats;

    my $drive_stats_ref = $_[0];
    my %vendor_stats;
    my %vendor_capacities;

    
    for my $system_ref (keys %HDD_RECORD)
    {
        for my $hdd_type (keys $HDD_RECORD{$system_ref})
        {
            for (1 .. $HDD_RECORD{$system_ref}{$hdd_type})
            {
                $vendor_capacities{ $HDD_TYPES{$hdd_type}{vendor} }
                    += $HDD_TYPES{$hdd_type}{size};
                $vendor_stats{ $HDD_TYPES{$hdd_type}{vendor} }++;
            }
        }
    }

    return \%vendor_stats, \%vendor_capacities;
}


sub get_system_count
{
    # Must be executed after remove_small_systems() to yield
    # desired result.
    return scalar(keys %HDD_RECORD);
}


sub get_drive_stats
{
    # $_[0]: reference to %drive_stats;

    my $drive_stats_ref = $_[0];

    ${ $drive_stats_ref }{total_drive_count} 
        = get_total_drives($drive_stats_ref);

    ${ $drive_stats_ref }{combined_capacity}
        = get_combined_capacity($drive_stats_ref);

    ${ $drive_stats_ref }{average_drive_cap}
        = get_avg_drive_cap($drive_stats_ref);


    # @drive_cap_list is ordered.
    my @drive_cap_list = generate_drive_cap_list($drive_stats_ref);

    ${ $drive_stats_ref }{median_drive_cap}
        = get_median_drive_cap($drive_stats_ref,\@drive_cap_list);

    ${ $drive_stats_ref }{cap_stats}
        = get_cap_stats($drive_stats_ref,\@drive_cap_list);

    (${ $drive_stats_ref }{vendor_stats}, 
        ${ $drive_stats_ref }{vendor_capacities})
        = get_vendor_stats($drive_stats_ref);

    ${ $drive_stats_ref }{system_count} = get_system_count();
}


sub print_drive_stats
{
    my %drive_stats;

    get_drive_stats(\%drive_stats);

    say "\n[b]HDD Statistics[/b]";

    print "Total Number of Drives                 " 
        . $drive_stats{total_drive_count}
        . "\n"
        . "Average Drives per System           ";
    printf("% 6.0f\n", $drive_stats{total_drive_count} 
        / $drive_stats{system_count});
    print "Total Combined Capacity      ";
    printf("% 10.1f", $drive_stats{combined_capacity});
    print " TB\nAverage Drive Capacity           ";
    printf("% 6.1f TB\n", $drive_stats{average_drive_cap});
    print "Median Drive Capacity            ";
    printf("% 6.1f TB\n", $drive_stats{median_drive_cap});


    say "\n[b]HDD Statistics, by Size[/b]";
    say "Capacity               Count           "
        . "Sum        Percentage of Total";
    printf(
        "%.2f TB          "
        . "%4d drives     "
        . "% 6.1f TB                    "
        . "% 6.2f%%\n",
        $_, 
        $drive_stats{cap_stats}{$_}, 
        $_ * $drive_stats{cap_stats}{$_}, 
        $_ * $drive_stats{cap_stats}{$_} / $drive_stats{combined_capacity}*100)
        for sort { $a cmp $b } keys %{ $drive_stats{cap_stats} };

    printf("[b]TOTAL            %4d drives    % 6.1f TB[/b]\n",
        $drive_stats{total_drive_count},
        $drive_stats{combined_capacity});


    say "\n[b]HDD Statistics, by Vendor[/b]";
    say "Vendor                 Count           "
        . "Sum     Percentage of Total\n"
        . "                                               "
        . "Drive Count       Capacity";
    printf("%-15s % 5s drives     "
        . "% 6.1f TB         "
        . "% 6.2f%%        "
        . "% 6.2f%%\n",
        $_,
        $drive_stats{vendor_stats}{$_},
        $drive_stats{vendor_capacities}{$_},
        $drive_stats{vendor_stats}{$_} / $drive_stats{total_drive_count} * 100,
        $drive_stats{vendor_capacities}{$_}/$drive_stats{combined_capacity}*100)
        for sort { 
            $drive_stats{vendor_stats}{$b} <=> $drive_stats{vendor_stats}{$a} }
            keys %{ $drive_stats{vendor_stats} };

    printf("[b]TOTAL            %4d drives    % 6.1f TB[/b]\n",
        $drive_stats{total_drive_count},
        $drive_stats{combined_capacity});
}


sub get_statistics
{
    # $_[0]: reference to @capacities_which_count

    my $valid_caps_ref = $_[0];
    my $stats = {};

    ${ $stats }{total_capacity} 
        = calculate_total_capacity($valid_caps_ref);
    ${ $stats }{arith_mean_cap} 
        = get_arithm_mean($valid_caps_ref,${ $stats }{total_capacity});
    ${ $stats }{median_cap}
        = get_median($valid_caps_ref);
    ${ $stats }{mode}
        = get_mode($valid_caps_ref);

    get_grouped_stats($valid_caps_ref,$stats);

    return $stats;
}


sub print_grouped_stats
{
    # $_[0]: reference to grouped statistics

    my $grouped_stats_ref = pad_capacities($_[0]);

    say "\n[b]Grouped Distribution[/b]";
    say $_ 
        . "     " 
        . ${ $grouped_stats_ref }{$_} 
        . " systems" for sort { $a cmp $b } keys %{ $grouped_stats_ref };
}


sub generate_rows
{
    # @_: copy of @formatted_cols
    # $_[0]: reference to @formatted_cols
    # $_[1]: reference to %POSTS
    # $_[2]: reference to %NOTES
    # $_[3]: reference to %USERNAMES
    # $_[4]: reference to $URL_OPN
    # $_[5]: reference to $URL_MID
    # $_[6]: reference to $URL_END
    # $_[7]: reference to %CAPACITIES
    # $_[8]: reference to %ranked_rows
    # $_[9]: reference to @unranked_rows

    my $formatted_cols_ref = $_[0];
    my $posts_ref          = $_[1];
    my $notes_ref          = $_[2];
    my $usernames_ref      = $_[3];
    my $url_opn            = $_[4];
    my $url_mid            = $_[5];
    my $url_end            = $_[6];
    my $ranked_rows_ref    = $_[7];
    my $unranked_rows_ref  = $_[8];

    for my $sys_id (keys %{ ${ $formatted_cols_ref }[2] })
    {
        #my $row = $sys_id;
        my $row = (
                    (   # For  the unranked  list,  we  want
                        # the  names  to  be  right  at  the 
                        # beginning of the  line, no padding 
                        # before them.
                        ${ ${ $formatted_cols_ref }[1] }{$sys_id} !~ /^ *$/ )
                        ?
                        ${ ${ $formatted_cols_ref }[1] }{$sys_id} 
                        :
                        ""
                    )
                . ${ $url_opn }
                . ${ $posts_ref }{$sys_id} 
                . ${ $url_mid }
                . ${ $usernames_ref }{$sys_id} 
                . ${ $url_end }
                . ${ ${ $formatted_cols_ref }[3] }{$sys_id} 
                . "[b]" 
                . ${ ${ $formatted_cols_ref }[4] }{$sys_id}  
                . " TB[/b]" 
                . $CAPACITY_PADDING_AFTER
                . ${ ${ $formatted_cols_ref }[5] }{$sys_id} 
                . ${ ${ $formatted_cols_ref }[6] }{$sys_id} 
                . ((${ $notes_ref }{$sys_id}) ? ${ $notes_ref }{$sys_id} : "");


        # Systems   with  capacities   below  the   capacity
        # threshold go  into the unranked list  (their ranks
        # will be pure whitespace strings):
        if (${ ${ $formatted_cols_ref }[1] }{$sys_id} =~ /^ *$/)
        {
            push (@{ $unranked_rows_ref }, $row);
            next;
        }


        ${ $ranked_rows_ref }{${ ${$formatted_cols_ref }[1]}{$sys_id}} = $row;
    }
}


sub print_list
{
    # @_: copy of @formatted_cols
    # $_[0]: reference to @formatted_cols
    # $_[1]: reference to %POSTS
    # $_[2]: reference to %NOTES
    # $_[3]: reference to %USERNAMES
    # $_[4]: reference to $URL_OPN
    # $_[5]: reference to $URL_MID
    # $_[6]: reference to $URL_END
    # $_[6]: reference to %CAPACITIES


    my $formatted_cols_ref = $_[0];
    my $posts_ref          = $_[1];
    my $notes_ref          = $_[2];
    my $usernames_ref      = $_[3];
    my $url_opn            = $_[4];
    my $url_mid            = $_[5];
    my $url_end            = $_[6];
    my $capacity_ref       = $_[7];


    my %ranked_rows;
    my @unranked_rows;

    # Make  sure  all  HDD  types used  in  %HDD_RECORD  are
    # properly defined in %HDD_TYPES.
    validate_hdd_types();

    generate_rows(
        $formatted_cols_ref,
        $posts_ref,
        $notes_ref,
        $usernames_ref,
        $url_opn,
        $url_mid,
        $url_end,
        \%ranked_rows,
        \@unranked_rows);


    say $TABLE_TITLE;


    #NOTE: We  sort  by  rank   here  as  determined  by
    #      get_rank().   The ranking  itself is  done in
    #      that function. In  this section, we  just use
    #      those results for sorting the output.

    say $ranked_rows{$_} for sort {$a <=> $b} keys %ranked_rows;


    my $time = Time::Piece->new();

    my $capacities_which_count_ref = get_valid_capacities($capacity_ref);
    my $stats_ref = get_statistics($capacities_which_count_ref);


    # Main List
    say "\n[hr][b][size=5]Total Storage Capacity  " 
        . ${ $stats_ref }{total_capacity}
        . " TB[/size][/b]"
        . "[hr]\n"
        . $FOOTER
        . $time->year() . '-' . uc($time->monname()) . '-' . $time->mday();


    # Statistics
    print "\n\n[size=5]Statistics[/size]"
        . "[hr]\n"
        . "[b]System Statistics[/b]\n"
        . "Arithmetic Mean Capacity                    ";
    printf("%.1f", ${ $stats_ref }{arith_mean_cap});
    print " TB\n"
        . "Median Capacity                             ";
    printf("%.1f", ${ $stats_ref }{median_cap});
    print " TB\n";

    my $number_of_unique_capacities 
        = ${ $stats_ref }{mode}{number_of_unique_capacities};
    delete ${ $stats_ref }{mode}{number_of_unique_capacities};

    my $number_of_occurrences 
        = ${ $stats_ref }{mode}{number_of_occurrences};
    delete ${ $stats_ref }{mode}{number_of_occurrences};

    # There may be more than one mode:
    if (scalar(keys %{ ${ $stats_ref }{mode} }) == 1)
    {
        print "Mode (most common capacity)                 ";
        print $_ . " TB" for keys %{ ${ $stats_ref }{mode} };
        print " (number of occurrences: " 
            . $number_of_occurrences 
            . ")\n";
    } else {
        print "Modes (most common capacities)              ";
        my $modes = join(" TB, ", keys %{ ${ $stats_ref }{mode} });
        print $modes 
            . " TB (number of occurrences: " 
            . $number_of_occurrences 
            . ")\n";
    }
    say "Number of Unique Capacities                 " 
        . $number_of_unique_capacities;


    print_grouped_stats(${ $stats_ref }{grouped_stats});


    # HDD Statistics
    remove_small_systems();
    print_drive_stats();


    # If  there  are  entries   with  capacities  below  the
    # capacity threshold, print those  into a separate list,
    # otherwise skip this.
    if (@unranked_rows)
    {
        say "\n\n\n[size=5]Noteworthy Systems w/ <"
            . $CAPACITY_THRESHOLD
            . " TB storage," 
            ."[/size] unranked, unsorted\n[hr]";

        say for @unranked_rows;
    }

    say $ABBR_KEY;
}


sub format_list
{
    # $_[0]: reference to %USERNAMES:       system_id => username
    # $_[1]: reference to %CAPACITIES:      system_id => capacity
    # $_[2]: reference to %OS:              system_id => OS
    # $_[3]: reference to %STORAGE_SYS:     system_id => storage system
    # $_[4]: reference to %CASES            system_id => case
    # $_[5]: reference to %POSTS            system_id => post number

    my $ranks_ref             = get_ranks($_[5], $_[1]);
    my $padded_ranks_ref      = pad_fields($ranks_ref, 2);
    my $padded_usernames_ref  = pad_fields($_[0], 2);
    my $pure_paddings_ref     = reduce_to_padding($_[0], $padded_usernames_ref);
    my $padded_capacities_ref = pad_capacities($_[1]);

    my $concat_os_storage_ref = { map { 
        $_ => ${$_[2]}{$_} . " (". ${$_[3]}{$_} . ")" } keys %{ $_[2] } };

    my $padded_concat_os_storage_ref = pad_fields($concat_os_storage_ref, 2);
    my $padded_cases_ref       = pad_fields($_[4], 2);

    return ( 
        $ranks_ref,
        $padded_ranks_ref,
        $padded_usernames_ref,
        $pure_paddings_ref,
        $padded_capacities_ref,
        $padded_cases_ref,
        $padded_concat_os_storage_ref);
}


sub extract_info
{
    # $_[0]: reference to %MASTER_RECORD
    # $_[1]: reference to %POSTS:           system_id => posts
    # $_[2]: reference to %USERNAMES:       system_id => username
    # $_[3]: reference to %CAPACITIES:      system_id => capacity
    # $_[4]: reference to %OS:              system_id => OS
    # $_[5]: reference to %STORAGE_SYS:     system_id => storage system
    # $_[6]: reference to %CASES            system_id => case
    # $_[7]: reference to %NOTES:           system_id => notes

    # Extracts info from %MASTER_RECORD into separate hashes
    # for easier processing.

    %{ $_[1] } = map { $_ => ${ ${ $_[0]}{$_} }{post}        } keys %{ $_[0] };
    %{ $_[2] } = map { $_ => ${ ${ $_[0]}{$_} }{username}    } keys %{ $_[0] };
    %{ $_[3] } = map { $_ => ${ ${ $_[0]}{$_} }{capacity}    } keys %{ $_[0] };
    %{ $_[4] } = map { $_ => ${ ${ $_[0]}{$_} }{os}          } keys %{ $_[0] };
    %{ $_[5] } = map { $_ => ${ ${ $_[0]}{$_} }{storage_sys} } keys %{ $_[0] };
    %{ $_[6] } = map { $_ => ${ ${ $_[0]}{$_} }{case}        } keys %{ $_[0] };
    %{ $_[7] } = map { $_ => ${ ${ $_[0]}{$_} }{notes}       } keys %{ $_[0] };


    # NOTE: It would be more  elegant to calculate the total
    # capacity for each system  automatically from its HDDs,
    # but that will require  some work on the pad_capacities
    # algorithm  as well  as  the final  output  to get  the
    # formatting correct again, so for now we shall leave it
    # as-is and do it manually.
    # pad_capacities will probably  be superfluous and might
    # be replaced by a simple sprintf or similar.
    #%{ $_[3] } = map{$_=>get_system_capacity($HDD_RECORD{$_})} keys %{ $_[0] };

}



############################################################
# PROGRAM SEQUENCE                                         #
############################################################

extract_info(
    \%MASTER_RECORD,
    \%POSTS,
    \%USERNAMES,
    \%CAPACITIES,
    \%OS,
    \%STORAGE_SYS,
    \%CASES,
    \%NOTES);


my @formatted_cols = format_list(
    \%USERNAMES,
    \%CAPACITIES,
    \%OS,
    \%STORAGE_SYS,
    \%CASES,
    \%POSTS);


print_list(
     \@formatted_cols,
     \%POSTS,
     \%NOTES,
     \%USERNAMES,
     \$URL_OPN,
     \$URL_MID,
     \$URL_END,
     \%CAPACITIES);
