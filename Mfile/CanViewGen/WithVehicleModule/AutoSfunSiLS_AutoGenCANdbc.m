function [SilsLogDataTime, SilsSignalInformByDataType] = AutoSfunSiLS_AutoGenCANdbc(AutoAscMultiRun, LogOutDataName)

% Handle response
CheckCanSave=who('AutoAscMultiRun');
if (isempty(CheckCanSave)) || (AutoAscMultiRun==0)
    choice = questdlg('Do you create New CANalyzer Configuration?', ...
	'CANalyzer Configuration Set', ...
	'Yes','No','No');    
    switch choice
        case 'Yes'
            disp([choice ' Set Complete.'])
            CanalyzerCfgSet = 1;
        case 'No'
            disp([choice ' Set Complete.'])
            CanalyzerCfgSet = 0;
    end
else
    CanalyzerCfgSet = 1;
end 

load(LogOutDataName);

% read signal information from excel file
FileName = fullfile(pwd, 'DataBase\SignalDataBase.xlsx');
  
    [~, ~, ExcelData] = xlsread(FileName);
    [num,~] = size(ExcelData);
    s = dir(FileName);
    LastUpdatedDate = s.date;
    SignalData = struct;
    SignalData.Date = LastUpdatedDate;
    
    FieldName{1} = 'SignalName';FieldName{2} = 'Minimum';FieldName{3} = 'Maximum';FieldName{4} = 'DataType';FieldName{5} = 'Resolution';
    FieldName{6} = 'PhysicalMinumum';FieldName{7} = 'PhysicalMaximum';FieldName{8} = 'PhysicalUnit';FieldName{9} = 'PortDimension';FieldName{10} = 'SampleTime';
    FieldName{11} = 'Description';

    DataTypeName{1}= 'uint32';DataTypeName{2}= 'int32';DataTypeName{3}= 'uint16';DataTypeName{4}= 'int16';
    DataTypeName{5}= 'uint8';DataTypeName{6}= 'int8';DataTypeName{7}= 'boolean';
    DataTypeNameForDBC{1}= '32@1+';DataTypeNameForDBC{2}= '32@1-';DataTypeNameForDBC{3}= '16@1+';DataTypeNameForDBC{4}= '16@1-';
    DataTypeNameForDBC{5}= '8@1+';DataTypeNameForDBC{6}= '8@1-';DataTypeNameForDBC{7}= '1@1+';
    DataTypeNameForSort{1}= '1_32+';DataTypeNameForSort{2}= '1_32-';DataTypeNameForSort{3}= '1_16+';DataTypeNameForSort{4}= '1_16-';
    DataTypeNameForSort{5}= '1_08+';DataTypeNameForSort{6}= '1_08-';DataTypeNameForSort{7}= '1_01+';
    DataTypeValue{1}= '32';DataTypeValue{2}= '32';DataTypeValue{3}= '16';DataTypeValue{4}= '16';
    DataTypeValue{5}= '8';DataTypeValue{6}= '8';DataTypeValue{7}= '1';
    DataResol{1}= '%';DataResolForDBC{1}= 'percent';
    
    j = 2;
    while (1)
        for k = 1 : 11
            kk = k;
            if isnan(ExcelData{j,kk})
                SignalData.(ExcelData{j,1}).(FieldName{k}) = '' ;
            elseif strcmp(ExcelData{j,kk}, 'ActiveX VT_ERROR: ')
                SignalData.(ExcelData{j,1}).(FieldName{k}) = '' ;
            else
                SignalData.(ExcelData{j,1}).(FieldName{k}) = ExcelData{j,kk};
            end
        end

        j = j + 1;
        if num < j
            break;
        elseif isnan(ExcelData{j,1})
            break;
        end

    end

    forsd=0; 
    SilsLogDataValue=[];
    SilsLogDataValue=int32(SilsLogDataValue);
    SilsLogDataSignalName = logsout.numElements;
    for for1ststr=1:SilsLogDataSignalName %for count 1st level structure
        if isstruct(logsout.get(for1ststr).Values)
            SilsLogDataSignalName_1=fieldnames(logsout.get(for1ststr).Values);
            for for2ndstr=1:length(SilsLogDataSignalName_1) %for count 2nd level structure
                decfind = 0;
                Temp=logsout.get(for1ststr).Values.(SilsLogDataSignalName_1{for2ndstr});
                SilsLogDataStructName=logsout.get(for1ststr).Name;                
                SilsLogDataName=Temp.Name;
                for exn=1:num
                    if strcmp(ExcelData{exn,1},SilsLogDataName)
                        decfind = 1;
                    end
                end
                if decfind == 1
                    forsd=forsd+1; %for count signal data                
                    SilsLogDataTime(1,:)=Temp.Time;
                    SilsLogDataValue(:,forsd)=Temp.Data(:,1);

                    for forexfn=1:11 %for count excel fieldname
                        SilsSignalInform{forsd,forexfn}=num2str(SignalData.(SilsLogDataName).(FieldName{forexfn}));
                    end
                    SilsSignalInform{forsd,1}=[SilsLogDataStructName, '_', SilsLogDataName];
                    for forexdn=1:7 %for count excel dataname
                        if strcmp(SilsSignalInform{forsd,4},DataTypeName{forexdn})
                            SilsSignalInform{forsd,4}=num2str(DataTypeNameForDBC{forexdn});
                            SilsSignalInform{forsd,12}=num2str(DataTypeNameForSort{forexdn});
                            SilsSignalInform{forsd,13}=num2str(DataTypeValue{forexdn});
                        end
                    end
                    if SilsSignalInform{forsd,8}==DataResol{1}
                        SilsSignalInform{forsd,8}=num2str(DataResolForDBC{1});
                    else
                    end
                end
            end
        else
            decfind = 0;
            Temp=logsout.get(for1ststr).Values;
            SilsLogDataName=Temp.Name;
            for exn=1:num
                if strcmp(ExcelData{exn,1},SilsLogDataName)
                    decfind = 1;
                end
            end
            if decfind == 1
                forsd=forsd+1;            
                SilsLogDataTime(1,:)=Temp.Time;
                SilsLogDataValue(:,forsd)=Temp.Data(:,1);
            
                for forexfn=1:11
                    SilsSignalInform{forsd,forexfn}=num2str(SignalData.(SilsLogDataName).(FieldName{forexfn}));
                end   
          
                for forexdn=1:7
                    if strcmp(SilsSignalInform{forsd,4},DataTypeName{forexdn})
                        SilsSignalInform{forsd,4}=num2str(DataTypeNameForDBC{forexdn});
                        SilsSignalInform{forsd,12}=num2str(DataTypeNameForSort{forexdn});
                        SilsSignalInform{forsd,13}=num2str(DataTypeValue{forexdn});
                    end
                end
                if SilsSignalInform{forsd,8}==DataResol{1}
                    SilsSignalInform{forsd,8}=num2str(DataResolForDBC{1});
                else
                end
            end
        end
    end
