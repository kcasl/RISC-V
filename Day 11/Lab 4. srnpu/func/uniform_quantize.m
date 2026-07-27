% Function: Symetric Uniform quantization
% Inputs
%	- x: 	input tensor
%	- step: quantized step 
%	- nbit: number of bits in fixed-point representation
% Outputs
%	- output: Quantized value mapping to x
%	- output_store: Store value

function [output, output_store] = uniform_quantize(x,step,nbit)
% Initialization
output = x;
output_store = x;

% Insert your code
% Maximum and minimum ranges
pos_end = 2 ^ nbit - 1;
neg_end = -pos_end;

% Quantized value
output = 2 * round(x./step + 0.5) - 1;
output(output > pos_end) = pos_end;
output(output < neg_end) = neg_end;

output_store = (output - 1) / 2;