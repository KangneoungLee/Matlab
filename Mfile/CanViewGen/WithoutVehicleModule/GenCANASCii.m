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
       
       
           if exist(char(SignalList(SignalIndex,1)))      % char : cell형에서 string으로 변환
       
               DataValue = eval(['double(',char(SignalList(SignalIndex,1)),'(timeStep)',')']);    % 무조건 double로 data input을 변환해주어야 하는데 이는 만약 workspace 저장된 변수를 불러올때 저장된 변수가 어떤 type을 가지고 있으면 asc으로 바꾸는 과정중간에 overflow발생할수 있기 떄문 
                                                                                                  % ex) int8으로 정의된 변수를 불러올때 int16 max 값은 127 이때 data value = -1 이라면 DataValue = DataValue + DataOffset + 1; 은 255가 나와야 하나 DataValue가 127이 나옴 이는 int8 의 범위를 넘기 때문임
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
           
               

           OriginAdStartBit = rem(cell2mat(SignalList(SignalIndex,18)),LogByteWidth);   %start bit가 16 24 32 ... 등으로 할당 될때 signal에 값을 실어줄 경우에는 8의 배수로 나눈 나머지를 start bit로 잡아야함. 각 byte별로 bit할당을 위해서 필요한 과정
            
               %SignalList( ,12) 참조시 str2double을 해주는 이유 : SignalList(,12)에
               %할당되는 값이 숫자가 아닌 char 형태로 저장되기 때문에 숫자로 바꾸어주어야 함
           
           if (OriginAdStartBit+str2double(cell2mat(SignalList(SignalIndex,12)))) > LogByteWidth     %cell2mat : cell에서 일반 array로 변환,  start bit + data length 의 크기가 8이 넘어가는지 비교
               
               FilledUpByte = Remainder; %old remiander를 byte에 할당
               
               %old remainder는 이미 할당되었음으로 버리고 새로운 remainder를 계산한다
               Remainder = bitshift( DataValue, -( LogByteWidth-OriginAdStartBit ) ) ;      % ex) 만약에 8bit array중 남은 자리가 3bit 라면 맨오른쪽부터 3개의 비트만 할당되어야 하므로 왼쪽부터 어디까지 비트를 다음에 할당할지 계산, 즉 다음에 할당되는 비트는 1100 0011 -->  1100 0  (이번 array 말고 다음 array에 들어가야할 remainder)
               RemainDataLength = str2double(cell2mat(SignalList(SignalIndex,12))) - (LogByteWidth-OriginAdStartBit); % total datalength -(8 - start bit position)
               
               CoreData = DataValue - bitshift( Remainder, LogByteWidth-OriginAdStartBit ); % ex) 1100 0 --> 1100 0000     ==>    1100 0011  -  1100 0000  =  0000 0011 , 즉 이번 array에 남은 자리 3bit에 들어갈 숫자는 011 
               FitIn2ByteCoreData = bitshift( CoreData,OriginAdStartBit ) ;    % ex) 011이 들어가는데 이미 8bit짜리 array의 lsb (0bit)부터 (5bit)까지는 이미 데이터가 차있음으로 011 --> 01100000 후 기존에 차있는 데이터와 더해줌
               
               FilledUpByte = FilledUpByte + FitIn2ByteCoreData; 
               
               
               TempHexAlocIndex= TempHexAlocIndex +1;
               TempHexAloc(TempHexAlocIndex)={dec2hex(FilledUpByte,2)};
               
               FilledUpByte = 0;
               
           
           else
               if Remainder~=0                     % 새로 들어올 signal이 8bit(BtyeWidth)를 꽉 채우지 못할경우 일단 기존에 남아있던 remainder를 먼저 할당해준다.
                  FilledUpByte = Remainder;
                  Remainder=0;
                  RemainDataLength=0;
               end
               
               CoreData = DataValue;
               FitIn2ByteCoreData = bitshift( CoreData,OriginAdStartBit ) ;    % ex) 011이 들어가는데 이미 8bit짜리 array의 lsb (0bit)부터 (5bit)까지는 이미 데이터가 차있음으로 011 --> 01100000 후 기존에 차있는 데이터와 더해줌
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
           elseif (SignalIndex == row_num_SigList)    %DB의 마지막이 꽉꽉 안채워져있을경우 asc에 wirte 하는 부분 
                   
               
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





