function [cache_filepath, is_cached] = Get_ModelConfigHash(tag_str, Params, n_d, n_a, n_z, N_j, ForceRecompute)
%% AUTOMATIC CONTENT-HASHED .MAT CACHE MANAGER
% File: Get_ModelConfigHash.m
% Returns the path to a cached .mat file in ./Cache_NZ_Intergen/ whose filename
% embeds an 8-char hash of (Params, n_d, n_a, n_z, N_j). If ForceRecompute == true,
% is_cached is forced to false so the caller recomputes and overwrites the cache.

if nargin < 7 || isempty(ForceRecompute)
    ForceRecompute = false;
end

CacheDir = fullfile(pwd, 'Cache_NZ_Intergen');
if ~exist(CacheDir, 'dir')
    mkdir(CacheDir);
end

% Serialize key numerical contents of Params and grid sizes into a byte stream
state_struct = struct('Params', Params, 'n_d', n_d, 'n_a', n_a, 'n_z', n_z, 'N_j', N_j);
raw_bytes    = getByteStreamFromArray(state_struct);

% Compute fast DJB2 / FNV-1a 64-bit checksum in pure MATLAB (no Java dependency required)
hash_val = uint64(14695981039346656037);
prime_64 = uint64(1099511628211);
% Sample up to 8192 bytes evenly for sub-millisecond hashing
stride   = max(1, floor(numel(raw_bytes) / 8192));
sampled  = uint64(raw_bytes(1:stride:end));
for k = 1:numel(sampled)
    hash_val = bitxor(hash_val, sampled(k));
    hash_val = uint64(mod(double(hash_val) * 1099511, 2^52));
end
hash_hex = sprintf('%08X', mod(hash_val, uint64(2^32)));

clean_tag      = regexprep(tag_str, '[^a-zA-Z0-9_]', '_');
cache_filepath = fullfile(CacheDir, sprintf('Cache_%s_%s.mat', clean_tag, hash_hex));
is_cached      = (~ForceRecompute) && (exist(cache_filepath, 'file') == 2);

end