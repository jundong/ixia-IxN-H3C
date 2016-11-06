##############################################################
# Script Name	 :   CIxiaPortETH.tcl
# Class Name	 :   CIxiaPortETH
# Description    :   Port Class, support port traffic operations.
# Related Script :   
# Created By     :   Judo Xu 
#############################################################

#############################################################
# Modify History:
#############################################################
# 1.Create	2016.09.28    	jxu@ixiacom.com
#
#############################################################

package require Itcl
package require cmdline

package require IxiaNet
package require Ixia

#引入基类
#package require TestInstrument 1.0

package provide IxiaPort 1.0

proc GetEnvTcl { product } {
   
   set productKey     "HKEY_LOCAL_MACHINE\\SOFTWARE\\Ixia Communications\\$product"
   set versionKey     [ registry keys $productKey ]
   set latestKey      [ lindex $versionKey end ]

    if { $latestKey == "Multiversion" } {
        set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 2 ] ]
        if { $latestKey == "InstallInfo" } {
            set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 3 ] ]
        }
    } elseif { $latestKey == "InstallInfo" } {
        set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 2 ] ]
    }
   set installInfo    [ append productKey \\ $latestKey \\ InstallInfo ]            
   return             [ registry get $installInfo  HOMEDIR ]

}

if { $::tcl_platform(platform) == "windows" } {
	puts "windows platform..."
	package require registry

    if { [ catch {
	    lappend auto_path  "[ GetEnvTcl IxNetwork ]/TclScripts/lib/IxTclNetwork"
    } err ] } {
        error "Failed to invoke IxNetwork environment...$err"
	}

    puts "load package IxTclNetwork..."
	package require IxTclNetwork
	puts "load package IxTclHal..."	
	catch {	
		source [ GetEnvTcl IxOS ]/TclScripts/bin/ixiawish.tcl
        package require IxTclHal
	}
}

::itcl::class CTestInstrumentPort {
	constructor { obj port portObj } {
	}
}

set ::CIxia::gIxia_OK true
set ::CIxia::gIxia_ERR false

#@@All Proc
#Ret: ::CIxia::gIxia_OK - if no error(s)
#     ferr - if error(s) occured
#Usage: CRouteTesterPort port1 {1 2 1}
::itcl::class CIxiaPortETH {
    private variable _chassis ""
    private variable _card ""
    private variable _port ""
    private variable _media ""
    private variable _streamid ""
    private variable _uti ""
    private variable _mode ""
    private variable _portObj ""
    private variable _handle ""
    private variable portList ""
    private variable _capture ""

    #继承父类 
    inherit CTestInstrumentPort
    
    #构造函数
    constructor { obj port portObj } { CTestInstrumentPort::constructor $obj $port $portObj } {
        set port [lindex $port 0]
        set _chassis [lindex $port 0]
        set _card [lindex $port 1]
        set _port [lindex $port 2]
        set portList [ list [ list $_chassis $_card $_port ] ]
        
        set _media [lindex $port 3]
        if { [ string tolower $_media == "c" ] } {
            set _media copper
        } elseif { [ string tolower  == "f" ] } {
            set _media fiber
        }
        
        set _portObj $portObj
        Port $_portObj $_chassis/$_card/$_port $_media
        set _handle [ $_portObj cget -handle ]
        
        Capture _capture $_portObj
        set _capture _capture
        
        Reset
    }
    
    #析构函数
    destructor {}
    
    private method get_params { args }
    private method get_mac { args } 
    private method config_port { args }
    private method config_stream { args }
    
    #Traffic APIs
    public method Reset { args }
    public method Run { args }
    public method Stop { args }
    public method SetTrig {args }
    public method SetPortSpeedDuplex { args }
    public method SetTxSpeed { args }
    public method SetTxMode { args }
    public method SetCustomPkt { args }
    public method SetVFD1 { args }
    public method SetVFD2 { args }
    public method SetEthIIPkt { args }
    public method SetArpPkt { args }
    public method CreateCustomStream { args }
    public method CreateIPStream { args }
    public method CreateTCPStream { args }
    public method CreateUDPStream { args }
    public method SetCustomVFD { args }
    public method CaptureClear { args }
    public method StartCapture { args }
    public method StopCapture { args }
    public method ReturnCaptureCount { args }
    public method ReturnCapturePkt { args }
    public method GetPortInfo { args }
	public method GetPortStatus {}
    public method GetTypeName {}
    public method GetPortCableType {}
    public method GetPortStreams {} {}
    public method Clear { args }
	public method CreateIPv6Stream { args }
	public method CreateIPv6TCPStream { args }
	public method CreateIPv6UDPStream { args }
	public method DeleteAllStream {}
	public method DeleteStream { args } 
	public method SetErrorPacket { args }
	public method SetFlowCtrlMode { args }
	public method SetMultiModifier { args }
	public method SetPortAddress { args } 
	public method SetPortIPv6Address { args }
	public method SetTxPacketSize { args }
    
    #处理并记录error错误
    method error {Str} {
        puts "Log: $Str"
    	#CTestException::Error $Str -origin Ixia
    } 
    
    #输出调试信息
    method Log {Str { Level info } }  {
        puts "Log: $info --- $Str"
    	#CTestLog::Log $Level $Str origin Ixia
    }
} ;# End of Class

