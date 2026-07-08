function numbers = getFileNumbers(folder,prefix,suffix)

files = dir(fullfile(folder,[prefix '*' suffix]));

numbers = [];

for k = 1:length(files)

    token = regexp( ...
        files(k).name,...
        [regexptranslate('escape',prefix) ...
        '(\d+)' ...
        regexptranslate('escape',suffix) '$'],...
        'tokens');

    if ~isempty(token)
        numbers(end+1) = str2double(token{1}{1});
    end

end

numbers = sort(numbers);

end