SilsLogDataValue = SilsLogDataValue';
SilsLogDataTime = SilsLogDataTime';
for formatconv=1:forsd %for count matrix convert
    SilsSignalInform{formatconv,14}=(SilsLogDataValue(formatconv,:));
end
   
SilsSignalInformByDataTypeTemp = sortrows(SilsSignalInform,-12);

if CanalyzerCfgSet==0
    load(fullfile(pwd, 'DataBase', 'SilsSignalDataBase.mat'));
    for forsdnbase=1:length(SilsSignalInformByDataType(:,1))
        SilsErrorCheckCnt=0;
        for forsdn=1:length(SilsSignalInformByDataTypeTemp(:,1))
            SilsErrorCheck=strfind(SilsSignalInformByDataTypeTemp{forsdn,1},SilsSignalInformByDataType{forsdnbase,1});
            if isempty(SilsErrorCheck)
                SilsErrorCheckCnt=SilsErrorCheckCnt+1;
            else
            end
        end
        if SilsErrorCheckCnt==forsdn
            errordlg('Not Include in Base Signal Data. Need to 1.New CANalyzer Cfg or 2.Click Logging on Base Signal', ...
                'Configuration Set Error');
        else
        end
    end
    SilsSignalAddCnt=length(SilsSignalInformByDataType(:,1));
    for forsdnsort=1:length(SilsSignalInformByDataTypeTemp(:,1))    
        SilsSignalAddCheckCnt=0;
        for forsdnbasesort=1:length(SilsSignalInformByDataType(:,1))
             if strcmp(SilsSignalInformByDataType{forsdnbasesort,1},SilsSignalInformByDataTypeTemp{forsdnsort,1})
                SilsSignalAddCheckCnt=1;
                for forsc=1:length(SilsSignalInformByDataTypeTemp(1,:))
                    SilsSignalInformByDataTypeSort{forsdnbasesort,forsc}=SilsSignalInformByDataTypeTemp{forsdnsort,forsc};
                end
            else
            end
        end
        if SilsSignalAddCheckCnt==0
            SilsSignalAddCnt=SilsSignalAddCnt+1;
            for forscadd=1:length(SilsSignalInformByDataTypeTemp(1,:))
                SilsSignalInformByDataTypeSort{SilsSignalAddCnt,forscadd}=SilsSignalInformByDataTypeTemp{forsdnsort,forscadd};
            end            
        else
        end
    end
    SilsSignalInformByDataType=SilsSignalInformByDataTypeSort;
