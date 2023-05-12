fname_vector = 'test_vectors_HP_w03_o8.txt';
fname_result = (strcat('result_of_',fname_vector));
fID_vector = fopen(fname_vector, 'r');
fID_result = fopen(fname_result, 'r');
c_data_w = 16;
c_len_frac = 13;

line1 = fgetl(fID_vector); % skip the first line

array_size = str2double(line1);

cnt_data = 1;

[vector, size1] = fscanf(fID_vector, '%s');
result = fscanf(fID_result, '%s');

vector_cell = breakupLine(vector, 16);
vector_str = string(vector_cell);
vector_dec = bin2dec(vector_str);
vector_int16 = uint16(vector_dec);

result_cell = breakupLine(result, 16);
result_str = string(result_cell);
result_dec = bin2dec(result_str);
result_int16 = uint16(result_dec);

vector_fi = reinterpretcast(vector_int16, numerictype(1, c_data_w, c_len_frac));

result_fi = reinterpretcast(result_int16, numerictype(1, c_data_w, c_len_frac));

reference_fi = vector_fi(size1/2+1:end);


figure(1);
subplot(2,1,1);
plot(reference_fi);
hold on
plot(result_fi);
xlim([0 array_size]);
hold off
legend('matlab','můj filtr');
xlabel('vzorek [-]');
ylabel('amplituda [-]');
title('matlab & můj filtr');

% subplot(3,1,2);
% plot(result_fi);
% xlabel('vzorek [-]');
% ylabel('amplituda [-]');
% title('můj filtr');

subplot(2,1,2);
plot((result_fi-reference_fi)/fi((1/2^c_len_frac),true,c_data_w, c_len_frac));
xlim([0 array_size]);
yticks([-1 0 1]);
xlabel('vzorek [-]');
ylabel('bity [-]');
title('rozdíl');