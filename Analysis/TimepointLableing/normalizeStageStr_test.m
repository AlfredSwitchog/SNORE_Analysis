%% Minimal stage normalizer + quick tests
% Paste this whole block into a new script and run it.

% ---- Quick tests ----
inputs   = ["Unknown","NREM1","NREM2","NREM3","Wake", ...
            "unknown","nrem1","nrem2","nrem3","wake", ...
            "REM","",missing,"NREM2 (artifact)"];  % last 3 are out-of-scope -> NA

expected = ["NA","N1","N2","N3","W", ...
            "NA","N1","N2","N3","W", ...
            "NA","NA","NA","NA"];

got = normalizeStageStr(inputs);

disp(table(inputs.', got.', expected.', 'VariableNames', {'Input','Got','Expected'}));
assert(isequal(got, expected), 'normalizeStageStr tests FAILED');
disp('✓ All normalizeStageStr tests passed');

% ===================== FUNCTION =====================
function out = normalizeStageStr(in)
%NORMALIZESTAGESTR Map ["Unknown","NREM1","NREM2","NREM3","Wake"] to ["NA","N1","N2","N3","W"].
% - Accepts char, string, or cellstr.
% - Case/whitespace-insensitive.
% - Anything outside the list -> "NA".

    s = string(in);
    out = strings(size(s));
    out(:) = "NA";  % default

    canon = lower(regexprep(strtrim(s), '[^a-z0-9]+', ''));  % 'NREM2 (foo)' -> 'nrem2foo'

    % Map exact tokens we care about
    out(canon == "unknown"               ) = "NA";
    out(canon == "wake" | canon == "w"   ) = "W";
    out(canon == "nrem1" | canon == "n1" ) = "N1";
    out(canon == "nrem2" | canon == "n2" ) = "N2";
    out(canon == "nrem3" | canon == "n3" ) = "N3";

    % Missing/empty stay NA
    out(ismissing(s) | strlength(strtrim(s))==0) = "NA";
end
