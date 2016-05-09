%% Generating a simple ISMRMRD data set

% This is an example of how to construct a datset from synthetic data
% simulating a fully sampled acquisition on a cartesian grid.
% data from 4 coils from a single slice object that looks like a square

% We are also adding the FM and senmap as ISMRMRD images to the file for
% use with PowerGrid.

% File Name
filename = '192_192_1_32coils.h5';

% Create an empty ismrmrd dataset
if exist(filename,'file')
    %error(['File ' filename ' already exists.  Please remove first'])
    delete(filename);
end
dset = ismrmrd.Dataset(filename);
% load trajectory data
load('kx.mat','kx');
load('ky.mat','ky');
load('kz.mat','kz');
load('t.mat','t');
% Synthesize the object
nX = 192;
nY = 192;
nZ = 1;
nCoils = 32;
nReps = 1;
nShots = 1;
load('data.mat','data');
nR0 = length(data)/(nShots*nCoils*nReps);
data = reshape(data,[nR0,nShots,nCoils,nReps]);

rho = zeros(nX,nY,nZ);
indxstart = floor(nX/4)+1;
indxend   = floor(3*nX/4);
indystart = floor(nY/4)+1;
indyend   = floor(3*nY/4);
indzstart = floor(nZ/4)+1;
indzend   = floor(3*nZ/4);
rho(indxstart:indxend,indystart:indyend,indzstart:indzend) = 1;

% load the coil sensitivities
load('SMap.mat','SMap');
SMap = reshape(SMap,[nX,nY,nZ,nCoils]);

% create NDArray with the data 
SENSEMap = ismrmrd.NDArray(SMap);

% Write to file
dset.appendArray('SENSEMap',permute(SENSEMap,[1,2,3]));

% load the field map
load('FM.mat', 'FM');
%FM = zeros(nX,nY,nZ);
FM = reshape(FM,[nX,nY,nZ]);

% create NDArray with the data
FieldMap = ismrmrd.NDArray(FM);


% Write to file
dset.appendArray('FieldMap',FieldMap);

% Synthesize the k-space data
nReps = 1;

% It is very slow to append one acquisition at a time, so we're going
% to append a block of acquisitions at a time.
% In this case, we'll do it one repetition at a time to show off this
% feature.  Each block has nY aquisitions
acqblock = ismrmrd.Acquisition(nShots);

% Set the header elements that don't change
acqblock.head.version(:) = 1;
acqblock.head.number_of_samples(:) = nR0;
acqblock.head.center_sample(:) = 0;
acqblock.head.active_channels(:) = nCoils;
acqblock.head.read_dir  = repmat([1 0 0]',[1 nShots]);
acqblock.head.phase_dir = repmat([0 1 0]',[1 nShots]);
acqblock.head.slice_dir = repmat([0 0 1]',[1 nShots]);
acqblock.head.trajectory_dimensions = repmat(4,[1 nShots]);


% Loop over the acquisitions, set the header, set the data and append
for rep = 1:nReps
    for acqno = 1:nShots
        
        % Set the header elements that change from acquisition to the next
        % c-style counting
        acqblock.head.scan_counter(acqno) = acqno-1;
        acqblock.head.idx.kspace_encode_step_1(acqno) = acqno-1; 
        acqblock.head.idx.repetition(acqno) = rep - 1;
        
        % Set the flags
        acqblock.head.flagClearAll(acqno);
        if acqno == 1
            acqblock.head.flagSet('ACQ_FIRST_IN_ENCODE_STEP1', acqno);
            acqblock.head.flagSet('ACQ_FIRST_IN_SLICE', acqno);
            acqblock.head.flagSet('ACQ_FIRST_IN_REPETITION', acqno);
        end
        if acqno==nShots
            acqblock.head.flagSet('ACQ_LAST_IN_ENCODE_STEP1', acqno);
            acqblock.head.flagSet('ACQ_LAST_IN_SLICE', acqno);
            acqblock.head.flagSet('ACQ_LAST_IN_REPETITION', acqno);
        end

        % fill the data
        acqblock.data{acqno} = 1E-3*squeeze(data(:,acqno,:,rep));
        % attach the trajectory
        acqblock.traj{acqno} = [kx(nR0*(acqno-1)+1:nR0*acqno),ky(nR0*(acqno-1)+1:nR0*acqno),kz(nR0*(acqno-1)+1:nR0*acqno),t(nR0*(acqno-1)+1:nR0*acqno)].';
    end

    % Append the acquisition block
    dset.appendAcquisition(acqblock);
        
end % rep loop


%%%%%%%%%%%%%%%%%%%%%%%%
%% Fill the xml header %
%%%%%%%%%%%%%%%%%%%%%%%%
% We create a matlab struct and then serialize it to xml.
% Look at the xml schema to see what the field names should be

header = [];

% Experimental Conditions (Required)
header.experimentalConditions.H1resonanceFrequency_Hz = 123000000; % 3T

% Acquisition System Information (Optional)
header.acquisitionSystemInformation.systemVendor = 'Siemens';
header.acquisitionSystemInformation.systemModel = 'Trio, A Tim System';
header.acquisitionSystemInformation.receiverChannels = nCoils;

% The Encoding (Required)
header.encoding.trajectory = 'spiral';
header.encoding.encodedSpace.fieldOfView_mm.x = 256;
header.encoding.encodedSpace.fieldOfView_mm.y = 256;
header.encoding.encodedSpace.fieldOfView_mm.z = 32;
header.encoding.encodedSpace.matrixSize.x = nX;
header.encoding.encodedSpace.matrixSize.y = nY;
header.encoding.encodedSpace.matrixSize.z = nZ;
% Recon Space
% (in this case same as encoding space)
header.encoding.reconSpace = header.encoding.encodedSpace;
% Encoding Limits;
header.encoding.encodingLimits.kspace_encoding_step_0.minimum = 0;
header.encoding.encodingLimits.kspace_encoding_step_0.maximum = nShots-1;
header.encoding.encodingLimits.kspace_encoding_step_0.center = floor((nShots-1)/2);
header.encoding.encodingLimits.kspace_encoding_step_1.minimum = 0;
header.encoding.encodingLimits.kspace_encoding_step_1.maximum = nZ-1;
header.encoding.encodingLimits.kspace_encoding_step_1.center = floor((nZ-1)/2);
header.encoding.encodingLimits.repetition.minimum = 0;
header.encoding.encodingLimits.repetition.maximum = nReps-1;
header.encoding.encodingLimits.repetition.center = floor((nReps-1)/2);

%% Serialize and write to the data set
xmlstring = ismrmrd.xml.serialize(header);
dset.writexml(xmlstring);

%% Load the FM and create an ISMRMRD Image from it



%% Write the dataset
dset.close();
