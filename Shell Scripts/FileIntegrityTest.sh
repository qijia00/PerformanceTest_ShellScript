#======================================================
# Purpose: This test is to verify that the file integrity remains intact after writing files to the same location of the file system again and again. 
# Criteria1: The files integrities will remain intact throughout 20 years worth erase-write cycles.
# Criteria2: Memory usage on the test device should not be higher than 5% than the reference test device.
# Duration: The script should be able to complete in 3.1 days.
#======================================================
#!/bin/sh

# Include functions to write memory usage to csv.
source MemoryUsageFunction.sh

# Create test output directories /firmware/test_out if it doesn't exist.
mkdir -p /firmware/test_out/random_files
# Remove the existing CSV otherwise the result will keep appending.
CSV=/firmware/test_out/FileIntegrityTest_MemoryUsage.csv
rm -rf $CSV

# 4,500 is chosen to be the number of copy operation to perform based on on a 20 year life projection of DALI ECU, with an average of 1 write per hour. 
# Each time we copy 13 files and each file writes 3 times to the flash (assume the same as DALI ECU ??????).
NUMLOOPS=4500

# Log $NUMLOOPS, date&time and ECU flash driver status before the loop starts.
LOG=/firmware/test_out/FileIntegrityTest_log
echo "File Integrity Test" > $LOG 2>&1
echo "Number of loops: $NUMLOOPS" >> $LOG 2>&1
echo " " >> $LOG 2>&1
echo "====== Starting ======" >> $LOG 2>&1
echo "Date:" >> $LOG 2>&1
date >> $LOG 2>&1
echo " " >> $LOG 2>&1

# This test will write files of different sizes with random data in them to the flash, compare them to a precomputed md5sum file to check their integrity, delete them and repeat the process again.
i=0
j=0 # Record the number of loop actually executed
while [ $i -lt $NUMLOOPS ]
do
        echo "Running $i of $NUMLOOPS..."
        # Display the date&time for the current run for debug purpose.
        date
        # Delete all files & sub-folders in /firmware/test_out/random_files.
        rm -rf /firmware/test_out/random_files/* 
        # Copy files with different sizes and random data to /firmware/test_out/random_files.
        cp ori_random_files/random* /firmware/test_out/random_files/.
        # Ensures everything in  memory is written to disk.
        sync
        # Record the memory usage every hour, each hour can roughly run 60 times.
        if [[ $(($((i % 60))==0)) == 1 ]]; then
            MemoryUsageFunction $CSV
        fi
        # Computing md5sum of the files at /firmware/test_out/random_files.
        ./busybox.full.arm_v7.rf md5sum -c ori_random_files/md5sum # eval md5sum -c ori_random_files/md5sum
        if [ $? -eq 0 ]; then
                echo "md5sum correct."
                true $(( i++ ))
                true $(( j++ ))
        else
                echo "md5sum invalid!" >> $LOG 2>&1
                echo " " >> $LOG 2>&1
                # Set j to record the number of loop actually executed.
                j=$((i+1))
                # Set i to $NUMLOOPS to exit the loop.
                i=$NUMLOOPS
        fi
done

# Log $i, the date&time and ECU flash driver status once the loop is done.
if [ $j -eq $NUMLOOPS ]; then
    echo "PASS!" >> $LOG 2>&1
else
    echo "FAIL!" >> $LOG 2>&1
    echo "$NUMLOOPS file touches should be executed." >> $LOG 2>&1
    echo "However, only $j file touches were executed." >> $LOG 2>&1
fi
echo " " >> $LOG 2>&1
echo "====== Finished ======" >> $LOG 2>&1
echo "Date:" >> $LOG 2>&1
date >> $LOG 2>&1

# Clean up: remove the random_files folder and all its contents.
rm -rf /firmware/test_out/random_files/ 