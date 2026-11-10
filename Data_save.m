clc
clear

load("/OneDrive/H_sorted.mat");

numSubjects = 80;

% Cella per memorizzare i dati per ogni soggetto
allSubjects = cell(numSubjects, 1);

% Ciclo per caricare i dati di ciascun soggetto
for i = 1:numSubjects
    % Creare il nome del file per ogni soggetto
    filename = sprintf('/OneDrive/Elaborato Neuroscienze/dataset1/ds004796-download/sourcedata/sub-%02d/logfiles/sub-%02d_task-sternberg_events.txt', i, i);
    
    % Verifica che il file esista
    if isfile(filename)
        allSubjects{i} = importfile(filename, [3, Inf]); % Import file tramite funzione
    else
        fprintf('File per il soggetto %02d non trovato. Passo al prossimo.\n', i);
        allSubjects{i} = [];
    end
end

missSubjects = [50, 51, 69];
allSubjects(missSubjects) = [];

% Seleziono solo le colonne che interessano
column = cell(size(allSubjects));

% Ciclo per estrarre le colonne desiderate da ciascun soggetto
for i = 1:numel(allSubjects)
    % Se la tabella non è vuota
    if ~isempty(allSubjects{i})
        % Estrai solo le colonne di interesse: Subject, EventType, Code
        column{i} = allSubjects{i}(:, {'Subject', 'Event Type', 'Code'});
    end
end

% Ciclo per rimuovere le righe che contengono NaN o <unknown>
for i = 1:numel(column)
    % Se la tabella non è vuota
    if ~isempty(column{i})
        % Trova le righe con NaN o <unknown> in qualsiasi colonna
        % Considera "NaN" per le variabili numeriche e "<unknown>" per le stringhe/categorie
        rowsToRemove = any(ismissing(column{i}) | ...
                           strcmp(column{i}.('Event Type'), '<unknown>') | ...
                           strcmp(column{i}.Code, '<unknown>'), 2);
                       
        % Rimuovi le righe che contengono NaN o <unknown>
        column{i}(rowsToRemove, :) = [];
    end
end
% Cella che contiene i dati estratti

% Cella per memorizzare le percentuali di correttezza per ogni soggetto
rightAnswer_100 = zeros(numel(column), 1);

% Ciclo per esaminare ogni soggetto
for i = 1:numel(column)
    if ~isempty(column{i})
        % Estrai la tabella per il soggetto corrente
        data = column{i};
        
        % Inizializza il contatore delle risposte corrette e totali
        rightAnswer = 0;
        total = 0;
        
        % Iniziamo a scorrere le righe
        letterSequence = {}; % Variabile per memorizzare la sequenza di lettere
        for j = 1:height(data)
            % Ignora le righe che contengono INT-1 o INT-2
            if contains(char(data.Code(j)), 'INT')
                continue;
            end
            
            % Trova la riga che contiene la "picture" (la sequenza di lettere)
            if contains(char(data.('Event Type')(j)), 'Picture') && iscategorical(data.Code(j)) && ~contains(char(data.Code(j)), 'retention') && contains(char(data.Code(j)), '+')
                letterSequence = strsplit(char(data.Code(j))); % Estrai la sequenza di lettere
            end

            if contains(char(data.('Event Type')(j)), 'Picture') && ~contains(char(data.Code(j)), 'retention') && ~contains(char(data.Code(j)), '+')
                singleLetter = char(data.Code(j));
            end
            
            % Trova la riga che contiene "response" (la risposta del soggetto)
            if strcmp(char(data.('Event Type')(j)), 'Response')
                % Estrai la lettera che è stata mostrata per il test         
                
                % Verifica se la lettera è presente nella sequenza mostrata
                isPresent = any(strcmp(letterSequence, singleLetter));
                subjectAnswer = str2double(char(data.Code(j)));

                % La risposta corretta è 1 (non presente) o 2 (presente)
                if (isPresent && subjectAnswer == 2) || (~isPresent && subjectAnswer == 1)
                    rightAnswer = rightAnswer + 1;
                end
                total = total + 1;
            end
        end
        
        % Calcola la percentuale di risposte corrette per il soggetto
        if total > 0
            rightAnswer_100(i) = (rightAnswer / total) * 100;
        end
    end
