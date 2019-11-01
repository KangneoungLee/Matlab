function AutoSfunSiLS_AutoGenCANASCii(SilsLogDataTime, SignalList)


ASCiiFile = fullfile(pwd, 'DataBase\ASCii_SilsOutput.asc')
fileID = fopen(ASCiiFile, 'w');
ASCiiFileInform=dir(ASCiiFile);
ASCiiFileUpdateDate=ASCiiFileInform.date;
% fileID = fopen(ASCiiFile, 'w');
dscrpt = {['date ', num2str(ASCiiFileUpdateDate),'\n', 'base hex  timestamps absolute\ninternal events logged\n// version 7.0.1\nBegin Triggerblock', num2str(ASCiiFileUpdateDate),'\n   0.00 Start of measurement\n']};
dscrpt = strjoin(dscrpt);
fprintf(fileID, dscrpt);

TempPath = fullfile(pwd, 'DataBase\EscSilsDbc.dbc')
Candb = canDatabase(TempPath);

% clear ASCiiFileInform;
CanMsgData{1,1}=num2str('Time');
CanMsgData{2,1}=num2str('CAN ID');

LogByteWidth = 8;
LogByteOld=0;
SilsLogDataTime=evalin('base', 'SilsLogDataTime');
SilsSignalInformByDataType=evalin('base', 'SignalList');

[row_num_SigList  column_num_SigList]=size(SignalList);

TempHexAloc=cell(1,8);
TempHexAlocIndex=0;

