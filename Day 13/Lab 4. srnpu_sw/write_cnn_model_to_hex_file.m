clc
clear all
close all

addpath('util');
outdir = 'output_hex_file';

%% Define model
model_name = 'sim_espcn_3x3';       % Class
%model_name = 'ssai2021';           % Final project

%% Load the test vector
load(sprintf('test_vector_%s.mat', model_name));

%% Write a test image
input = test_vector{1,1};
buf = input';     % Transpose
%buf = input;     % 
buf  = buf(:);
% 8-bit format
fid = fopen(sprintf('%s/%s/butterfly_08bit.hex',outdir, model_name),'wt');
fprintf(fid,'%x\n',buf);
fclose(fid);
% 32-bit format
fid = fopen(sprintf('%s/%s/butterfly_32bit.hex',outdir, model_name),'wt');
fprintf(fid,'%08x\n',buf);
fclose(fid);


%% Save the CNN model
n_layers = size(test_vector,1)-2;  
bitwidth = 128; 
Ti = 16;    % A CONV kernel computes 16 products at the same time (conv_kern.v)
To = 16;    % Run 16 CONV kernels at the same time (cnn_accel.v)

fid_all_weights     = fopen(sprintf('%s/%s/all_conv_weights.hex',outdir,model_name),'wt');
fid_all_biases      = fopen(sprintf('%s/%s/all_conv_biases.hex',outdir,model_name),'wt');
fid_all_scales      = fopen(sprintf('%s/%s/all_conv_scales.hex',outdir,model_name),'wt');  

fprintf('The model is %s !!!\n\n', model_name);
for i = 1:n_layers
    fprintf('Exporting layer %d .......... ',i);
    conv_weights     = test_vector{i,2};
    conv_biases      = test_vector{i,3};
    conv_scales      = test_vector{i,4};
    conv_output      = test_vector{i,7};
    
    fid_weights     = fopen(sprintf('%s/%s/conv_weights_L%d.hex',outdir,model_name,i),'wt');
    fid_biases      = fopen(sprintf('%s/%s/conv_biases_L%d.hex',outdir,model_name,i),'wt');
    fid_scales      = fopen(sprintf('%s/%s/conv_scales_L%d.hex',outdir,model_name,i),'wt');    
    fid_convout     = fopen(sprintf('%s/%s/convout_L%d.hex',outdir,model_name,i),'wt');    
    %% Weights
    if(i == 1) % first layer
        export_weight_to_file_merge(conv_weights, Ti, To, fid_weights, bitwidth);
    else
        export_weight_to_file_reorder(conv_weights, Ti, To, fid_weights, bitwidth);
    end
    
    %% Biases
    oc      = size(conv_biases,1);
    oc_new  = oc;
    if mod(oc_new, To) ~= 0
        oc_new  = floor(oc/To)*To+To;
    end
    conv_biases_tmp = zeros(oc_new,1);
    conv_biases_tmp(1:oc,1) = conv_biases;
    conv_biases = conv_biases_tmp;
    
    conv_biases(conv_biases<0) = conv_biases(conv_biases<0) + 2^16;    
    conv_biases = uint16(conv_biases);
    
    fprintf(fid_biases,'%04x\n',conv_biases);    
    
    %% Scales
    oc      = size(conv_scales,1);
    oc_new  = oc;
    if mod(oc_new, To) ~= 0
        oc_new  = floor(oc/To)*To+To;
    end
    conv_scales_tmp = zeros(oc_new,1);
    conv_scales_tmp(1:oc,1) = conv_scales;
    conv_scales = conv_scales_tmp;
    
    conv_scales = uint16(conv_scales);    
    fprintf(fid_scales,'%04x\n',conv_scales);
    
    %% Output
    save_convout_8b(conv_output, To, fid_convout, bitwidth);
    
    fclose(fid_weights);
    fclose(fid_biases);
    fclose(fid_scales);
    fclose(fid_convout);
    
    %% Merge all layers
    if(i == 1) % first layer
        export_weight_to_file_merge(conv_weights, Ti, To, fid_all_weights, bitwidth);
    else
        export_weight_to_file_reorder(conv_weights, Ti, To, fid_all_weights, bitwidth);
    end    
    fprintf(fid_all_biases,'%04x\n',conv_biases); 
    fprintf(fid_all_scales,'%04x\n',conv_scales);
    
    fprintf('done!\n');
end

fclose(fid_all_weights);
fclose(fid_all_biases);
fclose(fid_all_scales);