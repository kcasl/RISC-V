clc 
clear all
close all

addpath('util');
up_scale = 2;

%% Load images
im_gnd = imread('output/out_img_org.bmp');
im_bic = imread('output/out_img_bic.bmp');
im_espcn3x3 = imread('output/out_img_sim_espcn_3x3.bmp');
im_ssai2021= imread('output/out_img_ssai2021.bmp');

%% Remove borders
im_gnd_crop         = shave(im_gnd,[up_scale,up_scale]);
im_bic_crop         = shave(im_bic,[up_scale,up_scale]);
im_espcn3x3_crop    = shave(im_espcn3x3,[up_scale,up_scale]);
im_ssai2021_crop    = shave(im_ssai2021,[up_scale,up_scale]);

%% Compute PSNR
[psnr_bic     , mae_bic]       = compute_psnr(im_gnd_crop,im_bic_crop);
[psnr_espcn3x3, mae_espcn3x3]  = compute_psnr(im_gnd_crop,im_espcn3x3_crop);
[psnr_ssai2021, mae_ssai2021]  = compute_psnr(im_gnd_crop,im_ssai2021_crop);

figure(1), 
subplot(2,2,1),imshow(im_gnd); title('Original ');
subplot(2,2,2),imshow(im_bic); title(sprintf('Bicubic (%.2f dB)', psnr_bic));
subplot(2,2,3),imshow(im_espcn3x3); title(sprintf('ESPCN (%.2f dB) ',psnr_espcn3x3));
subplot(2,2,4),imshow(im_ssai2021); title(sprintf('SSAI (%.2f dB) ',psnr_ssai2021));