function v = normalizeVector(v)

v = double(v);

if any(isnan(v))
    error('Vector contains NaNs')
end

n = norm(v);

if n < 1e-12
    error('Near-zero vector')
end

v = v./n;

end