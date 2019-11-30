
%{
This function computes the cost volume using census transform. Cost_Volume 
holds the matching cost of the pixel with disparities from 1 to d_max. It 
has dimension h x w x d_max. 

Input Parameters: L, R are the left and the right images. h, w are the
height and the width of the image. d_max is the maximum disparity search range. 
n is the half window radius

Key Variables: 
T_L ("Transformed left") is a temporary variable used for every row. 
The ith row of T_L hold the result of the pixels within the window radius compared 
to the centered pixel which is the ith pixel of the current row the algorithm is 
working on. The same goes for T_R ("Transformed Right") except that T_R is
for the right image. 

pad_TR is a pre-padding of T_R. This is helpful for vectorization of the algorithm. 
Instead of performing the calculation between one pixel the left and the
right image for each disparity value, we can just "slide" T_R to the left and 
performing the calculation one row at a time for each disparity value. 

Side node: At first, to further vectorize the algorithm (reduce the nested for loop), 
I tried to convert the left and the right image into a Census Transform image where 
each element is the concatenated bits of the result when the pixels within the 
window radius compared to the center pixel. However, it turned out to be slower 
because of huge memory cost. 
%}

function [Cost_Volume] = Compute_Cost_Volume_Census(L, R, n, h, w, d_max)
    Cost_Volume = zeros(h, w, d_max,'double'); %initialize the cost volume
    
    L = padarray(L, [n n], 0, 'both');
    R = padarray(R, [n n], 0, 'both');
    
    % Because Census Transform has a window radius n, we only have information   
    % from (n+1)th row and the (h-n)th row 
    for row = n+1:h-n                           
        T_L = false(w, (2*n+1)^2);  %use logical matrix to minimize the space  
        T_R = false(w, (2*n+1)^2);
        
        % compute the transform for each pixel of the row 
        % we only have information from (n+1)th pixel and the (w-n)th pixel of the row 
        for col = n+1:w-n      
            template_L = L(row-n:row+n, col-n:col+n) > L(row, col);         
            T_L(col,:)= template_L(:);
    
            template_R = R(row-n:row+n, col-n:col+n) > R(row, col);  
            T_R(col,:) = template_R(:);
        end
        
        % cost calculation 
        pad_TR = [false(d_max, (2*n+1)^2); T_R];
        for i = 1:d_max             %for each disparity value
            % the difference is equivalent to xor. Using xor reduce the
            % computation cost as logical matrix requires much less space
            C = xor(T_L, pad_TR(d_max-(i-1):w+d_max-i, :));
            
            % hamming distance: sum all the result of all the pixels within the
            % window radius 
            Cost_Volume(row, :, i) = sum(C,2);  
        end
    end
    
    % normalize the output to be between 0 and 1. This makes tuning the
    % hyper parameter smooth cost easier. 
    Cost_Volume = Cost_Volume ./ (2*n+1)^2; 
end