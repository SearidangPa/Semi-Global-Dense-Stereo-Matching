%Author: Searidang Pa
%Computer Vision Coursework

% Cost Aggregation step: add up the aggregated cost from all 4 directions.
% Pass information of each pixel in the Cost Volume to its neighbor in 4
% directions
function [CostAggr] = scanlineOptimize4ways(Cost_Volume, half_window, d_max, P1, P2, smooth_cost_type)
    [h, w, ~] = size(Cost_Volume);
    %initialize the aggregated cost in each direction 
    costAggr_1 = Cost_Volume; %from left to right 
    costAggr_2 = Cost_Volume; %from right to left 
    costAggr_3 = Cost_Volume; %facing up 
    costAggr_4 = Cost_Volume; %facing down 
    
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
    Smooth_cost_matrix = zeros(d_max, d_max);
    for d = 1:d_max
        Smooth_cost_matrix(d, :) = penalize_cost(1+abs(d-(1:d_max)));
    end
    
    %----------------information passing from left to right----------------
    % Each row of the message variable holds the aggregated
    % cost of the previous column for all disparity values. 
    % The message variable has dimension h x d_max.
    for n=half_window:w-half_window                 %for each column
        message = squeeze(costAggr_1(:, n-1, :));
        for d=1:d_max                               %for each disparity 
            %message_added_smooth has dimension h x d_max. 
            message_added_smooth = message + Smooth_cost_matrix(d,:);
            
            % cost aggregate = cost from matching cost step + minimum of message_added_smooth
            costAggr_1(:,n,d)= Cost_Volume(:, n, d) + min(message_added_smooth,[],2);
        end  
    end

    %----------------information passing from right to left----------------
    % Each row of the message variable holds the aggregated
    % cost of the previous column from the right direction for all disparity values. 
    % The message variable has dimension h x d_max.
    %we have to flip the order as we have to aggregate from the right of the matrix to the left
    for n = fliplr(half_window:w-half_window)			
        message = squeeze(costAggr_2(:, n+1, :));
        for d=1:d_max  
             %message_added_smooth has dimension h x d_max. 
             message_added_smooth = message + Smooth_cost_matrix(d,:);
             
             % cost aggregate = cost from matching cost step + minimum of message_added_smooth
             costAggr_2(:,n,d)=Cost_Volume(:, n, d) + min(message_added_smooth,[],2);
        end   
    end

    %----------------information passing from up to down-------------------
    % Each row of the message variable holds the aggregated
    % cost of the previous row for all disparity values. 
    % The message variable has dimension h x d_max.
    for m=half_window:h-half_window
        message = squeeze(costAggr_3(m-1, :, :));
         for d=1:d_max  
             %message_added_smooth has dimension h x d_max. 
             message_added_smooth = message + Smooth_cost_matrix(d,:);
             
             % cost aggregate = cost from matching cost step + minimum of message_added_smooth
             costAggr_3(m,:,d)= Cost_Volume(m, :, d) + min(message_added_smooth,[],2)';
         end   
    end

    %----------------information passing from down to up------------------
    % Each row of the message variable holds the aggregated
    % cost of the previous row facing up for all disparity values. 
    % The message variable has dimension h x d_max.
    %we have to flip the order as we have to aggregate from the bottom of the matrix to the left
    for m=fliplr(half_window:h-half_window)
        message = squeeze(costAggr_4(m+1, :, :));
         for d=1:d_max  
             %message_added_smooth has dimension h x d_max. 
             message_added_smooth = message + Smooth_cost_matrix(d,:);
             
             % cost aggregate = cost from matching cost step + minimum of message_added_smooth
             costAggr_4(m,:,d)= Cost_Volume(m, :, d) + min(message_added_smooth,[],2)';
         end   
    end
    
    % add up the aggregated cost from all 4 directions 
    CostAggr = costAggr_1+costAggr_2+costAggr_3+costAggr_4;
    
    visualize_intermediate_result = false;
    if visualize_intermediate_result == true
       [~, D_left_1] = min(costAggr_1, [], 3);
       figure; imagesc(D_left_1);colormap(gray);  title('left to right');
       [~, D_left_2] = min(costAggr_2, [], 3);
       figure; imagesc(D_left_2);colormap(gray);  title('right to left');
       [~, D_left_3] = min(costAggr_3, [], 3); 
       figure; imagesc(D_left_3);colormap(gray);  title('going down');
       [~, D_left_4] = min(costAggr_4, [], 3); 
       figure; imagesc(D_left_4);colormap(gray);  title('going up');
    end
end

