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