%%This function generates saves weights of conv layers that has #channels < Ti, To
function export_weight_to_file_reorder(weight, Ti, To, file_id, bitwidth)

weight = (weight - 1) / 2;
weight(weight < 0) = weight(weight < 0) + 256;

f1 = size(weight,1);
f2 = size(weight,2);
ci = size(weight,3);
co = size(weight,4);

line_size = bitwidth/4;

weight_line = [];

Ni = ci/Ti;
if mod(ci,Ti) ~= 0
    Ni = 1 + floor(ci/Ti);
end
No = co/To;
if mod(co,To) ~= 0
    No = 1 + floor(co/To);
end

no = 1;
line = '';
while (no <= No)
    ni = 1;
    while (ni <= Ni)
        for ii = 1:f1
            for jj = 1:f2
                for o = (no - 1)*To + 1 : no*To
                    for i =  (ni - 1)*Ti + 1 : ni*Ti
                        if i > ci || o > co
                            w = '00';
                        else
                            w = dec2hex(weight(ii,jj,i,o),2);
                        end
                        line = strcat(w,line); %w0, w1,...,w9,w0,w1...
                        if length(line) == line_size
                            weight_line = [weight_line; line];
                            line = '';
                        end
                    end
                end
            end
        end
        ni = ni + 1;
    end
    no = no + 1;
end

nline = size(weight_line,1);
for i = 1:size(weight_line)
    fprintf(file_id,'%s\n',weight_line(i,:));
end
