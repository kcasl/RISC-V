% darknet on HW simulation: new version 20200224
% define your own things inside _USER_DEFINE_ and _USER_DEFINE_END_ field
% compulsory:
%       model_prefix
%       architecture
% optional:
%       preset
%-------preparing--------
clear;
close all;
clc;

addpath('arch');
addpath('func');
addpath('util');
% _USER_DEFINE_------------------------------------------------------------------------------------------------------------------------
%--------options---------
% support dynamic fixed-point for scales and biases
OPTION_AUTO_FORMAT_SCALES       = 1;
OPTION_AUTO_FORMAT_BIASES       = 1;
OPTION_USE_SCALE_LINEAR         = 1;  % Use linear-scale Quantization

%-----specification------
model_name = 'sim_espcn_3x3';    % Class
%model_name = 'ssai2021';        % Final project

model_prefix = ['bin/',model_name,'.weights_layer_'];
export_fname = ['export_data/',model_name,'.txt'];
up_scale = 2;

imname = 'butterfly_GT';
image_name = 'img\butterfly_GT.BMP';
net_w = 128;
net_h = 128;

% predefined presets from file
run('load_preset');
%------architecture-------
% structure
% {'conv', batchnorm, convol_preset, output_channels, activation_preset, wts_preset, scales_preset, biases_preset};
% {'route', layer_id, ...};
% {'sres'};
% {'sr_flat'}
% {'lp_sres'};

% predefined in a file with the same name, please check out
run(model_name)
input_input_channels = 1; % vdsr

%_USER_DEFINE_END_--------------------------------------------------------------------------------------------------------------------

%----preprocessing----
all_input_channels = hwu_parse_input_channels(architecture, input_input_channels);

%------buffering------
fprintf('[ INFO ] parse and create output buffers\n');
[STAT, output_buffer] = hwu_parse_and_create_buffer(architecture);

%--------param--------
fprintf('[ INFO ] parse and load params\n');
n_layer = numel(architecture);
weights = cell(n_layer, 1);
scales = cell(n_layer, 1);
biases = cell(n_layer, 1);

% Export data 
do_export = 0;
bitwidth = 128;
Ti = 16;
To = 16;
if (do_export)
    export_file = fopen(export_fname, 'w');
end

for i = 1:n_layer
    switch architecture{i}{1}
        case 'conv'
            [batchnorm, convol_settings, output_channels, ~, weights_settings] = architecture{i}{2:6};
            [kernel_size, ~, ~] = convol_settings{:};
            wts_scheme = weights_settings{1};
            
            input_channels = all_input_channels(i);
            param_file = [model_prefix num2str(i-1)];
            
            % Load weights, biases and scales from files
            [weightx, bias, scale, rolling_mean, rolling_var] = read_conv_param_module(param_file, kernel_size, input_channels, output_channels, batchnorm);
            
            % Quantization
            if strcmp(wts_scheme, 'none')
                weight = weightx;
                w_bonus_scale_factor = ones(output_channels,1);
            elseif strcmp(wts_scheme, 'uniform')
                [wts_nbit, wts_fbit, ~] = weights_settings{2:end};
                wts_step = 2^-wts_fbit;
                [weight, ~] = uniform_quantize(weightx, wts_step, wts_nbit);
                w_bonus_scale_factor = ones(output_channels,1);
            elseif strcmp(wts_scheme, 'scale_linear')
                wts_nlevel = 2^weights_settings{2};
                [weight, w_bonus_scale_factor] = scale_linear_quantize(weightx, output_channels, wts_nlevel/2);
            elseif strcmp(wts_scheme, 'scale_linear_float')
                wts_nlevel = 2^weights_settings{2};
                [weight, w_bonus_scale_factor] = scale_linear_quantize_float(weightx, output_channels, wts_nlevel/2);
            end
            
            weights{i} = permute(reshape(weight, kernel_size, kernel_size, input_channels, output_channels), [2, 1, 3, 4]);
            if (batchnorm)
                scales_new = w_bonus_scale_factor .* scale ./ sqrt(rolling_var + 0.00001);
                if (i == 1)
                    scales_new = scales_new / 255.;
                end
                biases_new = bias - scale .* rolling_mean ./ sqrt(rolling_var + 0.00001);
            else
                scales_new = w_bonus_scale_factor .* ones(output_channels, 1);
                if (i == 1)
                    scales_new = scales_new / 255.;
                end
                biases_new = bias;
            end
            
            [scales_settings, biases_settings] = architecture{i}{7:8};
            scales_nbit = scales_settings{1};
            biases_nbit = biases_settings{1};

            if scales_nbit > 0
                if OPTION_AUTO_FORMAT_SCALES
                    [fbit, sign] = hwu_auto_format(scales_new, scales_nbit);
                    architecture{i}{7} = {scales_nbit scales_nbit-fbit sign};
                end
            end
            if biases_nbit > 0
                if OPTION_AUTO_FORMAT_BIASES
                    [fbit, sign] = hwu_auto_format(biases_new, biases_nbit);
                    architecture{i}{8} = {biases_nbit biases_nbit-fbit sign};
                end
            end
            
            [scales_settings, biases_settings] = architecture{i}{7:8};
            [scales_ibit, scales_sign] = scales_settings{2:3};
            [biases_ibit, biases_sign] = biases_settings{2:3};

            [scales{i}, scale_string] = quantize_and_constrain2(scales_new, scales_nbit, scales_ibit, scales_sign, 1, type_hex);
            [biases{i}, bias_string] = quantize_and_constrain2(biases_new, biases_nbit, biases_ibit, biases_sign, 1, type_hex);
            
            %export data to HW
            if (do_export == 1)
                fprintf('Exporting layer %d ...\n', i-1);
                if(i == 1) % first layer
                    export_weight_to_file_merge(weights{i}, Ti, To, export_file, bitwidth);
                else
                    export_weight_to_file_reorder(weights{i}, Ti, To, export_file, bitwidth);
                end
                scale_bias_string = [scale_string,bias_string];
                export_scale_bias_to_file(scale_bias_string, export_file, bitwidth, To);
            end
        %===============================================================================
        case 'sr_flat'
        case 'lp_sres'
        otherwise
            fprintf('[FAILED] unknown layer type\n');
            break;
    end