for timeStep= 1 : length(SilsLogDataTime)
   
    TempHexAloc(1:8)={'00'};
    TempHexAlocIndex = 0;
    Remainder =0;
    RemainDataLength=0;
    FilledUpByte=0;
    
   for SignalIndex = 2 : row_num_SigList
       
       
           if exist(char(SignalList(SignalIndex,1)))      % char : cell������ string���� ��ȯ
       
               DataValue = eval(['double(',char(SignalList(SignalIndex,1)),'(timeStep)',')']);    % ������ double�� data input�� ��ȯ���־�� �ϴµ� �̴� ���� workspace ����� ������ �ҷ��ö� ����� ������ � type�� ������ ������ asc���� �ٲٴ� �����߰��� overflow�߻��Ҽ� �ֱ� ���� 
                                                                                                  % ex) int8���� ���ǵ� ������ �ҷ��ö� int16 max ���� 127 �̶� data value = -1 �̶�� DataValue = DataValue + DataOffset + 1; �� 255�� ���;� �ϳ� DataValue�� 127�� ���� �̴� int8 �� ������ �ѱ� ������
               if(DataValue < 0)
               
                 if strcmp(char(SignalList(SignalIndex,4)),'int16') 
                      DataOffset = 65535;
                 elseif strcmp(char(SignalList(SignalIndex,4)),'int8')
                      DataOffset = 255;
                 else
                      msgbox('invalid data type in excel sheet, confirm data type')
                      break
                 end
                 
                 DataValue = DataValue + DataOffset + 1;
               end
               
           else
              DataValue = 0;
           
           end
           
               

           OriginAdStartBit = rem(cell2mat(SignalList(SignalIndex,18)),LogByteWidth);   %start bit�� 16 24 32 ... ������ �Ҵ� �ɶ� signal�� ���� �Ǿ��� ��쿡�� 8�� ����� ���� �������� start bit�� ��ƾ���. �� byte���� bit�Ҵ��� ���ؼ� �ʿ��� ����
            
               %SignalList( ,12) ������ str2double�� ���ִ� ���� : SignalList(,12)��
               %�Ҵ�Ǵ� ���� ���ڰ� �ƴ� char ���·� ����Ǳ� ������ ���ڷ� �ٲپ��־�� ��
           
           if (OriginAdStartBit+str2double(cell2mat(SignalList(SignalIndex,12)))) > LogByteWidth     %cell2mat : cell���� �Ϲ� array�� ��ȯ,  start bit + data length �� ũ�Ⱑ 8�� �Ѿ���� ��
               
               FilledUpByte = Remainder; %old remiander�� byte�� �Ҵ�
               
               %old remainder�� �̹� �Ҵ�Ǿ������� ������ ���ο� remainder�� ����Ѵ�
               Remainder = bitshift( DataValue, -( LogByteWidth-OriginAdStartBit ) ) ;      % ex) ���࿡ 8bit array�� ���� �ڸ��� 3bit ��� �ǿ����ʺ��� 3���� ��Ʈ�� �Ҵ�Ǿ�� �ϹǷ� ���ʺ��� ������ ��Ʈ�� ������ �Ҵ����� ���, �� ������ �Ҵ�Ǵ� ��Ʈ�� 1100 0011 -->  1100 0  (�̹� array ���� ���� array�� ������ remainder)
               RemainDataLength = str2double(cell2mat(SignalList(SignalIndex,12))) - (LogByteWidth-OriginAdStartBit); % total datalength -(8 - start bit position)
               
               CoreData = DataValue - bitshift( Remainder, LogByteWidth-OriginAdStartBit ); % ex) 1100 0 --> 1100 0000     ==>    1100 0011  -  1100 0000  =  0000 0011 , �� �̹� array�� ���� �ڸ� 3bit�� �� ���ڴ� 011 
               FitIn2ByteCoreData = bitshift( CoreData,OriginAdStartBit ) ;    % ex) 011�� ���µ� �̹� 8bit¥�� array�� lsb (0bit)���� (5bit)������ �̹� �����Ͱ� ���������� 011 --> 01100000 �� ������ ���ִ� �����Ϳ� ������
               
               FilledUpByte = FilledUpByte + FitIn2ByteCoreData; 
               
               
               TempHexAlocIndex= TempHexAlocIndex +1;
               TempHexAloc(TempHexAlocIndex)={dec2hex(FilledUpByte,2)};
               
               FilledUpByte = 0;
               
           
           else
               if Remainder~=0                     % ���� ���� signal�� 8bit(BtyeWidth)�� �� ä���� ���Ұ�� �ϴ� ������ �����ִ� remainder�� ���� �Ҵ����ش�.
                  FilledUpByte = Remainder;
                  Remainder=0;
                  RemainDataLength=0;
               end
               
               CoreData = DataValue;
               FitIn2ByteCoreData = bitshift( CoreData,OriginAdStartBit ) ;    % ex) 011�� ���µ� �̹� 8bit¥�� array�� lsb (0bit)���� (5bit)������ �̹� �����Ͱ� ���������� 011 --> 01100000 �� ������ ���ִ� �����Ϳ� ������
               FilledUpByte = FilledUpByte + FitIn2ByteCoreData; 
               Remainder=FilledUpByte;
               
               if (OriginAdStartBit+str2double(cell2mat(SignalList(SignalIndex,12)))) == LogByteWidth
               TempHexAlocIndex= TempHexAlocIndex +1;
               TempHexAloc(TempHexAlocIndex)={dec2hex(FilledUpByte,2)};
               FilledUpByte=0;
               Remainder=0;
               RemainDataLength=0;
               end
           
           end
           
           
           while RemainDataLength >= LogByteWidth
                RemainDataLength=RemainDataLength-LogByteWidth;
                
                
              
                    RemainderOrg=Remainder;
               
                    Remainder=bitshift(Remainder,-LogByteWidth);
                    CoreData=RemainderOrg - bitshift(Remainder,LogByteWidth);
                    FilledUpByte = CoreData;
               
                    TempHexAlocIndex= TempHexAlocIndex +1;
                    TempHexAloc(TempHexAlocIndex)={dec2hex(FilledUpByte,2)};
               
                    FilledUpByte = 0;
                
               
           
           end
   
           
           if TempHexAlocIndex == 8;
               
               dscrpt = {['   ', num2str(SilsLogDataTime(timeStep)), ' 2  ', char(SignalList(SignalIndex,16)), '             Rx   d 8 ',char(TempHexAloc(1)),' ',char(TempHexAloc(2)),' ',char(TempHexAloc(3)),' ',char(TempHexAloc(4)),' ',char(TempHexAloc(5)),' ',char(TempHexAloc(6)),' ',char(TempHexAloc(7)),' ',char(TempHexAloc(8)),'\n']};
               dscrpt = strjoin(dscrpt);
               fprintf(fileID, dscrpt);
               
               TempHexAlocIndex = 0;
               TempHexAloc(1:8)={'00'};
           elseif (SignalIndex == row_num_SigList)    %DB�� �������� �˲� ��ä����������� asc�� wirte �ϴ� �κ� 
                   
               
               TempHexAlocIndex= TempHexAlocIndex +1;
               TempHexAloc(TempHexAlocIndex)={dec2hex(FilledUpByte,2)};
               
                dscrpt = {['   ', num2str(SilsLogDataTime(timeStep)), ' 2  ', char(SignalList(SignalIndex,16)), '             Rx   d 8 ',char(TempHexAloc(1)),' ',char(TempHexAloc(2)),' ',char(TempHexAloc(3)),' ',char(TempHexAloc(4)),' ',char(TempHexAloc(5)),' ',char(TempHexAloc(6)),' ',char(TempHexAloc(7)),' ',char(TempHexAloc(8)),'\n']};
                dscrpt = strjoin(dscrpt);
                fprintf(fileID, dscrpt);
                
                 TempHexAlocIndex = 0;
                 TempHexAloc(1:8)={'00'};
               
           end
           
   end
   
end

dscrpt = 'End TriggerBlock\n';
fprintf(fileID, dscrpt);
fclose(fileID);