###########################################################################################
#@@Proc
#Name: Reset
#Desc: Reset current Port
#Args: args
#Usage: port1 Reset
###########################################################################################
::itcl::body CIxiaPortETH::Reset { args } {
	Log "Reset port $_chassis $_card $_port..."
    set retVal $::CIxia::gIxia_OK
  
    if { ![ GetValueFromReturn [ $_portObj reset ]  Status ] } {
        Log "Failed to reset port: $_chassis/$_card/$_port"
        set retVal $::CIxia::gIxia_ERR 
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: Run
#Desc: Begin to send packects/stream
#Args: args
#Usage: port1 Run
###########################################################################################
::itcl::body CIxiaPortETH::Run { args } {
	Log "Start transmit at $_chassis $_card $_port..."
    set retVal $::CIxia::gIxia_OK
  
    if { ![ GetValueFromReturn [ $_portObj start_traffic ]  Status ] } {
        Log "Failed to start traffic on port: $_chassis/$_card/$_port"
        set retVal $::CIxia::gIxia_ERR 
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: Stop
#Desc: Stop to send packects/stream
#Args: args
#Usage: port1 Stop
###########################################################################################
::itcl::body CIxiaPortETH::Stop { args } {
	Log "Stop transmit at $_chassis $_card $_port..."
    set retVal $::CIxia::gIxia_OK
    if { ![ GetValueFromReturn [ $_portObj stop_traffic ]  Status ] } {
        Log "Failed to stop traffic on port: $_chassis/$_card/$_port"
        set retVal $::CIxia::gIxia_ERR 
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: SetTrig
#Desc: Set filter conditions
#Args:  
#	offset1:       offset of packect
#   pattern1:       trigger pattern
#	trigMode:      support && and ||
#   offset2:       offset of packet
#   pattern2:       trigger pattern
#Usage: port1 SetTrig 12 {00 10}
###########################################################################################
::itcl::body CIxiaPortETH::SetTrig {offset1 pattern1 {TrigMode ""} {offset2 ""} {pattern2 ""}} {
    set trigmode $TrigMode
    Log "Set trigger ($offset1 $pattern1 $trigmode $offset2 $pattern2) at $_chassis $_card $_port..."
    set retVal $::CIxia::gIxia_OK

    #将十进制数转换为十六进制数
    if {[regsub -nocase -all {0x} $pattern1 "" pattern1] == 0} {
        set m_pattern1 ""
        foreach ele $pattern1 {
            lappend m_pattern1 [format %02x $ele]
        }
        set pattern1 $m_pattern1
    }

    if {[regsub -nocase -all {0x} $pattern2 "" pattern2] == 0 && [string length $pattern2] > 0} {
        set m_pattern2 ""
        foreach ele $pattern2 {
            lappend m_pattern2 [format %02x $ele]
        }
        set pattern2 $m_pattern2
    }
    #end
    
    switch -- $trigmode {
        ""      {
                set TriggerMode pattern1
                }
        "||"    {
                set TriggerMode pattern1OrPattern2
                }
        "&&"    {
                set TriggerMode pattern1AndPattern2
                }
        default {
                error "Invaild trigmode: $trigmode"
                }
    }

    if { [catch {
        ixNet setM $_handle/capture -hardwareEnabled true -captureMode captureTriggerMode
        ixNet commit
        if { $TriggerMode == "pattern1" } {
            ixNet setM $_handle/trigger \
                -captureTriggerPattern pattern1 \
                -captureTriggerEnable true \
                -captureTriggerExpressionString P1
            if { $pattern1 != "" } {
                ixNet setM $_handle/filterPallette \
                    -patternOffset1 $offset1 \
                    -patternMask1 $pattern1
            }
            if { $pattern2 != "" } {
                ixNet setM $_handle/filterPallette \
                    -patternOffset2 $offset2 \
                    -patternMask2 $pattern2
                
                if { $TriggerMode == "pattern1OrPattern2" } {
                    ixNet setM $_handle/trigger \
                        -captureTriggerPattern pattern1AndPattern2 \
                        -captureTriggerEnable true \
                        -captureTriggerExpressionString "P1\ or\ P2"
                    
                } elseif { $TriggerMode == "pattern1AndPattern2" } {
                    ixNet setM $_handle/trigger \
                        -captureTriggerPattern pattern1AndPattern2 \
                        -captureTriggerEnable true \
                        -captureTriggerExpressionString "P1\ and\ P2"
                }
            }
        }
        ixNet commit
    } err] } {
        Log "Set trigger failed: $err"
        set retVal $::CIxia::gIxia_ERR 
    }
   	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetPortSpeedDuplex
#Desc: set port speed and duplex 
#Args: autoneg : 0 - disable autoneg 
#		 1 - enable autoneg
#      speed  : speed - 0x0002(10M),0x0008(100M) 0x0040(1G)or all
#      duplex : duplex - FULL(0) or HALF(1) or ALL
#Usage: port1 SetPortSpeedDuplex 1 10 full
###########################################################################################
::itcl::body CIxiaPortETH::SetPortSpeedDuplex {AutoNeg {Speed -1} {Duplex -1}} {
	Log "Set port speed duplex at $_chassis $_card $_port..."
   	set retVal $::CIxia::gIxia_OK
    
    set autoneg $AutoNeg
    set duplex [string toupper $Duplex]
    switch $duplex {
        FULL {set duplex 1}
        HALF {set duplex 0}
        1    {set duplex 1}
        0    {set duplex 0}
        -1   {
                set autoneg 1
                unset duplex
             }
        default { error "illegal duplex defined ($speed)" }
    }
   	set speed [string toupper $Speed]
    switch $speed {
        0X0002 {set speed 10M}
        0X0008 {set speed 100M}
        0X0040 {set speed 1000M}
        100M   {set speed 100M}
        10M    {set speed 10M}
        1000M  {set speed 1000M}
        100    {set speed 100M}
        10     {set speed 10M}
        1000   {set speed 1000M}
        -1     {
                set speed 100M
                set autoneg 1
               }
        default { error "illegal speed defined ($speed)" }
    }
   	
    if { [ info exists duplex ] } {
        if { ![ GetValueFromReturn [ $_portObj config -auto_neg $autoneg -duplex $duplex -speed $speed ]  Status ] } {
            set retVal $::CIxia::gIxia_ERR 
        }
        
    } else {
        if { ![ GetValueFromReturn [ $_portObj config -auto_neg $autoneg -speed $speed ]  Status ] } {
            set retVal $::CIxia::gIxia_ERR 
        }
    }

   	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetTxSpeed
#Desc: Set traffic mode and load
#Args:
#   Utilization : port utilization
#   Mode: traffic mode
#Usage: port1 SetTxSpeed
###########################################################################################
::itcl::body CIxiaPortETH::SetTxSpeed {Utilization {Mode "Uti"}} {

    set utilization $Utilization
    set _uti $Utilization
    set _mode $Mode

    Log "Set tx speed of {$_chassis $_card $_port}..."
    set retVal $::CIxia::gIxia_OK
    regsub {[%]} $utilization {} utilization

    foreach streamObj [ GetPortStreams ] {
        if { $Mode == "Uti" } {
            $streamObj config -load_unit percentLineRate -stream_load $utilization 
        } else {
            $streamObj config -load_unit framesPerSecond -stream_load $utilization 
        }
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: GetPortStreams
#Desc: Get all streams under current port
#Args: 
#Usage: port1 GetPortStreams
###########################################################################################
::itcl::body CIxiaPortETH::GetPortStreams {} {
    Log "Get all streams under current port"

	set streamObj [list]
	set objList [ find objects ]
	foreach obj $objList {
		if { [ $obj isa Traffic ] } {
			lappend streamObj $obj
		}
	}

    set txList [list ]
    foreach obj $streamObj {
        set traffic [ $obj cget -highLevelStream ]
        set txPort [ ixNet getA $traffic -txPortId ]
        if { $txPort == $_handle } {
            lappend txList $obj
            break
        }
    }

    return $txList
}

###########################################################################################
#@@Proc
#Name: SetTxMode
#Desc: set port send mode
#Args: 
#	txmode: send mode
#		0 - CONTINUOUS_PACKET_MODE              
#		1 - SINGLE_BURST_MODE  attach 1 params: BurstCount
#		2 - MULTI_BURST_MODE   attach 4 params: BurstCount InterBurstGap InterBurstGapScale MultiburstCount
#		3 - CONTINUOUS_BURST_MODE   attach 3 params: BurstCount InterBurstGap InterBurstGapScale
#	BurstCount:  ever burst package count
#	MultiburstCount:    multiburst count
#	InterBurstGap:      interval of every 2 bursts
#	InterBurstGapScale: interval unit
#		0 - NanoSeconds            
#		1 - MICRO_SCALE   
#		2 - MILLI_SCALE   
#		3 - Seconds
#Usage: port1 SetTxMode 0
###########################################################################################
::itcl::body CIxiaPortETH::SetTxMode {TxMode {BurstCount 0} {InterBurstGap 0} {InterBurstGapScale 0} {MultiBurstCount 0}} {
    Log "Set tx mode of {$_chassis $_card $_port}..."
    set retVal $::CIxia::gIxia_OK
    
    set txmode [ string tolower $TxMode ]
    switch $txmode {
        0 {set txmode continuous}
        1 {set txmode burst}
        2 {set txmode iteration}
        3 {set txmode custom}
        continuous  {set txmode continuous}
        burst       {set txmode burst}
        iteration   {set txmode iteration}
        custom      {set txmode custom}
        default     { default { error "illegal txmode defined ($txmode)" } }
    }
    set burstcount $BurstCount
    set interburstgap $InterBurstGap
    set interburstgapscale [ string tolower $InterBurstGapScale ]
    set multiburstcount $MultiBurstCount

    switch $interburstgapscale {
        0 {set interburstgapscale nanoseconds}
        1 {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 ]
          }
        2 {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 * 1000 ]
          }
        3 {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 * 1000 * 1000 ]
          }
        nanoseconds {set interburstgapscale nanoseconds}
        micro_scale {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 ]
          }
        milli_scale {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 * 1000 ]
          }
        seconds {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 * 1000 * 1000 ]
          }
        default { default { error "illegal interburstgap defined ($interburstgap)" } }
    }
    
    foreach streamObj [ GetPortStreams ] {
        if { [catch {
            if { $txmode == "continuous" } {
                $streamObj config -tx_mode continuous
            } elseif { $txmode == "burst" } {
                $streamObj config -tx_mode burst -tx_num $burstcount 
            } elseif { $txmode == "iteration" } {
                $streamObj config -tx_mode iteration -tx_num $burstcount -iteration_count $multiburstcount -enable_burst_gap true -burst_gap $interburstgap -burst_gap_units $interburstgapscale
            } elseif { $txmode == "custom" } {
                $streamObj config -tx_mode burst -burst_packet_count $burstcount -enable_burst_gap true -burst_gap $interburstgap -burst_gap_units $interburstgapscale
            } } err]} {
            Log "Failed to set tx mode of {$_chassis $_card $_port}..."
            set retVal $::CIxia::gIxia_ERR
        }
    }
   
    return $retVal
}

###########################################################################################
#@@Proc
#Name: SetCustomPkt
#Desc: set packet value
#Args: 
#	myValue eg:ff ff ff ff ff ff 00 00 00 00 00 01 08 00 45 00
#     	pkt_len default -1
#Usage: port1 SetCustomPkt {ff ff ff ff ff ff 00 00 00 00 00 01 08 00 45 00}
###########################################################################################
::itcl::body CIxiaPortETH::SetCustomPkt {{myValue 0} {pkt_len -1}} {
    Log "Set custom packet of {$_chassis $_card $_port}..."
    set retVal $::CIxia::gIxia_OK
    Log "SetCustomPkt: $myValue $pkt_len"
    
    set Srcip "0.0.0.0"
    set Dstip "0.0.0.0"
    set Srcmac 0000-0000-0000
    set frameSizeType fixed
    
    set streamIndex [llength [GetPortStreams]]
    set trafficName $_portObj.traffic$streamIndex
    Traffic $trafficName $_portObj NULL
    
    set payload $myValue
    set myvalue $myValue
    
    if {[llength $pkt_len] == 1} {
        if [string match $pkt_len "-1"] {
            set pkt_len [llength $myvalue]
        }
        
        if { $pkt_len < 60 } {
            set pkt_len 60
        }
        
        set frameSize [expr $pkt_len + 4]
        set frameSizeType fixed
    } else {
        set frameSizeMIN [lindex $pkt_len 0]
        set frameSizeMAX [lindex $pkt_len 1]
        set frameSizeType random
    }
    
    if { $pkt_len > [llength $myvalue] } {
        set patch_value [string repeat "00 " [expr $pkt_len - [llength $myvalue]]]
        set myvalue [concat $myvalue $patch_value]
        Log "Payload value: $myvalue"
    }
    
    if { [llength $myvalue] >= 12} {
        set DstMac "[lindex $myvalue 0][lindex $myvalue 1]-[lindex $myvalue 2][lindex $myvalue 3]-[lindex $myvalue 4][lindex $myvalue 5]"
        set Srcmac "[lindex $myvalue 6][lindex $myvalue 7]-[lindex $myvalue 8][lindex $myvalue 9]-[lindex $myvalue 10][lindex $myvalue 11]"
    } elseif { [llength $myvalue] > 6 } { 
        set Dstmac "[lindex $myvalue 0][lindex $myvalue 1]-[lindex $myvalue 2][lindex $myvalue 3]-[lindex $myvalue 4][lindex $myvalue 5]"
    } else {
        set Srcmac "[lindex $myvalue 0][lindex $myvalue 1]-[lindex $myvalue 2][lindex $myvalue 3]-[lindex $myvalue 4][lindex $myvalue 5]"
    }
    
    if { [llength $myvalue] >= 12 } {
        if { [lindex $myvalue 12] == "81" && [lindex $myvalue 13] == "00"} {
            set vlanOpts  0x[lindex $myvalue 14][lindex $myvalue 15]
            set vlanID                 [expr $vlanOpts & 0x0FFF]
            # 3 bits Priority
            set userPriority           [expr [expr $vlanOpts >> 13] & 0x0007]
            set cfi                    [expr [expr $vlanOpts >> 12] & 0x0001]
            set payload [lrange $myvalue 18 end]
            
            SingleVlanHdr vlanHdr
            vlanHdr config \
                -id $vlanID \
                -pri $userPriority \
                -cfi $cfi 
        } else {
            set payload [lrange $myvalue 14 end]
            if { [lindex $myvalue 16] == "08" } {
                set Srcip "[lindex $myvalue 26].[lindex $myvalue 27].[lindex $myvalue 28].[lindex $myvalue 29]"                   
            }
        }
    }
    
    if { $frameSizeType == "fixed" } {
        if { [info exists vlanHdr] } {
            $trafficName config -pdu "vlanHdr" -frame_len_type $frameSizeType -frame_len $frameSize -payload $payload
        } else {
            $trafficName config -frame_len_type $frameSizeType -frame_len $frameSize -payload $payload
        }
    } else {
        if { [info exists vlanHdr] } {
            $trafficName config -pdu "vlanHdr" -frame_len_type $frameSizeType -min_frame_len $frameSizeMIN -max_frame_len $frameSizeMAX -payload $payload
        } else {
            $trafficName config -frame_len_type $frameSizeType -min_frame_len $frameSizeMIN -max_frame_len $frameSizeMAX -payload $payload
        }
    }
    
    # Added table interafce to enable arp response
    if { $Srcip != "0.0.0.0" } {
        SetPortAddress -macaddress $Srcmac -ipaddress $Srcip -netmask "255.255.255.0" -replyallarp 1
    }

    return $retVal
}

###########################################################################################
#@@Proc
#Name: SetEthIIPkt
#Desc: set packet value
#Args:
#   -PacketLen
#   -SrcMac
#   -DesMac
#   -DesIP
#   -SrcIP
#   -Tos
#   -TTL
#   -EncapType
#   -VlanID
#   -Priority
#   -Data
#   -Protocol
#     	
#Usage: port1 SetEthIIPkt -PacketLen 1000 -DesMac 7425-8a48-de05 -SrcMac 0000-0001-0001 -DesIP 2.2.2.2 -SrcIP 105.83.157.2
###########################################################################################
::itcl::body CIxiaPortETH::SetEthIIPkt { args } {
    set PacketLen 60
    set SrcMac "0.0.0.1"
    set DesMac "ffff.ffff.ffff"
    set DesIP "1.1.1.2"
    set SrcIP "1.1.1.1"
    set TTL 64
    set Tos 0
    set EncapType EET_II
    set VlanID 0
    set Priority 0
    set Data ""
    set Protocol 1

    set argList {PacketLen.arg SrcMac.arg DesMac.arg DesIP.arg SrcIP.arg Tos.arg TTL.arg \
                 EncapType.arg VlanID.arg Priority.arg Data.arg Protocol.arg}

    set result [cmdline::getopt args $argList opt val]
    while {$result>0} {
        set $opt $val
        set result [cmdline::getopt args $argList opt val]        
    }
    
    if {$result<0} {
        Log "SetEthIIPkt has illegal parameter! $val"
        return $::CIxia::gIxia_ERR
    }

    # 参数检查
    set Match [MacValid $DesMac]
    if { $Match != 1} {
        Log "CIxiaPortETH::SetEthIIPkt >>> DesMac is invalid" warning
        return $::CIxia::gIxia_ERR
    }
    set Match [MacValid $SrcMac]
    if { $Match != 1} {
        Log "CIxiaPortETH::SetEthIIPkt >>> SrcMac is invalid" warning
        return $::CIxia::gIxia_ERR
    }
    set Match [IpValid $DesIP]
    if { $Match != 1} {
        Log "CIxiaPortETH::SetEthIIPkt >>> DesIP is invalid" warning
        return $::CIxia::gIxia_ERR
    }
    set Match [IpValid $SrcIP]
    if { $Match != 1} {
        Log "CIxiaPortETH::SetEthIIPkt >>> SrcIP is invalid" warning
        return $::CIxia::gIxia_ERR
    }

    if {$VlanID==0 && $Priority!=0} {
        Log "CIxiaPortETH::SetEthIIPkt >>> a vlan id is prefered if the priority is used"
        return $::CIxia::gIxia_ERR    
    }
    
    set EncapList {EET_II EET_802_2 EET_802_3 EET_SNAP}
    if {[lsearch $EncapList $EncapType] == -1} {
        Log "CIxiaPortETH::SetEthIIPkt >>> Invalid encapsulation type is prefered! $EncapType" warning
        return $::CIxia::gIxia_ERR
    }
    
    if {$PacketLen < 0} {
        Log "CIxiaPortETH::SetEthIIPkt >>> Invalid packet length is prefered! $PacketLen" warning
        return $::CIxia::gIxia_ERR
    }
    
    switch $EncapType {
           EET_II {
           	set min_pktLen 34
           	set frame_name eth_frame_hdr
           	}
           EET_802_3 {
           	set min_pktLen 34
           	set frame_name 802.3_frame_hdr
           	}
           EET_802_2 {
           	set min_pktLen 37
           	set frame_name 802.2_frame_hdr
           	}
           EET_SNAP {
           	set min_pktLen 42
           	set frame_name snap_frame_hdr
           	}
    }
    
    set vlan_tag_hdr ""
    if {$VlanID!=0} {
        set min_pktLen [expr $min_pktLen + 4]
        set PacketLen [expr $PacketLen + 4]
        
        set vlan_tag_hdr [::packet::conpkt vlan_tag -pri $Priority -tag $VlanID]
    }
    set Data [regsub -all "0x" $Data ""]
    set ipv4_packet [::packet::conpkt ipv4_header -srcip $SrcIP -desip $DesIP -ttl $TTL -tos $Tos -pro $Protocol -data $Data]
    set eth_packet [::packet::conpkt $frame_name -deth $DesMac -seth $SrcMac -vlantag $vlan_tag_hdr -data $ipv4_packet]
    
    Log "Set packet of {$_chassis $_card $_port}:\n\t$eth_packet"
    
    if {[llength $eth_packet] > $PacketLen} {
        $this SetCustomPkt $eth_packet -1
    } else {
        $this SetCustomPkt $eth_packet $PacketLen
    }
    
    return $::CIxia::gIxia_OK
}

::itcl::body CIxiaPortETH::SetArpPkt { args } {
    set PacketLen 60
    set ArpType 1
    set DesMac 0
    set SrcMac 0
    set ArpDesIP "0.0.0.0"
    set ArpSrcIP "0.0.0.0"
    set ArpSrcMac 0
    set ArpDesMac 0
    set EncapType EET_II
    set VlanID 0
    set Priority 0

    set argList {PacketLen.arg ArpType.arg DesMac.arg SrcMac.arg ArpDesMac.arg ArpSrcMac.arg ArpDesIP.arg ArpSrcIP.arg \
                 EncapType.arg VlanID.arg Priority.arg}

    set result [cmdline::getopt args $argList opt val]
    while {$result>0} {
        set $opt $val
        set result [cmdline::getopt args $argList opt val]        
    }
    
    if {$result<0} {
        Log "SetIPXPacket has illegal parameter! $val"
        return $::CIxia::gIxia_ERR
    }
    
    # 如果不指定ArpSrcMac或者取0,则取ArpSrcMac等于SrcMac,如果两者只指定一个就同取一个值。如果两者都为0即都没有指定，
    #则取默认值0.0.1
    if {$ArpSrcMac == 0 && $SrcMac == 0} {  
        set ArpSrcMac 0.0.1 
        set SrcMac 0.0.1 
    } else {
        if {$ArpSrcMac == 0} {set ArpSrcMac $SrcMac }
        if {$SrcMac == 0} {set SrcMac $ArpSrcMac }
    }    
    
    # 如果不指定ArpDesMac或者取0,则取ArpDesMac等于DesMac,如果两者只指定一个就同取一个值。如果两者都为0即都没有指定，
    #则取默认值ffff.ffff.ffff
    if {$ArpDesMac == 0 && $DesMac == 0} {  
        set DesMac ffff.ffff.ffff 
        set ArpDesMac ffff.ffff.ffff 
    } else {
        if {$ArpDesMac == 0} {set ArpDesMac $DesMac }
        if {$DesMac == 0} {set DesMac $ArpDesMac }
    }
    #对于请求报文 ArpDesMac取0.0.0
    if {($ArpType == 1) } {
        set ArpDesMac 0.0.0 
    }
    # 参数检查
    set Match [MacValid $SrcMac]
    if { $Match != 1} {
        Log "CIxiaPortETH::SetArpPkt >>> ArpSrcMac is invalid" warning
        return $::CIxia::gIxia_ERR
    }
    set Match [MacValid $DesMac]
    if { $Match != 1} {
        Log "CIxiaPortETH::SetArpPkt >>> DesMac is invalid" warning
        return $::CIxia::gIxia_ERR
    }
    if {$ArpSrcMac != 0 } {
    set Match [MacValid $ArpSrcMac]
        if { $Match != 1} {
            Log "CIxiaPortETH::SetArpPkt >>> ArpSrcMac is invalid" warning
            return $::CIxia::gIxia_ERR
        }
    }
    
    if {$ArpDesMac != 0 } {
    set Match [MacValid $ArpDesMac]
        if { $Match != 1} {
            Log "CIxiaPortETH::SetArpPkt >>> ArpDesMac is invalid" warning
            return $::CIxia::gIxia_ERR
        }
    }
    
    set Match [IpValid $ArpSrcIP]
    if { $Match != 1} {
        Log "CIxiaPortETH::SetArpPkt >>> ArpSrcIP is invalid" warning
        return $::CIxia::gIxia_ERR
    }
    set Match [IpValid $ArpDesIP]
    if { $Match != 1} {
        Log "CIxiaPortETH::SetArpPkt >>> ArpDesIP is invalid" warning
        return $::CIxia::gIxia_ERR
    }

    if {$VlanID==0 && $Priority!=0} {
        Log "CIxiaPortETH::SetArpPkt >>> a vlan id is prefered if the priority is used"
        return $::CIxia::gIxia_ERR    
    }

    set EncapList {EET_II EET_802_2 EET_802_3 EET_SNAP}
    if {[lsearch $EncapList $EncapType] == -1} {
        Log "CIxiaPortETH::SetArpPkt >>> Invalid encapsulation type is prefered! $EncapType" warning
        return $::CIxia::gIxia_ERR
    }

    if {$PacketLen < 0} {
        Log "CIxiaPortETH::SetArpPkt >>> Invalid packet length is prefered! $PacketLen" warning
        return $::CIxia::gIxia_ERR
    }

    switch $EncapType {
           EET_II {set min_pktLen 42}
           EET_802_3 {set min_pktLen 42}
           EET_802_2 {set min_pktLen 45}
           EET_SNAP {set min_pktLen 50}
    }
    
    if {$PacketLen < $min_pktLen} {
        set PacketLen $min_pktLen
    }
    
    set arp_pkt [::packet::conpkt arp_pkt -deth $DesMac -seth $SrcMac -srcMac $ArpSrcMac -srcIp $ArpSrcIP \
                                          -desMac $ArpDesMac -desIp $ArpDesIP -oper $ArpType]
    Log "Set packet of {$_chassis $_card $_port}:\n\t$arp_pkt"
                                               
    return [$this SetCustomPkt $arp_pkt 60]
}

###########################################################################################
#@@Proc
#Name: CreateCustomStream
#Desc: set custom stream
#Args: 
#      framelen: frame length
#      utilization: send utilization(percent)
#      txmode: send mode,[0|1] 0 - continuous 1 - burst
#      burstcount: burst package count
#      protheader: define packet value same as setcustompkt；
#      portspeed: port speed
#Usage: port1 CreateCustomStream -FrameLen 64 -Utilization 10 -TxMode 0 -BurstCount 0 -ProHeader {ff ff ff ff ff ff 00 00 00 00 00 01 08 00 45 00}
#
###########################################################################################
::itcl::body CIxiaPortETH::CreateCustomStream {args} {
	Log "Create custom stream..."
    set retVal $::CIxia::gIxia_OK

    ##framelen utilization txmode burstcount protheader {portspeed 1000}
    set FrameLen 60
    set FrameRate 0
    set TxMode 0
    set BurstCount 0
    set ProHeader ""
    set Utilization 1
    if { $_uti != "" } {
        set Utilization $_uti
    }
    set argList {FrameLen.arg Utilization.arg FrameRate.arg TxMode.arg BurstCount.arg ProHeader.arg}

    set result [cmdline::getopt args $argList opt val]
    while {$result>0} {
        set $opt $val
        set result [cmdline::getopt args $argList opt val]
    }    
    if {$result<0} {
        puts "CreateCustomStream has illegal parameter! $val"
        return $::CIxia::gIxia_ERR
    }
    
    if { $FrameRate != 0 } {
        set utilization $FrameRate
        set mode "PktPerSec"
    } else {
        set utilization $Utilization
        set mode "Uti"
        if { $_mode != "" } {
            set mode $_mode
        }
    }
    set txmode $TxMode
    set burstcount $BurstCount
    set protheader $ProHeader
    
    set framelen [llength $protheader]
    set retVal1 [SetCustomPkt $protheader $framelen]
    if {[string match $retVal1 $::CIxia::gIxia_ERR]} {	
        error "CreateCustomStream:SetCustomPkt failed."
        set retVal $::CIxia::gIxia_ERR
    }
    set retVal2 [SetTxMode $txmode $burstcount]
    if {[string match $retVal2 $::CIxia::gIxia_ERR]} {	
        error "CreateCustomStream:SetTxMode failed."
        set retVal $::CIxia::gIxia_ERR
    }
    set retVal3 [SetTxSpeed $utilization $mode]
    if {[string match $retVal3 $::CIxia::gIxia_ERR]} {	
        error "CreateCustomStream:SetTxSpeed failed."
        set retVal $::CIxia::gIxia_ERR
    }
    return $retVal      
}


###########################################################################################
#@@Proc
#Name: CreateIPStream
#Desc: set IP stream
#Args: 
#	   -name:    IP Stream name
#      -frameLen: frame length
#      -utilization: send utilization(percent), default 100
#      -txMode: send mode,[0|1] default 0 - continuous 1 - burst
#      -burstCount: burst package count
#      -desMac: destination MAC default ffff-ffff-ffff
#      -srcMac: source MAC default 0-0-0
#      -desIP: destination ip default 0.0.0.0
#      -srcIP: source ip, default 0.0.0.0
#      -tos: tos default 0
#      -_portSpeed: _port speed default 100                   
#	   -data: content of frame, 0 by default means random
#             example: -data 0   ,  the data pattern will be random    
#                      -data abac,  use the "abac" as the data pattern
#	   -signature: enable signature or not, 0(no) by default
#	   -ipmode: how to change the IP
#               0                          no change (default)
#               ip_inc_src_ip              source IP increment
#               ip_inc_dst_ip              destination IP increment
#               ip_dec_src_ip              source IP decrement
#               ip_dec_dst_ip              destination IP decrement
#               ip_inc_src_ip_and_dst_ip   both source and destination IP increment
#               ip_dec_src_ip_and_dst_ip   both source and destination IP decrement
#	   -ipbitsoffset1: bitoffset,0 by default 
#	   -ipbitsoffset2: bitoffset,0 by default
#	   -ipcount1:  the count that the first ip stream will vary,0 by default 
#      -ipcount2:  the count that the second ip stream will vary,0 by default
#      -stepcount1: the step size that the first ip will vary, it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#	   -stepcount2: the step size that the second ip will vary,it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#
#Usage: _port1 CreateIPStream -SMac 0010-01e9-0011 -DMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaPortETH::CreateIPStream { args } {
	Log "Create IP stream..."
    set retVal $::CIxia::gIxia_OK

    set framelen   64
    set framerate  0
    set txmode     0
    set burstcount 1
	set desmac       ffff-ffff-ffff
    set srcmac       0000-0000-0000
	set desip        0.0.0.0
	set srcip        0.0.0.0
    set tos        0
	set _portspeed  100
	set data 0
	set userPattern 0
	set signature 0 
	set ipmode 0 
	set ipbitsoffset1 0
	set ipbitsoffset2 0 
	set ipcount1 0 
    set ipcount2 0 
    set stepcount1 0 
    set stepcount2 0 

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set type       "08 00"
    set ver        4
    set iphlen     5
    set dscp       0
    set tot        0
    set id         0
    set mayfrag    0
    set lastfrag   0
    set fragoffset 0
    set ttl        255        
    set protocol   17
    set change     0
    set enable     true
    set value      {{00 }}
    set strframenum    100
    set utilization 100
    if { $_uti != "" } {
        set utilization $_uti
    }
    
    #---------------added by liusongzhi---------------------#
    set group 1 
    #-----------------end-liusongzhi------------------------#

    #get parameters
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
                append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val    
        puts "$opt: $val"
    }
    
    set streamIndex [llength [GetPortStreams]]
    set trafficName $_portObj.traffic$streamIndex
    Traffic $trafficName $_portObj NULL
    
    # Added table interafce to enable arp response
    SetPortAddress -macaddress $srcmac -ipaddress $srcip -netmask "255.255.255.0" -replyallarp 1
    
    #set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    #set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
    set srcmac [HexToMac $srcmac]
    set desmac [HexToMac $desmac]
		
    EtherHdr etherHdr
    etherHdr config -dst $desmac -src $srcmac

    set vlan $vlanid
    set pri  $priority

    SingleVlanHdr vlanHdr
    vlanHdr config \
        -id $vlan \
        -pri $pri \
        -cfi $cfi
    
    #Define Stream parameters.
    stream setDefault        
    stream config -enable $enable
    stream config -name $name
    stream config -numBursts $burstcount        
    stream config -numFrames $strframenum
    if { $framerate != 0 } {
        stream config -rateMode streamRateModeFps
        stream config -fpsRate $framerate
    } else {
        stream config -percentPacketRate $utilization
        stream config -rateMode usePercentRate
    }
    
    switch $txmode {
        0 {stream config -dma contPacket}
        1 {
            stream config -dma stopStream
            stream config -numBursts 1
            stream config -numFrames $burstcount
            stream config -startTxDelayUnit                   0
            stream config -startTxDelay                       0.0
        }
        2 {stream config -dma advance}
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        set frameSizeType fixed
        set framesize [expr $framelen + 4]
    } else {
        set frameSizeType random
        set frameSizeMIN [lindex $framelen 0]
        set frameSizeMAX [lindex $framelen 1]
    }
    
    

    if {$data == 0} {
            stream config -patternType  nonRepeat
            stream config -dataPattern  allZeroes
            stream config -pattern       "00 00"
    } else {
            stream config -patternType  nonRepeat
            stream config -pattern $data
            stream config -dataPattern 18
    }
    
    Ipv4Hdr ipv4Hdr
    if { $ipmode != 0} {
        if {$ipbitsoffset1 > 7} { set ipbitsoffset1 7 }
        if {$ipbitsoffset2 > 7} { set ipbitsoffset2 7 }
        switch $ipmode {
            ip_inc_src_ip  {
                ipv4Hdr config -protocol_type $protocol \
                    -tos $tos \
                    -identification $id \
                    -ttl $ttl \
                    -flag $mayfrag \
                    -fragment_offset 0 \
                    -src $srcip \
                    -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst $desip
            }
            ip_inc_dst_ip  { 
                ipv4Hdr config -protocol_type $protocol \
                    -tos $tos \
                    -identification $id \
                    -ttl $ttl \
                    -flag $mayfrag \
                    -fragment_offset 0 \
                    -src $srcip \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 \
                    -dst $desip
            }
            ip_dec_src_ip  { 
                ipv4Hdr config -protocol_type $protocol \
                    -tos $tos \
                    -identification $id \
                    -ttl $ttl \
                    -flag $mayfrag \
                    -fragment_offset 0 \
                    -src $srcip \
                    -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode decr \
                    -src_mod $ipbitsoffset1 \
                    -dst $desip
            }
            ip_dec_dst_ip  {
                ipv4Hdr config -protocol_type $protocol \
                    -tos $tos \
                    -identification $id \
                    -ttl $ttl \
                    -flag $mayfrag \
                    -fragment_offset 0 \
                    -src $srcip \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode decr \
                    -dst_mod $ipbitsoffset2 \
                    -dst $desip
            }
            ip_inc_src_ip_and_dst_ip  { 
                ipv4Hdr config -protocol_type $protocol \
                    -tos $tos \
                    -identification $id \
                    -ttl $ttl \
                    -flag $mayfrag \
                    -fragment_offset 0 \
                    -src $srcip \
                    -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 \
                    -dst $desip
            }
            ip_dec_src_ip_and_dst_ip  { 
                ipv4Hdr config -protocol_type $protocol \
                    -tos $tos \
                    -identification $id \
                    -ttl $ttl \
                    -flag $mayfrag \
                    -fragment_offset 0 \
                    -src $srcip \
                    -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 \
                    -dst $desip
            }
            default {
                error "Error: no such ipmode, please check your input!"
                set retVal $::CIxia::gIxia_ERR
            }
        }
    }
        
    return $retVal
}

###########################################################################################
#@@Proc
#Name: CreateTCPStream
#Desc: set TCP stream
#Args: args
#      -Name: the name of TCP stream
#	   -FrameLen: frame length
#      -Utilization: send utilization(percent), default 100
#      -TxMode: send mode,[0|1] 0 - continuous，1 - burst
#      -BurstCount: burst package count
#      -DesMac: destination MAC，default ffff-ffff-ffff
#      -SrcMac: source MAC，default 0-0-0
#      -DesIP: destination ip，default 0.0.0.0
#      -SrcIP: source ip, default 0.0.0.0
#      -Des_port: destionation _port, default 2000
#      -Src_port: source _port，default 2000
#      -Tos: tos，default 0
#	   -ipmode: how to change the IP
#               0                          no change (default)
#               ip_inc_src_ip              source IP increment
#               ip_inc_dst_ip              destination IP increment
#               ip_dec_src_ip              source IP decrement
#               ip_dec_dst_ip              destination IP decrement
#               ip_inc_src_ip_and_dst_ip   both source and destination IP increment
#               ip_dec_src_ip_and_dst_ip   both source and destination IP decrement
#	   -ipbitsoffset1: bitoffset,0 by default 
#	   -ipbitsoffset2: bitoffset,0 by default
#	   -ipcount1:  the count that the first ip stream will vary,0 by default 
#      -ipcount2:  the count that the second ip stream will vary,0 by default
#      -stepcount1: the step size that the first ip will vary, it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#	   -stepcount2: the step size that the second ip will vary,it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#      -_portSpeed: _port speed，default 100
#Usage: _port1 CreateTCPStream -SrcMac 0010-01e9-0011 -DesMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaPortETH::CreateTCPStream { args } {
    Log "Create TCP stream..."
    set retVal $::CIxia::gIxia_OK 
    
    set framelen        64
    set tos             0
    set txmode          0
    set framerate       0
    set utilization     100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set burstcount      1
    set srcport         2000
    set desport         2000     
    set desmac          ffff-ffff-ffff
    set srcmac          0000-0000-0000
    set desip           0.0.0.0
    set srcip           0.0.0.0
    set _portspeed      100    

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set type       "08 00"
    set ver        4
    set iphlen     5
    set dscp       0
    set tot        0
    set id         1
    set mayfrag    0
    set lastfrag   0
    set fragoffset 0
    set ttl        255        
    set pro        4
    set change     0
    set enable     true
    set value      {{00 }}
    set strframenum  100
    set seq        0
    set ack        0
    set tcpopt     ""
    set window     0
    set urgent     0  
    set data       0
    set userPattern 0
    set ipmode   0
 

    set udf1       0
    set udf1Offset 0
    set udf1ContinuousCount   0
    set udf1InitVal {00}
    set udf1Step    1
    set udf1ChangeMode 0
    set udf1Repeat  1
    set udf1Size  8
    set udf1CounterMode udfCounterMode
    
    set udf2       0
    set udf2Offset 0
    set udf2ContinuousCount   0
    set udf2InitVal {00}
    set udf2Step    1
    set udf2ChangeMode 0
    set udf2Repeat  1
    set udf2Size  8
    set udf2CounterMode udfCounterMode
    
    #get parameters
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
    lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
                append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val	
    }
    
    # Added table interafce to enable arp response
    SetPortAddress -macaddress $srcmac -ipaddress $srcip -netmask "255.255.255.0" -replyallarp 1
    
    set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
    
    #format the IP address from decimal to hex
    set hexSrcIp [split $srcip \.]
    set hexDesIp [split $desip \.]
    for {set i 0} {$i < 4} {incr i} {
        lappend hex1 [format %x [lindex $hexSrcIp $i]]
        lappend hex2 [format %x [lindex $hexDesIp $i]]
    }
    set hexSrcIp [lrange $hex1 0 end]
    set hexDesIp [lrange $hex2 0 end]

    set vlan $vlanid
    set pri  $priority

   #Setting the _streamid.
   set streamCnt 1 
   for {set i 1 } {1} {incr i} {
        if {[stream get $_chassis $_card $_port $i] == 0 } {incr streamCnt} else { break}
   }
   set _streamid $streamCnt

    #Define Stream parameters.
    stream setDefault        
    stream config -enable $enable
    stream config -name $name
    stream config -numBursts $burstcount        
    stream config -numFrames $strframenum
    if { $framerate != 0 } {
        stream config -rateMode streamRateModeFps
        stream config -fpsRate $framerate
    } else {
        stream config -percentPacketRate $utilization
        stream config -rateMode usePercentRate
    }
    stream config -sa $srcmac
    stream config -da $desmac
    switch $txmode {
        0 {stream config -dma contPacket}
        1 {
            stream config -dma stopStream
            stream config -numBursts 1
            stream config -numFrames $burstcount
            stream config -startTxDelayUnit                   0
            stream config -startTxDelay                       0.0
        }
        2 {stream config -dma advance}
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        stream config -framesize [expr $framelen + 4]
        stream config -frameSizeType sizeFixed
    } else {
        stream config -framesize 318
        stream config -frameSizeType sizeRandom
        stream config -frameSizeMIN [lindex $framelen 0]
        stream config -frameSizeMAX [lindex $framelen 1]
    }
   
    stream config -frameType $type
    
    #Define protocol parameters 
    protocol setDefault        
    protocol config -name ipV4        
    protocol config -ethernetType ethernetII
   
    ip setDefault        
    ip config -ipProtocol ipV4ProtocolTcp
    ip config -identifier   $id

        switch $mayfrag {
            0 {ip config -fragment may}
            1 {ip config -fragment dont}
        }       
        switch $lastfrag {
            0 {ip config -fragment last}
            1 {ip config -fragment more}
        }       

        ip config -fragmentOffset 0
        ip config -ttl $ttl        
        ip config -sourceIpAddr $srcip
        ip config -destIpAddr   $desip
        if [ip set $_chassis $_card $_port] {
            error "Unable to set IP configs to IxHal!"
            set retVal $::CIxia::gIxia_ERR
        }

	    #Dinfine TCP protocol
        tcp setDefault        
        tcp config -sourcePort $srcport
        tcp config -destPort $desport
        tcp config -sequenceNumber $seq
        tcp config -acknowledgementNumber $ack
        tcp config -window $window
        tcp config -urgentPointer $urgent
		
		if {[llength $tcpopt] != 0} {
			if { $tcpopt > 63 } { 
				error "Error: tcpopt couldn't no more than 63."
				set retVal $::CIxia::gIxia_ERR 
			} else {
				
				set tcpFlag [expr $tcpopt % 2]
				for {set i 2} { $i <= 32} { incr i $i} {
					lappend tcpFlag [expr $tcpopt / $i % 2 ]
				}
			}
			
			for { set i 0} { $i < 6} {incr i} {
				set tmp [lindex $tcpFlag $i]
				if {$tmp} { 
					case $i {
						0 { tcp config -finished true }
						1 { tcp config -synchronize true }
						2 { tcp config -resetConnection true }
						3 { tcp config -pushFunctionValid true }
						4 { tcp config -acknowledgeValid true }
						5 { tcp config -urgentPointerValid true }
					}
				}
			}
		}
		
		

        if [tcp set $_chassis $_card $_port] {
           error "Unable to set Tcp configs to IxHal!"
           set retVal $::CIxia::gIxia_ERR
        }
        
        if {$vlan != 0} {
            protocol config -enable802dot1qTag vlanSingle
            vlan setDefault        
            vlan config -vlanID $vlan
            vlan config -userPriority $pri
            if [vlan set $_chassis $_card $_port] {
                    error "Unable to set vlan configs to IxHal!"
                    set retVal $::CIxia::gIxia_ERR
            }
        }
        switch $cfi {
            0 {vlan config -cfi resetCFI}
            1 {vlan config -cfi setCFI}
        }
        
		if { $ipmode != 0} {
			if {$ipbitsoffset1 > 7} { set ipbitsoffset1 7 }
			if {$ipbitsoffset2 > 7} { set ipbitsoffset2 7 }
			switch $ipmode {
				
				ip_inc_src_ip  {
								set udf1 1
								set udf1Offset 26
								set udf1InitVal $hexSrcIp
								set udf1ChangeMode 0
								set udf1Step   $stepcount1								
								set udf1Repeat $ipcount1
								set udf1Size [expr 32 - $ipbitsoffset1]								
								}
				ip_inc_dst_ip  { 
								set udf2 1
								set udf2Offset 30
								set udf2InitVal $hexDesIp
								set udf2ChangeMode 0
								set udf2Step $stepcount2
								set udf2Repeat $ipcount2
								set udf2Size [expr 32 - $ipbitsoffset2]	
								
								}
				ip_dec_src_ip  { 
								set udf1 1
								set udf1Offset 26
								set udf1InitVal $hexSrcIp 
								set udf1ChangeMode 1
								set udf1Step $stepcount1
								set udf1Repeat $ipcount1
								set udf1Size [expr 32 - $ipbitsoffset1]	
								}
				ip_dec_dst_ip  {
								set udf2 1
								set udf2Offset 30
								set udf2InitVal $hexDesIp 
								set udf2ChangeMode 1
								set udf2Step $stepcount2
								set udf2Repeat $ipcount2
								set udf2Size [expr 32 - $ipbitsoffset2]	
								}
				ip_inc_src_ip_and_dst_ip  { 
								set udf1 1
								set udf1Offset 26
								set udf1InitVal $hexSrcIp 
								set udf1ChangeMode 0
								set udf1Step $stepcount1
								set udf1Repeat $ipcount1
								set udf1Size [expr 32 - $ipbitsoffset1]	
								
								set udf2 1
								set udf2Offset 30
								set udf2InitVal $hexDesIp 
								set udf2ChangeMode 0
								set udf2Step $stepcount2
								set udf2Repeat $ipcount2
								set udf2Size [expr 32 - $ipbitsoffset2]	
								}
				ip_dec_src_ip_and_dst_ip  { 
								set udf1 1
								set udf1Offset 26
								set udf1InitVal $hexSrcIp 
								set udf1ChangeMode 1
								set udf1Step $stepcount1
								set udf1Repeat $ipcount1
								set udf1Size [expr 32 - $ipbitsoffset1]	
								
								set udf2 1
								set udf2Offset 30
								set udf2InitVal $hexDesIp 
								set udf2ChangeMode 1
								set udf2Step $stepcount2
								set udf2Repeat $ipcount2
								set udf2Size [expr 32 - $ipbitsoffset2]	
								}
					default {
							error "Error: no such ipmode, please check your input!"
							set retVal $::CIxia::gIxia_ERR
					}
			}
		}
		
	#UDF Config
        if {$udf1 == 1} {
                udf setDefault        
                udf config -enable true
                udf config -offset $udf1Offset
				udf config -continuousCount  false
                switch $udf1ChangeMode {
                        0 {udf config -updown uuuu}
                        1 {udf config -updown dddd}
                }
				udf config -bitOffset   $ipbitsoffset1
                udf config -initval $udf1InitVal
                udf config -repeat  $udf1Repeat              
                udf config -step    $udf1Step
				udf config -counterMode   $udf1CounterMode
				udf config -udfSize   $udf1Size
                if {[udf set 1]} {
					error "Error calling udf set 1"
					set retVal $::CIxia::gIxia_ERR
				}
		}
				
        if {$udf2 == 1} {
                udf setDefault        
                udf config -enable true
                udf config -offset $udf2Offset
				udf config -continuousCount  false
                
                switch $udf2ChangeMode {
                        0 {udf config -updown uuuu}
                        1 {udf config -updown dddd}
                }
				udf config -bitOffset   $ipbitsoffset2
                udf config -initval $udf2InitVal
                udf config -repeat  $udf2Repeat              
                udf config -step    $udf2Step
				udf config -counterMode   $udf2CounterMode
				udf config -udfSize    $udf2Size
                if {[udf set 2]} {
					error "Error calling udf set 2"
					set retVal $::CIxia::gIxia_ERR
			}
        }
     
        
	#Table UDF Config        
        tableUdf setDefault        
        tableUdf clearColumns      
        tableUdf config -enable 0
        # tableUdfColumn setDefault        
        # tableUdfColumn config -formatType formatTypeHex
        # if {$change == 0} {
            # tableUdfColumn config -offset [expr $framelen -5]} else {
            # tableUdfColumn config -offset $change
        # }
        # tableUdfColumn config -size 1
        # tableUdf addColumn         
        # set rowValueList $value
        # tableUdf addRow $rowValueList
        # if [tableUdf set $_chassis $_card $_port] {
            # error "Unable to set tableUdf to IxHal!"
            # set retVal $::CIxia::gIxia_ERR
        # }

	#_port config -speed $_portspeed
	
		if {$data == 0} {
				stream config -patternType patternTypeRandom
			} else {
				stream config -patternType  nonRepeat
				stream config -pattern $data
				stream config -dataPattern 18
			}
		
		
		# stream set $_chassis $_card $_port $streamID
		# stream write $_chassis $_card $_port $streamID

	if {[string match [config_stream -StreamId $_streamid] $::CIxia::gIxia_ERR]} {
	    set retVal $::CIxia::gIxia_ERR
	}
    if {[string match [config_port -ConfigType config -NoProtServ ture] $::CIxia::gIxia_ERR]} {
	    set retVal $::CIxia::gIxia_ERR
	}

    return $retVal
}


