function [SignalList] = GenCANdbc


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

    SignalList = {num,13};
    
    
    j = 1;
    while (1)
        for k = 1 : 11
            kk = k;
            if isnan(ExcelData{j,kk})
                
            elseif strcmp(ExcelData{j,kk}, 'ActiveX VT_ERROR: ')
                
            else
                SignalList{j,k} =  ExcelData{j,kk};
            end
           
            
           
        end
        
        for x=1:7
          if strcmp(SignalList{j,4},DataTypeName{x})
              SignalList{j,12} = DataTypeValue{x};
          end
          
          if strcmp(SignalList{j,4},DataTypeName{x})
              SignalList{j,13} = DataTypeNameForDBC{x};
          end
        end
            

        j = j + 1;
        if num < j
            break;
        elseif isnan(ExcelData{j,1})
            break;
        end

    end


    
    
DBCFile = fullfile(pwd, 'DataBase\EscSilsDbc.dbc')
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

SignalList{1,12}='DataLength';
SignalList{1,13}='DataLengthForDBC';
SignalList{1,15}='MessageName';
SignalList{1,16}='MessageID_Hex';
SignalList{1,17}='MessageID_Dec';
SignalList{1,18}='StartBit';

for formsgch=2:num %for count message change
    WorkDataLocation = StartBit+str2double(SignalList{formsgch,12});
    if (WorkDataLocation > 64)
        WorkDataLocation = 0;
        StartBit=0;
        MessageId = MessageId + 1;
        LogByteCount = LogByteCount + 1;
        SignalList{formsgch,15}=['LOG_BYTE', num2str(LogByteCount)];
        SignalList{formsgch,16}=dec2hex(MessageId);
        SignalList{formsgch,17}=MessageId;
        SignalList{formsgch,18}=StartBit;
        dscrpt = {['\nBO_ ', num2str(MessageId), ' LOG_BYTE', num2str(LogByteCount),': 8 Vector__XXX\n']};
        dscrpt = strjoin(dscrpt);
        fprintf(fileID, dscrpt);

        dscrpt = {['SG_ ', num2str(SignalList{formsgch,1}), ' : ', num2str(StartBit), '|', num2str(SignalList{formsgch,13}), ' (', num2str(SignalList{formsgch,5}), ',0) [', num2str(SignalList{formsgch,6}), '|', num2str(SignalList{formsgch,7}), '] "', num2str(SignalList{formsgch,8}), '" Vector__XXX\n']};
        dscrpt = strjoin(dscrpt);
        fprintf(fileID, dscrpt);
    else    
        SignalList{formsgch,15}=['LOG_BYTE', num2str(LogByteCount)];
        SignalList{formsgch,16}=dec2hex(MessageId);
        SignalList{formsgch,17}=MessageId;
        SignalList{formsgch,18}=StartBit;
        dscrpt = {['SG_ ', num2str(SignalList{formsgch,1}), ' : ', num2str(StartBit), '|', num2str(SignalList{formsgch,13}), ' (', num2str(SignalList{formsgch,5}), ',0) [', num2str(SignalList{formsgch,6}), '|', num2str(SignalList{formsgch,7}), '] "', num2str(SignalList{formsgch,8}), '" Vector__XXX\n']};
        dscrpt = strjoin(dscrpt');
        fprintf(fileID, dscrpt);        
    end
    StartBit = StartBit+str2double(SignalList{formsgch,12});
end

dscrpt='\nBA_DEF_  "BusType" STRING ;\nBA_DEF_DEF_  "BusType" "CAN";\n';
fprintf(fileID, dscrpt);
fclose(fileID);

assignin('base', 'SignalList', SignalList);


 