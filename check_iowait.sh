#!/bin/bash
# ===================================================================================================================
# IO_WAIT cpu statistic Plugin for Nagios 
#
# Written by	: Steve Bosek
# Adapted by	: Lucas Di Paola
# Release		: 1.0
# Creation date	: 13 February 2014
# Revision date	: 13 February 2014
# Description	: Nagios Plugin (script) to check IO_WAIT cpu statistic, requiring iostat as external program. 
#                 The location of these can easily be changed by editing the variable $IOSTAT at the top of the script. 
#
# Usage			: ./check_iowait.sh [-w <warn>] [-c <crit] ( [ -i <intervals in second> ] [ -n <report number> ]) 
# ---------------------------------------------------------------------------------------------------------------------

IOSTAT=/usr/bin/iostat

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin parameters value if not define
WARNING_THRESHOLD=${WARNING_THRESHOLD:="30"}
CRITICAL_THRESHOLD=${CRITICAL_THRESHOLD:="100"}
INTERVAL_SEC=${INTERVAL_SEC:="1"}
NUM_REPORT=${NUM_REPORT:="3"}

# Plugin variable description
PROGNAME=$(basename $0)
RELEASE="1.0"
AUTHOR="(c) 2008 Steve Bosek (steve.bosek@gmail.com)"
ADAPTEDBY="Lucas Di Paola"

if [ ! -x $IOSTAT ]; then
	echo "UNKNOWN: iostat not found or is not executable by the nagios user."
	exit $STATE_UNKNOWN
fi

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR - $ADAPTEDBY"
}

print_usage() {
	echo ""
	echo "$PROGNAME $RELEASE - IO_WAIT cpu statistic Plugin for Nagios"
	echo ""
	echo "Usage: check_iowait.sh -w -c (-i -n)"
	echo ""
	echo "-w  Warning level in % for cpu iowait"
	echo "-c  Crical level in % for cpu iowait"
	echo "-i  Interval in seconds for iostat (default : 1)"
	echo "-n  Number report for iostat (default : 3)"
	echo "-h  Show this page"
	echo ""
	echo "Usage: $PROGNAME"
	echo "Usage: $PROGNAME --help"
	echo ""
}

print_help() {
	print_usage
		echo ""
		echo "This plugin will check io_wait cpu statistic"
		echo ""
	exit 0
}

# Parse parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit $STATE_OK
            ;;
        -v | --version)
                print_release
                exit $STATE_OK
                ;;
        -w | --warning)
                shift
                WARNING_THRESHOLD=$1
                ;;
        -c | --critical)
               shift
                CRITICAL_THRESHOLD=$1
                ;;
        -i | --interval)
               shift
               INTERVAL_SEC=$1
                ;;
        -n | --number)
               shift
               NUM_REPORT=$1
                ;;        
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

# CPU Utilization Statistics Unix Plateform (Linux)
case `uname` in
	Linux ) CPU_REPORT=`iostat -c $INTERVAL_SEC $NUM_REPORT | sed -e 's/,/./g' | tr -s ' ' ';' | sed '/^$/d' | tail -1`
			CPU_IOWAIT=`echo $CPU_REPORT | cut -d ";" -f 5`
			CPU_IOWAIT_MAJOR=`echo $CPU_IOWAIT | cut -d "." -f 1`
			NAGIOS_DATA="iowait=${CPU_IOWAIT}%"	
            ;;
	*) 		echo "UNKNOWN: `uname` not yet supported by this plugin!"
			exit $STATE_UNKNOWN 
	    ;;
	esac

# Return
	if [ ${CPU_IOWAIT_MAJOR} -ge $WARNING_THRESHOLD ] && [ ${CPU_IOWAIT_MAJOR} -lt $CRITICAL_THRESHOLD ]; then
		echo "IO_WAIT WARNING | ${NAGIOS_DATA}"
		exit $STATE_WARNING
	elif [ ${CPU_IOWAIT_MAJOR} -ge $CRITICAL_THRESHOLD ]; then
		echo "IO_WAIT CRITICAL | ${NAGIOS_DATA}"
		exit $STATE_CRITICAL
	else
		echo "IO_WAIT OK | ${NAGIOS_DATA}"
		exit $STATE_OK
	fi