end

% Visualizza i risultati delle percentuali di risposte corrette per ogni soggetto
disp('Percentuali di risposte corrette per ciascun soggetto:');
disp(rightAnswer_100);


%% Analisi statistica

S3_data = zeros (80, 24, 19, 5);
S4_data = zeros (80, 24, 19, 5);
S11_data = zeros (80, 48, 19, 5);
S12_data = zeros (80, 48, 19, 5);


for subject = 1:80
    field_name = sprintf('sub_%02d', subject);
    
    if isfield (H_sorted, field_name)
        S3_data(subject, :, :, :) = H_sorted.(field_name).S3;
        S4_data(subject, :, :, :) = H_sorted.(field_name).S4;
        S11_data(subject, :, :, :) = H_sorted.(field_name).S11;
        S12_data(subject, :, :, :) = H_sorted.(field_name).S_12;
    else
        disp(['Soggetto'  field_name  'mancante, saltato']);
    end
end

S3_data (missSubjects, :, :, :) = [];
S4_data (missSubjects, :, :, :) = [];
S11_data(missSubjects, :, :, :) = [];
S12_data(missSubjects, :, :, :) = [];

memorySet = cat(2, S3_data, S4_data);

datasets = {'S3_data', 'S4_data', 'S12_data'};

for i = 1:length(datasets)
    memorySet = eval(datasets{i});
    memorySet(memorySet > 1) = NaN; % Sostituisce i valori > 1 con NaN
    eval([datasets{i} ' = memorySet;']); % Salva di nuovo la variabile pulita
end

meanProbe = squeeze(mean(S12_data, 2, 'omitnan'));
meanMemorySet = squeeze(mean(memorySet,2, 'omitnan'));

median_threshold = median(rightAnswer_100);

high_perf = find(rightAnswer_100 >= median_threshold);

low_perf = find(rightAnswer_100 < median_threshold);

% Wilcoxon-Mann-Whitney
p_valuesMS = zeros (19, 5);
p_valuesProbe = zeros (19, 5);

for ch = 1:19
    for freq = 1:5
        % Estrai i valori DFA per ogni gruppo nella fase "stimolo"
        MS_highPerf = squeeze(meanMemorySet(high_perf, ch, freq));
        MS_lowPerf = squeeze(meanMemorySet(low_perf, ch, freq));
        probe_highPerf = squeeze(meanProbe(high_perf, ch, freq));
        probe_lowPerf = squeeze(meanProbe(low_perf, ch, freq));

        p_valuesMS (ch, freq) = ranksum (MS_highPerf, MS_lowPerf);
        p_valuesProbe (ch, freq) = ranksum (probe_highPerf, probe_lowPerf);
    end
end

p_values_fdrMS = zeros(size(p_valuesMS));
for h = 1:size(p_valuesMS,2)
    p_values_fdrMS(:,h)=mafdr(p_valuesMS(:,h), 'BHFDR', true);
end

p_values_fdrProbe = zeros(size(p_valuesProbe));
for h = 1:size(p_valuesProbe,2)
    p_values_fdrProbe(:,h)=mafdr(p_valuesProbe(:,h), 'BHFDR', true);
end

%% Topoplot
file_path = '/OneDrive/Elaborato Neuroscienze/dataset1/ds004796-download/sub-01/eeg/sub-01_task-sternberg_eeg.vhdr_final.set';
EEG = pop_loadset('filename', file_path);
for f = 1:5
    figure; 
    
    % Estraggo i pvalues e calcolo il logaritmo
    p_values_selected = p_values_fdrMS(:,f);
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
    
    title(['DFA Freq ' num2str(f) ' - p-values']);
end