% drawTurtle: returns a 'polyshape' object for plotting the turtle's pose.
%
%   [pgon] = drawTurtle(x, y, orientation)    Reads in the turtle's pose and
%   calculates the points needed to draw a polygon representing the turtle.
%   The output of this function is a 'polyshape' object which can be
%   displayed using the 'plot' function directly.
%
%   Parameters
%   x = the turtle's x position
%   y = the turtle's y position
%   orientation = the turtle's orientation angle in radians
%   
%   Returns
%   pgon = object returned by 'polyshape' containing 'Vertices',
%          'NumRegions' and 'NumHoles'. This object can be displayed using
%          'plot(pgon)'.
%
%   Author: Kyle Larsen
%   Date: 30 Mar 2020

function [pgon] = drawTurtle(x, y, orientation)
    % Arrow Parameters
    length = 8;
    

    % Draw Arrowhead shape with point going in X axis direction.
    %
    % The center of the Arrowhead is in the middle of the length. The
    % 'thin' end is facing to the right along the X axis (positive
    % direction), and the 'wide' end is facing to the left along the X axis
    % (negative direction).
    %
    % The indent on the back is 1/9th of the total length.
    % The width is 2/3rds the length.
    %
    % The Point indices are outlined below
    %
    %  y        |- length --|   width
    %  ^      1 .                ---
    %  |         .' .             |
    %  |          .   ' .         |
    %  o-----> x 2 .      ' . 0   |
    %             .     . '       |
    %            .  . '           |
    %         3 . '              ---
    
    points_x = [length/2, -length/2, -length/2 + length/9, -length/2];
    points_y = [0, (1/3)*length, 0, -(1/3)*length];
    
    % Generate rotation matrix
    R = rot2D(orientation);
    
    % Rotate the points
    points_rotated = R*[points_x; points_y];
    
    % Translate the points
    points_translated_x = points_rotated(1,:) + x;
    points_translated_y = points_rotated(2,:) + y;
    
    pgon = polyshape(points_translated_x, points_translated_y);
end