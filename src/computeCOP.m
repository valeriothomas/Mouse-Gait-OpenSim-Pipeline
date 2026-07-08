function [CoPx,CoPy,CoPz] = ...
    computeCOP(Fx,Fy,Fz,Mx,My,Mz)

threshold = 0.01;

CoPx = zeros(size(Fz));
CoPy = zeros(size(Fz));
CoPz = zeros(size(Fz));

valid = abs(Fz) > threshold;

CoPx(valid) = -My(valid)./Fz(valid);
CoPy(valid) =  Mx(valid)./Fz(valid);

CoPz(:) = 0;

end