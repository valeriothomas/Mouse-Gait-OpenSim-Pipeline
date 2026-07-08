function [Fx,Fy,Fz,Mx,My,Mz] = ...
    loadForcePlateData(c3dFile)

acq = btkReadAcquisition(c3dFile);

analogs = btkGetAnalogs(acq);

Fx = analogs.Force_Fx2;
Fy = analogs.Force_Fy2;
Fz = analogs.Force_Fz2;

Mx = analogs.Moment_Mx2;
My = analogs.Moment_My2;
Mz = analogs.Moment_Mz2;

end