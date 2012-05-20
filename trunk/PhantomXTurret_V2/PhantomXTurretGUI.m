classdef PhantomXTurretGUI < handle
    %PhantomXTurret This controls the PhantomXTurret via a GUI
    %
    % To create a PhantomXSequencePlayer object with dedault parameters
    % h = PhantomXTurretGUI();
    %
    % Or to create with specific parameters: PhantomXMessagePort handle: messagePort_h
    % h = PhantomXTurretGUI(messagePort_h);
    %
    % To use the GUI to click specific pan and tilt step values
    % h.Run();
    
    properties        
        fig_h
        axis_h
        messagePort_h

        actualPose_h
        desiredPose_h
        timerPeriod = 0.5;
        runAsyncTimer
    end
    
    properties (Constant)
        MIN_PAN_STEP = 0;
        MAX_PAN_STEP = 1027;
        MIN_TILT_STEP = 160;
        MAX_TILT_STEP = 850;
    end
    
    methods
%% ..structors        
        function self = PhantomXTurretGUI(messagePort_h)
            if nargin == 0                
                self.messagePort_h = PhantomXMessagePort();                
            else
                self.messagePort_h = messagePort_h;
            end
        end

        function delete(self)
            try  %#ok<TRYNC>
                delete(self.fig_h);
            end
            self.StopShowGurrentPoseTimer();
        end

%% SetupFigure
% Setup the figure so the axis only allows valid areas to be shown and show
% the title
        function SetupFigure(self)
            if isempty(self.fig_h)
                self.fig_h = figure;
                self.axis_h = gca;
                hold on;
            else
                try 
                    figure(self.fig_h);
                catch %#ok<CTCH>
                    self.fig_h = figure;
                end
                    
                self.axis_h = gca;
                hold on;
            end
            self.SetupAxisAndTitle();            
        end
        
%% SetupAxisAndTitle        
        function SetupAxisAndTitle(self)
            axis([self.messagePort_h.MIN_PAN_STEP ...
                , self.messagePort_h.MAX_PAN_STEP ...
                , self.messagePort_h.MIN_TILT_STEP ...
                , self.messagePort_h.MAX_TILT_STEP]);
            title('Press return on the figure to quit','fontsize',18);
            xlabel('-- PAN --','fontsize',14);
            ylabel('-- TILT --','fontsize',14);
        end        
        
%% Run        
        function Run(self)
            self.messagePort_h.OpenPort();
            self.StartShowGurrentPoseTimer();
            try 
                while 1                
                    try 
                        self.SetupFigure();
                        [x,y]=ginput(1);
                    catch ME_1
                        display(ME_1);
%                         keyboard;
                        warning('There was a problem with ginput or the Figure has been closed incorrectly. Press return to stop') %#ok<WNTAG>                    
                        continue;
                    end

                    if isempty(x) || isempty(y)
                        return;
                    end
                    self.messagePort_h.Send(x,y);

                    try delete(self.desiredPose_h);end %#ok<TRYNC>
                    self.desiredPose_h = plot(x,y,'marker','*','MarkerSize',10,'color','g','parent',self.axis_h);
                    display(['DESIRED: pan = ',num2str(x),' tilt = ',num2str(y)]); 
                    self.SetupAxisAndTitle();
                end
            catch ME_1
                display(ME_1);                
            end
            self.messagePort_h.ClosePort();
            self.StopShowGurrentPoseTimer();
        end
        
%% Show pose position updater timer
        function StartShowGurrentPoseTimer(self)
            self.runAsyncTimer = timer('TimerFcn', @(src,event)ShowGurrentPose(self), 'name', 'runAsyncTimer','Period', self.timerPeriod,'BusyMode','drop','ExecutionMode','fixedDelay');
            start(self.runAsyncTimer);  
        end
        
        function StopShowGurrentPoseTimer(self)
            if ~isempty(self.runAsyncTimer) && strcmp(self.runAsyncTimer.Running,'on')
                stop(self.runAsyncTimer);
            end
        end
                    
        function ShowGurrentPose(self)
            try delete(self.actualPose_h);end %#ok<TRYNC>
            self.messagePort_h.pose
            if ~isempty(self.messagePort_h.pose) && length(self.messagePort_h.pose)==2
                try self.actualPose_h = plot(self.messagePort_h.pose(1),self.messagePort_h.pose(2),'marker','*','MarkerSize',10,'color','r','parent',self.axis_h);end; %#ok<TRYNC>
                display(['ACTUAL: pan = ',num2str(self.messagePort_h.pose(1)),' tilt = ',num2str(self.messagePort_h.pose(2))]); 
            end
        end                                
    end
    
end

