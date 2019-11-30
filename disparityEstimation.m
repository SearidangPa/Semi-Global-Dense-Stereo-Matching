%Author: Searidang Pa
%Computer Vision Coursework
 
function [DisparityMap] = disparityEstimation(imageLeft, imageRight)   
    %------------------------Preprocessing---------------------------------
    % Read the image 
    I_L = imread(imageLeft);        
    I_R = imread(imageRight); 
    
    if size(I_L,3)==3         %convert to grayscale if the image is colored
        I_L = rgb2gray(I_L);
        I_R = rgb2gray(I_R);
    end   
    % normalize it
    L = double(I_L)./255;
    R = double(I_R)./255;
    
    [h_orig, w_orig] = size(L);
    
    %image pyramid scheme: 
    %shrink high resolution images until the width is less than 450 
    shrink_factor = 0;
    while size(L,2) > 450        
        L = impyramid(L, 'reduce');
        R = impyramid(R, 'reduce');
        shrink_factor = shrink_factor + 1;
    end
    
    % the dimension of the two images must be the same. Otherwise, the
    % algorithm will not output correct output. 
    [h,w] = size(L);        % h is the height and w is the width of the image
    assert(h == size(R,1), 'the height of the two images must be the same')
    assert(w == size(R,2), 'the height of the two images must be the same')
    
    %-----------------------Initialize parameters--------------------------
    d_max = 70;             % the maximum disparity search range. 
    
    % The options are 1 for for "BT" and 2 for "Census_Transform" 
    match_cost_type = 1; 
    
    %-----------------------Matching cost computation step-----------------
    % Initialize the cost volume. 
    Cost_Volume = zeros(h, w, d_max,'double');
    
        
    if match_cost_type == 1
        %get the horizontal and vertical gradients of the two images
        [Gx_L, Gy_L] = imgradientxy(L); 
        [Gx_R, Gy_R] = imgradientxy(R);

        %cost on the horizontal gradient 
        cost1 = Compute_Cost_Volume_BT(Gx_L, Gx_R, h, w, d_max);
        cost1(cost1>0.05)=0.05;  %unless it's accurate, i'm going to rely on the SO

        %cost on the vertical gradient 
        cost2 = Compute_Cost_Volume_BT(Gy_L, Gy_R, h, w, d_max);
        cost2(cost1>0.05)=0.05;

        %cost on the intensity 
        cost3 = Compute_Cost_Volume_BT(L, R, h, w, d_max);
        cost3(cost3>0.05)=0.05;
        
        %combine the three costs: the gradients are more reliable than the
        %intensity. Together, they are stronger than alone. 
        Cost_Volume = ((cost1 + cost2)*0.85 + cost3) *0.5;
        
        % assign the parameters for the cost aggregation step
        P1 = 0.03; P2 =  0.6;
        half_window = 2;

    elseif match_cost_type == 2
        half_window = 2;        % the window radius of the census transform
        Cost_Volume = Compute_Cost_Volume_Census(L, R, half_window, h, w, d_max);
        % assign the parameters for the cost aggregation step
        P1 = 0.15; P2 =  1.5;
    end
    
    %-----------------------Cost Aggregation step--------------------------
    % There are two options for smooth cost type: 1 for cap linear and 2 for piecewise constants. 
    % Experiments on Teddy and Cone show that cap linear is better 
    smooth_cost_type = 1;
    Optimize_8_way = false; 
    if Optimize_8_way == false
        Cost_Aggr = scanlineOptimize4ways(Cost_Volume, half_window, d_max, P1, P2,... 
                                                         smooth_cost_type);
    else
        Cost_Aggr = scanlineOptimize8ways(Cost_Volume, half_window, d_max, P1, P2,... 
                                                         smooth_cost_type);
    end
    
    %----------------------Disparity computation step----------------------
    % Winner-Take-All: for each pixel, take the disparity that corresponds
    % to the lowest aggregated cost
    [~, DisparityMap] = min(Cost_Aggr, [], 3); 
    
    %disparity refinement step 
    DisparityMap = medfilt2(DisparityMap, [3,3]);
    
    % We need to make sure the dimension of the disparity map is the same
    % as the original left image before shrinking
    while (shrink_factor > 0)    
        % the shrink affected the disparity by a factor of 2
        DisparityMap = DisparityMap * 2;  
        DisparityMap = impyramid(DisparityMap, 'expand');
        shrink_factor = shrink_factor - 1;
        size(DisparityMap)
    end
    
    %matlab does something weird with expanding the disparity map back.
    %even after expanding back by the shrink factor, sometimes the
    %dimension is 1 less than the original left image. I have not figured
    %out why yet. 
    if size(DisparityMap, 1) == h_orig -1 %if the height is odd, we need padding 
        DisparityMap = padarray(DisparityMap, [1 0], 0, 'pre');
    end
        
    if size(DisparityMap, 2) == w_orig -1 %if the height is odd, we need padding 
        DisparityMap = padarray(DisparityMap, [0 1], 0, 'pre');
    end
end 

