end

[bit_shift, output_fbit] = hwu_calculate_bit_shift(architecture, 8, 0);

%-------cleanup-------
clear wts_step wts_scheme wts_nbit wts_fbit weightx weights_settings weight weight_store ...
    scales_settings scales_nbit scales_ibit scales_sign scale scales_store scales_new ...
    rolling_mean rolling_var ...
    bias biases_settings biases_nbit biases_ibit biases_sign biases_new biases_store ...
    all_input_channels param_file ...
    convol_settings input_channels kernel_size pad stride ...
    output_channels layer_id n_input_layer i j batchnorm ...
    fbit sign

%% work on illuminance only
im = imread(image_name);
input_img =  modcrop(im, up_scale);
input_img =  single(input_img)/255;
input_img = imresize(input_img, 1/up_scale, 'bicubic');
if size(im,3) > 1
    im_ycbcr = rgb2ycbcr(im);
    im = im_ycbcr(:,:,1);
end
im_gnd = modcrop(im, up_scale);
im_gnd = single(im_gnd)/255;
im_l = imresize(im_gnd, 1/up_scale, 'bicubic');

input = floor(im_l(:,:,1) * 255);

outdir = 'export_data';
if(do_export)
    save_convout_consecutive(input, bitwidth, export_file, 1);
    fclose(export_file);
end
do_export = 0;

%% Inference
test_vector = cell(n_layer, 7);
OUTPUT.all_lp_sres = cell(STAT.n_lp_sres, 2);
dlp = 0;

