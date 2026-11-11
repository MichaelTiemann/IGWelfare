function ok = Validate_CacheConfig(cache_file, cfg_hash)
%% CACHE CONFIG-HASH VALIDATOR (IGW:StaleCache)
% File: Validate_CacheConfig.m
% Used by Run_All_NZ_Intergen_Suite.m before loading a per-step checkpoint. Each checkpoint stores the variable
% Cache_CfgHash (the Get_ModelConfigHash digest of the configured Params, computed once in Run_All_NZ_Intergen_Suite.m
% right after Configure_TimeGrid_Params). Returns true only if the file holds a Cache_CfgHash equal to cfg_hash.
% A missing or different hash, an empty current hash (Get_ModelConfigHash had no MD5 -- IGW:NoMD5), or an unreadable
% file is logged with IGW_Log('IGW:StaleCache', ...) (warning + igw_run.log line, naming the file) and returns false,
% so the caller recomputes and overwrites the checkpoint instead of loading it. Nothing is blocked.
% Only the variable list and the hash are read -- the (large) checkpoint arrays are not loaded.

ok = false;
if isempty(cfg_hash)
    IGW_Log('IGW:StaleCache', '%s: no current config hash is available; not loading it, rebuilding.', cache_file);
    return
end
try
    vars     = whos('-file', cache_file);
    has_hash = any(strcmp({vars.name}, 'Cache_CfgHash'));
catch err
    IGW_Log('IGW:StaleCache', '%s could not be inspected (%s); not loading it, rebuilding.', cache_file, err.message);
    return
end

if ~has_hash
    IGW_Log('IGW:StaleCache', ['%s has no Cache_CfgHash (written before cache hashing, or by another version); ' ...
        'not loading it, rebuilding.'], cache_file);
    return
end

S = load(cache_file, 'Cache_CfgHash');
if ~ischar(S.Cache_CfgHash) || ~strcmp(S.Cache_CfgHash, cfg_hash)
    stored = S.Cache_CfgHash;
    if ~ischar(stored), stored = '<non-text>'; end
    IGW_Log('IGW:StaleCache', ['%s was built for config hash %s but the current Params hash is %s; ' ...
        'not loading it, rebuilding.'], cache_file, stored, cfg_hash);
    return
end

ok = true;
end