###########################################################################################
#@@Proc
#Name: CreateUDPStream
#Desc: set UDP stream
#Args: args
#      -FrameLen: frame length
#      -Utilization: send utilization(percent), default 100
#      -TxMode: send mode,[0|1] 0 - continuous，1 - burst
#      -BurstCount: burst package count
#      -DesMac: destination MAC，default ffff-ffff-ffff
#      -SrcMac: source MAC，default 0-0-0
#      -DesIP: destination ip，default 0.0.0.0
#      -SrcIP: source ip, default 0.0.0.0
#      -Tos: tos，default 0
#	   -ipmode: how to change the IP
#               0                          no change (default)
#               ip_inc_src_ip              source IP increment
#               ip_inc_dst_ip              destination IP increment
#               ip_dec_src_ip              source IP decrement
#               ip_dec_dst_ip              destination IP decrement
#               ip_inc_src_ip_and_dst_ip   both source and destination IP increment
#               ip_dec_src_ip_and_dst_ip   both source and destination IP decrement
#	   -ipbitsoffset1: bitoffset,0 by default 
#	   -ipbitsoffset2: bitoffset,0 by default
#	   -ipcount1:  the count that the first ip stream will vary,0 by default 
#      -ipcount2:  the count that the second ip stream will vary,0 by default
#      -stepcount1: the step size that the first ip will vary, it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#	   -stepcount2: the step size that the second ip will vary,it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#      -_portSpeed: _port speed，default 100
#Usage: _port1 CreateUDPStream -SrcMac 0010-01e9-0011 -DesMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaPortETH::CreateUDPStream { args } {
    Log "Create UDP stream..."
    set retVal $::CIxia::gIxia_OK
    
    set framelen            64
    set tos                 0
    set txmode              0
    set framerate           0 
    set utilization         100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set burstcount          1
    set srcport             2000
    set desport             2000     
    set desmac              ffff-ffff-ffff
    set srcmac              0000-0000-0000
    set desip               0.0.0.0
    set srcip               0.0.0.0
    set _portspeed          100

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set type       "08 00"
    set ver        4
    set iphlen     5
    set dscp       0
    set tot        0
    set id         1
    set mayfrag    0
    set lastfrag   0
    set fragoffset 0
    set ttl        255        
    set pro        4
    set change     0
    set enable     true
    set value      {{00 }}
    set strframenum  100
    set data       0 
    set ipmode 0


    set udf1       0
    set udf1Offset 0
    set udf1ContinuousCount   0
    set udf1InitVal {00}
    set udf1Step    1
    set udf1ChangeMode 0
    set udf1Repeat  1
    set udf1Size  8
    set udf1CounterMode udfCounterMode

    set udf2       0
    set udf2Offset 0
    set udf2ContinuousCount   0
    set udf2InitVal {00}
    set udf2Step    1
    set udf2ChangeMode 0
    set udf2Repeat  1
    set udf2Size  8
    set udf2CounterMode udfCounterMode

    #get parameters
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
            append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val
    }
    
    # Added table interafce to enable arp response
    SetPortAddress -macaddress $srcmac -ipaddress $srcip -netmask "255.255.255.0" -replyallarp 1
    
    set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    set desmac [::ipaddress::format_mac_address $desmac 6 ":"]

    #format the IP address from decimal to hex
    set hexSrcIp [split $srcip \.]
    set hexDesIp [split $desip \.]
    for {set i 0} {$i < 4} {incr i} {
        lappend hex1 [format %x [lindex $hexSrcIp $i]]
        lappend hex2 [format %x [lindex $hexDesIp $i]]
    }
    set hexSrcIp [lrange $hex1 0 end]
    set hexDesIp [lrange $hex2 0 end]

    # get_params $args
    set vlan $vlanid
    set pri  $priority


    #Setting the _streamid.
    set streamCnt 1 
    for {set i 1 } {1} {incr i} {
        if {[stream get $_chassis $_card $_port $i] == 0 } {incr streamCnt} else { break}
    }
    set _streamid $streamCnt


    #Define Stream parameters.
    stream setDefault        
    stream config -enable $enable
    stream config -name $name
    stream config -numBursts $burstcount        
    stream config -numFrames $strframenum
    if { $framerate != 0 } {
        stream config -rateMode streamRateModeFps
    stream config -fpsRate $framerate
    } else {
        stream config -percentPacketRate $utilization
        stream config -rateMode usePercentRate
    }
    stream config -sa $srcmac
    stream config -da $desmac
    switch $txmode {
        0 {stream config -dma contPacket}
        1 {
            stream config -dma stopStream
            stream config -numBursts 1
            stream config -numFrames $burstcount
            stream config -startTxDelayUnit                   0
            stream config -startTxDelay                       0.0
        }
        2 {stream config -dma advance}
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        stream config -framesize [expr $framelen + 4]
        stream config -frameSizeType sizeFixed
    } else {
        stream config -framesize 318
        stream config -frameSizeType sizeRandom
        stream config -frameSizeMIN [lindex $framelen 0]
        stream config -frameSizeMAX [lindex $framelen 1]
    }
    
    stream config -frameType $type
    
    #Define protocol parameters 
    protocol setDefault        
    protocol config -name ipV4        
    protocol config -ethernetType ethernetII
    
    ip setDefault        
    ip config -ipProtocol ipV4ProtocolUdp
    ip config -identifier   $id
    switch $mayfrag {
        0 {ip config -fragment may}
        1 {ip config -fragment dont}
    }       
    switch $lastfrag {
        0 {ip config -fragment last}
        1 {ip config -fragment more}
    }       

    ip config -fragmentOffset 0
    ip config -ttl $ttl        
    ip config -sourceIpAddr $srcip
    ip config -destIpAddr   $desip
    if [ip set $_chassis $_card $_port] {
            error "Unable to set IP configs to IxHal!"
            set retVal $::CIxia::gIxia_ERR
    }
	#Dinfine UDP protocol
    udp setDefault        
    #tcp config -offset 5
    udp config -sourcePort $srcport
    udp config -destPort $desport
    if [udp set $_chassis $_card $_port] {
       error "Unable to set UDP configs to IxHal!"
       set retVal $::CIxia::gIxia_ERR
    }
    
    if {$vlan != 0} {
        protocol config -enable802dot1qTag vlanSingle
        vlan setDefault        
        vlan config -vlanID $vlan
        vlan config -userPriority $pri
        if [vlan set $_chassis $_card $_port] {
                error "Unable to set vlan configs to IxHal!"
                set retVal $::CIxia::gIxia_ERR
        }
    }
    switch $cfi {
            0 {vlan config -cfi resetCFI}
            1 {vlan config -cfi setCFI}
    }
        
	#UDF Config
    if { $ipmode != 0} {
        if {$ipbitsoffset1 > 7} { set ipbitsoffset1 7 }
        if {$ipbitsoffset2 > 7} { set ipbitsoffset2 7 }
        switch $ipmode {
            
            ip_inc_src_ip  {
                            set udf1 1
                            set udf1Offset 26
                            set udf1InitVal $hexSrcIp
                            set udf1ChangeMode 0
                            set udf1Step   $stepcount1								
                            set udf1Repeat $ipcount1
                            set udf1Size [expr 32 - $ipbitsoffset1]								
                            }
            ip_inc_dst_ip  { 
                            set udf2 1
                            set udf2Offset 30
                            set udf2InitVal $hexDesIp
                            set udf2ChangeMode 0
                            set udf2Step $stepcount2
                            set udf2Repeat $ipcount2
                            set udf2Size [expr 32 - $ipbitsoffset2]	
                            
                            }
            ip_dec_src_ip  { 
                            set udf1 1
                            set udf1Offset 26
                            set udf1InitVal $hexSrcIp 
                            set udf1ChangeMode 1
                            set udf1Step $stepcount1
                            set udf1Repeat $ipcount1
                            set udf1Size [expr 32 - $ipbitsoffset1]	
                            }
            ip_dec_dst_ip  {
                            set udf2 1
                            set udf2Offset 30
                            set udf2InitVal $hexDesIp 
                            set udf2ChangeMode 1
                            set udf2Step $stepcount2
                            set udf2Repeat $ipcount2
                            set udf2Size [expr 32 - $ipbitsoffset2]	
                            }
            ip_inc_src_ip_and_dst_ip  { 
                            set udf1 1
                            set udf1Offset 26
                            set udf1InitVal $hexSrcIp 
                            set udf1ChangeMode 0
                            set udf1Step $stepcount1
                            set udf1Repeat $ipcount1
                            set udf1Size [expr 32 - $ipbitsoffset1]	
                            
                            set udf2 1
                            set udf2Offset 30
                            set udf2InitVal $hexDesIp 
                            set udf2ChangeMode 0
                            set udf2Step $stepcount2
                            set udf2Repeat $ipcount2
                            set udf2Size [expr 32 - $ipbitsoffset2]	
                            }
            ip_dec_src_ip_and_dst_ip  { 
                            set udf1 1
                            set udf1Offset 26
                            set udf1InitVal $hexSrcIp 
                            set udf1ChangeMode 1
                            set udf1Step $stepcount1
                            set udf1Repeat $ipcount1
                            set udf1Size [expr 32 - $ipbitsoffset1]	
                            
                            set udf2 1
                            set udf2Offset 30
                            set udf2InitVal $hexDesIp 
                            set udf2ChangeMode 1
                            set udf2Step $stepcount2
                            set udf2Repeat $ipcount2
                            set udf2Size [expr 32 - $ipbitsoffset2]	
                            }
                default {
                        error "Error: no such ipmode, please check your input!"
                        set retVal $::CIxia::gIxia_ERR
                }
        }
    }
		
	#UDF Config
    if {$udf1 == 1} {
            udf setDefault        
            udf config -enable true
            udf config -offset $udf1Offset
            udf config -continuousCount  false
            switch $udf1ChangeMode {
                    0 {udf config -updown uuuu}
                    1 {udf config -updown dddd}
            }
            udf config -bitOffset   $ipbitsoffset1
            udf config -initval $udf1InitVal
            udf config -repeat  $udf1Repeat              
            udf config -step    $udf1Step
            udf config -counterMode   $udf1CounterMode
            udf config -udfSize   $udf1Size
            if {[udf set 1]} {
                error "Error calling udf set 1"
                set retVal $::CIxia::gIxia_ERR
            }
    }
            
    if {$udf2 == 1} {
            udf setDefault        
            udf config -enable true
            udf config -offset $udf2Offset
            udf config -continuousCount  false
            
            switch $udf2ChangeMode {
                    0 {udf config -updown uuuu}
                    1 {udf config -updown dddd}
            }
            udf config -bitOffset   $ipbitsoffset2
            udf config -initval $udf2InitVal
            udf config -repeat  $udf2Repeat              
            udf config -step    $udf2Step
            udf config -counterMode   $udf2CounterMode
            udf config -udfSize    $udf2Size
            if {[udf set 2]} {
                error "Error calling udf set 2"
                set retVal $::CIxia::gIxia_ERR
        }
    }
    
	#Table UDF Config        
    tableUdf setDefault        
    tableUdf clearColumns      
    tableUdf config -enable 0
    
    if {$data == 0} {
            stream config -patternType patternTypeRandom
    } else {
        stream config -patternType  nonRepeat
        stream config -pattern $data
        stream config -dataPattern 18
    }
									 
		
		
    # stream set $_chassis $_card $_port $streamID
    # stream write $_chassis $_card $_port $streamID

	#_port config -speed $_portspeed
        
	if {[string match [config_stream -StreamId $_streamid] $::CIxia::gIxia_ERR]} {
	    set retVal $::CIxia::gIxia_ERR
	}
	if {[string match [config_port -ConfigType config -NoProtServ ture] $::CIxia::gIxia_ERR]} {
	    set retVal $::CIxia::gIxia_ERR
	}

    return $retVal
}

