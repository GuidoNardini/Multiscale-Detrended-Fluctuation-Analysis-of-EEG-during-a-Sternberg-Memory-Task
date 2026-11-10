%% Elaborato
clear
clc
close all

main_folder ='';
subjects = dir(fullfile(main_folder, 'sub-*'));
H_all_subjects = struct(); %Crea la struttura per i valori di H
%% Caricamento dati
eeglab; %Lancia EEGLAB
for i = 69:min(69, length(subjects))
    subj_folder = fullfile(main_folder, subjects(i).name, 'eeg'); %
    
    if isfolder(subj_folder) %Verifica esistenza della cartella
        vhdr_files = dir(fullfile(subj_folder, '*task-sternberg*.vhdr')); %Identifica tutti i soggetti sternberg
        
        if isempty(vhdr_files)
            warning(['Nessun file .vhdr trovato per' subjects(i).name]);
            continue;
        end

        datapath = subj_folder;
        addpath(datapath)
        cd(datapath)
               
% eeglab; %Lancia EEGLAB
% datapath = '/OneDrive/Elaborato neuroscienze/sub-01/eeg';
% addpath(datapath)
% cd(datapath)
       
         filename = vhdr_files.name;
         disp(['Elaborazione del file: ' filename ]);

        %Scelta canali (19+57) totale di 76 canali su cui faccio la media
        channels = {'Fp1', {'AF7'    , 'AF3'   , 'AFp1'};
                    'Fp2', {'AF8'    , 'AF4'   , 'AFp2'};
                    'F7' , {'F9'     , 'FFT9h' , 'FFT7h'};
                    'F3' , {'AFF5h'  , 'FFC5h' , 'FFC3h'};
                    'Fz' , {'F1'     , 'AFz'   , 'F2'};
                    'F4' , {'AFF6h'  , 'FFC6h' , 'FFC4h'};
                    'F8' , {'F10'    , 'FFT10h', 'FFT8h'};
                    'T7' , {'FTT9h'  , 'FTT7h' , 'TTP7h'};
                    'C3' , {'CCP5h'  , 'FC3'   , 'CCP3h'};
                    'Cz' , {'CCP1h'  , 'FCz'   , 'CCP2h'};
                    'C4' , {'CCP6h'  , 'FC4'   , 'CCP4h'};
                    'T8' , {'FTT10h' , 'FTT8h' , 'TTP8h'};
                    'P7' , {'TPP9h'  , 'P9'    , 'PPO9h'};
                    'P3' , {'P5'     , 'CPP3h' , 'PPO5h'};
                    'Pz' , {'PPO1h'  , 'CPz'   , 'PPO2h'};
                    'P4' , {'P6'     , 'CPP4h' , 'PPO6h'};
                    'P8' , {'TPP10h' , 'P10'   , 'PPO10h'};
                    'O1' , {'POO9h'  , 'PO3'   , 'OI1h'};
                    'O2' , {'POO10h' , 'PO4'   , 'OI2h'};
                    };
%Analisi visiva
% figure;
% title('Electrodes positions');
% topoplot([], EEG.chanlocs, 'style', 'blank', 'electrodes', 'labelpoint');

        % Carico il dataset
                                 
        EEG = pop_loadbv(datapath,filename, [], 1:127);
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',[filename '_raw'],'gui','off');

        new_data = zeros (length(channels), size(EEG.data, 2), size(EEG.data, 3));
        
        % Calcolo la media dei canali main con vicini
        
        for k = 1:length(channels)
            main_channel = channels{k, 1};
        
            neighbors = channels{k, 2}; 
        
            main_idx = find(strcmp({EEG.chanlocs.labels}, main_channel));
            neighbors_idx = find(ismember({EEG.chanlocs.labels}, neighbors));
        
            all_idx = [main_idx, neighbors_idx];
            new_data(k, :, :) = mean(EEG.data(all_idx, : , :), 1);
        end

        % Update dataset

        main_channels = {channels{:,1}};
        main_channel_idx = find(ismember({EEG.chanlocs.labels}, main_channels));
        EEG.data = new_data;
        EEG.nbchan = size(new_data, 1);
        EEG.chanlocs = EEG.chanlocs(main_channel_idx);
        EEG = eeg_checkset(EEG); %Opzionale

        % Save dataset

        set_filename = [subjects(i).name '_Dataset19ch.set'];
        pop_saveset(EEG, 'filename', set_filename);
        
