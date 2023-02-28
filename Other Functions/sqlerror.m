
function [err] = sqlerror( err )
% GSS SQL exec error function 
if (isempty(err.Message))
    % no op
elseif strcmp(err.Message, 'No results were returned by the query.') || strcmp(err.SQLQuery(1:4),'COPY')
    % no op
else
    disp(['SQL Query: [' err.SQLQuery ']']);
    disp(['SQL Error: [' err.Message ']']);
    error('SQL Error: err.Message');
end