###########################################################################################
#@@Proc
#Name: CreateIPv6Stream
#Desc: set IPv6 stream
#Args: 
#	   -name:    IP Stream name
#      -frameLen: frame length
#      -utilization: send utilization(percent), default 100
#      -txMode: send mode,[0|1] default 0 - continuous 1 - burst
#      -burstCount: burst package count
#      -desMac: destination MAC default ffff-ffff-ffff
#      -srcMac: source MAC default 0-0-0
#      -_portSpeed: _port speed default 100                   
#	   -data: content of frame, 0 by default means random
#             example: -data 0   ,  the data pattern will be random    
#                      -data abac,  use the "abac" as the data pattern
#     -VlanID: default 0
#     -Priority: the priority of vlan, 0 by default
#     -DesIP: the destination ipv6 address,the input format should be X:X::X:X
#     -SrcIP: the source ipv6 address, the input format should be X:X::X:X
#	  -nextHeader: the next header, 59 by default
#     -hopLimit: 255 by default
#     -traffClass: 0 by default
#     -flowLable: 0 by default
#
#Usage: _port1 CreateIPv6Stream -SMac 0010-01e9-0011 -DMac ffff-ffff-ffff
###########################################################################################

::itcl::body CIxiaPortETH::CreateIPv6Stream { args } {
	Log  "Create IPv6 stream..."
    set retVal $::CIxia::gIxia_OK
    
    set framelen   128
    set framerate  0
    set utiliztion 100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set txmode     0
    set burstcount 1
    set desmac       ffff-ffff-ffff
    set srcmac       0000-0000-0000
    set desip        ::
    set srcip        ::
    set portspeed  100
    set data 0
    set signature 0 

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
#       set type       "86 00"
    set ver        6
    set id         0    
    set protocol   41       
    set enable     true
    set value      {{00 }}
    set strframenum    100
    
    set nextheader  59
    set hoplimit   255
    set traffclass  0 
    set flowlabel   0 
            
    set udf1       0
    set udf1offset 0
    set udf1len    1
    set udf1initval {00}
    set udf1step    1
    set udf1changemode 0
    set udf1repeat  1
    
    set udf2       0
    set udf2offset 0
    set udf2len    1
    set udf2initval {00}
    set udf2step    1
    set udf2changemode 0
    set udf2repeat  1
    
    set udf3       0
    set udf3offset 0
    set udf3len    1
    set udf3initval {00}
    set udf3step    1
    set udf3changemode 0
    set udf3repeat  1
    
    set udf4       0
    set udf4offset 0
    set udf4len    1
    set udf4initval {00}
    set udf4step    1
    set udf4changemode 0
    set udf4repeat  1        
    
    set udf5       0
    set udf5offset 0
    set udf5len    1
    set udf5initval {00}
    set udf5step    1
    set udf5changemode 0
    set udf5repeat  1
    
    set tableudf 0 
    set change   0
    
    #get_params $args
		
	set argList ""
	set temp ""
	for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
            append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val        
    }

    # Added table interafce to enable arp response
    SetPortIPv6Address -macaddress $srcmac -ipaddress $srcip -prefixLen "64" -replyallarp 1
         
    set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
	
    set vlan $vlanid
    set pri  $priority

	#Setting the _streamid.
    set streamCnt 1 
    for {set i 1 } {1} {incr i} {
        if {[stream get $_chassis $_card $_port $i] == 0 } {incr streamCnt} else { break}
    }
    set _streamid $streamCnt
		
	#Define Stream parameters.
    stream setDefault        
    stream config -enable $enable
    stream config -name $name
    stream config -numBursts $burstcount        
    stream config -numFrames $strframenum
    if { $framerate != 0 } {
        stream config -rateMode streamRateModeFps
        stream config -fpsRate $framerate
    } else {
        stream config -percentPacketRate $utiliztion
        stream config -rateMode usePercentRate
    }
    stream config -sa $srcmac
    stream config -da $desmac
    
    switch $txmode {
        0 {stream config -dma contPacket}
        1 { stream config -dma stopStream
            stream config -numBursts 1
            stream config -numFrames $burstcount
            stream config -startTxDelayUnit                   0
            stream config -startTxDelay                       0.0
           }
        2 {stream config -dma advance}
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        stream config -framesize [expr $framelen + 4]
        stream config -frameSizeType sizeFixed
    } else {
        stream config -framesize 318
        stream config -frameSizeType sizeRandom
        stream config -frameSizeMIN [lindex $framelen 0]
        stream config -frameSizeMAX [lindex $framelen 1]
    }
   
    #stream config -frameType $type
        
	#Define protocol parameters 
     protocol setDefault        
     protocol config -name ipV6
     protocol config -ethernetType ethernetII
     
     ipV6 setDefault 
     ipV6 config -sourceAddr $srcip
     ipV6 config -destAddr $desip
     ipV6 config -flowLabel $flowlabel
     ipV6 config -hopLimit  $hoplimit		
     ipV6 config -trafficClass $traffclass
     
     if { $nextheader != 59 } {
        switch $nextheader {
            0  { ipV6 addExtensionHeader ipV6HopByHopOptions}
            43 { ipV6 addExtensionHeader ipV6Routing}
            44 { ipV6 addExtensionHeader ipV6Fragment}
            50 { ipV6 addExtensionHeader ipV6EncapsulatingSecurityPayload}
            51 { ipV6 addExtensionHeader ipV6Authentication}
            60 { ipV6 addExtensionHeader ipV6DestinationOptions}
            6  { ipV6 addExtensionHeader tcp}
            17 { ipV6 addExtensionHeader udp}
            58 { ipV6 addExtensionHeader icmpV6}
            default { IxPuts -red "Wrong nextHeader type!"
                        set retVal $::CIxia::gIxia_ERR
                    }
        }
    }
     
    if [ipV6 set $_chassis $_card $_port] {
        IxPuts -red "Unable to set ipV6 configs to IxHal!"
        set retVal $::CIxia::gIxia_ERR
    }                 
    
    if {$vlan != 0} {
        protocol config -enable802dot1qTag vlanSingle
        vlan setDefault        
        vlan config -vlanID $vlan
        vlan config -userPriority $pri
        if [vlan set $_chassis $_card $_port] {
            error "Unable to set vlan configs to IxHal!"
            set retVal $::CIxia::gIxia_ERR
        }
    
        switch $cfi {
            0 {vlan config -cfi resetCFI}
            1 {vlan config -cfi setCFI}
        }
    }
        
	#UDF Config
    if {$udf1 == 1} {
            udf setDefault        
            udf config -enable true
            udf config -offset $udf1offset
            switch $udf1len {
                    1 { udf config -countertype c8  }                
                    2 { udf config -countertype c16 }               
                    3 { udf config -countertype c24 }                
                    4 { udf config -countertype c32 }
            }
            switch $udf1changemode {
                    0 {udf config -updown uuuu}
                    1 {udf config -updown dddd}
            }
            udf config -initval $udf1initval
            udf config -repeat  $udf1repeat              
            udf config -step    $udf1step
            udf set 1
    }
    if {$udf2 == 1} {
            udf setDefault        
            udf config -enable true
            udf config -offset $udf2offset
            switch $udf2len {
                    1 { udf config -countertype c8  }                
                    2 { udf config -countertype c16 }               
                    3 { udf config -countertype c24 }                
                    4 { udf config -countertype c32 }
            }
            switch $udf2changemode {
                    0 {udf config -updown uuuu}
                    1 {udf config -updown dddd}
            }
            udf config -initval $udf2initval
            udf config -repeat  $udf2repeat              
            udf config -step    $udf2step
            udf set 2
    }
    if {$udf3 == 1} {
            udf setDefault        
            udf config -enable true
            udf config -offset $udf3offset
            switch $udf3len {
                    1 { udf config -countertype c8  }                
                    2 { udf config -countertype c16 }               
                    3 { udf config -countertype c24 }                
                    4 { udf config -countertype c32 }
            }
            switch $udf3changemode {
                    0 {udf config -updown uuuu}
                    1 {udf config -updown dddd}
            }
            udf config -initval $udf3initval
            udf config -repeat  $udf3repeat              
            udf config -step    $udf3step
            udf set 3
    }
    if {$udf4 == 1} {
            udf setDefault        
            udf config -enable true
            udf config -offset $udf4offset
            switch $udf4len {
                    1 { udf config -countertype c8  }                
                    2 { udf config -countertype c16 }               
                    3 { udf config -countertype c24 }                
                    4 { udf config -countertype c32 }
            }
            switch $udf4changemode {
                    0 {udf config -updown uuuu}
                    1 {udf config -updown dddd}
            }
            udf config -initval $udf4initval
            udf config -repeat  $udf4repeat              
            udf config -step    $udf4step
            udf set 4
    }
    if {$udf5 == 1} {
            udf setDefault        
            udf config -enable true
            udf config -offset $udf5offset
            switch $udf5len {
                    1 { udf config -countertype c8  }                
                    2 { udf config -countertype c16 }               
                    3 { udf config -countertype c24 }                
                    4 { udf config -countertype c32 }
            }
            switch $udf5changemode {
                    0 {udf config -updown uuuu}
                    1 {udf config -updown dddd}
            }
            udf config -initval $udf5initval
            udf config -repeat  $udf5repeat              
            udf config -step    $udf5step
            udf set 5
    }        
        
	#Table UDF Config        
    if { $tableudf == 1 } {
        tableUdf setDefault        
        tableUdf clearColumns      
        tableUdf config -enable 1
        tableUdfColumn setDefault        
        tableUdfColumn config -formatType formatTypeHex
        if {$change == 0} {
            tableUdfColumn config -offset [expr $framelen -5]
        } else {
            tableUdfColumn config -offset $change
        }
        tableUdfColumn config -size 1
        tableUdf addColumn         
        set rowValueList $value
        tableUdf addRow $rowValueList
        if [tableUdf set $_chassis $_card $_port] {
            error "Unable to set tableUdf to IxHal!"
            set retVal $::CIxia::gIxia_ERR
        }
    } 
     
	# #data content	
    if {$data == 0} {
        stream config -patternType patternTypeRandom
    } else {stream config -patternType  nonRepeat
            stream config -pattern $data
            stream config -dataPattern 18
    }

	#port config -speed $portspeed

    if [stream set $_chassis $_card $_port $_streamid] {
             error "Stream set $_chassis $_card $_port $_streamid error"
             set retVal $::CIxia::gIxia_ERR
    }
    
    if  [stream write $_chassis $_card $_port $_streamid] {
            error "Stream write $_chassis $_card $_port $_streamid error"
            set retVal $::CIxia::gIxia_ERR
    }
    
    return $retVal
}


