function [env_outs_rescaled, es_outs_rescaled, sd_env_out, sd_es_out] = rescale_quantities(env_outs, ...
        es_outs, ...
        available_elm_options, ...
        year_scaled)
    num_elm_options = length(available_elm_options);
    env_out_scaled = [];
    es_out_scaled = [];
    for k = 1:num_elm_options
            env_out_scaled = [env_out_scaled; squeeze(env_outs.(available_elm_options{k})(:,:,year_scaled))];
            es_out_scaled = [es_out_scaled; squeeze(es_outs.(available_elm_options{k})(:,:,year_scaled))];
    end

    sd_env_out = std(env_out_scaled);
    sd_es_out = std(es_out_scaled);

    env_outs_rescaled = [];
    es_outs_rescaled = [];
    for i = 1:num_elm_options
        for t = 1:5
            env_outs_rescaled.(available_elm_options{i})(:,:,t) = env_outs.(available_elm_options{i})(:,:,t) ./ sd_env_out;
            es_outs_rescaled.(available_elm_options{i})(:,:,t) = es_outs.(available_elm_options{i})(:,:,t) ./ sd_es_out;
        end
    end
end