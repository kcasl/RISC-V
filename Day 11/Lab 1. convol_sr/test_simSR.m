clc
clear all
close all

%% Load pre-trained convolutional parameter
% Load Layer 1
[w1,b1,~,~,~] = read_conv_param_module('bin/sim_espcn_3x3.weights_layer_0',3, 1,16,0);
w1 = permute(reshape(w1, 3, 3, 1, 16), [2, 1, 3, 4]);
% Load Layer 2
[w2,b2,~,~,~] = read_conv_param_module('bin/sim_espcn_3x3.weights_layer_1',3,16,16,0);
w2 = permute(reshape(w2, 3, 3, 16, 16), [2, 1, 3, 4]);
% Load Layer 3
[w3,b3,~,~,~] = read_conv_param_module('bin/sim_espcn_3x3.weights_layer_2',3, 16,4,0);
w3 = permute(reshape(w3, 3, 3, 16,4), [2, 1, 3, 4]);

%% Load an image
SF = 2;     % Up scaling 2x
imGT = imread('img/butterfly_GT.bmp');
if size(imGT,3) > 1    
    im = rgb2ycbcr(imGT);
else
    im = imGT;        
end
imhigh = modcrop(im, SF);
imhigh = single(imhigh)/255;
imlow = imresize(imhigh, 1/SF, 'bicubic');        
%imlow = imresize(imlow, SF, 'bicubic');
if size(imlow,3)>1
    imlowy = imlow(:,:,1);
    imlowy = max(16.0/255, min(235.0/255, imlowy));
else
    imlowy = imlow;
end    
input = imlowy;

figure();
imshow(input);

% Now, we convert an image input to a 8-bit format
input = double(floor(imlowy * 255));

%% Demo sim-SR

% First Layer
conv_out = convol2(input, w1, 1, 2);
for j = 1:size(conv_out, 3)
    % Add bias
    conv_out(:,:,j) = conv_out(:,:,j) + b1(j);
end

% Activation
conv_out_relu = conv_out;
conv_out_relu(conv_out_relu < 0) = 0;

for i = 1:size(conv_out, 3)
   figure(1)
   subplot(1,2,1)
   imshow(conv_out(:,:,i));title(['ch = ',num2str(i)]);
   subplot(1,2,2)
   imshow(conv_out_relu(:,:,i));title('After ReLU');
   saveas(gcf,['output/1_',num2str(i),'.bmp']);
   pause(1)
end


% Insert your code for other layers