###########################################################################################
#@@Proc
#Name: CreateIPv6TCPStream
#Desc: set IPv6 TCP stream
#Args: 
#	   -name:    IP Stream name
#      -frameLen: frame length
#      -utilization: send utilization(percent), default 100
#      -txMode: send mode,[0|1] default 0 - continuous 1 - burst
#      -burstCount: burst package count
#      -desMac: destination MAC default ffff-ffff-ffff
#      -srcMac: source MAC default 0-0-0
#      -_portSpeed: _port speed default 100                   
#	   -data: content of frame, 0 by default means random
#             example: -data 0   ,  the data pattern will be random    
#                      -data abac,  use the "abac" as the data pattern
#     -VlanID: default 0
#     -Priority: the priority of vlan, 0 by default
#     -DesIP: the destination ipv6 address,the input format should be X:X::X:X
#     -SrcIP: the source ipv6 address, the input format should be X:X::X:X
#	  -nextHeader: the next header, 59 by default
#     -hopLimit: 255 by default
#     -traffClass: 0 by default
#     -flowLable: 0 by default
#	  -ipmode: how to change the IP
#               0                          no change (default)
#               ip_inc_src_ip              source IP increment
#               ip_inc_dst_ip              destination IP increment
#               ip_dec_src_ip              source IP decrement
#               ip_dec_dst_ip              destination IP decrement
#               ip_inc_src_ip_and_dst_ip   both source and destination IP increment
#               ip_dec_src_ip_and_dst_ip   both source and destination IP decrement
#	  -ipcount1:  the count that the first ip stream will vary,0 by default 
#     -ipcount2:  the count that the second ip stream will vary,0 by default
#     -stepcount1: the step size that the first ip will vary, it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#	  -stepcount2: the step size that the second ip will vary,it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#     -srcport: TCP source port , 2000 by default
#     -desport: TCP destination port, 2000 by default
#	  -tcpseq:  TCP sequenceNumber, 123456 by default
#     -tcpack:  TCP acknowledgementNumber, 234567 by default
#     -tcpopts: TCP Flag, 16 (push) by default 
#     -tcpwindow: TCP window, 4096 by default
#
#Usage: port1 CreateIPv6TCPStream -SMac 0010-01e9-0011 -DMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaPortETH::CreateIPv6TCPStream { args } {
	Log  "Create IPv6 TCP stream..."
         set retVal $::CIxia::gIxia_OK

    set framelen   128
    set framerate  0
    set utiliztion 100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set txmode     0
    set burstcount 1
    set desmac       ffff-ffff-ffff
    set srcmac       0000-0000-0000
    set desip        ::
    set srcip        ::
    set portspeed  100
    set data 0
    set signature 0 

        set name      ""
        set vlan       0
        set vlanid     0
        set pri        0
        set priority   0
        set cfi        0
        set ver        6
        set id         1    
        set protocol   41       
        set enable     true
        set value      {{00 }}
        set strframenum    100
		
		set nextheader  6
		set hoplimit   255
		set traffclass  0 
		set flowlabel   0 
		set ipmode 0
		set ipcount1 1 
		set ipcount2 1 
		set stepcount1 1 
		set stepcount2 1 
        
        set udf1       0
        set udf1offset 0
        set udf1len    1
        set udf1initval {00}
        set udf1step    1
        set udf1changemode 0
        set udf1repeat  1
        
        set udf2       0
        set udf2offset 0
        set udf2len    1
        set udf2initval {00}
        set udf2step    1
        set udf2changemode 0
        set udf2repeat  1
        
        set udf3       0
        set udf3offset 0
        set udf3len    1
        set udf3initval {00}
        set udf3step    1
        set udf3changemode 0
        set udf3repeat  1
        
        set udf4       0
        set udf4offset 0
        set udf4len    1
        set udf4initval {00}
        set udf4step    1
        set udf4changemode 0
        set udf4repeat  1        
        
        set udf5       0
        set udf5offset 0
        set udf5len    1
        set udf5initval {00}
        set udf5step    1
        set udf5changemode 0
        set udf5repeat  1
		
		set tableudf 0 
		set change   0
		
		set srcport 2000
		set desport 2000 
		set tcpseq 123456
		set tcpack 234567
		set tcpopts 16 
		set tcpwindow 4096
		set tcpFlag ""
        
        
	    #get_params $args
		
		set argList ""
		set temp ""
		for {set i 0} { $i < [llength $args]} {incr i} {
		lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
            append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val        
    }
   
    # Added table interafce to enable arp response
    SetPortIPv6Address -macaddress $srcmac -ipaddress $srcip -prefixLen "64" -replyallarp 1
    
    set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
	
        set vlan $vlanid
        set pri  $priority
	

	#Setting the _streamid.
		set streamCnt 1 
		for {set i 1 } {1} {incr i} {
			if {[stream get $_chassis $_card $_port $i] == 0 } {incr streamCnt} else { break}
		}
		set _streamid $streamCnt


    #Define Stream parameters.
    stream setDefault        
    stream config -enable $enable
    stream config -name $name
    stream config -numBursts $burstcount        
    stream config -numFrames $strframenum
    if { $framerate != 0 } {
        stream config -rateMode streamRateModeFps
        stream config -fpsRate $framerate
    } else {
        stream config -percentPacketRate $utiliztion
        stream config -rateMode usePercentRate
    }
    stream config -sa $srcmac
    stream config -da $desmac
   
    switch $txmode {
        0 {stream config -dma contPacket}
        1 { stream config -dma stopStream
            stream config -numBursts 1
            stream config -numFrames $burstcount
            stream config -startTxDelayUnit                   0
            stream config -startTxDelay                       0.0
        }
       2 {stream config -dma advance}
       default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
   
    if {[llength $framelen] == 1} {
        stream config -framesize [expr $framelen + 4]
        stream config -frameSizeType sizeFixed
    } else {
        stream config -framesize 318
        stream config -frameSizeType sizeRandom
        stream config -frameSizeMIN [lindex $framelen 0]
        stream config -frameSizeMAX [lindex $framelen 1]
    }
  
    #stream config -frameType $type   
    #Define protocol parameters 
    protocol setDefault        
    protocol config -name ipV6
    protocol config -ethernetType ethernetII
    
    ipV6 setDefault 
    ipV6 config -sourceAddr $srcip
    ipV6 config -destAddr $desip
    ipV6 config -flowLabel $flowlabel
    ipV6 config -hopLimit  $hoplimit        
    ipV6 config -trafficClass $traffclass
    
    switch $ipmode {
        0   {ipV6 config -sourceAddrMode ipV6Idle
            ipV6 config -destAddrMode ipV6Idle
        }
        ip_inc_src_ip {
            ipV6 config -sourceAddrMode ipV6IncrHost 
            ipV6 config -sourceAddrRepeatCount $ipcount1
            ipV6 config -sourceStepSize $stepcount1
        }
        ip_inc_dst_ip {
            ipV6 config -destAddrMode ipV6IncrHost 
            ipV6 config -destAddrRepeatCount $ipcount2
            ipV6 config -destStepSize $stepcount2
        }
        ip_dec_src_ip {
            ipV6 config -sourceAddrMode ipV6DecrHost 
            ipV6 config -sourceAddrRepeatCount $ipcount1
            ipV6 config -sourceStepSize $stepcount1                        
        }
        ip_dec_dst_ip {
            ipV6 config -destAddrMode ipV6DecrHost 
            ipV6 config -destAddrRepeatCount $ipcount2
            ipV6 config -destStepSize $stepcount2
        }
        ip_inc_src_ip_and_dst_ip {
            ipV6 config -sourceAddrMode ipV6IncrHost
            ipV6 config -destAddrMode ipV6IncrHost
            ipV6 config -sourceAddrRepeatCount $ipcount1
            ipV6 config -sourceStepSize $stepcount1                        
            ipV6 config -destAddrRepeatCount $ipcount2
            ipV6 config -destStepSize $stepcount2                                    
        }
        ip_dec_src_ip_and_dst_ip {
            ipV6 config -sourceAddrMode ipV6DecrHost
            ipV6 config -destAddrMode ipV6DecrHost
            ipV6 config -sourceAddrRepeatCount $ipcount1
            ipV6 config -sourceStepSize $stepcount1                        
            ipV6 config -destAddrRepeatCount $ipcount2
            ipV6 config -destStepSize $stepcount2    
        }
        default {
            set usage "ip_inc_src_ip,ip_inc_dst_ip,ip_dec_src_ip,ip_dec_dst_ip ,ip_inc_src_ip_and_dst_ip,ip_dec_src_ip_and_dst_ip"
            error "Error: ipmode should be $usage. "
            set retVal $::CIxia::gIxia_ERR 
        }
    }
    
    ipV6 config -nextHeader tcp
    if [ipV6 set $_chassis $_card $_port] {
        error  "Unable to set ipV6 configs to IxHal!"
        set retVal $::CIxia::gIxia_ERR 
    }                 
   
    if {$vlan != 0} {
       protocol config -enable802dot1qTag vlanSingle
       vlan setDefault        
       vlan config -vlanID $vlan
       vlan config -userPriority $pri
       if [vlan set $_chassis $_card $_port] {
           error "Unable to set vlan configs to IxHal!"
           set retVal $::CIxia::gIxia_ERR 
       }
   
       switch $cfi {
           0 {vlan config -cfi resetCFI}
           1 {vlan config -cfi setCFI}
       }
    }


   
		

    #TCP settings
    tcp setDefault
    tcp config -sourcePort $srcport
    tcp config -destPort $desport
    tcp config -useValidChecksum true
    tcp config -sequenceNumber $tcpseq
    tcp config -acknowledgementNumber $tcpack
    tcp config -window $tcpwindow
   
    if { $tcpopts > 63} { 
        error "Error: tcpopts couldn't no more than 63."
        set retVal $::CIxia::gIxia_ERR 
    } else {
        lappend tcpFlag [expr $tcpopts % 2 ]
        for {set i 1} { $i < 6} { incr i} {
           lappend tcpFlag [expr ($tcpopts / (2 * $i )) % 2 ]
        }
    }
   
    for { set i 0} { $i < 6} {incr i} {
        set tmp [lindex $tcpFlag $i]
        if {$tmp} { 
            case $i {
                0 { tcp config -finished true }
                1 { tcp config -synchronize true }
                2 { tcp config -resetConnection true }
                3 { tcp config -pushFunctionValid true }
                4 { tcp config -acknowledgeValid true }
                5 { tcp config -urgentPointerValid true }
            }
        }
    }
   
    if {[tcp set $_chassis $_card $_port ]} {
        error "Error setting tcp on port $_chassis.$_card.$_port"
        set retVal $::CIxia::gIxia_ERR 
    }
   
   
    #UDF Config
    if {$udf1 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf1offset
        switch $udf1len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf1changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf1initval
        udf config -repeat  $udf1repeat              
        udf config -step    $udf1step
        udf set 1
    }
    if {$udf2 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf2offset
        switch $udf2len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf2changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf2initval
        udf config -repeat  $udf2repeat              
        udf config -step    $udf2step
        udf set 2
    }
    if {$udf3 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf3offset
        switch $udf3len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf3changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf3initval
        udf config -repeat  $udf3repeat              
        udf config -step    $udf3step
        udf set 3
    }
    if {$udf4 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf4offset
        switch $udf4len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf4changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf4initval
        udf config -repeat  $udf4repeat              
        udf config -step    $udf4step
        udf set 4
    }
    if {$udf5 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf5offset
        switch $udf5len {
             1 { udf config -countertype c8  }                
             2 { udf config -countertype c16 }               
             3 { udf config -countertype c24 }                
             4 { udf config -countertype c32 }
        }
        switch $udf5changemode {
             0 {udf config -updown uuuu}
             1 {udf config -updown dddd}
        }
        udf config -initval $udf5initval
        udf config -repeat  $udf5repeat              
        udf config -step    $udf5step
        udf set 5
    }        
   
    #Table UDF Config        
    if { $tableudf == 1 } {
        tableUdf setDefault        
        tableUdf clearColumns      
        tableUdf config -enable 1
        tableUdfColumn setDefault        
        tableUdfColumn config -formatType formatTypeHex
        if {$change == 0} {
            tableUdfColumn config -offset [expr $framelen -5]} else {
            tableUdfColumn config -offset $change
        }
        tableUdfColumn config -size 1
        tableUdf addColumn         
        set rowValueList $value
        tableUdf addRow $rowValueList
        if [tableUdf set $_chassis $_card $_port] {
            error "Unable to set tableUdf to IxHal!"
            set retVal 1
        }
    } 
    
    # #data content    
    if {$data == 0} {
        stream config -patternType patternTypeRandom
    } else {stream config -patternType  nonRepeat
        stream config -pattern $data
        stream config -dataPattern 18
    }
    #port config -speed $portspeed
    if [stream set $_chassis $_card $_port $_streamid] {
        error "Stream set $_chassis $_card $_port $_streamid error"
        set retVal $::CIxia::gIxia_ERR 
    }
   
    if  [stream write $_chassis $_card $_port $_streamid] {
        error "Stream write $_chassis $_card $_port $_streamid error"
        set retVal $::CIxia::gIxia_ERR 
    }
   
    return $retVal
}

