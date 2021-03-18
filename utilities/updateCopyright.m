function result = updateCopyright(file)
%UPDATECOPYRIGHT - A project custom task that updates the copyright year.
%
% To create your own custom task, edit this function to perform the desired
% action on each file.
%
% Input arguments:
%  file - char array - The absolute path to a file included in the custom 
%  task. When you run the custom task, the project provides the file input 
%  for each selected file.
%
% Output arguments:
%  result - user-specified type - The result output argument of your custom
%  task. The project displays the result in the Custom Task Results column.
%
% To use the custom task from the project:
%  1) On the Project tab, click Custom Task.
%  2) Select the check boxes of project files you want to include in the 
%   custom task.
%  3) Click Select and choose your custom task from the list.
%  4) Click Run Task.
%
% An example is shown below, which extracts Code Analyzer information for
% each file.


[~,~,ext] = fileparts(file);
switch ext
    case {'.m', '.xml', '.html'}
        
        fid = fopen(file,'r+');
        fileContent = fscanf(fid,'%c');
        
        pattern = '(\s*Copyright\s+\d{4}-)\d{4}';
        matches = regexp(fileContent, pattern, 'match');
        
        if isempty(matches)
            result = 'No copyright found';
        else
            result = [matches{:}];
            
            fileContent = regexprep(fileContent, pattern, ...
                        ['$1' datestr(now,'yyyy')]);
            frewind(fid);
            fprintf(fid, '%c', fileContent);
        end
        
        fclose(fid);
    otherwise
        result = [];
end

end