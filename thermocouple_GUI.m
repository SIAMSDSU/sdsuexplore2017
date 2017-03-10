function thermocouple_GUI()
data = zeros(1e5,1);
time = zeros(1e4,1);
running=0;

scrsz = get(0,'ScreenSize');
% scrsz: [left,bottom,width,height]

%setup GUI figure
fg1ht=60;
fg1bottom=scrsz(4)-fg1ht;
fg1left=1;
fg1width=scrsz(3);
fg1 = figure(1);
set(fg1,'Position',[fg1left,fg1bottom,fg1width,fg1ht]);
set(fg1,'MenuBar','none','ToolBar','none');

%setup plot figure
fg2 = figure(2);
fg2bottom=1;
fg2ht=scrsz(4)-2.3*fg1ht;
fg2left=1;
fg2width=scrsz(3);
set(fg2,'Position',[fg2left,fg2bottom,fg2width,fg2ht]);
set(fg2,'MenuBar','none','ToolBar','none');

% setup buttons
% start/stop logging button
startbtn_left=15; 
btn_bottom=(fg1ht-20)/2;
btn_width=50;
btn_height=20;
uicontrol('Style', 'togglebutton', 'String', 'Start!',...
    'Position', [startbtn_left,btn_bottom,btn_width,btn_height],...
    'Callback', @collectData,'Parent',fg1);
% exit button
exitbtn_left=startbtn_left+btn_width+7; 
btn_bottom=(fg1ht-20)/2;
uicontrol('Style', 'togglebutton', 'String', 'Exit!',...
    'Position', [exitbtn_left,btn_bottom,btn_width,btn_height],...
    'Callback', @exitProgram,'Parent',fg1);

% setup model fields
% function LHS, text (LaTeX image, actually)
field_bottom=(fg1ht-20)/2;
field_height=20;
LHS_text_left=exitbtn_left+btn_width+7;
LHS_text_width=25;
figure(fg1);
axes('units','pixels','position',[LHS_text_left field_bottom LHS_text_width field_height],'visible','off')
text(0,0.5,'$T(t)=$','interpreter','latex',...
    'horiz','left','vert','middle');
% first function box
fn_width=75;
fn1_left=LHS_text_left+LHS_text_width+20;
fn1=uicontrol('Style', 'edit','Parent',fg1, ...
    'Position', [fn1_left,field_bottom,fn_width,field_height]);
% first plus sign
plus1_text_left=fn1_left+fn_width+7;
plus_text_width=10;
figure(fg1);
axes('units','pixels','position',[plus1_text_left field_bottom plus_text_width field_height],'visible','off')
text(0,0.5,'$+$','interpreter','latex',...
    'horiz','left','vert','middle');
% second function box
fn2_left=plus1_text_left+plus_text_width+7;
fn2=uicontrol('Style', 'edit','Parent',fg1, ...
    'Position', [fn2_left,field_bottom,fn_width,field_height]);
% second plus sign
plus2_text_left=fn2_left+fn_width+7;
figure(fg1);
axes('units','pixels','position',[plus2_text_left field_bottom plus_text_width field_height],'visible','off')
text(0,0.5,'$+$','interpreter','latex',...
    'horiz','left','vert','middle');
% third function box
fn3_left=plus2_text_left+plus_text_width+7;
fn3=uicontrol('Style', 'edit','Parent',fg1, ...
    'Position', [fn3_left,field_bottom,fn_width,field_height]);
% third plus sign
plus3_text_left=fn3_left+fn_width+7;
figure(fg1);
axes('units','pixels','position',[plus3_text_left field_bottom plus_text_width field_height],'visible','off')
text(0,0.5,'$+$','interpreter','latex',...
    'horiz','left','vert','middle');
% fourth function box
fn4_left=plus3_text_left+plus_text_width+7;
fn4=uicontrol('Style', 'edit','Parent',fg1, ...
    'Position', [fn4_left,field_bottom,fn_width,field_height]);
% fourth plus sign
plus4_text_left=fn4_left+fn_width+7;
figure(fg1);
axes('units','pixels','position',[plus4_text_left field_bottom plus_text_width field_height],'visible','off')
text(0,0.5,'$+$','interpreter','latex',...
    'horiz','left','vert','middle');
% fourth function box
fn5_left=plus4_text_left+plus_text_width+7;
fn5=uicontrol('Style', 'edit','Parent',fg1, ...
    'Position', [fn5_left,field_bottom,fn_width,field_height]);
