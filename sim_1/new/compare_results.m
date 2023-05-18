fname_vector = 'test_vectors_LP_w03_o8.txt';
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

test_fi = vector_fi(1:(size1/2+1)-1);

figure(1);
subplot(2,1,1);
plot(reference_fi);
hold on
plot(result_fi);
xlim([0 array_size]);
ylim([-1.25 1.25]);
hold off
legend('Referenční model','Navržený filtr');
xlabel('Vzorek [-]');
ylabel('Amplituda [-]');
title('Referenční model & navržený filtr');

% subplot(3,1,2);
% plot(result_fi);
% xlabel('vzorek [-]');
% ylabel('amplituda [-]');
% title('můj filtr');

subplot(2,1,2);
plot((result_fi-reference_fi)/fi((1/2^c_len_frac),true,c_data_w, c_len_frac));
xlim([0 array_size]);
yticks([-1 0 1]);
xlabel('Vzorek [-]');
ylabel('Bity [-]');
title('Rozdíl');
% position and size: 0.13,0.275,0.775,0.15


figure(2);
plot(test_fi);
xlim([0 array_size]);
xlabel('Vzorek [-]');
ylabel('Amplituda [-]');
title('Simulus');