% turtlesim: ROS node that simulates a simple robot used for teaching ROS
% principles.
%
%   [] = turtlesim() - Starts a ROS node that generates a simple 2D robot
%   in a figure. The robot can be controlled by publishing a linear X
%   velocity and an angular Z velocity to the "/turtle/cmd_vel" topic. The
%   robot's pose is published to "/turtle/pose". This is intended to be a
%   Matlab version of the "turtlesim" node provide with ROS on Ubuntu.
%
%   Topics
%   ----------
%   Published: /turtle/pose
%   Message Type: turtlesim/Pose
%   Info: The 2D pose of the robot including (x,y) position and the
%         orientation angle.
%
%   Subscribed: /turtle/cmd_vel
%   Message Type: geometry_msgs/Twist
%   Info: The linear and angular velocity of the robot. The linear velocity
%         command comes from linear.x and the angular velocity command 
%         comes from angular.z.
%
%   Author: Kyle Larsen
%   Date: 30 Mar 2020

%=========================================================================%
% Set Global Parameters
%=========================================================================%
% When set to 'true' the program ends
% this is set to true in the callback function when the "close figure"
% button is pressed.
global quit_program;
quit_program = false;

%=========================================================================%
% Start ROS
%=========================================================================%
try
    rosinit;
catch
end

% Needs to be global os it can be accessed in the subscriber over
% consecutive callbacks
global loop_rate;
loop_rate = rosrate(30);

velocity_rate = rosrate(30);
reset(velocity_rate);

% Needs to be global so it can be modified in the subscriber callback
% function
global turtle_pose_msg current_linear_cmd current_angular_cmd;
turtle_pose_msg = rosmessage('turtlesim/Pose');

% Size of the gridspace (needs to be global for the callback function)
global gridsize_x gridsize_y;
gridsize_x = 100;
gridsize_y = 100;

% Set Initial Pose
turtle_pose_msg.X = gridsize_x/2;
turtle_pose_msg.Y = gridsize_y/2;
turtle_pose_msg.Theta = pi/2;
turtle_pose_msg.LinearVelocity = 0;
turtle_pose_msg.AngularVelocity = 0;
current_linear_cmd = 0;
current_angular_cmd = 0;

%===== Publisher =====%
turtle_pose_pub = rospublisher('/turtle/pose', 'turtlesim/Pose');

%===== Subscriber =====%
turtle_vel_sub = rossubscriber('/turtle/cmd_vel', 'geometry_msgs/Twist', @turtleVelCallback);


%=========================================================================%
% Create and Format Visualization Objects
%=========================================================================%
% These objects need to be global so they can be edited in the callback
% function
global path turtle;

close all;
fig = figure(1);
set(fig, 'CloseRequestFcn', @closeCallback);
ax = axes;
disableDefaultInteractivity(ax);
ax.Toolbar.Visible = 'off';
plotedit off;
hold on;

%===== Create Bounding Box =====%
pgon_box = polyshape([0, gridsize_x, gridsize_x, 0], [0, 0, gridsize_y, gridsize_y]);
box = plot(pgon_box);
box.FaceColor = [0.1, 0.1, 0.1];
box.FaceAlpha = 0.1;
box.LineWidth = 2;

%===== Create Path =====%
path = plot(turtle_pose_msg.X, turtle_pose_msg.Y, 'r-');
path.LineWidth = 1;

%===== Create Turtle =====%
pgon_turtle = drawTurtle(turtle_pose_msg.X, turtle_pose_msg.Y, turtle_pose_msg.Theta);
turtle = plot(pgon_turtle);
turtle.FaceColor = [0.1, 0.5, 1];
turtle.FaceAlpha = 0.85;
turtle.LineWidth = 2;

%===== Define Axes Shape =====%
set(ax, 'XLim', [0, gridsize_x]);
set(ax, 'YLim', [0, gridsize_y]);
axis square;


%=========================================================================%
% Main Loop
%=========================================================================%
tic;
while true
    % Update position if new message has been received and timer has been
    % reset
    if (loop_rate.TotalElapsedTime < 1.0)
        %--- Time since last velocity change ---%
        %dt = velocity_rate.TotalElapsedTime;
        %reset(velocity_rate);
        dt = toc;
        
        %--- Update pose using previous velocity ---%
        % Rotate velocity to get dx and dy for current orientation
        R = rot2D(turtle_pose_msg.Theta);
        dv = R*[turtle_pose_msg.LinearVelocity;0];
        dx = dv(1)*dt;
        dy = dv(2)*dt;
        
        % Update pose values (saturate at the boundary)
        turtle_pose_msg.X = turtle_pose_msg.X + dx;
        turtle_pose_msg.Y = turtle_pose_msg.Y + dy;
        turtle_pose_msg.X = max(0, turtle_pose_msg.X);
        turtle_pose_msg.X = min(gridsize_x, turtle_pose_msg.X);
        turtle_pose_msg.Y = max(0, turtle_pose_msg.Y);
        turtle_pose_msg.Y = min(gridsize_y, turtle_pose_msg.Y);
        
        % Update orientation
        dTheta = turtle_pose_msg.AngularVelocity*dt;
        turtle_pose_msg.Theta = wrapToPi(turtle_pose_msg.Theta + dTheta);
        
        % Redraw Turtle
        turtle.Shape = drawTurtle(turtle_pose_msg.X, turtle_pose_msg.Y, turtle_pose_msg.Theta);
        
        % Add point to path
        path.XData = [path.XData, turtle_pose_msg.X];
        path.YData = [path.YData, turtle_pose_msg.Y];
        
        %--- Update current velocity ---%
        turtle_pose_msg.LinearVelocity = current_linear_cmd;
        turtle_pose_msg.AngularVelocity = current_angular_cmd;
        
        % Reset timer
        tic;
    else
        % Reset current velocities to 0
        current_linear_cmd = 0;
        current_angular_cmd = 0;
        turtle_pose_msg.LinearVelocity = 0;
        turtle_pose_msg.AngularVelocity = 0;
    end
        
    % Publish current pose
    turtle_pose_pub.send(turtle_pose_msg);
    
    if (quit_program)
        rosshutdown;
        return;
    end
    
    waitfor(loop_rate);
end


%=========================================================================%
% Callback Functions
%=========================================================================%
%===== GUI Callback Functions =====%
function [] = closeCallback(src, callbackdata)
    % Delete the figure
    delete(gcf);
    % Trigger program exit
    global quit_program;
    quit_program = true;
end

%===== Subscriber Callback Functions =====%
function [] = turtleVelCallback(~, msg)
    global loop_rate current_linear_cmd current_angular_cmd;

    % Update current velocities
    current_linear_cmd = msg.Linear.X;
    current_angular_cmd = msg.Angular.Z;
    
    % Reset the loop timer
    reset(loop_rate);
end