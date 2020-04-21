% rot2D: creates a 2D rotation matrix from a coordinate frame which has
% been rotated by an angle, theta.
%
%   [R] = rot2D(theta): Creates a 2D rotation matrix for a frame rotated by
%   an angle, theta, in radians. The matrix R projects a 2D point from the
%   second cooridnate system back onto the original coordinate system.
%
%   Parameters
%   theta = angle the second frame has been rotated with respect to the
%   first
%   
%   Returns
%   R = 2x2 rotation matrix
%
%   Author: Kyle Larsen
%   Date: 28 Feb 2020


function [R] = rot2D(theta)
    R = [cos(theta) -sin(theta);
         sin(theta)  cos(theta)];
end