# PerformanceTest_ShellScript
Sample Shell Script that I created to test device performance. Dependencies have been removed to protect privacy.

# How to execute
1, From Guru (a customized ECU tool), find the ECU under test, right click to open SFTP to ECU.

2, In WinSCP, create "/firmware/test" folder, copy the following files/folder to it:
"ori_random_files" folder
"busybox.full.arm_v7.rf"
"FileIntegrityTest.sh"
"HotspotWearingTest.sh"
"MemoryUsageFunction.sh"
"ReadWriteThroughputTest.sh"

3, Right click the above files and modify the properties - check X check boxes for Owner, Group and Others. (No need to modify folder and its content.)

4, From PuTTY, enter the ECU IP, Port 9003, Select SSH, click [Open], login as: root.

5, change directory by "cd /firmware/test/" command.

6, Execute the .sh files by:
"./FileIntegrityTest.sh" (case sensitive, 3.1 days to finish).
"./HotspotWearingTest.sh" (case sensitive, 3.0 days to finish).
"./ReadWriteThroughputTest.sh" (case sensitive, overnight/16 hours to finish).

7, Once the scripts are done, view the following logs:
"/firmware/test_out/FileIntegrityTest_log" (Criteria: No "md5sum invalid" and "FAIL!" should be seen.)
"/firmware/test_out/HotspotWearingTest_log" (Criteria: No "FAIL!" should be seen.)
"/firmware/test_out/ReadWriteThroughputTest_log" (Criteria: No "FAIL!" should be seen, and read and write throughput of a file on the test device should not be lower than 90% of the same test on the reference test device.)

8, Once the scripts are done, view the following csvs: 
"/firmware/test_out/FileIntegrityTest_MemoryUsage.csv" (Criteria: Memory usage on the test device should not be higher than 5% than the reference test device.)
"/firmware/test_out/HotspotWearingTest_MemoryUsage.csv" (Criteria: Memory usage on the test device should not be higher than 5% than the reference test device.)
"/firmware/test_out/ReadWriteThroughputTest_MemoryUsage.csv" (Criteria: Memory usage on the test device should not be higher than 5% than the reference test device.)

9, In WinSCP, delete the "/firmware/test" and "/firmware/test_out" folders.
