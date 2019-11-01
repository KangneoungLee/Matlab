function AutoSfunSiLS_AutoGenCANASCii(SilsLogDataTime, SilsSignalInformByDataType, AutoAscMultiRun, SaveFileName)

CheckCanSave=who('AutoAscMultiRun');
if isempty(CheckCanSave)
    ASCiiFile = fullfile(pwd, 'DataBase\ASCii_SilsOutput.asc')
else
    ASCiiFile = fullfile(pwd, 'DataBase\', SaveFileName);   
    [path, name, ext] = fileparts(ASCiiFile);
    ASCiiFile = fullfile(path, [name, '.asc'])
end
fileID = fopen(ASCiiFile, 'w');
ASCiiFileInform=dir(ASCiiFile);
ASCiiFileUpdateDate=ASCiiFileInform.date;
% fileID = fopen(ASCiiFile, 'w');
dscrpt = {['date ', num2str(ASCiiFileUpdateDate),'\n', 'base hex  timestamps absolute\ninternal events logged\n// version 7.0.1\nBegin Triggerblock', num2str(ASCiiFileUpdateDate),'\n   0.00 Start of measurement\n']};
dscrpt = strjoin(dscrpt);
fprintf(fileID, dscrpt);

TempPath = fullfile(pwd, 'DataBase\BtcsSilsDbc.dbc')
Candb = canDatabase(TempPath);

% clear ASCiiFileInform;
CanMsgData{1,1}=num2str('Time');
CanMsgData{2,1}=num2str('CAN ID');

LogByteOld=0;
SilsLogDataTime=evalin('base', 'SilsLogDataTime');
SilsSignalInformByDataType=evalin('base', 'SilsSignalInformByDataType');
for forcscell=1:length(SilsSignalInformByDataType(:,1)) %Signal Data
    SignalDataValue(forcscell,:)=SilsSignalInformByDataType{forcscell,14};
end
SignalDataValueTemp=num2cell(SignalDataValue);
for forct=1:length(SilsLogDataTime(:,1)) %Time Data
    for forcs=1:length(SilsSignalInformByDataType(:,1)) %Signal Data
        if forcs==1
            if (SilsSignalInformByDataType{forcs,17})~=LogByteOld
                forcm=0;
            end
        else
        end
        SignalDataValueCell{forcs,forct}=num2str(SignalDataValueTemp{forcs,forct});
        
        if (SilsSignalInformByDataType{forcs,17})==LogByteOld
            CanMsgDataCheck=0;
        else
            CanMsgDataCheck=1;
            CanMsgInfo = canMessage(Candb, num2str(SilsSignalInformByDataType{forcs,15}));
        end
        CanMsgInfo.Signals.(SilsSignalInformByDataType{forcs,1})=str2double(SignalDataValueCell{forcs,forct})*str2double(SilsSignalInformByDataType{forcs,5});
        if CanMsgDataCheck==1
            forcm=forcm+1;
            CanMsgData{1,forcm+1}=num2str(SilsSignalInformByDataType{forcs,15});
            CanMsgData{2,forcm+1}=num2str(SilsSignalInformByDataType{forcs,16});    
        else
        end
        CanMsgData{forct+2,1}=SilsLogDataTime(forct,1);
        CanMsgData{forct+2,forcm+1}=CanMsgInfo.Data;
        LogByteOld=SilsSignalInformByDataType{forcs,17};
    end
    
    if forct>1
        for forcd=1:forcm
            HexDataTemp=dec2hex(CanMsgData{forct+2,forcd+1});
            dscrpt = {['   ', num2str(CanMsgData{forct+2,1}), ' 2  ', num2str(CanMsgData{2,forcd+1}), '             Rx   d 8 ', num2str([HexDataTemp(1,:) ' ' HexDataTemp(2,:) ' ' HexDataTemp(3,:) ' ' HexDataTemp(4,:) ' ' HexDataTemp(5,:) ' ' HexDataTemp(6,:) ' ' HexDataTemp(7,:) ' ' HexDataTemp(8,:)]),'\n']};
            dscrpt = strjoin(dscrpt);
            fprintf(fileID, dscrpt);
        end
    else
    end
end

assignin('base', 'CanMsgData', CanMsgData);

dscrpt = 'End TriggerBlock\n';
fprintf(fileID, dscrpt);
fclose(fileID);

if (isempty(CheckCanSave)) || (AutoAscMultiRun==0)
helpdlg('CANalyzer Configuration을 다 만들었으면,                                      1.같은 SimulationLogsOut Data로 VarReGen_AutoGenCANdbc Function 실행 후, 2.SignalDataBase를 저장해 주세요~', ...
        'Inform to Save SignalData File');
end
