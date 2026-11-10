%% Plotting S3 e S4
load("/OneDrive/H_sorted.mat");

disp('Soggetti disponibili:');
subject_names = fieldnames(H_sorted);
disp(strjoin(subject_names, ', '));
selected_subject = input('Inserire il nome del soggetto desiderato: ', 's');

if isfield(H_sorted, selected_subject)% Controlla se il soggetto è nei dati
    H_values = H_sorted.(selected_subject);
    
    figure;
    event_names = fieldnames(H_values);
    
    for ev = 1:length(event_names)
        subplot(3, 3, ev);
        H_data = H_values.(event_names{ev});
        H_data(H_data > 1) = NaN;
        H_mean = squeeze(mean(H_data, 1, 'omitnan'));
        
        % Plot
        plot(1:5, H_mean', '-o');
        title(['DFA per ', event_names{ev}], 'Interpreter', 'none');
        xlabel('Scale');
        ylabel('H');
        xticks(1:5);
        xticklabels({'8', '10', '12', '15', '20'});
        grid on;
        
    end
    
    H_S3 = permute(H_values.S3, [1, 3, 2]);
    H_S4 = permute(H_values.S4, [1, 3, 2]);     
    
    H_S3(H_S3 > 1) = NaN;
    H_S4(H_S4 > 1) = NaN;
    
    epochs = 1:24;

    H_S3_mean = H_values.S3;
    H_S4_mean = H_values.S4;
    H_S3_mean(H_S3_mean > 1) = NaN;
    H_S4_mean(H_S4_mean > 1) = NaN;
    H_S3_mean1 = squeeze(mean(H_S3_mean, 1, 'omitnan'));
    H_S4_mean1 = squeeze(mean(H_S4_mean, 1, 'omitnan')); 
    
    
    subplot(3, 3, 9);
    hold on;
    plot(1:5, H_S3_mean1', '-o', 'Color', [0.3, 0.3, 1], 'LineWidth', 1.2, 'MarkerFaceColor', [0.6, 0.6, 1]); % S3 in blu
    plot(1:5, H_S4_mean1', '-^', 'Color', [1, 0.3, 0.3], 'LineWidth', 1.2, 'MarkerFaceColor', [1, 0.6, 0.6]); % S4 in rosso

    h1 = plot(nan, nan, 'o', 'Color', 'b', 'MarkerFaceColor', 'b', 'MarkerSize', 6); % S3 blu
    h2 = plot(nan, nan, '^', 'Color', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 6); % S4 rosso

    xlabel('Hz');
    ylabel('H');
    title(['DFA per S3 e S4 - ' selected_subject],'Interpreter', 'none');
    xticks(1:5);
    xticklabels({'8', '10', '12', '15', '20'});
    legend([h1, h2], {'S3', 'S4'}, 'Location', 'best');
    grid on;
    hold off;
    
    %Plot S3
    figure;
    subplot(1,2,1);
    hold on;
    for channel_idx = 1:19
        plot(epochs, squeeze(mean(H_S3(:, :, channel_idx), 2, 'omitnan')), 'Color', [0.7, 0.7, 0.7], 'LineWidth', 0.1);
    end

    H_S3_mean= mean(H_S3, [2,3], 'omitnan');
    plot(epochs, H_S3_mean, 'b');%Evidenzia la media di S3
    xlabel('Epoch');
    ylabel('H values');
    title(['DFA per S3 - ' selected_subject],'Interpreter', 'none');
    grid on;
    hold off;

    %Plot S4
    subplot(1,2,2);
    hold on;
    for channel_idx = 1:19
        plot(epochs, squeeze(mean(H_S4(:, :, channel_idx), 2, 'omitnan')), 'Color', [0.7, 0.7, 0.7], 'LineWidth', 0.1);
    end
    H_S4_mean = mean(H_S4, [2,3], 'omitnan');
    plot(epochs, H_S4_mean, 'r');
    xlabel('Epoch');
    ylabel('H values');
    title(['DFA per S4 - ' selected_subject],'Interpreter', 'none');
    grid on;
    hold off;
    
else
    disp('Error');
end

%%
% Assumo che H_S3 abbia dimensioni (24 epoche × 5 scale × 19 canali)
epochs = 1:24;
scale_labels = {'8', '10', '12', '15', '20'};

figure;
for scale = 1:5
    subplot(2,3,scale); % layout 2x3
    hold on;
    
    % Per ogni canale, plotta l'andamento sulle epoche per la scala attuale
    for ch = 1:19
        plot(epochs, squeeze(H_S3(:, scale, ch)), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.2);
    end
    
    % Calcola la media sui canali
    media_per_epoca = mean(squeeze(H_S3(:, scale, :)), 2, 'omitnan');
    plot(epochs, media_per_epoca, 'b', 'LineWidth', 1.5);
    
    title(['DFA S3 - Scala ' scale_labels{scale} ' Hz']);
    xlabel('Epoche');
    ylabel('H');
    ylim([0 1]); % opzionale per coerenza visiva
    grid on;
    hold off;
end
sgtitle(['DFA per S3 - ' selected_subject],'Interpreter','none');