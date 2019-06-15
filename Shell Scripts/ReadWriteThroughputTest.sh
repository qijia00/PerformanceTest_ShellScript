#======================================================
# Purpose: This test is to avoid unexpected rise in read and write delays. 
# Criteria: Read and write throughput of a file on the test device should not be lower than 90% of the same test on the reference test device.
# Duration: The script should be able to complete in 16 hours (overnight).
#======================================================
#!/bin/sh

# Write before read to create $TEMPFILE.
ReadWriteThroughputFunction()
{
# Function input.
Size=$1
Count=$2

# To free pagecache, dentries and inodes before each write.
echo 3 > /proc/sys/vm/drop_caches
# Write to $TEMPFILE (size $1) $2 times.
WriteResult=$(./busybox.full.arm_v7.rf dd if=/dev/zero of=$TEMPFILE bs=$1 count=$2 conv=fsync,notrunc 2>&1 1>/dev/null)
# Extract the time(in seconds) used to write.
WriteTime=$(echo $WriteResult | sed 's/.*copied\, //' |sed 's/ seconds.*$//')

# To free pagecache, dentries and inodes before each read.
echo 3 > /proc/sys/vm/drop_caches
# Read to $TEMPFILE (size $1) $2 times.
ReadResult=$(./busybox.full.arm_v7.rf dd if=$TEMPFILE of=/dev/null bs=$1 count=$2 2>&1 1>/dev/null)
# Extract the time(in seconds) used to read.
ReadTime=$(echo $ReadResult | sed 's/.*copied\, //' |sed 's/ seconds.*$//')

# Function returns.
echo "$WriteTime, $ReadTime"
}

# Calculate the AverageWriteTime and AverageReadTime
AverageReadWriteTimeFunction()
{
# Function input.
Size=$1
Count=$2
NUMLOOPS=$3

i=0
TotalWriteTime=0.000000 # Same amount of decimals allows add operation.
TotalReadTime=0.000000
while [ $i -lt $3 ]
do
    echo "Running $i of $NUMLOOPS..."
    # Display the date&time for the current run for debug purpose.
    date
    TimeBundle=$( ReadWriteThroughputFunction $1 $2 )
    CurrentWriteTimeWithCommaAndSpace=$( echo $TimeBundle | ./busybox.full.arm_v7.rf awk '{print $1}' )
    CurrentWriteTime=$(echo $CurrentWriteTimeWithCommaAndSpace | sed 's/[^0-9\.]//g')
    CurrentReadTime=$( echo $TimeBundle | ./busybox.full.arm_v7.rf awk '{print $2}' )
    echo "Current Write Time is $CurrentWriteTime"
    echo "Current Read Time is $CurrentReadTime"
    # Will NOT use the 1st write/read time to calculate the total write/read time, since the 1st time is at least 10% different than the rest of times.
    if [ $i -gt 0 ]; then
        TotalWriteTime=$(echo $TotalWriteTime $CurrentWriteTime | ./busybox.full.arm_v7.rf awk '{print $1+$2}')
        TotalReadTime=$(echo $TotalReadTime $CurrentReadTime | ./busybox.full.arm_v7.rf awk '{print $1+$2}')
    fi
    # Record the memory usage every 5 loops.
    if [[ $(($((i % 5))==0)) == 1 ]]; then
        MemoryUsageFunction $CSV
    fi
    i=$((i+1))
done

echo ">>>>>> Write/Read $1B file $2 times:" >> $LOG 2>&1
if [ $i -eq $3 ]; then
    echo "PASS!" >> $LOG 2>&1
else
    echo "FAIL!" >> $LOG 2>&1
    echo "$3 loops should be executed." >> $LOG 2>&1
    echo "However, only $i loops were executed." >> $LOG 2>&1
fi
# Will NOT use the 1st write/read time to calculate the average write/read time, since the 1st time is at least 10% different than the rest of times.
echo $TotalWriteTime $((NUMLOOPS-1)) | ./busybox.full.arm_v7.rf awk '{AverageWriteTime=$1/$2; printf"The average write time is %0.6f seconds.\n", AverageWriteTime}' >> $LOG 2>&1
echo $TotalReadTime $((NUMLOOPS-1)) | ./busybox.full.arm_v7.rf awk '{AverageReadTime=$1/$2; printf"The average read time is %0.6f seconds.\n", AverageReadTime}' >> $LOG 2>&1
echo " " >> $LOG 2>&1
}

# Include functions to write memory usage to csv.
source MemoryUsageFunction.sh

# Create test output directories /firmware/test_out if it doesn't exist.
mkdir -p /firmware/test_out
# Specify temp file path in the test output directory.
TEMPFILE=/firmware/test_out/tempfile
# Remove the existing CSV otherwise the result will keep appending.
CSV=/firmware/test_out/ReadWriteThroughputTest_MemoryUsage.csv
rm -rf $CSV

# Log the date&time and ECU flash driver status before the write-read cycles start.
LOG=/firmware/test_out/ReadWriteThroughputTest_log
echo "Read Write Throughput Test" > $LOG 2>&1
echo "Number of loops: 80" >> $LOG 2>&1
echo " " >> $LOG 2>&1
echo "====== Starting ======" >> $LOG 2>&1
echo "Date:" >> $LOG 2>&1
date >> $LOG 2>&1
echo " " >> $LOG 2>&1

# 80 is chosen to be the number of read/write operation to perform based on the script can be finished overnight in 16 hours.
echo ">>>>>> Write/Read 128KB file:"
echo ">>>>>> Memory usage when write/read 128KB file:" >> $CSV 2>&1
AverageReadWriteTimeFunction 128K 50 80
echo ">>>>>> Write/Read 512KB file:"
echo ">>>>>> Memory usage when write/read 512KB file:" >> $CSV 2>&1
AverageReadWriteTimeFunction 512K 50 80
echo ">>>>>> Write/Read 1MB file:"
echo ">>>>>> Memory usage when write/read 1MB file:" >> $CSV 2>&1
AverageReadWriteTimeFunction 1M 50 80

# Log the date&time and ECU flash driver status once the loop is done.
echo "====== Finished ======" >> $LOG 2>&1
echo "Date:" >> $LOG 2>&1
date >> $LOG 2>&1

# Clean up: remove the TEMPFILE.
rm -rf $TEMPFILE