% fit model button
fitbtn_left=fn5_left+fn_width+10;
uicontrol('Style', 'togglebutton', 'String', 'Fit!',...
    'Position', [fitbtn_left,btn_bottom,btn_width,btn_height],...
    'Callback', @fitModel,'Parent',fg1);

% start serial process
s = serial('/dev/ttyUSB0','BaudRate',9600);
fopen(s);
if checkStatus()==0
    exitProgram();
end

% check serial status
function isgood=checkStatus()
    if s.Status ~= 'open'
        isgood=0;
    else
        isgood=1;
    end
end

% log data
function getData()
    data = zeros(1e6,1);
    time = zeros(1e6,1);
    tic;
    i=1;
    while(running==1 && checkStatus())
        stringdata=fscanf(s);
        dubble=str2double(deblank(stringdata));
        figure(fg2);
        if(~isnan(dubble))
            data(i)=dubble;
            time(i)=toc; 
            plot(time(1:i),data(1:i),'.-');
            ylim([32,110]);
            xlabel('Time (s)');
            ylabel('Temperature ($\circ$F)');
            title('Temperature over Time');
            drawnow;
            i=i+1;
        end
    end
end

function fitData(fncell,nfuns)
    nlen=find(time~=0,1,'last');
    X=zeros(nlen,nfuns+1);
    for tix=1:nlen
        X(tix,1)=1;
        for fnix=2:nfuns+1
            fnh=str2func(sprintf('@(t)(%s)',fncell{fnix-1}{1}));
            X(tix,fnix)=fnh(time(tix));
        end
    end
    Y=data(1:nlen);
    params=(X'*X)\(X'*Y);
    fitvals=X*params;
    err=Y-fitvals;
    SSE=err'*err;% SSE=RSS
    epsvar=SSE/(nlen+nfuns);
    AIC=(SSE+2*(nfuns+1)*epsvar)/(nlen*epsvar);
    figure(fg2);
    clf;
    plot(time(1:nlen),data(1:nlen),'.');
    ylim([32,110]);
    xlabel('Time (s)');
    ylabel('Temperature ($\circ$F)');
    title('Temperature over Time');
    hold on;
    plot(time(1:nlen),fitvals,'r');
    legend({'Measurements';sprintf('Fit: AIC=%.5e',AIC)});
    hold off;
    drawnow;
end
        

% shut down serial object
function shutdown()
    fclose(s);
    delete(s);
    clear s;
end

% UI callback functions
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

function fitModel(varargin)
    valid_funs=0;
    fns={};
    if(~strcmp(fn1.String,''))
        result=testFunc(fn1.String,'t');
        if(result==1)
            % valid function; store!
            valid_funs=valid_funs+1;
            fns{valid_funs}=cellstr(fn1.String);
        elseif(result==0)
            % kill function, do nothing!
            return;
        end
    end
    if(~strcmp(fn2.String,''))
        result=testFunc(fn2.String,'t');
        if(result==1)
            % valid function; store!
            valid_funs=valid_funs+1;
            fns{valid_funs}=cellstr(fn2.String);
        elseif(result==0)
            % kill function, do nothing!
            return;
        end
    end
    if(~strcmp(fn3.String,''))
        result=testFunc(fn3.String,'t');
        if(result==1)
            % valid function; store!
            valid_funs=valid_funs+1;
            fns{valid_funs}=cellstr(fn3.String);
        elseif(result==0)
            % kill function, do nothing!
            return;
        end
    end
    if(~strcmp(fn4.String,''))
        result=testFunc(fn4.String,'t');
        if(result==1)
            % valid function; store!
            valid_funs=valid_funs+1;
            fns{valid_funs}=cellstr(fn4.String);
        elseif(result==0)
            % kill function, do nothing!
            return;
        end
    end
    if(~strcmp(fn5.String,''))
        result=testFunc(fn5.String,'t');
        if(result==1)
            % valid function; store!
            valid_funs=valid_funs+1;
            fns{valid_funs}=cellstr(fn5.String);
        elseif(result==0)
            % kill function, do nothing!
            return;
        end
    end
    if(~isempty(fns))
        fitData(fns,valid_funs);
    end
end

% exit the program gracefully
function exitProgram(varargin)
    shutdown();
    clearvars;
    close all;
end

end