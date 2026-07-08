function [Fx,Fy,Fz,Mx,My,Mz] = ...
    preprocessForcePlate(Fx,Fy,Fz,Mx,My,Mz)

%% Remove offsets

Fx = removeOffset(Fx);
Fy = removeOffset(Fy);
Fz = removeOffset(Fz);

Mx = removeOffset(Mx);
My = removeOffset(My);
Mz = removeOffset(Mz);

%% Low-pass filter

Fx = lowpassFilter(Fx);
Fy = lowpassFilter(Fy);
Fz = lowpassFilter(Fz);

Mx = lowpassFilter(Mx);
My = lowpassFilter(My);
Mz = lowpassFilter(Mz);

%% Nexus sign correction

Fx = -Fx;
Fz = -Fz;

Mx = -Mx;
Mz = -Mz;

end