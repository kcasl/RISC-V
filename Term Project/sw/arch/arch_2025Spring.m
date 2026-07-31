architecture = { ...
    {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_7_0, ps.wts_scale_linear_8, ps.scales_16_4_1, ps.biases_16_8_1}; ... %    0  L1 3x3 1->16
    {'conv', 0, ps.conv_f1_p0_s1,   16,  ps.act_relu_8_7_0, ps.wts_scale_linear_8, ps.scales_16_4_1, ps.biases_16_8_1}; ... %    1  L2 1x1 16->16
    {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_7_0, ps.wts_scale_linear_8, ps.scales_16_4_1, ps.biases_16_8_1}; ... %    2  L3 3x3 16->16
    {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_7_0, ps.wts_scale_linear_8, ps.scales_16_4_1, ps.biases_16_8_1}; ... %    3  L4 3x3 16->16
    {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_7_0, ps.wts_scale_linear_8, ps.scales_16_4_1, ps.biases_16_8_1}; ... %    4  L5 3x3 16->16
    {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_7_0, ps.wts_scale_linear_8, ps.scales_16_4_1, ps.biases_16_8_1}; ... %    5  L6 3x3 16->16
    {'conv', 0, ps.conv_f1_p0_s1,   16,  ps.act_relu_8_8_0, ps.wts_scale_linear_8, ps.scales_16_4_1, ps.biases_16_8_1}; ... %    6  L7 1x1 16->16
    {'conv', 0, ps.conv_f3_p2_s1,    4,  ps.act_lineq_8_8_1, ps.wts_scale_linear_8, ps.scales_16_4_1, ps.biases_16_8_1};... %    7  L8 3x3 16->4
    {'sr_flat'};   % sub-pixel rearrange 4ch -> 2x2
    {'lp_sres'};   % residual add with upsampled LR input
};