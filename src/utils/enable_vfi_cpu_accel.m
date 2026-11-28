function tf = enable_vfi_cpu_accel(vfiOctaveDir, vecKernels)
%ENABLE_VFI_CPU_ACCEL Mount VFIToolkit-octave vectorized CPU solvers in MATLAB No-GPU.
%   Leaves MATLAB native builtins and graphics untouched (never adds shims/matlab).
%   Safe no-op if a CUDA GPU is active or if running under GNU Octave.

Backend = Resolve_Compute_Backend();
if Backend.IsOctave || Backend.UseGPU
    tf = false;
    return;
end

if nargin < 1 || isempty(vfiOctaveDir)
    igwRoot = getappdata(0, 'IGW_ROOT_DIR');
    if isempty(igwRoot)
        igwRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    end
    vfiOctaveDir = fullfile(fileparts(igwRoot), 'VFIToolkit-octave');
end

if exist(vfiOctaveDir, 'dir') ~= 7
    tf = false;
    return;
end

if nargin < 2 || isempty(vecKernels)
    vecKernels = { ...
        'ReturnFn_SpatialHH', ...
        'ReturnFn_Firm', ...
        'HumanCapital_Lifecycle_aprimeFn'};
end

addpath(fullfile(vfiOctaveDir, 'uinfhorz'),           '-begin');
addpath(fullfile(vfiOctaveDir, 'ufhorz', 'matrices'), '-begin');
addpath(fullfile(vfiOctaveDir, 'ufhorz', 'solvers'),  '-begin');
addpath(fullfile(vfiOctaveDir, 'ufhorz'),             '-begin');
addpath(fullfile(vfiOctaveDir, 'shims',  'pool'),     '-begin');
addpath(fullfile(vfiOctaveDir, 'shims',  'vfi'),      '-begin');

if exist('vfi_vectorized_registry', 'file') ~= 0
    vfi_vectorized_registry('add', vecKernels);
end

tf = true;
end
