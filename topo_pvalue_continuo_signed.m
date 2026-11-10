function topo_pvalue_continuo_signed(channels, data, pval)
    log_alpha = -log(0.05); % soglia log(p)
    logp = -log(pval);      % logaritmo dei p-value

    % Direzione effetto
    logp_signed = logp;
    logp_signed(data < 0) = -logp(data < 0); % negativo se effetto "verso il secondo gruppo"
    
    % Metti i non significativi a 0 (verranno bianchi)
    logp_signed(pval >= 0.05) = 0;

    % Limiti per la colormap simmetrici
    max_abs = max(abs(logp_signed(:)));
    maplimits = [-max_abs max_abs];

    % Disegna topoplot
    topoplot(logp_signed, channels, ...
        'maplimits', maplimits, ...
        'electrodes', 'on');

    % Colormap: blu (negativo) - bianco (non significativo) - rosso (positivo)
    n_colors = 256;
    half = floor(n_colors/2);
    blues = [linspace(0,1,half)' linspace(0,1,half)' ones(half,1)];
    reds = [ones(half,1) linspace(1,0.5,half)' linspace(1,0.5,half)'];
    cmap = [blues; ones(1,3); reds]; % aggiungo il bianco centrale
    colormap(gca, cmap);

    % Colorbar personalizzata
    cb = colorbar;
    ticks = unique(round([-max_abs, -log_alpha, 0, log_alpha, max_abs], 2));
    ticklabels = arrayfun(@(x) sprintf('p = %.3f', exp(-abs(x))), ticks, 'UniformOutput', false);
    ticklabels{ticks == 0} = 'p ≥ 0.05';
    set(cb, 'Ticks', ticks, 'TickLabels', ticklabels);
    ylabel(cb, '-log(p)', 'FontSize', 12);

    title('Differenze con direzione e soglia p = 0.05', 'FontSize', 14);
end
