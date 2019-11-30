# Semi_Global_Dense_Stereo_Matching

This implementation follows closely from the paper by Heiko. Link to paper: https://pdfs.semanticscholar.org/bcd8/4d8bd864ff903e3fe5b91bed3f2eedacc324.pdf

Run the get_result file to get a sample result of the algorithm. 

However, there are some modification to the methods used in the paper. The user can also change the match_cost_type to 2 to use the Census Transform, change smooth cost type to be constant for the scan-line optimization and change the boolean Optimize_8_way to true to perform an 8-way optimization. I should warn that the 8-way optimization would take much longer, around 30 seconds. The algorithm should also work for images of high resolution. In the disparityEstimation function, the default of the algorithm is to use the Birchfield Tomasi cost,  optimize 4-way, and capped linear smooth cost for the scan-line optimization. 



 


