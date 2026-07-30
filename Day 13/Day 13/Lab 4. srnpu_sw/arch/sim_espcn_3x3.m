if OPTION_USE_SCALE_LINEAR == 1
    architecture = { ...
        {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_8_0 , ps.wts_scale_linear_8, ps.scales_16_1_1, ps.biases_16_10_1}; ... %    0
        {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_8_0 , ps.wts_scale_linear_8, ps.scales_16_1_1, ps.biases_16_10_1}; ... %    1
        {'conv', 0, ps.conv_f3_p2_s1,    4,  ps.act_lineq_8_8_1, ps.wts_scale_linear_8, ps.scales_16_1_1, ps.biases_16_10_1}; ... %    2
        {'sr_flat'};
        {'lp_sres'};
    };
else
    architecture = { ...
        {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_8_0 , ps.wts_uniform_8_8_1, ps.scales_16_1_1, ps.biases_16_10_1}; ... %    0
        {'conv', 0, ps.conv_f3_p2_s1,   16,  ps.act_relu_8_8_0 , ps.wts_uniform_8_8_1, ps.scales_16_1_1, ps.biases_16_10_1}; ... %    1
        {'conv', 0, ps.conv_f3_p2_s1,    4,  ps.act_lineq_8_8_1, ps.wts_uniform_8_8_1, ps.scales_16_1_1, ps.biases_16_10_1}; ... %    2
        {'sr_flat'};
        {'lp_sres'};
    };
end

cutpoint = inf;