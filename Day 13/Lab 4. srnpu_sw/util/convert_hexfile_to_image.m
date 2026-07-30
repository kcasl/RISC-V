function image = convert_hexfile_to_image(file_name, h, w, c, To, nbit) %128,128,64,64, (8 or 16)

assert((nbit == 8) || (nbit == 16), 'nbit must be 8 or 16')
m = nbit / 4;

fileID = fopen(file_name);
image = zeros(h, w, c);

image_tmp = [];

tline = fgetl(fileID); % get first line
n_char = numel(tline) / m; % number of image values, not number of string chars
image_line = zeros(n_char,1);
for i = 1:n_char
    image_line(i) = hex2dec(tline(i*m-m+1:i*m)); % convert text hex to dec
end
image_tmp = [image_tmp, image_line(end:-1:1)];

while ischar(tline) % keep getting line and converting things
    tline = fgetl(fileID);
    if numel(tline) < n_char * m
        break;
    end
    image_line = zeros(n_char,1);
    for i = 1:n_char
        image_line(i) = hex2dec(tline(i*m-m+1:i*m));
    end
    image_tmp = [image_tmp, image_line(end:-1:1)];
end

fclose(fileID);

% this is copied from save_convout_8b.m
% the reverse process

No = c/To;
if mod(c,To) ~= 0
    No = 1 + floor(c/To);
end

ii = 0;
count = 0;
for row = 1:h
    for no = 1:No
        for col = 1:w
            for o = (no-1)*To+1:1:(no-1)*To+To
                if o > c
                    ii = ii + 1; %skip unused
                else
                    ii = ii + 1;
                    % use single index
                    % even though image_tmp is 2D
                    % thus, make sure image_tmp is created by column vector concat
                    image(row,col,o) = image_tmp(ii);
                end
            end
        end
    end
end