% control_node: simple ROS node demonstrating how to control the robot in
% the 'turtlesim' node.
%
%   Topics
%   ----------
%   Published: /turtle/cmd_vel
%   Message Type: geometry_msgs/Twist
%   Info: The linear and angular velocity of the robot. The linear velocity
%         command comes from linear.x and the angular velocity command 
%         comes from angular.z.
%
%   Subscribed: /turtle/pose
%   Message Type: turtlesim/Pose
%   Info: The 2D pose of the robot including (x,y) position and the
%         orientation angle.
%
%   Author: Kyle Larsen
%   Date: 30 Mar 2020

function [] = control_node()

    %=========================================================================%
    % Start ROS
    %=========================================================================%
    try
        rosinit;
    catch
    end

    % This shuts down ROS when the script is closed. This makes sure it runs
    % "rosinit" everytime the script starts. That way it is sure to connect to
    % any other instance of Matlab that may be running ROS. The output of this
    % assignment must be assigned to a variable (not the "~" placeholder) and
    % it must be in a function.
    cleanup_obj = onCleanup(@rosshutdown);

    %===== Publisher =====%
    velocity_msg = rosmessage('geometry_msgs/Twist');
    velocity_pub = rospublisher('/turtle/cmd_vel', 'geometry_msgs/Twist');

    %===== Subscriber =====%
    % This is made a global variable so it can be set in the callback function
    % and then used in the main loop
    global pose_msg;
    pose_sub = rossubscriber('/turtle/pose', 'turtlesim/Pose', @poseCallback);

    % ROS rate for setting the speed of the control loop
    loop_rate = rosrate(10); % 10Hz

    %=========================================================================%
    % Controller and Path
    %=========================================================================%
    % Control Gains
    Kp = 10; % proportional gain for linear velocity
    Kt = 10; % proportional gain for angular velocity
    max_lin = 20; % saturation linear velocity
    max_ang = 10*pi; % saturation angular velocity

    % Target
    target = [80;20]; % single target value, not needed if using the path below
    threshold = 5;

    % Heart Shape Path
    % (use any set of path points to follow)
    path = [50, 45, 40, 30, 20, 10, 20, 30, 40, 50, 60, 70, 80, 90, 80, 70, 60, 50;
            50, 60, 65, 70, 60, 50, 40, 30, 20, 10, 20, 30, 40, 50, 60, 70, 60, 50];

    % Get initial error
    pose_msg = receive(pose_sub); % waits until a message is published


    %=========================================================================%
    % Main Loop
    %=========================================================================%
    for point = path

        % Set new target point and obtain error
        target = point;
        error_x = (target(1) - pose_msg.X)^2;
        error_y = (target(2) - pose_msg.Y)^2;
        error = error_x + error_y;    

        % Use proportional control until the target is within the threshold
        while (error > threshold)
            % Update the error as the pose changes
            error_x = (target(1) - pose_msg.X)^2;
            error_y = (target(2) - pose_msg.Y)^2;
            error = error_x + error_y;

            % Obtain control variable using gains and error
            target_theta = atan2(target(2) - pose_msg.Y, target(1) - pose_msg.X);
            error_theta = wrapToPi(target_theta - pose_msg.Theta);

            % Saturate velocities
            velocity_msg.Linear.X = min(max_lin, Kp*sqrt(error));
            velocity_msg.Angular.Z = min(max_ang, Kt*error_theta);

            % Publish velocity
            velocity_pub.send(velocity_msg);

            % Used to set a specific loop rate
            waitfor(loop_rate);
        end

    end

end

%=========================================================================%
% Callback Functions
%=========================================================================%
function [] = poseCallback(~, msg)
    global pose_msg;
    pose_msg = msg;
end