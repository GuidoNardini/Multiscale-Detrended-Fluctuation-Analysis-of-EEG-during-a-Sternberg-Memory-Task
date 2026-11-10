clear
clc
close all

load("/OneDrive/H_sorted.mat");

% Creo 8 array 
S3_data = zeros (80, 24, 19, 5);
S4_data = zeros (80, 24, 19, 5);
S11_data = zeros (80, 48, 19, 5);
S11_S3data = zeros (80, 24, 19, 5);
S11_S4data = zeros (80, 24, 19, 5);
S12_data = zeros (80, 48, 19, 5);
S12_S3data = zeros (80, 24, 19, 5);
S12_S4data = zeros (80, 24, 19, 5);


for subject = 1:80
    field_name = sprintf('sub_%02d', subject);
    
    if isfield (H_sorted, field_name)
        S3_data(subject, :, :, :) = H_sorted.(field_name).S3;
        S4_data(subject, :, :, :) = H_sorted.(field_name).S4;
        S11_data(subject, :, :, :) = H_sorted.(field_name).S11;
        S11_S3data(subject, :, :, :) = H_sorted.(field_name).S11_S3;
        S11_S4data(subject, :, :, :) = H_sorted.(field_name).S11_S4;
        S12_data(subject, :, :, :) = H_sorted.(field_name).S_12;
        S12_S3data(subject, :, :, :) = H_sorted.(field_name).S_12_S3;
        S12_S4data(subject, :, :, :) = H_sorted.(field_name).S_12_S4;
    else
        disp(['Soggetto'  field_name  'mancante, saltato']);
    end
end

%Soggetti che hanno riportato problemi o non sono presenti nel dataset
soggetti_mancanti = [50, 51, 69];

S3_data(soggetti_mancanti, :, :, :) = [];
S4_data(soggetti_mancanti, :, :, :) = [];
S11_data(soggetti_mancanti, :, :, :) = [];
S11_S3data(soggetti_mancanti, :, :, :) = [];
S11_S4data(soggetti_mancanti, :, :, :) = [];
S12_data(soggetti_mancanti, :, :, :) = [];
S12_S3data(soggetti_mancanti, :, :, :) = [];
S12_S4data(soggetti_mancanti, :, :, :) = [];

datasets = {'S3_data', 'S4_data', 'S11_data', 'S11_S3data', 'S11_S4data', ...
            'S12_data', 'S12_S3data', 'S12_S4data'};

for i = 1:length(datasets)
    data = eval(datasets{i});
    data(data > 1) = NaN; % Sostituisce i valori > 1 con NaN
    eval([datasets{i} ' = data;']); % Salva di nuovo la variabile pulita
end

%% Trattamento dati con due metodi differenti
% VALORI MAGGIORI DI 1 RIPORTATI A 0.99

% S3_data(S3_data > 1) = 0.99;
% S4_data(S4_data > 1) = 0.99;
% S11_S3data(S11_S3data > 1) = 0.99;
% S11_S4data(S11_S4data > 1) = 0.99;
% S12_S3data(S12_S3data > 1) = 0.99;
% S12_S4data(S12_S4data > 1) = 0.99;

%SOSTITUITO I VALORI MAGGIORI DI 1 CON LA MEDIANA.
% med = median (S3_data(:));
% outliers = S3_data > 1;
% S3_data(outliers) = med;
% 
% med = median (S4_data(:));
% outliers = S4_data > 1;
% S4_data(outliers) = med;
% 
% med = median (S11_S3data(:));
% outliers = S11_S3data > 1;
% S11_S3data(outliers) = med;
% 
% med = median (S11_S4data(:));
% outliers = S11_S4data > 1;
% S11_S4data(outliers) = med;
% 
% med = median (S12_S3data(:));
% outliers = S12_S3data > 1;
% S12_S3data(outliers) = med;
% 
% med = median (S12_S4data(:));
% outliers = S12_S4data > 1;
% S12_S4data(outliers) = med;

