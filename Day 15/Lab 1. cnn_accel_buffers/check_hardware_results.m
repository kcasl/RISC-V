clc 
clear all
close all

for ch = 1:4
    % Output from the reference S/W
    im_sw = imread(sprintf('out_sw/ofmap_L01_ch%02d.bmp',ch));
    % Output from the H/W simulation
    im_hw = imread(sprintf('out/convout_layer01_ch%02d.bmp',ch));
    im_hw = im_hw(:,:,1);    % Gray image

    % Calculate the difference between S/W and H/W outputs
    img_diff = abs(single(im_hw) - single(im_sw));
    max_diff = max(img_diff(:));
    if(max_diff == 0)
        fprintf('Results of the channel %02d are same!\n', ch);   
    else
        fprintf('ERROR: Results of the channel %02d are different!\n', ch);   
        disp(max_diff);
        figure(ch)
        imshow(uint8(img_diff));
    end
end
