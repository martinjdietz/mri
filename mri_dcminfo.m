function I = mri_dcminfo(P)

% MRI acquisition parameters (Siemens Trio)
% FORMAT I = mri_dcminfo(P)
%
% P - path to dicom file
%     (leave void to use file selector)
%
% TR          - repetition time         (ms)
% TE          - echo time               (ms)
% ES          - effective echo spacing  (s)
% RT          - total readout time      (s)
% FA          - flip angle              (degrees)
% FoV         - field of view           (mm2)
% Dim         - image dimensions        (voxels)
% Voxel       - voxel size              (mm)
% Nslices     - number of slices    
% Slicethick  - slice thickness         (mm)
% Tesla       - field strength          (Tesla)
% Acquisition - acquisition mode    
% Order       - slice order
% ___________________________________________________________
% Copyright (C) 2013-16 Martin Dietz, CFIN, Aarhus University


if ~nargin
    P = spm_select(1,'any','Please select dicom file',[],[],'.dcm$');
end

if license('checkout','image_toolbox')
    
    D = dicominfo(P);
    S = D.Private_0029_1020;
    n = numel(D.Private_0019_1029);
    S = char(S');
    j = strfind(S,'sSliceArray.ucMode');

    [~, r] = strtok(S(j:j + 100), '=');
    ucmode = strtok(strtok(r, '='));
    
    
    % image dimensions
    % -----------------------------------------
    
    mtx = double(D.AcquisitionMatrix([1 4]))';
    pxl = double(D.PixelSpacing)'; 
    vxl = cat(2,pxl,D.SliceThickness);
    
    
    % phase encoding
    % -----------------------------------------
    
    bpp = D.Private_0019_1028;               
    msp = sscanf(D.Private_0051_100b,'%d');  
    
    
    % store
    % -----------------------------------------
    
    I.TR         = D.RepetitionTime;
    I.TE         = D.EchoTime;
    I.FA         = D.FlipAngle;
    I.ES         = 1/(bpp/msp);
    I.RT         = 1/bpp;
    I.FoV        = pxl.*mtx;
    I.Dim        = cat(2,mtx,n);
    I.Voxel      = vxl;
    I.Nslices    = n;
    I.Slicethick = D.SliceThickness;
    I.Tesla      = D.MagneticFieldStrength;
    
    switch(ucmode)
        case '0x1'
            I.Acquisition = 'ascending';
            I.Order = 1:n;
        case '0x2'
            I.Acquisition = 'descending';
            I.Order = n:-1:1;
        case '0x4'
            I.Acquisition = 'interleaved';
            if isequal(fix(n/2),n/2)
                I.Order = [2:2:n 1:2:n];
            else
                I.Order = [1:2:n 2:2:n];
            end
        otherwise
            I.Acquisition = 'unknown';
            I.Order = 'unknown';
    end
    
elseif exist('spm.m','file')
    
    D = spm_dicom_headers(P);
    D = D{:};
    
    % image dimensions
    % -----------------------------------------
    
    mtx = double(D.AcquisitionMatrix([1 4]));
    pxl = double(D.PixelSpacing)'; 
    vxl = cat(2,pxl,D.SliceThickness);
    n   = numel(D.Private_0019_1029);
    
    
    % phase encoding
    % -----------------------------------------
    
    bpp = D.Private_0019_1028;               
    msp = sscanf(D.Private_0051_100b,'%d');  
    
    
    % store
    % -----------------------------------------
    
    I.TR         = D.RepetitionTime;
    I.TE         = D.EchoTime;
    I.FA         = D.FlipAngle;
    I.ES         = 1/(bpp/msp);
    I.RT         = 1/bpp;
    I.FoV        = pxl.*mtx;
    I.Dim        = cat(2,mtx,n);
    I.Voxel      = vxl;
    I.Nslices    = n;
    I.Slicethick = D.SliceThickness;
    I.Tesla      = D.MagneticFieldStrength;
end


