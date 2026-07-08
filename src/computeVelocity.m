function [velVector,speed] = ...
    computeVelocity(markerXYZ,samplingRate)

dt = 1/samplingRate;

velVector = zeros(size(markerXYZ));

velVector(2:end-1,:) = ...
    (markerXYZ(3:end,:) - markerXYZ(1:end-2,:)) ...
    /(2*dt);

velVector(1,:) = ...
    (markerXYZ(2,:) - markerXYZ(1,:))/dt;

velVector(end,:) = ...
    (markerXYZ(end,:) - markerXYZ(end-1,:))/dt;

speed = vecnorm(velVector,2,2);

end