fprintf('[ INFO ] forwarding\n');
run_upto = inf;
for i = 1:n_layer
    if i > run_upto
        break;
    end
    fprintf('[ INFO ] layer %3d (%8s)\n', i-1, architecture{i}{1});
    switch architecture{i}{1}
        case 'conv'
            [convol_settings, output_channels, act_settings, ~, scales_settings, biases_settings] = architecture{i}{3:8};
            [kernel_size, pad, stride] = convol_settings{:};
            activation = act_settings{1};
            [scales_nbit, scales_ibit, scales_sign] = scales_settings{:};
            [biases_nbit, biases_ibit, biases_sign] = biases_settings{:};
            scales_fbit = scales_nbit - scales_ibit;
            biases_fbit = biases_nbit - biases_ibit;
            
            %auto format info
            scales_sign_str = '  ';
            if scales_sign
                scales_sign_str = '+-';
            end
            biases_sign_str = '  ';
            if biases_sign
                biases_sign_str = '+-';
            end
            
            %fprintf('\b (scale %s%02d.%02d) (biases %s%02d.%02d) (bias_shift = %02d act_shift = %02d)\n', scales_sign_str, scales_ibit-scales_sign, scales_fbit, biases_sign_str, biases_ibit-biases_sign, biases_fbit,bit_shift(i),);
            %auto format info
            
            weight = weights{i};
            
            conv_out = convol2(input, weight, stride, pad);
            for j = 1:size(conv_out, 3)
                conv_out(:,:,j) = conv_out(:,:,j) .* scales{i}(j);
                conv_out(:,:,j) = floor(conv_out(:,:,j) / 2^bit_shift(i)); %if floating point is used, this line should be commented
                conv_out(:,:,j) = conv_out(:,:,j) + biases{i}(j);
            end
            
            if strcmp(activation, 'float_relu')
                output = hwu_float_relu_activate(conv_out);
            elseif strcmp(activation, 'relu')
                [act_nbit, act_fbit] = act_settings{2:3};
                act_step = 2^-act_fbit;
                [output, ~] = hwu_relu_quantize(conv_out, act_step, act_nbit, biases_fbit);
                for j = 1:size(output, 3)
                    fmap = uint8(output(:,:,j));
                    imwrite(fmap,sprintf('%s/%s/ofmap_L%02d_ch%02d.bmp',outdir,model_name,i,j));
                end
            elseif strcmp(activation, 'line_q')
                [act_nbit, act_fbit] = act_settings{2:3};
                act_step = 2^-act_fbit;
                [output, ~] = hwu_linear_quantize(conv_out, act_step, act_nbit, biases_fbit);
                for j = 1:size(output, 3)
                    fmap = output(:,:,j);
                    fmap(fmap<0) = fmap(fmap<0)+ 256;
                    fmap = uint8(fmap);
                    imwrite(fmap,sprintf('%s/%s/ofmap_L%02d_ch%02d.bmp',outdir,model_name,i,j));
                end                
            else
                output = conv_out;
            end
            weight_store = (weight-1)/2;
            weight_store(weight_store<0) = weight_store(weight_store<0) + 256;
            test_vector{i,1} = input;
            test_vector{i,2} = weight;
            test_vector{i,3} = biases{i};
            test_vector{i,4} = scales{i};
            test_vector{i,5} = bit_shift(i);
            test_vector{i,6} = biases_fbit-act_fbit;
            test_vector{i,7} = output;            
            input = output;
            fprintf('\b (scale %s%02d.%02d) (biases %s%02d.%02d) (bias_shift = %02d act_shift = %02d)\n', scales_sign_str, scales_ibit-scales_sign, scales_fbit, biases_sign_str, biases_ibit-biases_sign, biases_fbit,bit_shift(i),biases_fbit-act_fbit);                  
        %===============================================================================
        case 'sr_flat'
            [output, u] = flatten_sres(input);
            input = output;
        case 'lp_sres'
            dlp = dlp + 1;
            OUTPUT.all_lp_sres{dlp,1} = i-1;
            OUTPUT.all_lp_sres{dlp,2} = input;
        otherwise
            fprintf('[FAILED] unknown layer type\n');
            break;
    end
    
    % save output buffer
    if output_buffer{i, 1}
        output_buffer{i, 2} = output;
    end
end

assert(i == n_layer, ['[ STOP ] intended debugging, stopped at layer ' num2str(i)]);
    
%---post_processing---
x_img = im2double(imread(image_name));
x_img = rgb2ycbcr(x_img);
im_gnd = x_img(:,:,1);
% Bicubic interpolation
im_b = imresize(im_l, up_scale, 'bicubic');
% CNN method
if STAT.n_lp_sres > 0
    for i = 1:STAT.n_lp_sres
        highres_img = rgb2ycbcr(upsample_2x_3d(input_img));
        add_image = OUTPUT.all_lp_sres{i,2} / 2^output_fbit(OUTPUT.all_lp_sres{i,1});
        highres_img(:,:,1) = add_image + highres_img(:,:,1);

        im_h = highres_img(:,:,1);
        highres_img = ycbcr2rgb(highres_img);
%         imshow(highres_img);
    end
end

%% remove border
outdir = 'output';
imwrite(im_gnd,fullfile(outdir,'out_img_org.bmp'));
imwrite(im_l,fullfile(outdir,'out_img_low.bmp'));
imwrite(im_b,fullfile(outdir,'out_img_bic.bmp'));
imwrite(im_h,fullfile(outdir,sprintf('out_img_%s.bmp',model_name)));
im_h = shave(uint8(im_h * 255), [up_scale, up_scale]);
im_gnd = shave(uint8(im_gnd * 255), [up_scale, up_scale]);
im_b = shave(uint8(im_b * 255), [up_scale, up_scale]);

%% compute PSNR
[psnr_bic, mae_bic] = compute_psnr(im_gnd,im_b);
[psnr_srcnn,mae_srcnn] = compute_psnr(im_gnd,im_h);
figure(1), 
subplot(1,3,1),imshow(im_gnd); title('Original ');
subplot(1,3,2),imshow(im_b); title(sprintf('Bicubic (%.2f dB)', psnr_bic));
subplot(1,3,3),imshow(im_h); title(sprintf('SRCNN (%.2f dB) ',psnr_srcnn));
%% show results
fprintf('PSNR for Bicubic Interpolation: %0.2f dB\n', psnr_bic);
fprintf('PSNR for SRCNN Reconstruction: %0.2f dB\n', psnr_srcnn);

save(sprintf('test_vector_%s.mat',model_name),'test_vector');