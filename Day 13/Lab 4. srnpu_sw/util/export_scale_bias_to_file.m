function export_scale_bias_to_file(scale_bias_string, file_id, bitwidth, To)

oc = size(scale_bias_string,1);
oc_new = oc;
if mod(oc_new, To) ~= 0
    oc_new = To*(floor(oc_new/To)+1);
end

lines = [];
scale_bias_per_line = bitwidth/32;
No = oc_new/scale_bias_per_line; %Number of lines
if mod(oc_new,scale_bias_per_line) ~= 0
    No = floor(No)+1;
end

for no = 1:No %256-bit = 8
    line = '';
    for j = scale_bias_per_line:-1:1
       if (no-1)*scale_bias_per_line+j > oc
          line = [line, '00000000'];
       else
          line = [line,scale_bias_string((no-1)*scale_bias_per_line+j,:)];
       end
     end
     lines = [lines;line];
end
for j = 1:size(lines,1);
    fprintf(file_id,'%s\n',lines(j,:));
end