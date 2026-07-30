function save_convout_frame_8b(conv_out, To, file_id, bitwidth)
    [h,w,c] = size(conv_out);
    No = c/To;
    if mod(c,To) ~= 0
        No = 1 + floor(c/To);
    end
    line_size = bitwidth/4;
    
    conv_out(conv_out < 0) = conv_out(conv_out < 0) + 2^8;
    output_lines = [];
    
    line = '';
    %Save partial-output line-by-line
    for no = 1:No
        for row = 1:h
            for col = 1:w
                line = '';
                for o = (no-1)*To+1:1:(no-1)*To+To
                    if o > c
                        output = '00';
                    else
                        output = lower(dec2hex(conv_out(row,col,o),2));
                    end
                    line = strcat(output,line);
                    if(length(line) == line_size)
                        output_lines = [output_lines; line];
                        line = '';
                    end
                end
            end
        end
    end
    
    for i = 1:size(output_lines)
        fprintf(file_id, '%s\n', output_lines(i,:));
    end
end
                    
        
    
    