%% Pre-processing
        
        % Re-Reference
        EEG = pop_reref( EEG, []);
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', [filename 'ReRef'] ,'gui','off');
        
        % Filtro FIR PA
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass',[0.25 0.75] ,'BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[filename '_FIR'],'gui','off'); 
        
        % Selezione dei canali
        original_channel_labels = {EEG.chanlocs.labels};
        num_chan = EEG.nbchan;
        
        % Rimozione canali "non buoni"
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname',[filename '_19ChRemoveNotGood'],'gui','off'); 
        
        %Interpolazione
        if EEG.nbchan < num_chan
            remaning_channel_labels = {EEG.chanlocs.labels};
            removed_channels = setdiff (original_channel_labels, remaning_channel_labels);
            disp (['Canali rimossi:' strjoin(removed_channels, ',')] );
            EEG = pop_interp(EEG, ALLEEG(2).chanlocs, 'spherical');
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname',[filename '_Intrp'],'gui','off'); 
        else
            disp ('Nessun canale rimosso');
        end
        
        % ICA
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        %pop_viewprops(EEG, 0 , 1:13, 'freqrange', [2 80]);
        
        EEG = pop_iclabel(EEG, 'default'); %Classifica le componenti
        removed_components = [];
        for k = 1 : size(EEG.etc.ic_classification.ICLabel.classifications, 1)
            if EEG.etc.ic_classification.ICLabel.classifications(k,1) < 0.05
                removed_components = [removed_components, k];       
            end
        end
        EEG = pop_subcomp(EEG, removed_components, 0);
        
        % Estrazione epoche
        event_type = {'S 12','S  3','S  4','S 11'};
        filtered_events = EEG.event(ismember({EEG.event.type}, event_type));
        EEG.event=filtered_events; 
        EEG = pop_epoch( EEG, {  'S 12' 'S  3' 'S  4' 'S 11' }, [0 1.8], 'newname', [filename '_19ChRemoveNotGood_epochs'], 'epochinfo', 'yes');
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'setname',[filename '_Epochs'],'gui','off');
        
        output_filename = fullfile (datapath, [filename '_final.set']);
        EEG = pop_saveset (EEG, 'filename', output_filename);
        disp(['Dataset salvato: ' output_filename]);

%% Carico Dataset (new dataset)
        % clc
        % clear
        % close all
        %file_path = '/OneDrive/Elaborato neuroscienze/sub-01/eeg/sub-01_task-sternberg_eeg_final.set';
        %EEG = pop_loadset('filename', file_path);

