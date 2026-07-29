% Function: Activation quantization
% Inputs
%	- x: 	input tensor
%	- step: quantized step 
%	- nbit: number of bits in fixed-point representation
%	- biases_shift
% Outputs
%	- activations: Quantized value mapping to x
%	- activations_store: Store value

function [activations, activations_store] = hwu_linear_quantize(x, step, nbit, biases_shift)
% Initialization
activations = x;
activations_store = x;

% Insert your code

neg_end = -2^(nbit-1);
pos_end = 2^(nbit-1)-1;

activations_store = round(x / (2^biases_shift * step));

activations_store(activations_store > pos_end) = pos_end;
activations_store(activations_store < neg_end) = neg_end;

activations = activations_store;

end