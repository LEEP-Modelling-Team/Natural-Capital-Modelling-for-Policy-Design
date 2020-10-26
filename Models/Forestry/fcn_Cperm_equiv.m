%% Function: fnc_Cperm_equiv 
%  =========================
%  Receivies a time  series of annual emissions and sequestrations and
%  calculates the equivalent quantity of permanent carbon emission or
%  sequestration.

function Cperm = fnc_Cperm_equiv(Ctser)

    %% (1) Ensure C time series is a row vector 
    % -----------------------------------------
    if ~isrow(Ctser) Ctser = Ctser'; end
    M = length(Ctser);
    
    %% (2) Find periods where carbon series shows net sequestration or emission
    %  ------------------------------------------------------------------------
    Ctser_cumsum  = cumsum(Ctser);
    Ctser_pos_ind = (Ctser_cumsum >= 0);
    Ctser_neg_ind = (Ctser_cumsum <  0);
    
    Ctser_pos = diff([0 Ctser_cumsum.*Ctser_pos_ind]);
    Ctser_neg = diff([0 Ctser_cumsum.*Ctser_neg_ind]);
    
    
    %% (3) PERIODS OF NET POSITIVE (EMISSIONS?)
    %  ----------------------------------------
    if sum(Ctser_pos_ind) > 0
        
        % (a) Find start & end indices for period of positive carbon in the time series 
        % -----------------------------------------------------------------------------
        Ctser_pos_idx = find(Ctser_neg_ind);   
        Ctser_pos_idx = [[1 Ctser_pos_idx+1]' [Ctser_pos_idx-1 M]'];
        Ctser_pos_idx = Ctser_pos_idx(Ctser_pos_idx(:,1)<=Ctser_pos_idx(:,2),:);
            
        % (b) Calculate number of sequences of positive carbon of different lengths
        % -------------------------------------------------------------------------
        Cyrs_pos = fcn_count_seq_lengths(Ctser_pos, Ctser_pos_idx);

    else 
        Cyrs_pos = zeros(1,M);        
    end
    
    
    %% 4. PERIODS OF NET NEGATIVE (SEQUESTRATION?)
    %  -------------------------------------------   
    if sum(Ctser_neg_ind) > 0

        % (a) Find start & end indices for negative sequences in the carbon series 
        % ------------------------------------------------------------------------
        Ctser_neg_idx = find(Ctser_pos_ind);   
        Ctser_neg_idx = [[1 Ctser_neg_idx+1]' [Ctser_neg_idx-1 M]'];
        Ctser_neg_idx = Ctser_neg_idx(Ctser_neg_idx(:,1)<=Ctser_neg_idx(:,2),:);
    
        % (b) Calculate number of sequences of negative carbon of different lengths
        % -------------------------------------------------------------------------
        % Note turn negative C to positive to facilitate count
        Cyrs_neg = fcn_count_seq_lengths(-Ctser_neg, Ctser_neg_idx);
        
    else
        Cyrs_neg = zeros(1,M);
    end
    

    %% 5. CONVERT NON PERMANENT SEQUENCES TO PERMANENT EQUIVALENTS
    %  -----------------------------------------------------------
    
    % (a) Net number of sequences of different lengths (can be pos or neg)
    % --------------------------------------------------------------------
    Cyrs = Cyrs_pos - Cyrs_neg;
        
    % (b) Reorient vector so shorest duration sequences are to left
    % -------------------------------------------------------------
    Cduration = flip(Cyrs);
    
    % (c) All duration of 100 or greater are equivalent to permanent
    % -------------------------------------------------------------
    if (M < 100) 
        Cduration = padarray(Cduration,[0 100-M],'post'); 
    else
        Cduration(100) = sum(Cduration(100:end));
        Cduration      = Cduration(1:100);
    end
    
    % (d) Use IPCC conversion factors to convert temporary seq/emm to permanent equivalent    
    % ------------------------------------------------------------------------------------
    IPCC_Frac = interp1q([0,10,20,30,40,50,60,70,80,90,100]',[0,.074,.15,.229,.312,.399,.493,.594,.706,.833,1]',(1:100)');    
    Cperm = Cduration*IPCC_Frac;  
    
end


% Function: fcn_count_seq_lengths
% -------------------------------
%   Takes a time series of only positive or only negative periods of annual
%   emissions. For each period counts the number of sequences of carbon 
%   seq/emm of different lengths, where (obviously) the longest sequence is
%   the length of the period.

function Cyrs = fcn_count_seq_lengths(Ctser, Ctser_idx)

    M    = length(Ctser);
    Cyrs = zeros(1,M);

    % Loop through each period counting sequence lengths
    % --------------------------------------------------
    for i = 1:size(Ctser_idx,1);
        for j = Ctser_idx(i,1):Ctser_idx(i,2)
            % If a neg in this period then must be terminating sequences
            if Ctser(j) < 0;
                defi = Ctser(j);                
                cnt = 0;
                while defi < 0
                    % Work back terminating sequences until cleared deficit
                    surp = Ctser(j-cnt-1);
                    Ctser(j-cnt)   = 0;
                    Cyrs(M-cnt) = Cyrs(M-cnt) + min(surp,-defi);
                    Ctser(j-cnt-1) = Ctser(j-cnt-1) + defi;
                    defi = defi + surp;
                    cnt = cnt + 1;
                end
            end
        end

        % Add non-terminated sequences for this period to the vector 
        % counting number of sequences of lengths of terminated sequences
        period_len = Ctser_idx(i,2)- Ctser_idx(i,1);
        Cyrs(M-period_len:M) = Cyrs(M-period_len:M) + Ctser(Ctser_idx(i,1):Ctser_idx(i,2));    

    end

end    
    