%% DFA per evento
        % Definizione degli eventi
        addpath('/OneDrive/Elaborato neuroscienze')
        savepath

        event_types = {'S  3', 'S  4', 'S 11', 'S 12'};
        %event_names = {'S3', 'S4', 'S11', 'S12_1', 'S12_2', 'S12_3'}; %Questo perche matlab non vuole spazi
             

        box_sizes = logspace(log10(65), log10(900), 15); 
        % Box sizes originali. Indica diverse dimensioni di box per il
        % detrending polinomiale. (Finestre di segmentazione DFA)
        
        % Scalare i box_sizes in base al downsampling
        box_sizes_8   = round(box_sizes * (8   / 1000));
        box_sizes_10  = round(box_sizes * (10  / 1000));
        box_sizes_12  = round(box_sizes * (12  / 1000));
        box_sizes_15  = round(box_sizes * (15  / 1000));
        box_sizes_20  = round(box_sizes * (20  / 1000));
      
        % Struttura per salvare i valori di H
        H_values = struct();
        S11_indices = [];        % S11 (tutti)
        S11_S3_indices = [];     % S11 associato a S3 (task semplici)
        S11_S4_indices = [];     % S11 associato a S4 (task difficili)
        
        S12_1_S3_indices = [];   % S12_1 associato a S3 (task semplici)
        S12_1_S4_indices = [];   % S12_1 associato a S4 (task difficili)
        S12_2_S3_indices = [];   % S12_2 associato a S3 (task semplici)
        S12_2_S4_indices = [];   % S12_2 associato a S4 (task difficili)
        S12_3_S3_indices = [];   % S12_3 associato a S3 (task semplici)
        S12_3_S4_indices = [];   % S12_3 associato a S4 (task difficili)
        % Estrai la lista dei tipi di evento
        event_type_list = {EEG.event.type};
        for w = 1:length(EEG.event)
            current_event = EEG.event(w).type;
    
            if strcmp(current_event, 'S  3')
                % Se l'evento corrente è S3, memorizza l'indice di S3
                last_task = 'S  3';
                last_task_index = w;
            elseif strcmp(current_event, 'S  4')
                % Se l'evento corrente è S4, memorizza l'indice di S4
                last_task = 'S  4';
                last_task_index = w;
            elseif strcmp(current_event, 'S 11')
                % Se l'evento corrente è S11, associalo all'ultimo task (S3 o S4)
                S11_indices = [S11_indices, w];  % Aggiungi a S11 (tutti)
                if strcmp(last_task, 'S  3')
                    S11_S3_indices = [S11_S3_indices, w];  % Aggiungi a S11_S3
                elseif strcmp(last_task, 'S  4')
                    S11_S4_indices = [S11_S4_indices, w];  % Aggiungi a S11_S4
                end
            elseif strcmp(current_event, 'S 12')
                % Se l'evento corrente è S12, associalo all'ultimo task (S3 o S4)
                % Determina se è S12_1, S12_2 o S12_3
                S12_count = sum(strcmp(event_type_list(1:w), 'S 12'));  % Conta quanti S12 ci sono stati finora
                if mod(S12_count, 3) == 1
                    % S12_1
                    if strcmp(last_task, 'S  3')
                        S12_1_S3_indices = [S12_1_S3_indices, w];
                    elseif strcmp(last_task, 'S  4')
                        S12_1_S4_indices = [S12_1_S4_indices, w];
                    end
                elseif mod(S12_count, 3) == 2
                    % S12_2
                    if strcmp(last_task, 'S  3')
                        S12_2_S3_indices = [S12_2_S3_indices, w];
                    elseif strcmp(last_task, 'S  4')
                        S12_2_S4_indices = [S12_2_S4_indices, w];
                    end
                else
                    % S12_3
                    if strcmp(last_task, 'S  3')
                        S12_3_S3_indices = [S12_3_S3_indices, w];
                    elseif strcmp(last_task, 'S  4')
                        S12_3_S4_indices = [S12_3_S4_indices, w];
                    end
                end
            end
        end
        
        
        %Estrazione degli eventi S3, S4, S11, S12(x3)
        event_groups = {
            find(strcmp(event_type_list, 'S  3')), ...  % S3
            find(strcmp(event_type_list, 'S  4')), ...  % S4
            S11_indices, ...          % S11 (tutti)
            S11_S3_indices, ...       % S11 associato a S3
            S11_S4_indices, ...       % S11 associato a S4
            S12_1_S3_indices, ...     % S12_1 associato a S3
            S12_1_S4_indices, ...     % S12_1 associato a S4
            S12_2_S3_indices, ...     % S12_2 associato a S3
            S12_2_S4_indices, ...     % S12_2 associato a S4
            S12_3_S3_indices, ...     % S12_3 associato a S3
            S12_3_S4_indices          % S12_3 associato a S4
        };
        event_names = {
            'S3', 'S4', ...
            'S11', 'S11_S3', 'S11_S4', ...
            'S12_1_S3', 'S12_1_S4', ...
            'S12_2_S3', 'S12_2_S4', ...
            'S12_3_S3', 'S12_3_S4', ...
            'S12_1', 'S12_2', 'S12_3'
        };

        S12_indices = find(strcmp(event_type_list, 'S 12'));
        %Considera insieme la prima fase di S12, la seconda fase e la
        %terza.
        S12_1_indices = S12_indices(1:3:end);
        S12_2_indices = S12_indices(2:3:end);
        S12_3_indices = S12_indices(3:3:end);
        
        event_groups = [event_groups, {S12_1_indices, S12_2_indices, S12_3_indices}]; %Update degli eventi in modo da raggrupparli tutti insieme
        
        % Iterazione su ogni tipo di evento
        for ev = 1:length(event_groups) %event_groups contiene gli eventi
            event_name = event_names{ev};
            fprintf('Processando %s...\n', event_name);
            
            if isempty(event_groups{ev})
                warning('Nessuna epoca trovata per %s.', event_name);
                continue;
            end
            
            % Trova gli indici degli eventi
            epoch_latencies = arrayfun(@(x) EEG.event(x).latency, event_groups{ev}); %tempo in cui si verifica un evento, applica la funzione a tutti gli eventi e restituisce array
            n_epochs = length(epoch_latencies); 
        
            % Prealloca i dati EEG per l'evento corrente
            event_data = zeros(size(EEG.data, 1), 1800, n_epochs); %1.8s a 1000Hz
        
            % Estrai i dati per ogni epoca dall inizio fino alla fine
            for j = 1:n_epochs
                event_data(:, :, j) = EEG.data(:, epoch_latencies(j):epoch_latencies(j) + 1799);
            end
        
            % Prealloca i risultati di DFA
            H_event = zeros(n_epochs, size(EEG.data, 1), 5);
           
            % Calcola DFA per ogni epoca e canale
            for epoch_idx = 1:n_epochs
                for channel_idx = 1:size(EEG.data, 1)
                    y = event_data(channel_idx, :, epoch_idx);
        
                    % Downsampling ( 8 , 10 , 12, 15, 20)
                    y_8   = downsample(y,    8);
                    y_10  = downsample(y,   10);
                    y_12  = downsample(y,   12);
                    y_15  = downsample(y,   15);
                    y_20  = downsample(y,   20);
        
                    % DFA su ogni scala ("x"-->[], (std) matrice che indica i
                    % punti di campionamento; "detrend_order"--> 2 (std)
                    % grado del polinomio da utilizzare; "[xstart,
                    % xend]"-->[], (std) posizione dei dati per la quale deve essere
                    % stimato H; "box_sizes"-->indica diverse dimensioni di
                    % box èer il detrending polinomiale)
                    H_8   = dfa(y_8,   [], 2, [], box_sizes_8,   false);
                    H_10  = dfa(y_10,  [], 2, [], box_sizes_10,  false);
                    H_12  = dfa(y_12,  [], 2, [], box_sizes_12,  false);
                    H_15  = dfa(y_15,  [], 2, [], box_sizes_15,  false);
                    H_20  = dfa(y_20,  [], 2, [], box_sizes_20,  false);
        
                    % Memorizza i risultati
                    H_event(epoch_idx, channel_idx, :) = [H_8, H_10, H_12, H_15, H_20];
                end
            end
        
            % Salva i risultati per l'evento corrente
            H_values.(event_name) = H_event;
        end

        if isfield(H_values, 'S12_1') && isfield(H_values, 'S12_2') && isfield(H_values, 'S12_3') %Verifica di S12_1, S12_2, S12_3
             H_values.S_12 = (H_values.S12_1 + H_values.S12_2 + H_values.S12_3) / 3; %Calcola la media
             H_values = rmfield(H_values, {'S12_1', 'S12_2', 'S12_3'}); %Rimuovo per evitare che rimangano nella struttura
        else
            error('Uno dei gruppi di S12 non è stato calcolato correttamente.');
        end

        if isfield(H_values, 'S12_1_S3') && isfield(H_values, 'S12_2_S3') && isfield(H_values, 'S12_3_S3') %Verifica di S12_1, S12_2, S12_3
             H_values.S_12_S3 = (H_values.S12_1_S3 + H_values.S12_2_S3 + H_values.S12_3_S3) / 3; %Calcola la media
             H_values = rmfield(H_values, {'S12_1_S3', 'S12_2_S3', 'S12_3_S3'}); %Rimuovo per evitare che rimangano nella struttura
        else
            error('Uno dei gruppi di S12 non è stato calcolato correttamente.');
        end
        
        if isfield(H_values, 'S12_1_S4') && isfield(H_values, 'S12_2_S4') && isfield(H_values, 'S12_3_S4') %Verifica di S12_1, S12_2, S12_3
             H_values.S_12_S4 = (H_values.S12_1_S4 + H_values.S12_2_S4 + H_values.S12_3_S4) / 3; %Calcola la media
             H_values = rmfield(H_values, {'S12_1_S4', 'S12_2_S4', 'S12_3_S4'}); %Rimuovo per evitare che rimangano nella struttura
        else
            error('Uno dei gruppi di S12 non è stato calcolato correttamente.');
        end

        save_path = fullfile(main_folder, 'H_all_subjects.mat');
        if exist(save_path, 'file')
            % Se il file esiste, carica i dati esistenti
            load(save_path, 'H_all_subjects');
            disp('File esistente caricato.');
        else
            % Se il file non esiste, inizializza la struttura
            H_all_subjects = struct();
            disp('File non esistente, struttura nuova creata.');
        end
        subject_name = subjects(i).name; 
        subject_name = strrep(subject_name, '-', '_'); %Sostituisce - con _ perche matlab vuole _
        H_all_subjects.(subject_name) = H_values; %Salvo tutto nella struttura finale
        
        save(save_path, 'H_all_subjects');
        disp(['Struttura aggiornata e salvata per il soggetto: ', subject_name]);
    end
end
