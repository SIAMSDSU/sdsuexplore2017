function output=testFunc(strin,variable)
hasvars=regexp(strin,sprintf('[%s]',variable),'ONCE');
if(isempty(hasvars))
    output=-1;
else
    strtest=sprintf('@(%s)(%s)',variable,strin);
    try
        handle=str2func(strtest);
        result=handle(rand(1));
        output=isnumeric(result);
    catch 
        warndlg(sprintf('Could not parse function %s!',strin));
        output=0;
    end
end
end