###########################################################################################
#@@Proc
#Name: CreateIPv6UDPStream
#Desc: set IPv6 UDP stream
#Args: 
#	   -name:    IP Stream name
#      -frameLen: frame length
#      -utilization: send utilization(percent), default 100
#      -txMode: send mode,[0|1] default 0 - continuous 1 - burst
#      -burstCount: burst package count
#      -desMac: destination MAC default ffff-ffff-ffff
#      -srcMac: source MAC default 0-0-0
#      -_portSpeed: _port speed default 100                   
#	   -data: content of frame, 0 by default means random
#             example: -data 0   ,  the data pattern will be random    
#                      -data abac,  use the "abac" as the data pattern
#     -VlanID: default 0
#     -Priority: the priority of vlan, 0 by default
#     -DesIP: the destination ipv6 address,the input format should be X:X::X:X
#     -SrcIP: the source ipv6 address, the input format should be X:X::X:X
#	  -nextHeader: the next header, 59 by default
#     -hopLimit: 255 by default
#     -traffClass: 0 by default
#     -flowLabel: 0 by default
#     -srcport: UDP source port , 2000 by default
#     -desport: UDP destination port, 2000 by default
#
#Usage: port1 CreateIPv6UDPStream -SMac 0010-01e9-0011 -DMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaPortETH::CreateIPv6UDPStream { args } {
    Log  "Create IPv6 udp stream..."
    set retVal $::CIxia::gIxia_OK

    set framelen   128
    set framerate  0
    set utiliztion 100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set txmode     0
    set burstcount 1
    set desmac       ffff-ffff-ffff
    set srcmac       0000-0000-0000
    set desip        ::
    set srcip        ::
    set portspeed   100
    set data        0
    set signature   0 

    set name       ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set ver        6
    set id         1    
    set protocol   41       
    set enable     true
    set value      {{00 }}
    set strframenum    100
    
    set hoplimit    255
    set traffclass  0 
    set flowlabel   0 
    set udf1       0
    set udf1offset 0
    set udf1len    1
    set udf1initval {00}
    set udf1step    1
    set udf1changemode 0
    set udf1repeat  1
    
    set udf2       0
    set udf2offset 0
    set udf2len    1
    set udf2initval {00}
    set udf2step    1
    set udf2changemode 0
    set udf2repeat  1
    
    set udf3       0
    set udf3offset 0
    set udf3len    1
    set udf3initval {00}
    set udf3step    1
    set udf3changemode 0
    set udf3repeat  1
    
    set udf4       0
    set udf4offset 0
    set udf4len    1
    set udf4initval {00}
    set udf4step    1
    set udf4changemode 0
    set udf4repeat  1        
    
    set udf5       0
    set udf5offset 0
    set udf5len    1
    set udf5initval {00}
    set udf5step    1
    set udf5changemode 0
    set udf5repeat  1
    
    set tableudf 0 
    set change   0
    
    set desport 2000
    set srcport  2000 
  
    #get_params $args
    
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
            append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val        
    }
    
    # Added table interafce to enable arp response
    SetPortIPv6Address -macaddress $srcmac -ipaddress $srcip -prefixLen "64" -replyallarp 1
    
    set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
	
        set vlan $vlanid
        set pri  $priority

    #Setting the _streamid.
    set streamCnt 1 
    for {set i 1 } {1} {incr i} {
        if {[stream get $_chassis $_card $_port $i] == 0 } {incr streamCnt} else { break}
    }
    set _streamid $streamCnt
     
    #Define Stream parameters.
    stream setDefault        
    stream config -enable $enable
    stream config -name $name
    stream config -numBursts $burstcount        
    stream config -numFrames $strframenum
    if { $framerate != 0 } {
        stream config -rateMode streamRateModeFps
    stream config -fpsRate $framerate
    } else {
        stream config -percentPacketRate $utiliztion
        stream config -rateMode usePercentRate
    }
    stream config -sa $srcmac
    stream config -da $desmac
    
    switch $txmode {
        0 {stream config -dma contPacket}
        1 { stream config -dma stopStream
            stream config -numBursts 1
            stream config -numFrames $burstcount
            stream config -startTxDelayUnit                   0
            stream config -startTxDelay                       0.0
        }
        2 {stream config -dma advance}
        default {error "No such stream transmit mode, please check -strtransmode parameter."
            set retVal $::CIxia::gIxia_ERR
        }
    }
    
    if {[llength $framelen] == 1} {
        stream config -framesize [expr $framelen + 4]
        stream config -frameSizeType sizeFixed
    } else {
        stream config -framesize 318
        stream config -frameSizeType sizeRandom
        stream config -frameSizeMIN [lindex $framelen 0]
        stream config -frameSizeMAX [lindex $framelen 1]
    }
    
    #stream config -frameType $type
    #Define protocol parameters 
    protocol setDefault        
    protocol config -name ipV6
    protocol config -ethernetType ethernetII
    ipV6 setDefault 
    ipV6 config -sourceAddr $srcip
    ipV6 config -destAddr $desip
    ipV6 config -flowLabel $flowlabel
    ipV6 config -hopLimit  $hoplimit        
    ipV6 config -trafficClass $traffclass
    ipV6 config -nextHeader udp
    
    if [ipV6 set $_chassis $_card $_port] {
        IxPuts -red "Unable to set ipV6 configs to IxHal!"
        set retVal $::CIxia::gIxia_ERR
    }          
    
    udp setDefault
    udp config -sourcePort $srcport
    udp config -destPort $desport
    
    if {[udp set $_chassis $_card $_port]} {
       error "Error udp set $_chassis $_card $_port"
       set retVal $::CIxia::gIxia_ERR 
   }
   
   if {$vlan != 0} {
       protocol config -enable802dot1qTag vlanSingle
       vlan setDefault        
       vlan config -vlanID $vlan
       vlan config -userPriority $pri
       if [vlan set $_chassis $_card $_port] {
           error "Unable to set vlan configs to IxHal!"
           set retVal $::CIxia::gIxia_ERR
       }
   
       switch $cfi {
           0 {vlan config -cfi resetCFI}
           1 {vlan config -cfi setCFI}
       }
   }
     
    #UDF Config
    if {$udf1 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf1offset
        switch $udf1len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf1changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf1initval
        udf config -repeat  $udf1repeat              
        udf config -step    $udf1step
        udf set 1
    }
    if {$udf2 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf2offset
        switch $udf2len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf2changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf2initval
        udf config -repeat  $udf2repeat              
        udf config -step    $udf2step
        udf set 2
    }
    if {$udf3 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf3offset
        switch $udf3len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf3changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf3initval
        udf config -repeat  $udf3repeat              
        udf config -step    $udf3step
        udf set 3
    }
    if {$udf4 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf4offset
        switch $udf4len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf4changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf4initval
        udf config -repeat  $udf4repeat              
        udf config -step    $udf4step
        udf set 4
    }
    if {$udf5 == 1} {
        udf setDefault        
        udf config -enable true
        udf config -offset $udf5offset
        switch $udf5len {
            1 { udf config -countertype c8  }                
            2 { udf config -countertype c16 }               
            3 { udf config -countertype c24 }                
            4 { udf config -countertype c32 }
        }
        switch $udf5changemode {
            0 {udf config -updown uuuu}
            1 {udf config -updown dddd}
        }
        udf config -initval $udf5initval
        udf config -repeat  $udf5repeat              
        udf config -step    $udf5step
        udf set 5
    }        
     
    #Table UDF Config        
    if { $tableudf == 1 } {
        tableUdf setDefault        
        tableUdf clearColumns      
        tableUdf config -enable 1
        tableUdfColumn setDefault        
        tableUdfColumn config -formatType formatTypeHex
        if {$change == 0} {
            tableUdfColumn config -offset [expr $framelen -5]} else {
            tableUdfColumn config -offset $change
        }
        tableUdfColumn config -size 1
        tableUdf addColumn         
        set rowValueList $value
        tableUdf addRow $rowValueList
        if [tableUdf set $_chassis $_card $_port] {
            error "Unable to set tableUdf to IxHal!"
            set retVal $::CIxia::gIxia_ERR
        }
    } 
      
    # #data content    
    if {$data == 0} {
        stream config -patternType patternTypeRandom
    } else {
        stream config -patternType  nonRepeat
        stream config -pattern $data
        stream config -dataPattern 18
    }
     
    #port config -speed $portspeed
    if [stream set $_chassis $_card $_port $_streamid] {
        error "Stream set $_chassis $_card $_port $_streamid error"
        set retVal $::CIxia::gIxia_ERR
    }
    
    if  [stream write $_chassis $_card $_port $_streamid] {
        error "Stream write $_chassis $_card $_port $_streamid error"
        set retVal $::CIxia::gIxia_ERR
    }
     
    return $retVal
}


###########################################################################################
#@@Proc
#Name: SetErrorPacket
#Desc: set Error packet
#Args: 
#     -crc     : enable CRC error
#     -align   : enable align error
#     -dribble : enable dribble error
#     -jumbo   : enable jumbo error
#Usage: port1 SetErrorPacket -crc 1
###########################################################################################
::itcl::body CIxiaPortETH::SetErrorPacket {args} {
		Log   "set errors packet..."
		set retVal $::CIxia::gIxia_OK
      
        set tmpList     [lrange $args 0 end]
        set idxxx      0
        set tmpllength [llength $tmpList]

        #  Set the defaults
        set Default    0
        set Crc        1
        set Nocrc      0
        set Dribble    0
        set Align      0
		set Jumbo      0
        

        while { $tmpllength > 0  } {
            set cmdx [string tolower [lindex $args $idxxx]]
           
            case $cmdx   {
               -crcerror      { set Crc 1 }
               -dribblebits  {set Dribble 1}
               -alignerror    {set Align 1}
			   -jumbo    {set Jumbo 1}
               
               default   {
                   set retVal $::CIxia::gIxia_ERR
                   IxPuts -red "Error : cmd option $cmdx does not exist"
                   return $retVal
               }
            }
            # incr idxxx  +2
            # incr tmpllength -2
            incr idxxx  +1
            incr tmpllength -1
        }

        if {[stream get $_chassis $_card $_port $_streamid]} {
            set retVal $::CIxia::gIxia_ERR
            IxPuts -red "Unable to retrive config of No.$_streamid stream from $_chassis $_card $_port!"
        }
        
            if {$Crc == 1} {
				set Default 1
                stream config -fcs 3
            }
            if {$Dribble == 1} {
				set Default 1
                stream config -fcs 2
            }
            if {$Align == 1} {
                stream config -fcs 1
            } 
			if {$Jumbo == 1} {
				set Default 1
				stream config -framesize 9000				
			}
        
        if {$Default == 0} {
		
            stream config -fcs 0
        }
        
        if [stream set $_chassis $_card $_port $_streamid] {
            IxPuts -red "Unable to set streams to IxHal!"
            set retVal  $::CIxia::gIxia_ERR
        }
        

        if [stream write $_chassis $_card $_port $_streamid] {
            IxPuts -red "Unable to write streams to IxHal!"
            set retVal  $::CIxia::gIxia_ERR
        }
        
        return $retVal
    }  

###########################################################################################
#@@Proc
#Name: SetFlowCtrlMode
#Desc: set the flow control mode on a port
#Args: 
#     1   enable
#     0   disable
#Usage: port1 SetFlowCtrlMode 1
###########################################################################################
::itcl::body CIxiaPortETH::SetFlowCtrlMode {args} {
        Log   "set flow control mode..."
		set retVal $::CIxia::gIxia_OK
		
        # enable flow control
		if { [llength $args] > 0} {
			set FlowCtrlMode $args
		} else { 
			set FlowCtrlMode 1
		  }
		 set tmp [llength $args]
		
        port config -flowControl $FlowCtrlMode

        # type of flow control
        if   {$FlowCtrlMode == 1}  {
            port config -autonegotiate  true
            port config -advertiseAbilities 0
        } 
        
        if { [port set $_chassis $_card $_port] } {
            IxPuts -red "failed to set port configuration on port $_chassis $_card $_port"
            set retVal $::CIxia::gIxia_ERR
        }

        lappend portList [list $_chassis $_card $_port]
        if [ixWritePortsToHardware portList -noProtocolServer] {
            IxPuts -red "Can't write config to $_chassis $_card $_port"
            set retVal $::CIxia::gIxia_ERR   
        }    
		
        return $retVal
    }
	

###########################################################################################
#@@Proc
#Name: DeleteAllStream
#Desc: To delete all streams of the target port
#Args: no
#Usage: port1 DeleteAllStream
###########################################################################################
::itcl::body CIxiaPortETH::DeleteAllStream {} {
    Log "Delete all streams of $_chassis $_card $_port..."
	set retVal $::CIxia::gIxia_OK
    
    if { [catch {
        foreach streamObj [ GetPortStreams ] {
            $streamObj unconfig
            ::itcl::delete object $streamObj
        }
    } err]} {
        Log "Failed to delete all streams on $_chassis $_card $_port: $err"
        set retVal $::CIxia::gIxia_ERR
    }

    return $retVal 
}

###########################################################################################
#@@Proc
#Name: SetMultiModifier
#Desc: change multi-field value in the existing stream
#Args: 
#     -srcmac {mode step count}
# 	  -desmac {mode step count}
#	  -srcip  {mode step count}
#	  -desip  {mode step count}
#	  -srcport  {mode step count}
#	  -desport {mode step count}
#     mode: 
#     random incr decr list
#    
#Usage: port1 SetMultiModifier -srcmac {incr 1 16}
###########################################################################################
::itcl::body CIxiaPortETH::SetMultiModifier {args} {
		
        Log   "set multi-field value..."
		set retVal $::CIxia::gIxia_OK
		
		set srcMac ""
		set desMac ""
		set srcIp "" 
		set desIp ""
		set srcPort ""
		set desPort ""
		
		set counterIndex 0
        
        set tableUdf 0
		
		set tmpList     [lrange $args 0 end]
        set idxxx      0
        set tmpllength [llength $tmpList]

        #  Set the defaults
        set Default    1

    while { $tmpllength > 0  } {
        set cmdx [string toupper [lindex $args $idxxx]]
        set argx [string toupper [lindex $args [expr $idxxx + 1]]]
    
        case $cmdx   {
            -SRCMAC      { set srcMac $argx}
            -DESMAC      {set desMac $argx }
            -SRCIP       {set srcIp $argx  }
            -DESIP       {set desIp $argx  }
            -SRCPORT     {set srcPort $argx}
            -DESPORT     {set desPort $argx}
            default   {
                set retVal $::CIxia::gIxia_ERR
                error  "Error : cmd option $cmdx does not exist"
                return $retVal
            }
        }
        incr idxxx  +2
        incr tmpllength -2
    }
    
    if {[stream get $_chassis $_card $_port $_streamid]} {
        set retVal $::CIxia::gIxia_ERR
        error  "Unable to retrive config of No.$_streamid stream from $_chassis $_card $_port!"
    }
    
    if {$srcMac != ""} {
        set tmp [lindex $srcMac 0]
        case $tmp {
            RANDOM { stream config -saRepeatCounter ctrRandom}
            INCR {
                stream config -saRepeatCounter increment
                stream config -saStep [lindex $srcMac 1]
                stream config -numSA [lindex $srcMac 2]
            }
            DECR {
                stream config -saRepeatCounter decrement
                stream config -saStep [lindex $srcMac 1]
                stream config -numSA [lindex $srcMac 2]
            }
            LIST {     
                set tableUdf 1 
                for {set i 1} { [lindex $srcMac $i] != ""} {incr i} {
                    set tmpSrcMac1 [lindex $srcMac $i] 
                    regsub -all --  {-} $tmpSrcMac1 {} tmpSrcMac1
                    regsub -all { } $tmpSrcMac1 {} tmpSrcMac1
                    lappend tmpSrcMac $tmpSrcMac1
                }
                # set tmpMac [lrange $tmpMac 1 end]
                lappend tmpSrcMac  6 6 formatTypeMAC
                set tableList(srcMac) $tmpSrcMac
            }
        }
    }
    
    
    if {$desMac != ""} {
        set tmp [lindex $desMac 0]
        case $tmp {
            RANDOM { stream config -daRepeatCounter ctrRandom}
            INCR {
                stream config -daRepeatCounter increment
                stream config -daStep [lindex $desMac 1]
                stream config -numDA [lindex $desMac 2]
            }
            DECR {
                stream config -daRepeatCounter decrement
                stream config -daStep [lindex $desMac 1]
                stream config -numDA [lindex $desMac 2]
            }
            LIST {     
                set tableUdf 1 
                for {set i 1} { [lindex $desMac $i] != ""} {incr i} {
                    set tmpDesMac1 [lindex $desMac $i]
                    regsub -all --  {-} $tmpDesMac1 {} tmpDesMac1
                    regsub -all { } $tmpDesMac1 {} tmpDesMac1
                    lappend tmpDesMac $tmpDesMac1
                }
                # set tmpMac [lrange $tmpMac 1 end]
                lappend tmpDesMac 0 6 formatTypeMAC
                set tableList(desMac) $tmpDesMac
            }
        }
    }
    
    if {$srcIp != ""} {
        set udf1 1
        if { [stream cget -frameType] == "08 00"} {    
            set udf1Offset 26                    
            set udf1InitVal [lrange [stream cget -packetView] 26 29]
        } else {
            set udf1Offset 34                    
            set udf1InitVal [lrange [stream cget -packetView] 34 37]
        }
        set udf1Step [lindex $srcIp 1]
        set udf1Repeat [lindex $srcIp 2]
        set udf1CounterMode udfCounterMode
        set udf1Size 32
            
        set tmpIp [lindex $srcIp 0]
        case $tmpIp {
            RANDOM { set udf1CounterMode udfRandomMode}
            INCR { set udf1UpDown "uuuu"   }
            DECR { set udf1UpDown "duuu"   }
            LIST { set udf1 0
                   set tableUdf 1
                   set tmpIp [lrange $srcIp 1 end]
                   if { $udf1Offset == 34 } {
                        lappend tmpIp 22 16 formatTypeIPv6
                    } else {
                        lappend tmpIp 26 4 formatTypeIPv4
                        }
                   set tableList(srcIp) $tmpIp
            }
        }            
    }
                 
    if {$desIp != ""} {
        set udf2 1
        if { [stream cget -frameType] == "08 00"} { 
            set udf2Offset 30                    
            set udf2InitVal [lrange [stream cget -packetView] 30 33]
        } else {
            set udf2Offset 50                    
            set udf2InitVal [lrange [stream cget -packetView] 50 53]
        }
        set udf2Step [lindex $desIp 1]
        set udf2Repeat [lindex $desIp 2]
        set udf2CounterMode udfCounterMode
        set udf2Size 32
                
        set tmpIp [lindex $desIp 0]
        case $tmpIp {   
            RANDOM { set udf2CounterMode udfRandomMode}
            INCR { set udf2UpDown "uuuu"   }
            DECR { set udf2UpDown "duuu"   }
            LIST {
                set udf2 0
                set tableUdf 1
                set tmpIp [lrange $desIp 1 end]
                if { $udf2Offset == 50 } {
                    lappend tmpIp 38 16    formatTypeIPv6
                } else {
                    lappend tmpIp 30 4 formatTypeIPv4
                }
                set tableList(desIp) $tmpIp
            }      
        }       
    }    

    if {$srcPort != ""} {
        set udf3 1         
        set udf3Offset 54                    
        set udf3InitVal [lrange [stream cget -packetView] 54 55]
        set udf3Step [lindex $srcPort 1]
        set udf3Repeat [lindex $srcPort 2]
        set udf3CounterMode udfCounterMode
        set udf3Size 16
                
        set tmpPort [lindex $srcPort 0]
        case $tmpPort { 
            RANDOM { set udf3CounterMode udfRandomMode}
            INCR { set udf3UpDown "uuuu"   }
            DECR { set udf3UpDown "duuu"   }
            LIST {
                set udf3 0
                set tableUdf 1
                set tmpPort [lrange $srcPort 1 end]
                lappend tmpPort 54 2 formatTypeDecimal    
                set tableList(srcPort) $tmpPort
            }        
        }  
    }    

    if {$desPort != ""} {
        set udf4 1
        set udf4Offset 56                    
        set udf4InitVal [lrange [stream cget -packetView] 56 57]
        set udf4Step [lindex $desPort 1]
        set udf4Repeat [lindex $desPort 2]
        set udf4CounterMode udfCounterMode
        set udf4Size 16
                
        set tmpPort [lindex $desPort 0]
        case $tmpPort {
            RANDOM { set udf4CounterMode udfRandomMode}
            INCR { set udf4UpDown "uuuu"   }
            DECR { set udf4UpDown "duuu"   }
            LIST {
                set udf4 0
                set tableUdf 1
                set tmpPort [lrange $desPort 1 end]
                lappend tmpPort  56 2 formatTypeDecimal        
                set tableList(desPort) $tmpPort
            }
                    
        } 
    }    
         
    if { $udf1 == 1 } {
        udf setDefault 
        udf config -enable                             true
        udf config -offset                             $udf1Offset
        udf config -counterMode                        $udf1CounterMode
        udf config -udfSize                            $udf1Size
        udf config -chainFrom                          udfNone
        
        
        if {$udf1CounterMode == "udfRandomMode"} {
            udf config -maskselect                         {00 00 00 00 }
            udf config -maskval                            {00 00 00 00 }
        } else {
            udf config -bitOffset                          0
            udf config -updown                             $udf1UpDown
            udf config -initval                            $udf1InitVal
            udf config -repeat                             $udf1Repeat
            udf config -cascadeType                        udfCascadeNone
            udf config -enableCascade                      false
            udf config -step                               $udf1Step    
        }
        
        if {[udf set 1]} {
            error "Error calling udf set 1"
            set retVal $::CIxia::gIxia_ERR
        }
    }
    if { $udf2 == 1 } {
        udf setDefault 
        udf config -enable                             true
        udf config -offset                             $udf2Offset
        udf config -counterMode                        $udf2CounterMode
        udf config -udfSize                            $udf2Size
        udf config -chainFrom                          udfNone
        
        if {$udf2CounterMode == "udfRandomMode"} {
            udf config -maskselect                         {00 00 00 00 }
            udf config -maskval                            {00 00 00 00 }
        } else {
            udf config -bitOffset                          0
            udf config -updown                             $udf2UpDown
            udf config -initval                            $udf2InitVal
            udf config -repeat                             $udf2Repeat
            udf config -cascadeType                        udfCascadeNone
            udf config -enableCascade                      false
            udf config -step                               $udf2Step         
        }
        
        if {[udf set 2]} {
            error "Error calling udf set 1"
            set retVal $::CIxia::gIxia_ERR
        }
    }
    if { $udf3 == 1 } {
        udf setDefault 
        udf config -enable                             true
        udf config -offset                             $udf3Offset
        udf config -counterMode                        $udf3CounterMode
        udf config -udfSize                            $udf3Size
        udf config -chainFrom                          udfNone

        if {$udf3CounterMode == "udfRandomMode"} {
            udf config -maskselect                         {00 00 00 00 }
            udf config -maskval                            {00 00 00 00 }
        } else {
            udf config -bitOffset                          0
            udf config -updown                             $udf3UpDown
            udf config -initval                            $udf3InitVal
            udf config -repeat                             $udf3Repeat
            udf config -cascadeType                        udfCascadeNone
            udf config -enableCascade                      false
            udf config -step                               $udf3Ste
        }
        
        if {[udf set 3]} {
            error "Error calling udf set 1"
            set retVal $::CIxia::gIxia_ERR
        }
    }
    
    if { $udf4 == 1 } {
        udf setDefault 
        udf config -enable                             true
        udf config -offset                             $udf4Offset
        udf config -counterMode                        $udf4CounterMode
        udf config -udfSize                            $udf4Size
        udf config -chainFrom                          udfNone
        
        if {$udf4CounterMode == "udfRandomMode"} {
            udf config -maskselect                         {00 00 00 00 }
            udf config -maskval                            {00 00 00 00 }
        } else {
            udf config -bitOffset                          0
            udf config -updown                             $udf4UpDown
            udf config -initval                            $udf4InitVal
            udf config -repeat                             $udf4Repeat
            udf config -cascadeType                        udfCascadeNone
            udf config -enableCascade                      false
            udf config -step                               $udf4Step
        }
        
        if {[udf set 4]} {
            error "Error calling udf set 1"
            set retVal $::CIxia::gIxia_ERR
        }
    }
    
    if { $tableUdf == 1} {
        tableUdf setDefault
        tableUdf clearColumns
        tableUdf config -enable true

        foreach fieldName [array names tableList] {
            for {set i 0} { $i < [expr [llength $tableList($fieldName)] - 3]} {incr i} {
                lappend rowList($i) [lindex $tableList($fieldName) $i]
                if { $i > $counterIndex } {
                    set counterIndex $i
                } 
            }
        
            set checkA [expr $i - 1]
            set checkB [expr $i - 2]
            if {$checkA != 0} {
                if {[llength $rowList($checkA)] != [llength $rowList($checkB)]} {
                    error "Error:The counts of values in columns are not equal."
                    set retVal $::CIxia::gIxia_ERR
                    break
                }
            }

            tableUdfColumn setDefault
            tableUdfColumn config -name $fieldName
            tableUdfColumn config -offset [lindex $tableList($fieldName) end-2]
            tableUdfColumn config -size [lindex $tableList($fieldName) end-1]
            tableUdfColumn config -formatType [lindex $tableList($fieldName) end]
            tableUdfColumn config -customFormat                       ""
            
            if {[tableUdf addColumn]} {
                error  "Error adding a column with formatType: \
                [lindex $tableList($fieldName) end]"
                set retVal $::CIxia::gIxia_ERR
                break
            }
        }    
        
        for {set i 0} { $i <= $counterIndex} {incr i} {
            if {[tableUdf addRow $rowList($i)] } {
                error "Error: the input $rowList($i) is not correct,error adding row  $rowList($i)"
                set retVal $::CIxia::gIxia_ERR
                break
            }
    
        }
        if {[tableUdf set $_chassis $_card $_port]} {
            error "Error calling tableUdf set $_chassis $_card $_port"
            set retVal $::CIxia::gIxia_ERR
        }
    }
    
    if [stream set $_chassis $_card $_port $_streamid] {
        error  "Unable to set streams to IxHal!"
        set retVal $::CIxia::gIxia_ERR
    }

        if [stream write $_chassis $_card $_port $_streamid] {
            error  "Unable to write streams to IxHal!"
            set retVal $::CIxia::gIxia_ERR
        }      
     
		return $retVal

}

