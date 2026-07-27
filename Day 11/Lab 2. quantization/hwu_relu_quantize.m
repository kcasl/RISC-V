% Function: Activation quantization
% Inputs
%	- x: 	input tensor
%	- step: quantized step 
%	- nbit: number of bits in fixed-point representation
%	- biases_shift
% Outputs
%	- activations: Quantized value mapping to x
%	- activations_store: Store value

function [activations, activations_store] = hwu_relu_quantize(x, step, nbit, biases_shift)
% Initialization
activations = x;
activations_store = x;

% Insert your code
