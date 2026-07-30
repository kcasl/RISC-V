%%This function generates saves weights of conv layers that has #channels < Ti, To
function export_weight_dw_to_file(weight, Ti, To, file_id, bitwidth)

weight = (weight - 1) / 2;
weight(weight < 0) = weight(weight < 0) + 256;

f1 = size(weight,1);
f2 = size(weight,2);
ci = size(weight,3);


line_size = bitwidth/4;

weight_line = [];

Ni = ci/Ti;
if mod(ci,Ti) ~= 0
    Ni = 1 + floor(ci/Ti);
end

no = 1;
line = '';
    ni = 1;
    while (ni <= Ni)
            for i =  (ni - 1)*Ti + 1 : ni*Ti
                for ii = 1:f1
                    for jj = 1:f2
                        if i > ci
                            w = '00';
                        else
                            w = lower(dec2hex(weight(ii,jj,i),2));
                        end
                        line = strcat(w,line); %w0, w1,...,w9,w0,w1...
                        if length(line) == line_size
                            weight_line = [weight_line; line];
                            line = '';
                        end
                    end
                end
            end
        ni = ni + 1;
    end

nline = size(weight_line,1);
for i = 1:size(weight_line)
    fprintf(file_id,'%s\n',weight_line(i,:));
end
