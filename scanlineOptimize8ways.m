
function[Cost_Volume] = scanlineOptimize8ways(Cost_Volume, half_window, d_max, P1, P2, smooth_cost_type)
    [h, w, ~] = size(Cost_Volume);
    cost4ways = scanlineOptimize4ways(Cost_Volume, half_window, d_max, P1, P2, smooth_cost_type);
    
    %cap_linear cost
    if smooth_cost_type == 1
        penalize_cost=P1*(0:d_max-1);
        penalize_cost(penalize_cost > P2)=P2;    
        penalize_cost(1)=0;
    else  %constant cost: Penalize 
        penalize_cost = P2*ones(1,d_max);     
        penalize_cost([1 2]) = [0 P1];
    end

    %precompute the matrix smooth cost for vectorization
    %Smooth_cost has dimension d_max x d_max. The ith element in each row holds  
    %the smooth cost penalty for the having different of disparity i and d
    Smooth_cost = zeros(d_max, d_max);
    for d = 1:d_max
        Smooth_cost(d, :) = penalize_cost(1+abs(d-(1:d_max)));
    end
    
    %initialize the aggregated cost in each direction 
    cost_5 = Cost_Volume;  % from left top corner to right bottom corner
    cost_6 = Cost_Volume;  % from right top corner to left bottom corner
    cost_7 = Cost_Volume;  % from right bottom corner to left top corner
    cost_8 = Cost_Volume;  % from left bottom corner to right top corner
    
    %vectorization computation of information passing for all of
    %disparity in one go. Since information is passed diagonally, 
    %the feature that allows for more vectorization as in the 4-way
    %optimization do not exist here. We vectorize the computation
    %for each disparity instead.
    
    for m = half_window:h-half_window
        disp(['Scanline Optimization. Line ', num2str(m)])
        
        %information passing from left top corner to right bottom corner
         % Each row of the message variable holds the aggregated
         % cost of the previous column for all disparity values. 
         % The message variable has dimension 1 x d_max.
        for n = half_window:w-half_window
            message = squeeze(cost_5(m-1, n-1, :));
             
            %add smooth cost and replicate the matrix to add everything in bulk 
            message_added_smooth = repmat(message, [1 d_max]) + Smooth_cost;
            
            %take the min of message_added_smooth and reshape for
            %matrix broadcasting/vectorization
            smooth_term = reshape(min(message_added_smooth), [1,1,d_max]);
            cost_5(m,n,:) = Cost_Volume(m,n,:) + smooth_term;
        end
        
        %information passing from right top corner to left bottom corner
        for n = fliplr(half_window:w-half_window)
            message = squeeze(cost_6(m-1, n+1, :));
            
            %add smooth cost and replicate the matrix to add everything in bulk 
            message_added_smooth = repmat(message, [1 d_max]) + Smooth_cost;
            
            %take the min of message_added_smooth and reshape for
            %matrix broadcasting/vectorization
            smooth_term = reshape(min(message_added_smooth), [1,1,d_max]);
            cost_6(m,n,:) = Cost_Volume(m,n,:) + smooth_term;
        end
    end
    for m = fliplr(half_window:h-half_window)
        disp(['Scanline Optimization. Line ', num2str(m)])
        
        %information passing from right bottom corner to left top corner
        for n = fliplr(half_window:w-half_window)
            message = squeeze(cost_7(m+1, n+1, :));

            %add smooth cost and replicate the matrix to add everything in bulk 
            message_added_smooth = repmat(message, [1 d_max]) + Smooth_cost;
            
            %take the min of message_added_smooth and reshape for
            %matrix broadcasting/vectorization
            smooth_term = reshape(min(message_added_smooth), [1,1,d_max]);
            cost_7(m,n,:) = Cost_Volume(m,n,:) + smooth_term;
        end
        
        %information passing from left bottom corner to right top corner
        for n = half_window:w-half_window
            message = squeeze(cost_8(m+1, n-1, :));

            %add smooth cost and replicate the matrix to add everything in bulk 
            message_added_smooth = repmat(message, [1 d_max]) + Smooth_cost;
            
            %take the min of message_added_smooth and reshape for
            %matrix broadcasting/vectorization
            smooth_term = reshape(min(message_added_smooth), [1,1,d_max]);
            cost_8(m,n,:) = Cost_Volume(m,n,:) + smooth_term;
        end
    end
    
    Cost_Volume = cost4ways + cost_5 + cost_6 + cost_7 + cost_8;
end