% Medio sulle epoche
S3_mean = mean(S3_data, 2, 'omitnan');
S4_mean = mean(S4_data, 2, 'omitnan');
S11_mean = mean(S11_data, 2, 'omitnan');
S11_S3mean = mean(S11_S3data, 2, 'omitnan');
S11_S4mean = mean(S11_S4data, 2, 'omitnan');
S12_mean = mean(S12_data, 2, 'omitnan');
S12_S3mean = mean(S12_S3data, 2, 'omitnan');
S12_S4mean = mean(S12_S4data, 2, 'omitnan');

%% Test di Shapiro-Wilk (NB: i dati vengono tutti non normali)
for freq = 1:5
    % Test di Shapiro-Wilk per S3 e S4 per ogni frequenza
    [h_S3, ~] = swtest(S3_mean(:, freq));  
    [h_S4, ~] = swtest(S4_mean(:, freq));
    [h_S11, ~] = swtest(S11_mean(:, freq));
    [h_S11_S3, ~] = swtest(S11_S3mean(:, freq));
    [h_S11_S4, ~] = swtest(S11_S4mean(:, freq));
    [h_S12, ~] = swtest(S12_mean(:, freq));
    [h_S12_S3, ~] = swtest(S12_mean(:, freq));
    [h_S12_S4, ~] = swtest(S12_mean(:, freq));
    % [h_simple, ~] = swtest(simple(:,freq));
    % [h_difficult, ~] = swtest(difficult(:,freq));
end

%% Test per 19 canali (Wilcoxon)
p_values1 = zeros(19,5); % Matrice per salvare i p-values (19 canali x 5 frequenze)
p_values2 = zeros (19,5);
p_values3 = zeros (19,5);
% Estraggo i dati per ogni canale e frequenza
for ch = 1:19 
    for f = 1:5 
        S3_f_ch = squeeze(S3_mean(:,1,ch,f));
        S4_f_ch = squeeze(S4_mean(:,1,ch,f));
        S11_f_ch = squeeze(S11_mean(:,1,ch,f));
        S11_S3_f_ch = squeeze(S11_S3mean(:,1,ch,f));
        S11_S4_f_ch = squeeze(S11_S4mean(:,1,ch,f));
        S12_f_ch = squeeze(S12_mean(:,1,ch,f));
        S12_S3_f_ch = squeeze(S12_S3mean(:,1,ch,f));
        S12_S4_f_ch = squeeze(S12_S4mean(:,1,ch,f));

        %simple_f_ch = squeeze(simple(:,1,ch,f));
        %difficult_f_ch = squeeze(difficult(:,1,ch,f));

        % Test di Wilcoxon per ogni canale e frequenza
        p_values1(ch, f) = signrank(S3_f_ch, S4_f_ch); % S3 vs S4
        p_values2(ch, f) = signrank(S11_S3_f_ch, S11_S4_f_ch);
        p_values3(ch, f) = signrank(S12_S3_f_ch, S12_S4_f_ch);
        %p_values2(ch, f) = signrank(simple_f_ch, difficult_f_ch); %Fase semplice vs fase difficile
    end
end

p_values1_fdr = zeros(size(p_values1));
for h = 1:size(p_values1,2)
    p_values1_fdr(:,h)=mafdr(p_values1(:,h), 'BHFDR', true);
end

p_values2_fdr = zeros(size(p_values2));
for h = 1:size(p_values2, 2)
    p_values2_fdr(:,h)=mafdr(p_values2(:,h), 'BHFDR', true);
end

p_values3_fdr = zeros(size(p_values3));
for h = 1:size(p_values3, 2)
    p_values3_fdr(:,h)=mafdr(p_values3(:,h), 'BHFDR', true);
end

