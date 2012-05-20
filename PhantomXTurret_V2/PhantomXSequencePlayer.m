classdef PhantomXSequencePlayer < handle
    %PHANTOMXSEQUENCEPLAYER This is used to load and play sequences of
    %movements
    % To create a PhantomXSequencePlayer object with dedault parameters
    % h = PhantomXSequencePlayer();
    %
    % Or to create with specific parameters: PhantomXMessagePort handle: messagePort_h
    % h = PhantomXSequencePlayer(messagePort_h);
    %
    % To save a trajectory consisting of poses
    % poses = [512,512;  600,400;  800,600; 810,610];
    % and times at which to execute these in ms. Note that these must be
    % ever-increasing: i.e. pose(1) happens at milliseconds(1), pose(2)
    % happens at milliseconds(2) or later if it is impossible to do this
    % fast.
    % milliseconds = [0;  500; 1250; 1400];   
    % trajectory = [poses,milliseconds];
    %
    % To set the trajectory into the sequence player
    % h.Set(trajectory);
    %
    % To save the trajectory to file (NOTE the data MUST be stored in
    % variable called "trajectory" (as shown above) or load will fail
    % save('trajectoryData.mat','trajectory');
    %
    % To load a trjectory from a filename 'trajectoryData.mat'
    % h.Load('trajectoryData.mat');
    %
    % To show the trajectory in memory
    % h.trajectory
    %
    % To play a trajectory that is in memory
    % h.Play();
    %
    % To play a trajectory that is in memory 10 times
    % h.PlayTimes(10);
    %
    % To play a sequence infitely until "ctrl+c" is pressed
    % h.PlayTimes(inf);
    %
    % To delete the player after use
    % delete(h);
    
    properties (SetAccess = protected)
        messagePort_h;
        trajectory
    end
    
    properties (Constant)
        PAUSE_MILLISECONDS = 1;
        PAN_COLLUM = 1;
        TILT_COLLUM = 2;
        MILLISECONDS_COLLUM = 3;
    end        
    
    methods
%% ..structors                
        function self = PhantomXSequencePlayer(messagePort_h)
            if nargin == 0                
                self.messagePort_h = PhantomXMessagePort();                
            else
                self.messagePort_h = messagePort_h;
            end
            
            if ~self.messagePort_h.OpenPort()
                error('Cannot open the serial port');
            end
        end
        
        function delete(self)
            self.messagePort_h.ClosePort()
        end
        
%% Play        
        function Play(self)
            tic
            cummulativeMilliseconds = 0;
            index = 1;
            if (~isempty(self.trajectory) && size(self.trajectory,2)==3)
                while index <= size(self.trajectory,1)
                    cummulativeMilliseconds = cummulativeMilliseconds + toc * 1000;
                    if self.trajectory(index,self.MILLISECONDS_COLLUM) < cummulativeMilliseconds
                        self.messagePort_h.Send(self.trajectory(index,self.PAN_COLLUM) ...
                                              , self.trajectory(index,self.TILT_COLLUM));
                        index = index +1;
                    else
                        pause(self.PAUSE_MILLISECONDS);
                    end
                end
            end
        end
        
%% PlayRepeater
% Note if you want infite play then set desiredReplays to inf        
        function PlayRepeater(self,desiredReplays)            
            for counter = 1:desiredReplays
                display(['Playing iteration: ',num2str(counter)]);
                self.Play();
            end
        end        

%% Load     
% load from file a set of poses and times pppp tttt milliseconds
        function Load(self,fileName)
            if nargin==1
                [fileName,pathName] = uigetfile();
            else
                pathName = [pwd,'\'];
            end
                
            data = load([pathName,fileName]);
            Set(self,data.trajectory);
        end

%% Set
% Set the poses and milliseconds of the trajectory
        function Set(self,trajectory)
            self.trajectory = trajectory;
        end        

    end    
end

