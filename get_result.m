%Author: Searidang Pa
%Computer Vision Coursework

image_pair_index = 1; 
% image pair #1 is Teddy; #2 is Cone
% motobike
[imageLeft, imageRight, compare_with_GT, quarter_resolution, ground_disp] = load_image_pair(image_pair_index);

%computes the disparity Map 
  
DisparityMap = disparityEstimation(imageLeft, imageRight);
RMS = evaluate(DisparityMap, compare_with_GT, quarter_resolution, ground_disp); 
%print out the RMS error
disp(['RMS: ', num2str(RMS)]);	

% visualize the disparity map 
figure; imagesc(DisparityMap); colormap(gray); title('Computed Disparity Map');

 

function [RMS] = evaluate(DisparityMap, compare_with_GT, quarter_resolution, ground_disp)
    if compare_with_GT == true
        %load ground truth image.
        if quarter_resolution == true
            GT = double (imread(ground_disp)) ./4;
        else
            GT = double (imread(ground_disp));
        end

        % if compare_at_the_edge is false, then we don't compare the edge pixels that 
        % census transform do not have any information on 
        compare_at_the_edge  = true; 
        if compare_at_the_edge == true
            DisparityMap = DisparityMap(:, 50:end);
            GT = GT(:, 50:end);
        else
            % the census transform do not have any information around the edges of the images. 
            DisparityMap = DisparityMap(2:end-2, 50:end-2);
            GT = GT(2:end-2, 50:end-2);
        end

        % Compute Root Mean Squared (RMS) error
        Sq_Diff = (DisparityMap - GT).^2;
        RMS = (sum(Sq_Diff(:))/ numel(GT)) .^ 0.5;		
    end
end

function [imageLeft, imageRight, compare_with_GT, quarter_resolution, ground_disp] = load_image_pair(image_pair_index)
    %set up the image pair and the ground truth image
    if image_pair_index == 1
        imageLeft = '../images/ted_L.png'; imageRight = '../images/ted_R.png';
        ground_disp = '../images/Ted_disp.png';
        compare_with_GT = true; quarter_resolution = true; 

    elseif image_pair_index == 2
        imageLeft = '../images/cone_L.png'; imageRight = '../images/cone_R.png';
        ground_disp = '../images/cone_disp.png';
        compare_with_GT = true; quarter_resolution = true; 
    end 
end