###########################################################################################
#@@Proc
#Name: SetPortAddress
#Desc: Set IP address on the target port
#Args: 
#     MacAddress: the mac address of the port
#     IpAddress: the ip address of the port
#     NetMask: the netmask of the ip address
#     GateWay: the gateway of the port
#     ReplyAllArp: send a response to the arp request
#
#Usage: port1 SetPortAddress -macaddress 112233445566 -ipaddress 192.168.1.1 -netmask 255.255.255.0 -replyallarp 1
###########################################################################################ss
::itcl::body CIxiaPortETH::SetPortAddress {args} {

	Log "Set the IP address on $_chassis $_card $_port..."
	set retVal $::CIxia::gIxia_OK

	set macaddress 0000-0000-1111
	set ipaddress 0.0.0.0 
	set netmask 255.255.255.0
	set gateway 0.0.0.0 
	set replyallarp 0 
	set vlan 0
	set flag 0 

    set prefixLen 24

    #Start to fetch param

	set argList ""
	set temp ""
	for {set i 0} { $i < [llength $args]} {incr i} {
	lappend temp [ string tolower [lindex $args $i]]
	}
	set tmp [split $temp \-]
	set tmp_len [llength $tmp]
	for {set i 0 } {$i < $tmp_len} {incr i} {
  	    set tmp_list [lindex $tmp $i]
  	    if {[llength $tmp_list] == 2} {
      	    	append argList " [lindex $tmp_list 0].arg"
  	    }
 	}
	while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
		set $opt $val		
	}
	
    #End of fetching param
    
    #Start to format the macaddress and IP netmask
    set macaddress HexToMac $macaddress
	
    for {set i 24} {$i > 0} {incr i -1} {
        if {$netmask == [ixNumber2Ipmask $i]} {
            set prefixLen $i
            break
        }
    }
	
    if {$gateway == "0.0.0.0"} {
        set numList [split $ipaddress "\."]
        set gateway [lindex $numList 0].[lindex $numList 1].[lindex $numList 2].1
    }

    if {$vlan} { 
        $_portObj config -enable_arp $replyallarp -intf_ip $ipaddress -dut_ip $gateway -mask $prefixLen -inner_vlan_id $vlan
    } else {
        $_portObj config -enable_arp $replyallarp -intf_ip $ipaddress -dut_ip $gateway -mask $prefixLen 
    }
    
	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetPortIPv6Address
#Desc: set IPv6 address on the target port
#Args: 
#     MacAddress: the mac address of the port
#     IpAddress: the ipv6 address of the port
#     PrefixLen: the prefix of the ipv6 address
#     GateWay: the gateway of the port
#     ReplyAllArp: send a response to the arp request
#
#Usage: port1 SetPortIPv6Address -macaddress 112233445566 -ipv6address 2001::1 -prefixLen 64 -replyallarp 1
###########################################################################################
::itcl::body CIxiaPortETH::SetPortIPv6Address {args} {

	Log "Set the IPv6 address on $_chassis $_card $_port..."
	set retVal $::CIxia::gIxia_OK
	
	set macaddress 0000-0000-0000
	set ipv6address 0:0:0:0:0:0:0:1 
	set prefixlen 64
	set gateway 0:0:0:0:0:0:0:0 
	set replyallarp 0 
	set vlan 0 
	set flag 0 

    #Start to fetch param
	set argList ""
	set temp ""
	for {set i 0} { $i < [llength $args]} {incr i} {
	lappend temp [ string tolower [lindex $args $i]]
	}
	set tmp [split $temp \-]
	set tmp_len [llength $tmp]
	for {set i 0 } {$i < $tmp_len} {incr i} {
  	    set tmp_list [lindex $tmp $i]
  	    if {[llength $tmp_list] == 2} {
      	    	append argList " [lindex $tmp_list 0].arg"
  	    }
 	}
	while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
		set $opt $val		
	}
    #End of fetching param

    set macaddress [::ipaddress::format_mac_address $macaddress 6 ":"]

	# port setFactoryDefaults $_chassis $_card $_port
	# protocol setDefault
	# protocol config -ethernetType ethernetII

    #Start to configure IP / Mac / gateway / autoArp /replyallarp to the target port	
	interfaceTable select $_chassis $_card $_port
	interfaceTable clearAllInterfaces
	interfaceTable config -enableAutoNeighborDiscovery true
	
	if {[interfaceTable set]} {
		error "Error calling interfaceTable set"
		set retVal $::CIxia::gIxia_ERR
	}	
	
	interfaceIpV6 setDefault
	interfaceIpV6 config -ipAddress $ipv6address
	interfaceIpV6 config -maskWidth $prefixlen

	
	if [interfaceEntry addItem addressTypeIpV6] {
		error "Error interfaceEntry addItem addressTypeIpV6 on $_chassis $_card $_port"
		set retVal $::CIxia::gIxia_ERR
	}
	
	interfaceEntry setDefault
	interfaceEntry config -enable true
	interfaceEntry config -description "_port $ipv6address/:01 Interface-1"
	interfaceEntry config -macAddress $macaddress
	interfaceEntry config -ipV6Gateway $gateway
	if {$vlan} { set flag true}
	interfaceEntry config -enableVlan                         $flag
	interfaceEntry config -vlanId                             $vlan
	interfaceEntry config -vlanPriority                       0
	interfaceEntry config -vlanTPID                           0x8100

	
	if [interfaceTable addInterface] {
		error "Error interfaceTable addInterface on $_chassis $_card $_port"
		set retVal $::CIxia::gIxia_ERR
	}
	
	
	if [interfaceTable write] {
		error "Error interfaceTable write to $_chassis $_card $_port"
		set retVal $::CIxia::gIxia_ERR
	
	}
	
	protocolServer setDefault
	protocolServer config -enableArpResponse $replyallarp
    protocolServer config -enablePingResponse   true
	if { [protocolServer set $_chassis $_card $_port] } {
		error "Error setting protocolServer on $_chassis $_card $_port"
		set retVal $::CIxia::gIxia_ERR
	}
	if { [protocolServer write $_chassis $_card $_port] } {
		error "Error writting protocolServer on $_chassis $_card $_port"
		set retVal $::CIxia::gIxia_ERR
	}
    #End of configuring  IP / Mac / gateway / autoArp / replyallarp

	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetTxPacketSize
#Desc: set the Tx packet size of the target stream
#Args:  
#     frameSize:   0 means set the packet size to randomSize
#Usage: port1 SetTxPacketSize 1500
###########################################################################################
::itcl::body CIxiaPortETH::SetTxPacketSize { frameSize } {
    Log "Set the Tx packet size..."
    set retVal $::CIxia::gIxia_OK
    
    set minSize 64
    set maxSize 1518
    set stepSize 1
    set randomSize 0 
     
    if {$frameSize > 0} {
        set frameSize $frameSize 
    } else {
        set randomSize 1  
    }

    set streamObj [lindex [GetPortStreams] end]
    if { $randomSize == 1 } {
        $streamObj config -frame_len_type random -min_frame_len $minSize -max_frame_len $maxSize -frame_len_step $stepSize
    } else {
        $streamObj config -frame_len_type fixed -frame_len $frameSize
    }
    return $retVal
}

###########################################################################################
#@@Proc
#Name: DeleteStream
#Desc: to disable a specific stream of the target port
#Args: -minindex: The first stream ID, start from 1. This could be a stream's name.
#	   -maxindex: If the "minindex" is a digital, then this function will disable streams from "minindex" to "maxindex". 
#                 If the "minindex" is a stream's name, then this option make no sense.
#	   
#Usage: port1 DeleteStream -minindex 1 -maxindex 10
#       port1 DeleteStream -minindex "stream_name"
###########################################################################################
::itcl::body CIxiaPortETH::DeleteStream {args} {
	Log "Disable the specific stream of $_chassis $_card $_port..."
	set retVal $::CIxia::gIxia_OK
	
	set minindex ""
	set maxindex ""
	set test ""
	set flag ""

    #Get param	
	set argList ""
	set temp ""
	for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
	}
	set tmp [split $temp \-]
	set tmp_len [llength $tmp]
	for {set i 0 } {$i < $tmp_len} {incr i} {
  	    set tmp_list [lindex $tmp $i]
  	    if {[llength $tmp_list] == 2} {
      	    append argList " [lindex $tmp_list 0].arg"
  	    }
 	}
	while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
		set $opt $val
	}
	#end get param
	
    if { [ catch {
        if { [llength $minindex] != 0 } {
            # Stream ID
            if [string is digit $minindex] {
                foreach stream [lrange [GetPortStreams] [expr $minindex - 1] [expr $maxindex - 1]] {
                    $stream unsuspend
                    ::itcl::delete object $stream
                }
            } else {
                # Stream name 
                foreach stream [GetPortStreams] {
                    set name [$stream cget -name]
                    if {$name == $minindex} {
                        $stream unsuspend
                        ::itcl::delete object $stream
                    }
                }
            }
        }
    } err ] } {
        Log "Failed to disable the specific stream of $_chassis $_card $_port..."
        set retVal $::CIxia::gIxia_ERR
    }
	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetCustomVFD
#Desc: set VFD
#Args:
#                       -Vfd1           VFD1 change state, default OffState; value:
#                                       OffState 
#                                       StaticState 
#                                       IncreState 
#                                       DecreState 
#                                       RandomState 
#                       -Vfd1cycle 	VFD1 cycle default no loop,continuous
#                       -Vfd1step	VFD1 change step,default 1
#                       -Vfd1offset     VFD1 offser,default 12, in bytes
#                       -Vfd1start      VFD1 start as {01} {01 0f 0d 13},default {00}
#                       -Vfd1len        VFD1 len [1~4], default 4
#                       -Vfd2           VFD2 change state, default OffState; value:
#                                       OffState 
#                                       StaticState 
#                                       IncreState 
#                                       DecreState 
#                                       RandomState 
#                       -Vfd2cycle 	VFD2 cycle default no loop,continuous
#                       -Vfd2step	VFD2 step,default 1
#                       -Vfd2offset     VFD2 offset,default 12, in bytes
#                       -Vfd2start      VFD2 start,as {01} {01 0f 0d 13},default {00}
#                       -Vfd2len        VFD2 len [1~4], default 4
#Usage: port1 SetCustomVFD 
###########################################################################################
::itcl::body CIxiaPortETH::SetCustomVFD {Id Mode Range Offset Data DataCount {Step 1}} {
	Log "Set custom VFD..."
        set retVal $::CIxia::gIxia_OK

        #set vfd1       OffState
        #set vfd1cycle  1
        #set vfd1step   1
        #set vfd1offset 12
        #set vfd1start  {00}
        #set vfd1len    4
        #set vfd2       OffState
        #set vfd2cycle  1
        #set vfd2step   1
        #set vfd2offset 12
        #set vfd2start  {00}
        #set vfd2len    4
        #
        #get_params $args

        if [stream get $_chassis $_card $_port $_streamid] {
            error "Unable to retrive config of No.$_streamid stream from port $_chassis $_card $_port!"
            set retVal $::CIxia::gIxia_ERR
	    return $retVal
        }

	#UDF1 config
        if { $Id == 1 } {            
            switch $Mode {                
                1 { set vfd1 "RandomState" }
                2 { set vfd1 "IncreState" }
                3 { set vfd1 "DecreState" }
				4 { set vfd1 "List"}
                default { set vfd1 "OffState" }
            }

            set vfd1len $Range
            set vfd1offset [expr $Offset / 8]
            set vfd1start $Data
			
	#Added by zshan begin
	#Format the data, transform the input from {0x01 0x02} to {01 02} or to {{01} {02}}
	
			regsub -all --  {0x} $vfd1start {} vfd1start
			regsub -all --  {0X} $vfd1start {} vfd1start
			
			set lenData [llength $vfd1start]
			
			
			if { $Mode == 4 && [expr $lenData % $Range] == 0 } {

				set cnt [expr $lenData / $Range]
				
				for { set i 0} { $i < $cnt} { incr i $Range} {
					lappend tempVfd1 [lrange $vfd1start $i [expr $Range - 1] ]
				}
				
				set vfd1start ""
				lappend vfd1start $tempVfd1
			}
	#Added by zshan  end		
 
			set vfd1cycle $DataCount
            set vfd1step $Step

            if {$vfd1 != "OffState"} {
                udf setDefault
                udf config -enable true
                switch $vfd1 {
                       "RandomState" {
                        udf config -counterMode udfRandomMode
                        }
                        "StaticState" -
                        "IncreState"  -
                        "DecreState" {
                        udf config -counterMode udfCounterMode
                        }
#Added by zshan begin
						"List" {
						if {[expr $lenData % $Range ] != 0} { 
								error "The length of Data should be multiper of $Range."
								set retVal $::CIxia::gIxia_ERR
								return $retVal
								} else {
								udf config -counterMode udfValueListMode
							}
						}
#Added by zshan end
                }
                set vfd1len [llength $vfd1start]
                switch $vfd1len  {
                        1 { udf config -countertype c8  }
                        2 { udf config -countertype c16 }
                        3 { udf config -countertype c24 }
                        4 { udf config -countertype c32 }
	#Added by zshan begin: support more than 4 bytes
						default { 
						
							udf config -conftertype c32 
							set tempVfd [lrange $vfd1start [expr $Range - 4] end]
							set vfd1start $tempVfd
						
						}
                        # default {error "-vfd1start only support 1-4 bytes, for example: {11 11 11 11}"}
	#Added by zshan end
                }
                switch $vfd1 {
                        "IncreState" {udf config -updown uuuu}
                        "DecreState" {udf config -updown dddd}
                }

                udf config -offset  $vfd1offset
				
				if {$Mode == 4} {
					udf config -valueList $vfd1start
				} else {
					udf config -initval $vfd1start
					udf config -repeat  $vfd1cycle
					udf config -step    $vfd1step
				}
                udf set 1
            } elseif {$vfd1 == "OffState"} {
                udf setDefault
                udf config -enable false
                udf set 1
            }
        }

	#UDF2 config
        if { $Id == 2 } {
            switch $Mode {                
                1 { set vfd2 "RandomState" }
                2 { set vfd2 "IncreState" }
                3 { set vfd2 "DecreState" }
				4 { set vfd2 "List"       }
                default { set vfd2 "OffState" }
            }
            set vfd2len $Range
            set vfd2offset [expr $Offset / 8]
            set vfd2start $Data


	#Added by zshan begin
	#Format the data, transform the input from {0x01 0x02} to {01 02} or to {{01} {02}}
	
			regsub -all --  {0x} $vfd2start {} vfd2start
			regsub -all --  {0X} $vfd2start {} vfd2start
			
			set lenData [llength $vfd2start]
			
			
			if { $Mode == 4 && [expr $lenData % $Range] == 0 } {

				set cnt [expr $lenData / $Range]
				
				for { set i 0} { $i < $cnt} { incr i $Range} {
					lappend tempVfd2 [lrange $vfd2start $i [expr $Range - 1] ]
				}
				
				set vfd2start ""
				lappend vfd2start $tempVfd2
			}
			
	#Added by zshan  end		


            set vfd2cycle $DataCount
            set vfd2step $Step

            if {$vfd2 != "OffState"} {
                udf setDefault
                udf config -enable true
                switch $vfd2 {
                       "RandomState" {
                	        udf config -counterMode udfRandomMode
                        }
                        "StaticState" -
                        "IncreState"  -
                        "DecreState" {
                        	udf config -counterMode udfCounterMode
                        }
	#Added by zshan begin
						"List" {
						if {[expr $lenData % $Range ] != 0} { 
								error "The length of Data should be multiper of $Range."
								set retVal $::CIxia::gIxia_ERR
								return $retVal
								} else {
								udf config -counterMode udfValueListMode
							}
						}
	#Added by zshan end

                }
                set vfd2len [llength $vfd2start]
                switch $vfd2len  {
                        1 { udf config -countertype c8  }
                        2 { udf config -countertype c16 }
                        3 { udf config -countertype c24 }
                        4 { udf config -countertype c32 }
                        # default {error "-vfd2start only support 1-4 bytes, for example: {11 11 11 11}"}
	#Added by zshan begin: support more than 4 bytes
						default { 
						
							udf config -conftertype c32 
							set tempVfd [lrange $vfd2start [expr $Range - 4] end]
							set vfd2start $tempVfd
						
						}
	#Added by zshan end
                }
                switch $vfd2 {
                        "IncreState" {udf config -updown uuuu}
                        "DecreState" {udf config -updown dddd}
                }
                udf config -offset  $vfd2offset
  
				if {$Mode == 4} {
					udf config -valueList $vfd2start
				} else {
					udf config -initval $vfd2start
					udf config -repeat  $vfd2cycle
					udf config -step    $vfd2step
				}
                udf set 2
            } elseif {$vfd2 == "OffState"} {
                udf setDefault
                udf config -enable false
                udf set 2
            }
        }

	if {[string match [config_stream -StreamId $_streamid] $::CIxia::gIxia_ERR]} {
	    set retVal $::CIxia::gIxia_ERR
	}
	if {[string match [config_port -ConifgType config -NoProtServ ture] $::CIxia::gIxia_ERR]} {
	    set retVal $::CIxia::gIxia_ERR
	}

        return $retVal
}


####################################################################
# 方法名称： SetVFD1
# 方法功能： 设置指定网卡发包的源MAC地址(使用VFD1)
# 入口参数：
#	    Offset 偏移，in byte,注意不要偏移位设置到报文的CHECKSUM的字节上。
#       DataList   需要设定的数据list，如果超过6个字节则取前面6个字节
#	    Mode   源MAC地址的变化形式，可取 
#                                     HVFD_RANDOM,
#                                     HVFD_INCR,
#                                     HVFD_DECR,
#                                     HVFD_SHUFFLE
#	    Count  源地址变化的循环周期
#
# 出口参数： 无
# 其他说明： 使用了VFD1资源
# 例   子:
#            SetVFD1 8 {1 1} $::HVFD_SHUFFLE 100
#            SetVFD1 12 {0x00 0x10 0xec 0xff 0x00 0x12} $::HVFD_INCR 100
####################################################################
::itcl::body CIxiaPortETH::SetVFD1 {Offset DataList {Mode 1} {Count 0}} {
    set Offset [expr 8*$Offset]
    $this SetCustomVFD $::HVFD_1 $Mode [llength $DataList] $Offset $DataList $Count 1
}

####################################################################
# 方法名称： SetVFD2
# 方法功能： 设置指定网卡发包的源MAC地址(使用VFD2)
# 入口参数：
#	    Offset 偏移，in byte,注意不要偏移位设置到报文的CHECKSUM的字节上。
#           DataList   需要设定的数据list，如果超过6个字节则取前面6个字节
#	    Mode   源MAC地址的变化形式，可取 
#                                     HVFD_RANDOM,
#                                     HVFD_INCR,
#                                     HVFD_DECR,
#                                     HVFD_SHUFFLE
#	    Count  源地址变化的循环周期
#
# 出口参数： 无
# 其他说明： 使用了VFD2资源
# 例   子:
#            SetVFD2 8 {1 1} $::HVFD_INCR 100
#            SetVFD2 12 {0x00 0x10 0xec 0xff 0x00 0x12} $::HVFD_INCR 100
####################################################################
::itcl::body CIxiaPortETH::SetVFD2 {Offset DataList {Mode 5}  {Count 0} } {
    set Offset [expr 8*$Offset]
    $this SetCustomVFD $::HVFD_2 $Mode [llength $DataList] $Offset $DataList $Count 1
}

###########################################################################################
#@@Proc
#Name: CaptureClear
#Desc: Clear capture buffer, in face, Ixia doesn't need clear the buffer, because each
#      time begin start capture, the buffer will clear automatically.
###########################################################################################
::itcl::body CIxiaPortETH::CaptureClear {} {
	Log "Capture clear..."
    $_capture stop
    return $retVal
}

###########################################################################################
#@@Proc
#Name: StartCapture
#Desc: Start Port capture
#Args: mode: capture mode,1:capture trig,2:capture bad,0:capture all
#Usage: port1 StartCapture 
###########################################################################################
::itcl::body CIxiaPortETH::StartCapture {{CapMode 0}} {
    capture   setDefault
    switch $CapMode {
        0 {
            $_capture config -cap_mode all
        }
        2 {
            $_capture config -cap_mode trig
        }
        default {}
    }
    $_capture start
    return $retVal
}

###########################################################################################
#@@Proc
#Name: StopCapture
#Desc: Stop Port capture
#Args:
#Usage: port1 StopCapture 
###########################################################################################
::itcl::body CIxiaPortETH::StopCapture { } {
	Log "Stop capture..."
    set retVal $::CIxia::gIxia_OK
    $_capture stop
    return $retVal
}

###########################################################################################
#@@Proc
#Name: ReturnCaptureCount
#Desc: Get capture buffer packet number. 
#Args:
#Ret:a list include 1.   ::CIxia::gIxia_OK or ::CIxia::gIxia_ERR, ::CIxia::gIxia_OK means ok, ::CIxia::gIxia_ERR means error.
#                   2.   the number of packet.
#Usage: port1 ReturnCaptureCount
###########################################################################################
::itcl::body CIxiaPortETH::ReturnCaptureCount { } {
	Log "Get capture count..."
    return [ GetStatsFromReturn [$_capture get_count ] count ]
}

###########################################################################################
#@@Proc
#Name: ReturnCapturePkt
#Desc: Get detailed byte infomation of specific packet. 
#Args:
#	-index : the index of packet in buffer. default 0.
#       -offset: the bytes to be retrieved offset. default 0.
#       -len   : how many bytes to be retrieved.
#                                 default 0, means the whole packet, from the offset byte to end.
#Ret:a list include 1.   0 or 1, 0 means ok, 1 means error.
#                   2.   a list include the specific byte content of the packet.
#Usage: port1 ReturnCapturePkt
###########################################################################################
::itcl::body CIxiaPortETH::ReturnCapturePkt { {PktIndex 0} } {
	Log "Get capture packet..."
    set retVal $::CIxia::gIxia_OK
    set packet [$_capture get_content -packet_index [expr $PktIndex + 1]
    
    return [ GetStatsFromReturn $packet Content ]
}

###########################################################################################
#@@Proc
#Name: GetPortInfo
#Desc: retrieve specific counter.
#Args:
#    -RcvPkt: received packets count
#    -TmtPkt: sent packets count
#    -RcvTrig: capture trigger packets count
#    -RcvTrigRate: capture trigger packets rate
#    -RcvByte: capture received packets bytes
#    -RcvByteRate: capture received packets rate
#    -RcvPktRate: received packets rate
#    -TmtPktRate: sent packects count
#    -CRC: received CRC errors packets count
#    -CRCRate: received CRC errors packets rate
#    -Collision: collision packets count
#    -CollisionRate: collision packets rate
#    -Align: alignment errors packets count
#    -AlignRate: alignment errors packets rate
#    -Oversize: oversize packets count
#    -OversizeRate: oversize packets rate
#    -Undersize: undersize packets count
#    -UndersizeRate: undersize packets rate
#Ret: success: eg: ::CIxia::gIxia_OK {-RcvPkt 100} {-RcvPktRate 20}
#     fail:    ::CIxia::gIxia_ERR {}
#Usage: port1 GetPortInfo -Undersize -Oversize
###########################################################################################
::itcl::body CIxiaPortETH::GetPortInfo { args } {
    set retVal $::CIxia::gIxia_OK

    set RcvPkt ""
    set TmtPkt ""
    set RcvTrig ""
	set RcvTrigRate ""
	set RcvByte ""
	set RcvByteRate ""
	set RcvPktRate ""
	set TmtPktRate ""
	set CRC ""
	set CRCRate ""
	set Align ""
	set AlignRate ""
	set Oversize ""
	set OversizeRate ""
	set Undersize ""
	set UndersizeRate ""
	
	set argList {RcvPkt.arg TmtPkt.arg RcvTrig.arg RcvTrigRate.arg RcvByte.arg RcvByteRate.arg RcvPktRate.arg TmtPktRate.arg \
                     CRC.arg CRCRate.arg Align.arg AlignRate.arg Oversize.arg OversizeRate.arg Undersize.arg UndersizeRate.arg}
        
    set result [cmdline::getopt args $argList opt val]
    while {$result>0} {
        set $opt $val
        set result [cmdline::getopt args $argList opt val]        
    }
    
    if {$result<0} {
        Log "GetPortInfo has illegal parameter! $val"
        return $$::CIxia::gIxia_ERR
    }
    
    ixConnectToTclServer $_chassis
    ixConnectToChassis $_chassis
    set chas [chassis cget -id]
        
    if [stat get statAllStats $chas $_card $_port] {
        error "Get all Event counters Error"
        set retVal $::CIxia::gIxia_ERR
        return $retVal
    }
    
    if { $RcvPkt != "" } {
        upvar $RcvPkt m_RcvPktt
        
        set m_RcvPktt [stat cget -framesReceived]	
    }
    
    if { $TmtPkt != "" } {
        upvar $TmtPkt m_TmtPkt
        
        set m_TmtPkt [stat cget -framesSent]
    }
    
    if { $RcvTrig != "" } {
        upvar $RcvTrig m_RcvTrig
        
        set m_RcvTrig [stat cget -captureTrigger]
    }
    
    if { $RcvByte != "" } {
        upvar $RcvByte m_RcvByte
        
        set m_RcvByte [stat cget -bytesReceived]
    }
    
    if { $CRC != "" } {
        upvar $CRC m_CRC
        
        set m_CRC [stat cget -fcsErrors]
    }
    
    if { $Align != "" } {
        upvar $Align m_Align
        
        set m_Align [stat cget -alignmentErrors]
    }
    
    if { $Oversize != "" } {
        upvar $Oversize m_Oversize
        
        set m_Oversize [stat cget -oversize]
    }
                   
    if { $Undersize != "" } {
        upvar $Undersize m_Undersize
        
        set m_Undersize [stat cget -undersize]
    }
    
    if [stat getRate allStats $_chassis $_card $_port] {
            error "Get all Rate counters Error"
            set retVal $::CIxia::gIxia_ERR
        return $retVal
    }
    
    
    if { $RcvTrigRate != "" } {
        upvar $RcvTrigRate m_RcvTrigRate
        
        set m_RcvTrigRate [stat cget -captureTrigger]
    }
    
    if { $RcvByteRate != "" } {
        upvar $RcvByteRate m_RcvByteRate
        
        set m_RcvByteRate [stat cget -bytesReceived]
    }
    
    if { $RcvPktRate != "" } {
        upvar $RcvPktRate m_RcvPktRate
        
        set m_RcvPktRate [stat cget -framesReceived]
    }
    
    if { $TmtPktRate != "" } {
        upvar $TmtPktRate m_TmtPktRate
        
        set m_TmtPktRate [stat cget -framesSent]
    }
    
    if { $CRCRate != "" } {
        upvar $CRCRate m_CRCRate
        
        set m_CRCRate [stat cget -fcsErrors]
    }
    
    if { $AlignRate != "" } {
        upvar $AlignRate m_AlignRate
        
        set m_AlignRate [stat cget -alignmentErrors]
    }
    
    if { $OversizeRate != "" } {
        upvar $OversizeRate m_OversizeRate
        
        set m_OversizeRate [stat cget -oversize]
    }
    
    if { $UndersizeRate != "" } {
        upvar $UndersizeRate m_UndersizeRate
        
        set m_UndersizeRate [stat cget -undersize]
    }
    
    return $::CIxia::gIxia_OK
}
###########################################################################################
#@@Proc
#Name: GetPortStatus
#Desc: retrieve specific port's status
#Args: No
#    
#Ret: success:  {up} {down}
#     fail:    ::CIxia::gIxia_ERR {}
#
#Usage: port1 GetPortInfo 
###########################################################################################

::itcl::body CIxiaPortETH::GetPortStatus {  } {
	Log "Get port's status..."
	if {[ixNet getA $_handle -state] == "up"} {
        return up
    }

	return down
}

###########################################################################################
#@@Proc
#Name: GetTypeName
#Desc: retrieve specific port's speed
#Args: No
#    
#Ret: success:  the type of specific port,ie. GigabitEthernet
#     fail:    ::CIxia::gIxia_ERR {}
#
#Usage: port1 GetTypeName
###########################################################################################
::itcl::body CIxiaPortETH::GetTypeName {  } {
    Log "Get port's speed..."
    if {[catch {
        set type [ixNet getL $_handle [ixNet getA $_handle -type]]
        set portSpeed [ixNet getA $type -speed]
        } err]} {
        if {$type == "tenGigLan" || $type == "tenGigLanFcoe" || $type == "tenGigWan" || $type == "tenGigWanFcoe"} {
            set portSpeed "speed10g"
        } elseif {$type == "fortyGigLan" || $type == "fortyGigLanFcoe" } {
            set portSpeed "speed40g"
        } else {
            set portSpeed "speed1000"
        }
    }
	
    if {$portSpeed == "speed100fd" || $portSpeed == "speed100hd"} {
        set typeName "Ethernet"
    } elseif {$portSpeed == "speed10g"} {
        set typeName "Ten-GigabitEthernet"
    } elseif {$portSpeed == "speed40g"} {
        set typeName "FortyGigE"
    } elseif {$portSpeed == "speed100g"} {
        set typeName "HundredGigE"
    } else {
        set typeName "GigabitEthernet"
    }
    
	return $typeName
}

###########################################################################################
#@@Proc
#Name: GetPortCableType
#Desc: retrieve specific port's media type
#Args: No
#    
#Ret: success:  the media of specific port,ie. F C
#     fail:    ::CIxia::gIxia_ERR {}
#
#Usage: port1 GetPortCableType
###########################################################################################
::itcl::body CIxiaPortETH::GetPortCableType {  } {
    Log "Get port cable type..."
	set retVal $::CIxia::gIxia_OK
	set eth [lindex [ixNet getL $_handle ethernet] 0]

    if {[ixNet getA $eth -media] == "copper"} {
        return C
    } elseif {[ixNet getA $eth -media] == "fiber"} {
        return F
    }
    return UNKNOWN
}

###########################################################################################
#@@Proc
#Name: Clear
#Desc: Clear Counter
#Args:
#Usage: port1 Clear
###########################################################################################
::itcl::body CIxiaPortETH::Clear { args } {
	Log "Clear counter..."
    Tester::clear_traffic_stats
    return $retVal
}