else
    SilsSignalInformByDataType=SilsSignalInformByDataTypeTemp;
end

if (isempty(CheckCanSave)) || (AutoAscMultiRun==0)
    choice = questdlg('Do you cut Data Time?', ...
	'Cut Data Time', ...
	'Yes','No','No');    
    switch choice
        case 'Yes'
            disp([choice ' Set Complete.'])
            DataCut = 1;
        case 'No'
            disp([choice ' Set Complete.'])
            DataCut = 0;
    end    
    if (DataCut == 1)
        prompt = {'Start of Data Time(sec):',...
                 'End of Data Time(sec):'};
        name = 'Which use data time?';
        numlines = 1;
        defaultanswer = {'0','10'};
        answer = inputdlg(prompt,name,numlines,defaultanswer);
        CutTime(1,1) = str2num(answer{1,1});CutTime(2,1) = str2num(answer{2,1});
        SamTime = SilsLogDataTime(2,1) - SilsLogDataTime(1,1);
        if (CutTime(1,1) == 0)
            StartData = 1;
        else
            StartData = CutTime(1,1)/SamTime;
        end
        if (CutTime(2,1) == 0)
            EndData = 1;
        else
            EndData = CutTime(2,1)/SamTime;
        end        

        for dsort = 1:length(SilsSignalInformByDataType(:,14))
            tempsort = SilsSignalInformByDataType{dsort,14};
            SilsSignalInformByDataType{dsort,14} = tempsort(StartData:EndData);
        end
        SilsLogDataTime = SilsLogDataTime(1:(EndData-StartData+1),1);
    end
% if isempty(CheckCanSave) || (AutoAscMultiRun==0)
    choice = questdlg('SimulationLogsOut Data로 CANalyzer Configuration을 Update했나요?                Base Configuration을 위하여 SimulationLogsOut Data를 저장할까요?', ...
        'Save Base SimulationLogsOut Data', ...
        'Yes','No','Yes');
    % Handle response
    switch choice
        case 'Yes'
            disp([choice ' Set Complete.']);
            SilsDataSave = 1;
        case 'No'
            disp([choice ' Set Complete.']);
            SilsDataSave = 0;
    end
else
SilsDataSave = 0;
end

if SilsDataSave==1
    save(fullfile(pwd, 'DataBase', 'SilsSignalDataBase.mat'), 'SilsSignalInformByDataType');
