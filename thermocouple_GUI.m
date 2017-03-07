function thermocouple_GUI()
data = zeros(1e6,1);
time = zeros(1e6,1);
running=0;
s = serial('/dev/ttyUSB0','BaudRate',9600);
fopen(s);
if checkStatus()==0
    shutdown();
end

uicontrol('Style', 'togglebutton', 'String', 'Start!',...
    'Position', [10 285 50 20],...
    'Callback', @collectData);
uicontrol('Style', 'togglebutton', 'String', 'Exit!',...
    'Position', [10 255 50 20],...
    'Callback', @exitProgram);

    function isgood=checkStatus()
        if s.Status ~= 'open'
            isgood=0;
        else
            isgood=1;
        end
    end

    function getData()
        data = zeros(1e6,1);
        time = zeros(1e6,1);
        tic;
        i=1;
        while(running==1 && checkStatus())
            stringdata=fscanf(s);
            dubble=str2double(deblank(stringdata));
            if(~isnan(dubble))
                data(i)=dubble;
                time(i)=toc; 
                plot(time(1:i),data(1:i));
                drawnow;
                i=i+1;
            end
            pause(0.1);
        end
            
    end

    function shutdown()
        fclose(s);
        delete(s);
        clear s;
    end


function collectData(source,~)
    if running==0
        running=1;
        source.String='Stop!';
        getData();
    else
        running=0;
        source.String='Start!';
        
    end

end

    function exitProgram(varargin)
        shutdown();
        clearvars;
        close all;
    end


end
