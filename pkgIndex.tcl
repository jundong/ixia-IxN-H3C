lappend auto_path [file join $dir lib]
package ifneeded Ixia 1.0     [list source [file join $dir CIxia.tcl]]
package ifneeded IxiaPort 1.0     [list source [file join $dir CIxiaPortETH.tcl]]

