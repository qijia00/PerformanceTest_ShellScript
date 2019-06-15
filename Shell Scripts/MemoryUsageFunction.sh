#======================================================
# Purpose: This function is to avoid unexpected rise in memory usage. 
# Criteria: Memory usage on the test device should not be higher than 5% than the reference test device.
# Duration: The function should be able to complete instantly.
#======================================================

#If use this script to execute instead of a function, then please do the following:
#1, Add "#!/bin/sh", 
#2, Remove MemoryUsageFunction(){}, 
#3, Add "mkdir -p /firmware/test_out" to create test output directories,
#4, Change CSV name.
#5, From Guru, find the ECU under test, right click to open SFTP to ECU.
#6, In WinSCP, create "/root/firmware/test" folder, copy the following files to it: "MemoryUsageTest.sh" & "busybox.full.arm.g4"
#7, Right click the above files and modify the properties - check X check boxes for Owner, Group and Others.
#8, From PuTTY, enter the ECU IP, Port 9003, Select SSH, click [Open], login as: root.
#9, change directory by "cd /firmware/test/" command.
#10, Execute the .sh file by "./MemoryUsageTest.sh" (case sensitive).
#11, Once the script is done, use "cat /firmware/test_out/MemoryUsageTest.csv" to view the csv.

MemoryUsageFunction()
{
#CSV=/firmware/test_out/MemoryUsageTest.csv #use this name when execute the script.
CSV=$1

# Read memories.
MemTotal=$(cat /proc/meminfo | grep MemTotal | ./busybox.full.arm_v7.rf awk '{print $2}')
MemFree=$(cat /proc/meminfo | grep MemFree | ./busybox.full.arm_v7.rf awk '{print $2}')
Cached=$(cat /proc/meminfo | grep ^Cached | ./busybox.full.arm_v7.rf awk '{print $2}')
Buffers=$(cat /proc/meminfo | grep Buffers | ./busybox.full.arm_v7.rf awk '{print $2}')

# Total Free Memory = Free + Buffers + Cached
TotalFreeMemory=$((MemFree+Cached+Buffers))

# Memory usage = 1- Total Free Memory / Total Memory
echo $TotalFreeMemory $MemTotal | ./busybox.full.arm_v7.rf awk '{MemoryUsage=1-$1/$2; printf"%0.6f\n", MemoryUsage}' >> $CSV 2>&1
}