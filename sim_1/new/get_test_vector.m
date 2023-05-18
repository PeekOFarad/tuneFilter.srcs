fname_vector = 'test_vectors_BS_w03_07_o8.txt';
fname_pkg = 'filter_tb_BS_w03_07_o8_data.vhd';
fID_vector = fopen(fname_vector, 'wt');
fID_pkg = fopen(fname_pkg, 'r');

data = cell(10000,1);

line = fgetl(fID_pkg);
cnt_data = 1;
while ischar(line)
    n = extractBetween(line, 'X"', '"');
    
    if not(isempty(n))
        hNum = hex2dec(n);
        bNum = dec2bin(hNum,16);
        data(cnt_data+1,1) = cellstr(bNum);
        cnt_data = cnt_data + 1;
    end
    line = fgetl(fID_pkg);
end


data(1,1) = cellstr(num2str((cnt_data - 1)/2));


for i=1:cnt_data
    if i == cnt_data
        fprintf(fID_vector, '%s', string(data(i,1)));
    else
        fprintf(fID_vector, '%s\n', string(data(i,1)));
    end
end

fclose('all');