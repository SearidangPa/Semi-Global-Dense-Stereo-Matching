%Author: Searidang Pa
%Computer Vision Coursework

function [Cost_Volume] = Compute_Cost_Volume_BT(L, R, h, w, d_max)
    Cost_Volume=zeros(h, w, d_max); % initialize the cost
    
    % get sampled image of the left and the right images
    Sampled_L = ComputeSampledImg(L);
    Sampled_R = ComputeSampledImg(R);
    
    %pad the right sampled image for vectorization of finding the absolute
    %difference below
    pad_Sampled_R = padarray(Sampled_R, [0 d_max 0], 0, 'pre');
    
    %iterate over each disparity level
    for d=1:d_max
        %initialize the absolute difference between the left and the sampled right images
        d_L = Inf*ones(h, w); 
        %initialize the absolute difference between the right and the sampled left images
        d_R = Inf*ones(h, w);
        
        % find the minimum of the absolute difference between the left and the sampled right images
        for i=1:3
             d_L = min(d_L, abs(L - pad_Sampled_R(:, d_max-(d-1) : w + d_max-d, i)));
        end
        
        % find the minimum of the absolute difference between the right and the sampled left images
        for i=1:3
             d_R = min(d_R, abs(Sampled_L(:,:,i)-pad_Sampled_R(:, d_max-(d-1) : w + d_max-d, 2)));
        end
        
        %the final cost is the minimum between the two 
        Cost_Volume(:,:,d)= min (d_L, d_R);
    end
end

%the sampled image would have a dimension of h x w x 3. The first layer is I-, where each 
%pixel is a linear interpolation with its left neighbor. The second layer is I, no interpolation.
%The third layer is I+, where each pixel is a linear interpolation with its right neighbor.

function [I_sampled]= ComputeSampledImg(I)
    [h,w] = size(I);

    %keep a copy I and pad it so that for  vectorization of the interpolation
    I_pad=padarray(I, [0 1], 'replicate', 'pre');

    %linearly interpolate with the left neighbor by adding itself with the padded copy shifting to the left by 1  
    I_interpolate_left = (I + I_pad(:, 1:w))*0.5;

    %we can cut down some computational cost by just shifting the left interpolated image 
    %to the right and pad the array with a row of infinity to keep the dimension h x w. 
    I_interpolate_right = [I_interpolate_left(:,2:w), Inf(h,1)];

    %stack them all together and we get a data structure that holds all the sampled images 
    I_sampled = reshape([I_interpolate_left, I, I_interpolate_right], [h,w,3]); 
end





