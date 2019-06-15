#======================================================
# Purpose: This test is performed by continuously writing the same file to the flash to test if hotspot wearing is developing.
# Criteria1: File is still accessible after 20 years worth touch operations.
# Criteria2: Memory usage on the test device should not be higher than 5% than the reference test device.
# Duration: The script should be able to complete in 3.0 days.
#======================================================
#!/bin/sh

# Include functions to write memory usage to csv.
source MemoryUsageFunction.sh

# Create test output directories /firmware/test_out if it doesn't exist.
mkdir -p /firmware/test_out
# Create an empty file in the test output directory.
TEMPFILE=/firmware/test_out/empty
./busybox.full.arm_v7.rf touch $TEMPFILE
# Remove the existing CSV otherwise the result will keep appending.
CSV=/firmware/test_out/HotspotWearingTest_MemoryUsage.csv
rm -rf $CSV

# 175,316 is chosen to be the number of touch operation to perform based on a 20 year life projection of DALI ECU, with an average of 1 write per hour.
NUMLOOPS=175316

# Log $NUMLOOPS, the date&time and ECU flash driver status before the loop starts.
LOG=/firmware/test_out/HotspotWearingTest_log
echo "Hotspot Wearing Test" > $LOG 2>&1
echo "Number of loops: $NUMLOOPS" >> $LOG 2>&1
echo " " >> $LOG 2>&1
echo "====== Starting ======" >> $LOG 2>&1
echo "Date:" >> $LOG 2>&1
date >> $LOG 2>&1 # Log script starting date and time.
echo " " >> $LOG 2>&1

# This test will perform touch operation to a file such that its inode table is updated. 
# Sync operation is needed after each touch operation to make sure changes are written to the flash. 
i=0
while [ $i -lt $NUMLOOPS ]
do
    echo "Running $i of $NUMLOOPS..."
    # Display the date&time for the current run for debug purpose.
    date
    # Change time stamp of the file without change the content.
    ./busybox.full.arm_v7.rf touch $TEMPFILE
    # Ensures everything in  memory is written to disk.
    sync
    # Record the memory usage every hour, each hour can roughly run 3000 times.
    if [[ $(($((i % 3000))==0)) == 1 ]]; then
        MemoryUsageFunction $CSV
    fi
    i=$((i+1)) # true $(( i++ ))
done

# Log the date&time and ECU flash driver status once the loop is done.
if [ $i -eq $NUMLOOPS ]; then
    echo "PASS!" >> $LOG 2>&1
else
    echo "FAIL!" >> $LOG 2>&1
    echo "$NUMLOOPS file touches should be executed." >> $LOG 2>&1
    echo "However, only $i file touches were executed." >> $LOG 2>&1
fi
echo " " >> $LOG 2>&1
echo "====== Finished ======" >> $LOG 2>&1
echo "Date:" >> $LOG 2>&1
date >> $LOG 2>&1

# Clean up: remove the TEMPFILE.
rm -rf $TEMPFILE
