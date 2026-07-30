% Function: Convolution Only
% Input
% 	- img: Input feature map
%	- kernel: Weight
%	- s: stride
% 	- p: padding
% Output
%	- out
function out = convol2(img,kernel,s,p)
% Input Feature Maps
h = size(img,1);	% height
w = size(img,2);	% width
c = size(img,3);	% number of input features

% Padded image: zero padding
pad_img = zeros(h+p,w+p,c);
st_p = ceil(p/2);
pad_img(1+st_p:st_p+h,1+st_p:st_p+w,:) = img;

% Filter kernel size
f = size(kernel,1);

% Output feature maps
c_out = size(kernel,4);				% Number of output features
w_out = floor((w - f + p) / s + 1);	% width
h_out = floor((h - f + p) / s + 1);	% height

out = zeros(h_out,w_out,c_out);		% buffer of output feature maps

% Convolution
for k = 1:c_out % Number of output channels            
	win = kernel(:,:,:,k);	% Weight
    for i = 1:h_out			% Row
        for j = 1:w_out		% Column
			% Input feature map
			din = pad_img(1+(i-1)*s:1+(i-1)*s+f-1, 1+(j-1)*s:1+(j-1)*s+f-1, :);            
            % Element-wise Muliplication => Products
            scalar = win .* din;            
			% Sum (Sum of Products): Adder tree
            out(i,j,k) = sum(scalar(:));
        end
    end
end

end