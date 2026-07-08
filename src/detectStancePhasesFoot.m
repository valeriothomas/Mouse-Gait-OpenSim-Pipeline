function validEvents = detectStancePhasesFoot(xyz,fs,MIN_SPEED)

y = xyz.RightMET(:,2);

vy = gradient(y,1/fs);
vyABS = abs(vy);

speedThresh = mean(vyABS(vyABS>0.00005),'omitnan');

stance = vyABS < speedThresh;

d = diff(double(stance));

IC = find(d==1)+1;
TO = find(d==-1)+1;

if ~isempty(IC) && ~isempty(TO)

    if TO(1) < IC(1)
        TO(1) = [];
    end

end

nPairs = min(length(IC),length(TO));

IC = IC(1:nPairs);
TO = TO(1:nPairs);

events = [IC TO];

%% NaN frames

names = fieldnames(xyz);

nFrames = size(xyz.(names{1}),1);

nanFrames = false(nFrames,1);

for k=1:numel(names)

    M = xyz.(names{k});

    nanFrames = nanFrames | ...
        any(isnan(M),2);

end

%% filter events

validEvents = [];

for i=1:size(events,1)

    s = events(i,1);
    e = events(i,2);

    durationOK = ...
        (e-s)>5 && ...
        (e-s)<18;

    containsNaN = ...
        any(nanFrames(s:e));

    if durationOK && ~containsNaN
         [~,speed] = ...
        computeVelocity( ...
        xyz.RightHIP(s:e,:),...
        fs);

        meanSpeed = ...
            mean(speed,'omitnan')/1000;
        
        if meanSpeed >= MIN_SPEED
        validEvents = ...
            [validEvents ; s e];
        end
    end

end

end