else
end
    
    
DBCFile = fullfile(pwd, 'DataBase\BtcsSilsDbc.dbc')
fileID = fopen(DBCFile, 'w'); % 'w->Open or create new file for writing. Discard existing contents, if any.
dscrpt='VERSION ""\nNS_ :\nNS_DESC_\nCM_\nBA_DEF_\nBA_\nVAL_\nCAT_DEF_\nCAT_\nFILTER\nBA_DEF_DEF_\nEV_DATA_\nENVVAR_DATA_\nSGTYPE_\nSGTYPE_VAL_\nBA_DEF_SGTYPE_\nBA_SGTYPE_\nSIG_TYPE_REF_\nVAL_TABLE_\nSIG_GROUP_\nSIG_VALTYPE_\nSIGTYPE_VALTYPE_\nBS_:\nBU_:\n';
fprintf(fileID, dscrpt);

WorkDataLocation = 0;
StartBit=0;
LogByteCount = 0;

MessageId = 256; % 0x100

dscrpt = {['\nBO_ ', num2str(MessageId), ' LOG_BYTE', num2str(LogByteCount), ': 8 Vector__XXX\n']};
dscrpt = strjoin(dscrpt, '\n');
fprintf(fileID, dscrpt);

for formsgch=1:forsd %for count message change
    WorkDataLocation = StartBit+str2double(SilsSignalInformByDataType{formsgch,13});
    if (WorkDataLocation > 64)
        WorkDataLocation = 0;
        StartBit=0;
        MessageId = MessageId + 1;
        LogByteCount = LogByteCount + 1;
        SilsSignalInformByDataType{formsgch,15}=['LOG_BYTE', num2str(LogByteCount)];
        SilsSignalInformByDataType{formsgch,16}=dec2hex(MessageId);
        SilsSignalInformByDataType{formsgch,17}=MessageId;
        dscrpt = {['\nBO_ ', num2str(MessageId), ' LOG_BYTE', num2str(LogByteCount),': 8 Vector__XXX\n']};
        dscrpt = strjoin(dscrpt);
        fprintf(fileID, dscrpt);

        dscrpt = {['SG_ ', num2str(SilsSignalInformByDataType{formsgch,1}), ' : ', num2str(StartBit), '|', num2str(SilsSignalInformByDataType{formsgch,4}), ' (', num2str(SilsSignalInformByDataType{formsgch,5}), ',0) [', num2str(SilsSignalInformByDataType{formsgch,6}), '|', num2str(SilsSignalInformByDataType{formsgch,7}), '] "', num2str(SilsSignalInformByDataType{formsgch,8}), '" Vector__XXX\n']};
        dscrpt = strjoin(dscrpt);
        fprintf(fileID, dscrpt);
    else    
        SilsSignalInformByDataType{formsgch,15}=['LOG_BYTE', num2str(LogByteCount)];
        SilsSignalInformByDataType{formsgch,16}=dec2hex(MessageId);
        SilsSignalInformByDataType{formsgch,17}=MessageId;
        dscrpt = {['SG_ ', num2str(SilsSignalInformByDataType{formsgch,1}), ' : ', num2str(StartBit), '|', num2str(SilsSignalInformByDataType{formsgch,4}), ' (', num2str(SilsSignalInformByDataType{formsgch,5}), ',0) [', num2str(SilsSignalInformByDataType{formsgch,6}), '|', num2str(SilsSignalInformByDataType{formsgch,7}), '] "', num2str(SilsSignalInformByDataType{formsgch,8}), '" Vector__XXX\n']};
        dscrpt = strjoin(dscrpt');
        fprintf(fileID, dscrpt);        
    end
    StartBit = StartBit+str2double(SilsSignalInformByDataType{formsgch,13});
end

assignin('base', 'SilsLogDataTime', SilsLogDataTime);
assignin('base', 'SilsSignalInformByDataType', SilsSignalInformByDataType);

dscrpt='\nBA_DEF_  "BusType" STRING ;\nBA_DEF_DEF_  "BusType" "CAN";\n';
fprintf(fileID, dscrpt);
fclose(fileID);
 