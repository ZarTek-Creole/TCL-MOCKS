# Manage "My Own soCKs Server" with eggdrop bot
# https://sourceforge.net/projects/mocks/
#
# LATEST VERSION : https://github.com/MalaGaM/TCL-MOCKS
namespace eval ::MOCKS {
	variable ns [namespace current]
	variable np [namespace qualifiers [namespace parent]]

	variable PATHROOT	"/home/user/mocks"
	variable CONF_FILE	"mocks.conf"
	variable PID_FILE	"mocks.pid"
	variable CRON_FILE	"mocks.cron"
	variable LOG_FILE	"mocks.log"
	variable SHELL_USER	"mockusershell"

}
proc ::MOCKS::INIT { } {
	bind pub - !mocks ::MOCKS::MAIN
	putlog "msocks.tcl 1.0 by sitetechicien@gmail.com loaded."
}
proc ::MOCKS::MAIN { nick uhost hand chan arg } {
	set CMD	[lindex $arg 0];
	set MSG	[lrange $arg 1 end]
	switch -nocase $CMD {
		list {
			::MOCKS::LIST $nick $uhost $hand $chan $MSG 
		}
		add {
			::MOCKS::ADD $nick $uhost $hand $chan $MSG 
		}
		remove {
			::MOCKS::REMOVE $nick $uhost $hand $chan $MSG 
		}
		stop {
			::MOCKS::STOP $nick $uhost $hand $chan $MSG 
		}
		start {
			::MOCKS::START $nick $uhost $hand $chan $MSG 
		}
		restart {
			::MOCKS::RESTART $nick $uhost $hand $chan $MSG 
		}
		Logs {
			::MOCKS::LOGS $nick $uhost $hand $chan $MSG 
		}
		default {
			::MOCKS::HELP $nick $uhost $hand $chan $arg
		}
	}
}
proc ::MOCKS::REMOVE { nick uhost hand chan IP } {
	variable CONF_FILE
	variable PATHROOT
	set LINE_STATE	0
	set FILE_NEW	""
	set FILE_LINE	[FCT::FILE:READ "$PATHROOT/$CONF_FILE"]
	set RE_FIND 	"*FILTER_EXCEPTION*=*${IP}*"

	foreach LINE_DATA $FILE_LINE {
		if { 
				[string match -nocase [lindex $LINE_DATA 0] "FILTER_EXCEPTION"] && \
				[string match -nocase [lindex $LINE_DATA 2] $IP]
			} {
			incr LINE_STATE
		} else {
			append FILE_NEW \n $LINE_DATA
		}
		
	}
	if { $LINE_STATE != 0 } {
		if { [catch {exec -- sudo cp "$PATHROOT/$CONF_FILE" "${CONF_FILE}~bak"} ERR_MSG] } {
			FCT::MSG $chan $ERR_MSG
			return 0
		}
		set PFILE_NEW	[open "$PATHROOT/$CONF_FILE" w]
		puts $PFILE_NEW	$FILE_NEW
		close $PFILE_NEW
	}
	FCT::MSG $chan "Nombre d'IPs enlever: $LINE_STATE"

}
proc ::MOCKS::ADD { nick uhost hand chan IP } {
	variable CONF_FILE
	variable PATHROOT
	set FILE_DATA	[open "$PATHROOT/$CONF_FILE" a]
	puts $FILE_DATA	"FILTER_EXCEPTION = $IP"
	close $FILE_DATA;
	FCT::MSG $chan "$IP is added in WhiteList."
}
proc ::MOCKS::STOP { nick uhost hand chan arg } {
	variable PID_FILE
	variable PATHROOT
	set PID		[FCT::FILE:READ "$PATHROOT/$PID_FILE"]
	if { [catch {set ok [exec -- sudo kill -9 $PID]} ERR_MSG] } {
		FCT::MSG $chan $ERR_MSG
		return 0
	}
	FCT::MSG $chan "PID '$PID' Killed. $ok"
}
proc ::MOCKS::RESTART { nick uhost hand chan arg } {
	::MOCKS::STOP $nick $uhost $hand $chan $arg
	::MOCKS::START $nick $uhost $hand $chan $arg
}
proc ::MOCKS::LOGS { nick uhost hand chan arg } {
	variable PATHROOT
	variable LOG_FILE
	foreach LINE [split [exec -- tail -n 10 $PATHROOT/$LOG_FILE] "\n"] {
		FCT::MSG $chan $LINE
	}
}
proc ::MOCKS::START { nick uhost hand chan arg } {
	variable CRON_FILE
	variable PATHROOT
	variable SHELL_USER
	if { [catch { set MSG [exec -- sudo su - $SHELL_USER -c $PATHROOT/$CRON_FILE &] } ERR_MSG] } {
		FCT::MSG $chan $ERR_MSG
		return 0
	}
	FCT::MSG $chan "MOCKS Started with PID: $MSG"
}

proc ::MOCKS::LIST { nick uhost hand chan arg } {
	variable CONF_FILE
	variable PATHROOT
	set IPS_LIST	[list];
	set FILE_LINE	[FCT::FILE:READ "$PATHROOT/$CONF_FILE"]
	
	foreach LINE_DATA $FILE_LINE {
		if { [string match -nocase "FILTER_EXCEPTION*" $LINE_DATA] } {
			lappend IPS_LIST [lindex $LINE_DATA 2]
		}
	}
	FCT::MSG $chan "WhiteList: [join $IPS_LIST ", "]"
}

proc ::MOCKS::HELP { nick uhost hand chan arg } {
	FCT::MSG $chan "*** HELP MOCKS ***"
	FCT::MSG $chan "* !mocks                : Affiche cette aide."
	FCT::MSG $chan "* !mocks list           : Affiche la whitelist."
	FCT::MSG $chan "* !mocks add    <ip>    : Ajoute une IP de la whitelist"
	FCT::MSG $chan "* !mocks remove <ip>    : Enlever une IP de la whitelist"
	FCT::MSG $chan "* !mocks restart        : Relance MOCKS"
	FCT::MSG $chan "* !mocks stop           : arette MOCKS"
	FCT::MSG $chan "* !mocks start          : Demarre MOCKS"
	FCT::MSG $chan "* !mocks logs           : Affiche les LOGS"
	FCT::MSG $chan "******************"
	
}
namespace eval ::MOCKS::FCT {
	namespace export *
}
proc ::MOCKS::FCT::FILE:READ { FILE_NAME } {
	set FILE_DATA	[open "$FILE_NAME" r]
	set FILE_LINE	[split [read $FILE_DATA] "\n"]
	close $FILE_DATA;
	return $FILE_LINE
}
proc ::MOCKS::FCT::MSG { DEST MSG } {
	putnow "PRIVMSG $DEST :$MSG"
}

::MOCKS::INIT

