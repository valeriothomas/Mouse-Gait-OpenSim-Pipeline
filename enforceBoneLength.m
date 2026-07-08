function [m1,m2] = enforceBoneLength(m1,m2,lengthTol)

d = vecnorm(m1-m2,2,2);

dRef = median(d,'omitnan');
dStd = std(d,'omitnan');

bad = abs(d-dRef) > lengthTol*dStd;

m1(bad,:) = NaN;
m2(bad,:) = NaN;

end