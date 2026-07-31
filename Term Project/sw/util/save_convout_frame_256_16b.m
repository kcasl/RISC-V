function save_convout_frame_256_16b(conv_out, To, file_id)
    [h,w,c] = size(conv_out);
    No = c/To;
    if mod(c,To) ~= 0
        No = 1 + floor(c/To);
    end
    
    conv_out(conv_out < 0) = conv_out(conv_out < 0) + 2^16;
    output_lines = [];
    
    %Save partial-output line-by-line
    for no = 1:No
        for row = 1:h
            for col = 1:w
                line = '';
                for o = (no-1)*To+To/2 :-1:(no-1)*To+1
                    if o > c
                        output = '0000';
                    else
                        output = lower(dec2hex(conv_out(row,col,o),4));
                    end
                    line = strcat(line, output);
                end
                output_lines = [output_lines; line];
                line = '';
                for o = no*To :-1:(no-1)*To+To/2+1
                    if o > c
                        output = '0000';
                    else
                        output = lower(dec2hex(conv_out(row,col,o),4));
                    end
                    line = strcat(line, output);
                end
                output_lines = [output_lines; line];
            end
        end
    end
    
    for i = 1:size(output_lines)
        fprintf(file_id, '%s\n', output_lines(i,:));
    end
end
                    
        
    
    