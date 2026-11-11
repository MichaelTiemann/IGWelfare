function [hdr, cells] = read_csv_cells(fname)
%READ_CSV_CELLS Minimal CSV reader shared by the tests (no toolboxes; MATLAB + Octave).
%   [hdr, cells] = read_csv_cells(fname) returns the header as a 1xC cellstr and the
%   body as an RxC cell array of strings. Accepts LF or CRLF. Errors on double quotes
%   or ragged rows, because the repo's writetable output contains neither.
%   Convert a column with str2double(cells(:, find(strcmp(hdr, 'Name')))).
fid = fopen(fname, 'r');
if fid < 0
    error('read_csv_cells:open', 'cannot open %s', fname);
end
cleaner = onCleanup(@() fclose(fid));
hdr = {};
cells = {};
n = 0;
while true
    ln = fgetl(fid);
    if ~ischar(ln), break; end
    ln = strrep(ln, char(13), '');
    if isempty(ln), continue; end
    if ~isempty(strfind(ln, '"'))
        error('read_csv_cells:quote', 'quoted fields not supported (%s)', fname);
    end
    parts = strsplit(ln, ',', 'CollapseDelimiters', false);
    if n == 0
        hdr = parts;
    else
        if numel(parts) ~= numel(hdr)
            error('read_csv_cells:ragged', '%s row %d has %d fields, header has %d', ...
                  fname, n, numel(parts), numel(hdr));
        end
        cells(n, 1:numel(parts)) = parts; %#ok<AGROW>
    end
    n = n + 1;
end
end
