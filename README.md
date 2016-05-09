# PowerGrid Test Data

Test datasets for use with [PowerGrid](http://mrfil.github.io/PowerGrid). For all data sets the trajectories are in .mat files (MATLAB format) with kx, ky, kz containing the trajectories, t.mat containing the timing vector, and SMap.mat containing the SENSE map. FM.mat contains the field map.

## Test Datasets
*   192_192_1_32coils - a 2D dataset with 32 coils and an R=2 factor applied in human brain.

*   DWITestData - a 120x120x4 dataset with 32 coils. The data is a single slab of a 3D multislab dataset, and has motion induced phase errors included in the raw data. This dataset contains a PMap.mat file containing the phase images corresponding to the navigator images for each shot. This dataset uses a 2D navigator as the slabs are very thin in the z-direction.
