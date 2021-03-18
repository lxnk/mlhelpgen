function [x, y, z, q] = pipe3(varargin)
%PIPE3 Generates point for a ring in 3D
%   Generates the points for SURF or draws them itself.
%   
%   [X,Y,Z] = PIPE3 Radius 1, z-up, 12 circle points, height 1
%   
%   [X,Y,Z] = PIPE3(R) Radius R, z-up, 12 circle points, height 1
%   
%   [X,Y,Z] = PIPE3(R,T) Radius R, direction T, 12 circle points
%   
%   [X,Y,Z] = PIPE3(R,T,N) Radius R, direction T, N circle points
%
%   [X,Y,Z] = PIPE3(R,T,N,C) Radius R, direction T, N circle points,
%   coordinates C (default [0; 0; 0])
%   
%   [X,Y,Z] = PIPE3(R,T,N,M) Radius R, direction T, N circle points,
%   M axial points
%
%   [X,Y,Z] = PIPE3(R,T,N,C,M) Radius R, direction T, N circle points,
%   coordinates C (default [0; 0; 0]), M axial points (if R is not a scalar 
%   or/and T or/and C is matrix, M is ignored, otherwise default 2)
%
%   [X,Y,Z,Q] = PIPE3(R,T,N,C,M,B) Returns the color data Q with bounds for
%   ring data B = [Bmin Bmax]



% The code from the axescheck()
args = varargin;
nargs = nargin;
% ax=[];
% 
% % Check for either a scalar numeric Axes handle, or any size array of Axes.
% % 'isgraphics' will catch numeric graphics handles, but will not catch
% % deleted graphics handles, so we need to check for both separately.
% if (nargs > 0) && ...
%         ((isnumeric(args{1}) && isscalar(args{1}) && isgraphics(args{1}, 'axes')) ...
%         || isa(args{1},'matlab.graphics.axis.AbstractAxes') || isa(args{1},'matlab.ui.control.UIAxes'))
%   ax = handle(args{1});
%   args = args(2:end);
%   nargs = nargs-1;
% end

% --- Default values ---
ringRadius = 1;
ringData = .5;
axisTangent = [0; 0; 1];
axisTangentNorm = 1;
nCirclePoints = 12;
nAxisPoints = 2;
ringCoordinates = [0; 0; 0];

% --- Read arguments ---
if nargs >= 1
    ringRadius = args{1};
    if isrow(ringRadius)
    elseif iscolumn(ringRadius)
        ringRadius = shiftdim(ringRadius(:),1);
    elseif ismatrix(ringRadius) && size(ringRadius,1) == 2
        ringData = ringRadius(2,:);
        ringRadius = ringRadius(1,:);
    end
    validateattributes(ringRadius, {'numeric'}, {'real', 'nonempty', 'vector'})
    validateattributes(ringData, {'numeric'}, {'real', 'nonempty', 'vector'})
end


if nargs >= 2
    axisTangent = args{2};
    if isrow(axisTangent)
        axisTangent = axisTangent(:);
    end
    axisTangentNorm = vecnorm(axisTangent);
    validateattributes(axisTangent, {'numeric'}, {'real', 'nonempty', 'size', [3 NaN]})
    validateattributes(axisTangentNorm, {'numeric'}, {'real', 'nonempty', 'row', 'positive'})
end
if nargs >= 3
    nCirclePoints = args{3};
    validateattributes(nCirclePoints, {'numeric'}, {'integer', 'scalar', '>=' 3})
end

if nargs >= 4
    if isscalar(args{4}) % && args{4} == round(args{4}) %isinteger(args{4})
        nAxisPoints = args{4};
        validateattributes(nAxisPoints, {'numeric'}, {'integer', 'scalar', '>=' 1})
    else
        ringCoordinates = args{4};
        if isrow(ringCoordinates)
            ringCoordinates = ringCoordinates(:);
        end
        validateattributes(ringCoordinates, {'numeric'}, {'real', 'nonempty', 'size', [3 NaN]})
    end
    
end

if nargs >= 5
    ringCoordinates = args{4};
    nAxisPoints = args{5};
    validateattributes(nAxisPoints, {'numeric'}, {'integer', 'scalar', '>=' 1})
    if isrow(ringCoordinates)
            ringCoordinates = ringCoordinates(:);
    end
    validateattributes(ringCoordinates, {'numeric'}, {'real', 'nonempty', 'size', [3 NaN]})
end


[ringDataMin, ringDataMax] = bounds(ringData);
if ringDataMin == ringDataMax
    ringDataMin = ringDataMin - 1;
    ringDataMax = ringDataMax - 1;
end

if nargs >= 6
    ringDataBounds = args{6};
    ringDataBounds = ringDataBounds(:);
    
    validateattributes(ringDataBounds, {'numeric'}, {'real', 'nonempty', 'size', [2 1]})
    ringDataMin = ringDataBounds(1);
    ringDataMax = ringDataBounds(2);
end
% --- Main code ---


axisTangentUnit = axisTangent./axisTangentNorm;

szT = size(axisTangentUnit);
axisPerp1 = zeros(szT);
axisPerp2 = zeros(szT);
et = [0;0;1];
en1 = [1;0;0];
en2 = [0;1;0];
for i=1:szT(2)
    m = rotationMatrix(et,axisTangentUnit(:,i));
    et = axisTangentUnit(:,i);
    en1 = m*en1;
    en2 = m*en2;
    axisPerp1(:,i) = en1;
    axisPerp2(:,i) = en2;
end


e1 = ringRadius .* permute(axisPerp1, [3 2 1]);
e2 = ringRadius .* permute(axisPerp2, [3 2 1]);


theta = shiftdim(2.*pi.*(0:nCirclePoints)./nCirclePoints, 1);

points = e1 .* cos(theta) + e2 .* sin(theta);

nAxisPoints = max(nAxisPoints, size(points, 2));

if iscolumn(ringCoordinates)
    axisTangent = ones(1,nAxisPoints) .* axisTangent;
    axisTangent = [[0;0;0] axisTangent(:,1:end-1)];
    ringCoordinates = ringCoordinates + cumsum(axisTangent, 2);
end

points = points + permute(ringCoordinates, [3 2 1]);

x = points(:,:,1);
y = points(:,:,2);
z = points(:,:,3);

map = parula;
ringDataScaled = (ringData - ringDataMin)./(ringDataMax - ringDataMin);
ringDataScaled(ringDataScaled>1) = 1;
ringDataScaled(ringDataScaled<0) = 0;
ringDataScaled = ones(nCirclePoints,nAxisPoints) .* 1+round((size(map,1)-1).*ringDataScaled);

q = reshape(map(ringDataScaled(:),:),nCirclePoints,nAxisPoints,3);

end


function m = rotationMatrix(a1,a2)
    %rotationMatrix is based on the makehgtform function
    % We use normalised vectors a1 and a2, therefore we skip the norm check
    u = cross(a1,a2); %/norm(a1)/norm(a2);
    c = dot(a1,a2); %/norm(a1)/norm(a2);
    m = c*eye(3);
    if any(u)
        s = norm(u);
        u = u./s;
        skewSymm = [   0  -u(3)  u(2); ...
                     u(3)    0  -u(1); ...
                    -u(2)  u(1)    0];
        m = m + (1-c)*kron(u,u') + s*skewSymm;
    end
end
