clc
clear all
close all

% Input file
src_image_file = 'img/kodim01.bmp';
% Load an input image
img = imread(src_image_file);

% Save pixel values to a buffer
[height,width,nch] = size(img);
buf = zeros(height*width*nch,1);
idx = 1;
for i = height:-1:1
    for j = 1:width
        buf(idx  ) = img(i,j,1); % Red
        buf(idx+1) = img(i,j,2); % Green
        buf(idx+2) = img(i,j,3); % Blue
        idx = idx + 3;           
    end
end

% Write a hex file
out_image_file = [src_image_file(1:end-4) '.hex'];
fid = fopen(out_image_file,'wt');
fprintf(fid,'%x\n',buf);
fclose(fid);

% Display an image
% figure(1);
% imshow(img)