%% Carico un soggetto per EEGLAB per topoplot
file_path = '/OneDrive/Elaborato Neuroscienze/dataset1/ds004796-download/sub-01/eeg/sub-01_task-sternberg_eeg.vhdr_final.set';
EEG = pop_loadset('filename', file_path);
scale = {'8', '10', '12', '15', '20'};
% %% Topoplot Simple vs Difficult (inutile non si puo confrontare cose diverse!)
% for f = 1:5
%     figure; 
% 
%     % Estraggo i pvalues e calcolo il logaritmo
%     p_values_selected = p_values2(:,f);
%     topo_data = -log(p_values_selected);
%     log_05 = -log(0.05);
% 
%     % Controllo per verificare il numero di valori significativi
%     num_valid = sum(p_values_selected < 0.05);
%     if num_valid < 2
%         disp(['Troppi pochi dati significativi per DFA Freq ' num2str(f) ', salto il grafico.']);
%         close(gcf);
%         continue;
%     end 
% 
%     topoplot(topo_data, EEG.chanlocs, 'maplimits', [0, max(topo_data)], 'electrodes', 'on');
% 
%     num_colors = 10;
%     cmap = ones(num_colors, 3);  % Inizia tutto bianco
% 
%     % Verifica l'indice di 0.05 che separe i valori significativi da quelli
%     % non significativi
%     idx_05 = round(num_colors * (log_05 / max(topo_data)));
% 
%     cmap(idx_05+1:end, :) = [linspace(0, 0, num_colors-idx_05)' ...
%                              linspace(0.5, 0, num_colors-idx_05)' ...
%                              linspace(1, 0, num_colors-idx_05)'];       
% 
%     colormap(cmap);
%     % Definisco la colorbar con etichette
%     cb = colorbar;
%     tick_values = [0 log_05 max(topo_data)];
%     tick_labels = {'non significativo', '0.05', 'significativo'};
%     set(cb, 'Ticks', tick_values, 'TickLabels', tick_labels);
%     ylabel(cb, 'p-value', 'FontSize', 10);
% 
%     title(['DFA Freq ' num2str(f) ' - p-values']);
% end

%% Topoplot S3 vs S4
for f = 1:5
    figure; 

    % Estraggo i pvalues e calcolo il logaritmo
    p_values_selected = p_values1_fdr(:,f);
    topo_data = -log(p_values_selected);
    log_05 = -log(0.05); 
    
    % Controllo per verificare il numero di valori significativi
    num_valid = sum(p_values_selected < 0.05);
    if num_valid < 2
        disp(['Troppi pochi dati significativi per DFA Freq ' num2str(f) ', salto il grafico.']);
        close(gcf);
        continue;
    end 
   
    topoplot(topo_data, EEG.chanlocs, 'maplimits', [0, max(topo_data)], 'electrodes', 'on');
    
    num_colors = 10;
    cmap = ones(num_colors, 3);
    
    % Verifica l'indice di 0.05 che separe i valori significativi da quelli
    % non significativi
    idx_05 = round(num_colors * (log_05 / max(topo_data)));
    
    cmap(idx_05+1:end, :) = [linspace(0, 0, num_colors-idx_05)' ...
                             linspace(0.5, 0, num_colors-idx_05)' ...
                             linspace(1, 0, num_colors-idx_05)'];       
    
    colormap(cmap);
    
    % Definisco la colorbar con etichette
    cb = colorbar;
    tick_values = [0 log_05 max(topo_data)];
    tick_labels = {'non significativo', '0.05', 'significativo'};
    set(cb, 'Ticks', tick_values, 'TickLabels', tick_labels);
    ylabel(cb, 'p-value', 'FontSize', 10);
    
    title(['S3 vs S4; DFA scale' scale(f)], 'Interpreter', 'none' );
end
%% Topoplot S11_S3 vs S11_S4
for f = 1:5
    figure; 
    
    % Estraggo i pvalues e calcolo il logaritmo
    p_values_selected = p_values2_fdr(:,f);
    topo_data = -log(p_values_selected);
    log_05 = -log(0.05); 
    
    % Controllo per verificare il numero di valori significativi
    num_valid = sum(p_values_selected < 0.05);
    if num_valid < 2
        disp(['Troppi pochi dati significativi per DFA Freq ' num2str(f) ', salto il grafico.']);
        close(gcf);
        continue;
    end 
   
    topoplot(topo_data, EEG.chanlocs, 'maplimits', [0, max(topo_data)], 'electrodes', 'on');
    
    num_colors = 10;
    cmap = ones(num_colors, 3);
    
    % Verifica l'indice di 0.05 che separe i valori significativi da quelli
    % non significativi
    idx_05 = round(num_colors * (log_05 / max(topo_data)));
    
    cmap(idx_05+1:end, :) = [linspace(0, 0, num_colors-idx_05)' ...
                             linspace(0.5, 0, num_colors-idx_05)' ...
                             linspace(1, 0, num_colors-idx_05)'];       
    
    colormap(cmap);
    
    % Definisco la colorbar con etichette
    cb = colorbar;
    tick_values = [0 log_05 max(topo_data)];
    tick_labels = {'non significativo', '0.05', 'significativo'};
    set(cb, 'Ticks', tick_values, 'TickLabels', tick_labels);
    ylabel(cb, 'p-value', 'FontSize', 10);
    
    title(['S11_S3 vs S11_S4; DFA scale' scale(f)],'Interpreter', 'none' );
end
%% Topoplot S12_S3 vs S12_S4
for f = 1:5
    figure; 
    
    % Estraggo i pvalues e calcolo il logaritmo
    p_values_selected = p_values3_fdr(:,f);
    topo_data = -log(p_values_selected);
    log_05 = -log(0.05); 
    
    % Controllo per verificare il numero di valori significativi
    num_valid = sum(p_values_selected < 0.05);
    if num_valid < 2
        disp(['Troppi pochi dati significativi per DFA Freq ' num2str(f) ', salto il grafico.']);
        close(gcf);
        continue;
    end 
   
    topoplot(topo_data, EEG.chanlocs, 'maplimits', [0, max(topo_data)], 'electrodes', 'on');
    
    num_colors = 10;
    cmap = ones(num_colors, 3);
    
    % Verifica l'indice di 0.05 che separe i valori significativi da quelli
    % non significativi
    idx_05 = round(num_colors * (log_05 / max(topo_data)));
    
    cmap(idx_05+1:end, :) = [linspace(0, 0, num_colors-idx_05)' ...
                             linspace(0.5, 0, num_colors-idx_05)' ...
                             linspace(1, 0, num_colors-idx_05)'];       
    
    colormap(cmap);
    
    % Definisco la colorbar con etichette
    cb = colorbar;
    tick_values = [0 log_05 max(topo_data)];
    tick_labels = {'non significativo', '0.05', 'significativo'};
    set(cb, 'Ticks', tick_values, 'TickLabels', tick_labels);
    ylabel(cb, 'p-value', 'FontSize', 10);
    
    title(['S12_S3 vs S12_S4; DFA scale' scale(f)],'Interpreter', 'none');
end

%%
figure;
for f = 1:5
    subplot(1,5,f);
    % Prendo la media su tutti i canali (oppure scegli un canale, es. ch=5)
    s3 = squeeze(mean(S3_mean(:,1,:,f), 3)); 
    s4 = squeeze(mean(S4_mean(:,1,:,f), 3));
    
    boxplot([s3 s4], {'S3', 'S4'});
    title(['DFA scala ' num2str(f)]);
    ylabel('DFA');
end
%%
% cleanfigure; % (opzionale, rimuove rumore visivo)
% matlab2tikz('immg.tex');
exportgraphics(gcf, 'dfa_S3.pdf', 'ContentType', 'vector');
