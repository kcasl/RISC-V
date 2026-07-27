function save_convout_consecutive(conv_out, bitwidth, file_dir, file_exist)
    [h,w,c] = size(conv_out);
    line_size = bitwidth/4;
%     conv_out(conv_out < 0) = conv_out(conv_out < 0) + 256;
    output_lines = [];
    
    %Save partial-output line-by-line
    line = '';
    for row = 1:h
            for col = 1:w
                pixel = '00';
                for o = c:-1:1
                    output = lower(dec2hex(conv_out(row,col,o),2));
                    pixel = strcat(pixel, output);
                end
                line = strcat(pixel, line);
                if(length(line) == line_size)
                    output_lines = [output_lines; line];
                    line = '';
                end
            end
    end
    
    if (file_exist == 0) %Write to new file
        output_file = fopen(file_dir,'w');
        for i = 1:size(output_lines)
            fprintf(output_file, '%s\n', output_lines(i,:));
        end
        fclose(output_file);
    else % Write to existen file
        for i = 1:size(output_lines)
            fprintf(file_dir, '%s\n', output_lines(i,:));
        end
    end
end
                    
        
    
    