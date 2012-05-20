classdef PhantomXMessagePort < handle
    %PHANTOMXMESSAGEPORT Holds the serial port, issues commands and keeps
    %track of the state of the turret
    %
    % To create a PhantomXMessagePort object with dedault parameters
    % h = PhantomXMessagePort();
    %
    % Or to create with specific parameters: port and the baudrate
    % h = PhantomXMessagePort('COM1',38400);
    %
    % To open the message port and to start listening for joint poses
    % h.OpenPort();
    %
    % To get the current pose values: pan and tilt
    % pan = h.pose(1);
    % tilt = h.pose(2);
    %
    % To send a command to move PhantomX to a specific pose: [pan tilt]
    % pand = 400;
    % tilt = 600;
    % h.Send(pan,tilt);
    %
    % To close the port after use
    % h.ClosePort();
    
    properties (SetAccess = protected)
        port = 'COM14';
        baudrate = 38400;
        serial_h
        
        running = true;

        portOpen = false;
        actualPose_h
        desiredPose_h
        pose
        
        serialReadCountDownMilliseconds = 10000;
        timerPeriod = 0.35;        
        runAsyncTimer
    end
    
    properties (Constant)
        PACKET_LENGTH = 11;
        MIN_PAN_STEP = 0;
        MAX_PAN_STEP = 1027;
        MIN_TILT_STEP = 160;
        MAX_TILT_STEP = 850;
    end
    
    methods
%% ..structors        
        function self = PhantomXMessagePort(port,baudrate)
            if nargin == 2
                self.port = port;
                self.baudrate = baudrate;
            end           
        end

        function delete(self)
            self.ClosePort();
        end
        
%% Send
        function Send(self,pan,tilt)
            [pan,tilt] = self.KeepInPanAndTiltBounds(pan,tilt);
            pppp = strpad(num2str(round(pan)),4);
            tttt = strpad(num2str(round(tilt)),4);
                    
            if self.portOpen
                cmd = [':',pppp,',',tttt,';'];
                fprintf(self.serial_h,cmd);
                display(['COMMAND ',cmd]);
            else
                display('Port is current closed. Command not sent.');
            end                
        end
        
%% Pose updating timer        
        function StartGetGurrentPoseTimer(self)
            self.runAsyncTimer = timer('TimerFcn', @(src,event)GetGurrentPose(self), 'name', 'RunAsync','Period', self.timerPeriod,'BusyMode','drop','ExecutionMode','fixedDelay');
            start(self.runAsyncTimer);  
        end
        
        function StopGetGurrentPoseTimer(self)
            if ~isempty(self.runAsyncTimer) && strcmp(self.runAsyncTimer.Running,'on')
                stop(self.runAsyncTimer);
            end
        end
                    
        function GetGurrentPose(self)
            %display('GetGurrentPose');
            if self.portOpen
                tic
                previousToc = toc;
                bytesAvailable = self.serial_h.BytesAvailable;
                while bytesAvailable < 2*self.PACKET_LENGTH                                        
                    pause(0.05);                    
                    if self.serialReadCountDownMilliseconds < toc * 1000
                        warning('Not getting data back from serial port. Closing port'); %#ok<WNTAG>
                        self.ClosePort();
                        break;
                    else
                        bytesAvailable = self.serial_h.BytesAvailable;
                    end
                    if round(previousToc) < round(toc)
                        display(['Waiting for data. So far waited ',num2str(toc),'secs']);
                        previousToc = toc;
                    end
                end
                
                if self.portOpen
                    % Get all the data available                    
                    dataStr = char(fread(self.serial_h,bytesAvailable)); %#ok<FREAD> % DONT CHANGE THIS BECAUSE IT DOES A DIFFERENT THING IF CHANGED
                    packet = dataStr(find(dataStr== ';',1,'last')-10:find(dataStr == ';',1,'last'));
                    %packet = fscanf(self.serial_h);
                    % Get the last packet
                    if ~strcmp(packet(1),':') || ~strcmp(packet(6),',') || ~strcmp(packet(11),';')
                        warning('A problem with this packet. Must be in the form :pppp,tttt;'); %#ok<WNTAG>                       
                    end
                    % Set the pose
                    self.pose(1) = round(str2double(packet(2:5)));
                    self.pose(2) = round(str2double(packet(7:10)));                   
                end                
            end
        end
                            
%% KeepInPanAndTiltBounds
% Fix the pan and tilt angles entered so they are within the movement
% bounds of the servos
        function [newPan,newTilt] = KeepInPanAndTiltBounds(self,pan,tilt)        
            newPan = pan;
            newTilt = tilt;
            if newPan < self.MIN_PAN_STEP
                newPan = self.MIN_PAN_STEP;
            elseif self.MAX_PAN_STEP < newPan
                newPan = self.MAX_PAN_STEP;
            end
            
            if newTilt < self.MIN_TILT_STEP
                newTilt = self.MIN_TILT_STEP;
            elseif self.MAX_TILT_STEP < newTilt
                newTilt = self.MAX_TILT_STEP;
            end
        end
        
%% OpenPort        
        function result = OpenPort(self)
            result = false;
            try
                if isempty(self.serial_h)
                    self.serial_h = serial(self.port,'BaudRate',self.baudrate);
                end
                if ~strcmp(get(self.serial_h,'Status'),'open')
                    fopen(self.serial_h);
                end
                    
                if strcmp(get(self.serial_h,'Status'),'open')
                    self.portOpen = true;
                    self.StartGetGurrentPoseTimer();
                    result = self.portOpen;
                else
                    warning('Port not opened'); %#ok<WNTAG>
                end
                
            catch ME_1
                display(ME_1);
            end            
            
        end
        
%% ClosePort        
        function ClosePort(self)
            self.StopGetGurrentPoseTimer();
            try      %#ok<TRYNC>
                fclose(self.serial_h);
%             catch ME_1
%                 display(ME_1);
            end
            self.portOpen = false;
        end            
    end    
end

