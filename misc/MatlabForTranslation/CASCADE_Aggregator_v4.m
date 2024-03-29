%This is a fourth prototype of an Aggregator - obtains a model SkB+c =
%deltaB for each timeslot using the Matlab regression function and invokes
%an optimisation function to minimise cost. Uses the ProsumerGenerator to 
%initialise prosumer random variables. CHECK CHOICE OF S AT LINE 175-ish.
global B coeffs_pos coeffs_neg Dpredmin Dpred Cavge Kpos Kneg Cost
%
NoPros = 1000; %The number of prosumers each appliance function is going to run with.
Pros=ProsumerGenerator(NoPros); %generate all the prosumer properties
%First create a demand baseline B using a null signal S
S=zeros(1,48);
%Now call the various prosumer functions
Miscr = Miscellaneous(S,NoPros);
Coldr = ColdAppliances(S,NoPros);
Wetr = WetAppliances(S,NoPros,Pros);
Hwatr = WaterHeating(S,NoPros,Pros);
Spacer = SpaceHeating(S,NoPros,Pros);
B = Miscr + Coldr + Wetr + Hwatr + Spacer;
PeakToMeanBaseline = max(B)/(sum(B)/48); PeakToMeanBaseline
%
%Now plot or save the baseline
% t=[0.5:0.5:24];%This is an x-axis marker array which can be inserted before the array to be plotted.
figure;
plot(Miscr, 'c','LineWidth',2);hold on;
plot(Miscr + Coldr, 'g','LineWidth',2);hold on;
plot(Wetr + Miscr + Coldr, 'b','LineWidth',2);hold on;
plot(Hwatr + Wetr + Miscr + Coldr, 'm','LineWidth',2);hold on;
plot(Spacer + Hwatr + Wetr + Miscr + Coldr, 'r','LineWidth',2);hold on;
grid on;
axis([0 48 0 3000]);
%figure; plot(B)
sum(B)/2
%save('Baseline_v1.dat','B','-ascii','-tabs')
%
%Perform initial training to derive k values
Cavge=zeros(1,48); %holds constant deltaBs
Kpos=zeros(1,48);%holds k values from positive signals for a single signal
Kposm=zeros(48,48);%holds k values from positive signals as training signal is stepped through all 48 timeslots.
Kneg=zeros(1,48);%holds k values from negative signals for a single signal
Knegm=zeros(48,48);%holds k values from negative signals as training signal is stepped through all 48 timeslots.
DeltaBm=zeros(48,48);%holds all the deltas from training.
SBprodm=zeros(48,48);%hold all the Si*Bi products from training.
Strn=[0,0.166666667,0.25,0.333333333,0.416666667,0.5,0.583333333,0.666666667,0.75,0.833333333,0.916666667,1,1,0.916666667,0.833333333,0.75,0.666666667,0.583333333,0.5,0.416666667,0.333333333,0.25,0.166666667,0,0,-0.166666667,-0.25,-0.333333333,-0.416666667,-0.5,-0.583333333,-0.666666667,-0.75,-0.833333333,-0.916666667,-1,-1,-0.916666667,-0.833333333,-0.75,-0.666666667,-0.583333333,-0.5,-0.416666667,-0.333333333,-0.25,-0.166666667,0];
for i=1:48
    if i>1
    Strn = circshift(Strn,[0 1]);
    end
    Miscr = Miscellaneous(Strn,NoPros);
    Coldr = ColdAppliances(Strn,NoPros);
    Wetr = WetAppliances(Strn,NoPros,Pros);
    Hwatr = WaterHeating(Strn,NoPros,Pros);
    Spacer = SpaceHeating(Strn,NoPros,Pros);
    Dtrn = Miscr + Coldr + Wetr + Hwatr + Spacer;
    DeltaB=Dtrn-B;
    DeltaBm(i,1:48)= DeltaB;
    SBprodm(i,1:48)= B.*Strn;
end
%Collect training limits for use in optimisation MORE WORK HERE
Strnpos=0;Strnneg=0;
for n=1:48
    if Strn(n)>0
        Strnpos=Strnpos+Strn(n);
    elseif Strn(n)<0
        Strnneg=Strnneg+Strn(n);
    end
end

%Initialise arrays for the regression function
coeffs_pos = zeros(2,48);
coeffs_neg = zeros(2,48);
DeltaB_pos = zeros(24,1);
DeltaB_neg = zeros(24,1);
SBprod_pos = zeros(24,2);
SBprod_neg = zeros(24,2);
SBprod_pos(:,1)=ones(24,1);%needed to collect constant coefficient
SBprod_neg(:,1)=ones(24,1);
i=1;
for j = 1:48
    if j==1
        DeltaB_pos=DeltaBm(i+24:48,j);
        DeltaB_neg=DeltaBm(i:i+23,j);
        SBprod_pos(:,2)=SBprodm(i+24:48,j);
        SBprod_neg(:,2)=SBprodm(i:i+23,j);
        coeffs_pos(:,j)=regress(DeltaB_pos,SBprod_pos);
        coeffs_neg(:,j)=regress(DeltaB_neg,SBprod_neg);
    
    elseif j >1 && j<=24
        DeltaB_pos(i:24)=DeltaBm(i+24:48,j);
        DeltaB_pos(1:i-1)=DeltaBm(1:i-1,j);
        DeltaB_neg=DeltaBm(i:i+23,j);
        SBprod_pos(i:24,2)=SBprodm(i+24:48,j);
        SBprod_pos(1:i-1,2)=SBprodm(1:i-1,j);
        SBprod_neg(:,2)=SBprodm(i:i+23,j);
        coeffs_pos(:,j)=regress(DeltaB_pos,SBprod_pos);
        coeffs_neg(:,j)=regress(DeltaB_neg,SBprod_neg);
    
    elseif j==25    
        DeltaB_pos=DeltaBm(1:i-1,j);
        DeltaB_neg=DeltaBm(i:48,j);
        SBprod_pos(:,2)=SBprodm(1:i-24,j);
        SBprod_neg(:,2)=SBprodm(i:48,j);
        coeffs_pos(:,j)=regress(DeltaB_pos,SBprod_pos);
        coeffs_neg(:,j)=regress(DeltaB_neg,SBprod_neg);
   
    elseif j >25 && j<=48
        DeltaB_pos=DeltaBm(i-24:i-1,j);
        DeltaB_neg(i-24:24)=DeltaBm(i:48,j);
        DeltaB_neg(1:i-25)=DeltaBm(1:i-25,j);
        SBprod_pos(:,2)=SBprodm(i-24:i-1,j);
        SBprod_neg(i-24:24,2)=SBprodm(i:48,j);
        SBprod_neg(1:i-25,2)=SBprodm(1:i-25,j);
        coeffs_pos(:,j)=regress(DeltaB_pos,SBprod_pos);
        coeffs_neg(:,j)=regress(DeltaB_neg,SBprod_neg);     
      
    end
    i=i+1;
end
format compact;
%coeffs_pos
%coeffs_neg

%This block uses S=0 and a simple slope averaging method to obtain the aggregators model 
i=1; %initialise for loop
for j=1:48 %This loop extracts the "c" constants in the linear model for each timeslot
    if j==1 || j==25
        Cavge(1,j) = (DeltaBm(i,j)+DeltaBm(i+23,j)+DeltaBm(i+24,j)+DeltaBm(i+47,j))/4;
    elseif 1<i && i <=24
        Cavge(1,j) = (DeltaBm(i,j)+DeltaBm(i+1,j)+DeltaBm(i+23,j)+DeltaBm(i+24,j))/4;   
    elseif i>25 && i<=48
        Cavge(1,j) = (DeltaBm(i,j)+DeltaBm(i+1,j)+DeltaBm(i+23,j)+DeltaBm(i+24,j))/4;
    end
    i=i+1;
    if i==25
        i=1;
    end
end
%Cavge
for j=1:25 %This block extracts the positive and negative K values
    Knegm(j+2:j+23,j)= (DeltaBm(j+2:j+23,j)-Cavge(1,j))./SBprodm( j+2:j+23,j);
    Kneg(1,j)=sum(Knegm(:,j))/22;#
    
end
for j=26:46
    Knegm(j+2:48,j)=(DeltaBm(j+2:48,j)-Cavge(1,j))./SBprodm( j+2:48,j);
    Knegm(1:j-25,j)=(DeltaBm(1:j-25,j)-Cavge(1,j))./SBprodm( 1:j-25,j);
    Kneg(1,j)=sum(Knegm(:,j))/22;
end
for j=47:48
    Knegm(j-46:j-25,j)=(DeltaBm(j-46:j-25,j)-Cavge(1,j))./SBprodm( j-46:j-25,j);
    Kneg(1,j)=sum(Knegm(:,j))/22;
end
for j=1:1
    Kposm(j+26:48,j)= (DeltaBm(j+26:48,j)-Cavge(1,j))./SBprodm( j+26:48,j);
    Kpos(1,j)=sum(Kposm(:,j))/22;
end
for j=2:22
    Kposm(j+26:48,j)= (DeltaBm(j+26:48,j)-Cavge(1,j))./SBprodm( j+26:48,j);
    Kposm(1:j-1,j)= (DeltaBm(1:j-1,j)-Cavge(1,j))./SBprodm( 1:j-1,j);
    Kpos(1,j)=sum(Kposm(:,j))/22;
end
for j=23:48
    Kposm(j-22:j-1,j)= (DeltaBm(j-22:j-1,j)-Cavge(1,j))./SBprodm( j-22:j-1,j);
    Kpos(1,j)=sum(Kposm(:,j))/22;
end

%format compact; 
%Kposm
%Kpos
%Knegm 
%Kneg
%save('Kposm_v1.txt','Kposm','-ascii','-tabs');
%save('Knegm_v1.txt','Knegm','-ascii','-tabs');
%save('DeltaBm_v1.txt','DeltaBm','-ascii','-tabs');
%
%Now compute the responsive demand
%Read in price P
% load Price_demand_shape.dat
% P=Price_demand_shape;
load Baseline_v1.dat
P=Baseline_v1;
Pavge=sum(P)/48;
S=P-Pavge; %Generate an area symmetric S with one side normalised to 1
Smax=max(S);
Smin=min(S)*-1;
if Smax>Smin
    S=S*1/Smax;
else S=S*1/Smin;
end

Cost=20*(P+2); %�per MWh
%figure;plot(S)
Dpred=zeros(1,48); %create array to hold predicted demand
Dpredregn=zeros(1,48);%and another array which uses the result from Matlab regression
%Predict the response from the aggregator's models using the regression method
for j=1:48
    if S(1,j)>0
        Dpredregn(1,j)=B(1,j)+coeffs_pos(1,j)+(B(1,j)*S(1,j)*coeffs_pos(2,j));
    elseif S(1,j)<0
        Dpredregn(1,j)=B(1,j)+coeffs_neg(1,j)+(B(1,j)*S(1,j)*coeffs_neg(2,j));
    end
end
%Predict the response from the aggregator's models using the simple method
for j=1:48
    if S(1,j)>0
        Dpred(1,j)=B(1,j)+Cavge(1,j)+(B(1,j)*S(1,j)*Kpos(1,j));
    elseif S(1,j)<0
        Dpred(1,j)=B(1,j)+Cavge(1,j)+(B(1,j)*S(1,j)*Kneg(1,j));
    end
end

%Now call the various prosumer functions
Miscr = Miscellaneous(S,NoPros);
Coldr = ColdAppliances(S,NoPros);
Wetr = WetAppliances(S,NoPros,Pros);
Hwatr = WaterHeating(S,NoPros,Pros);
Spacer = SpaceHeating(S,NoPros,Pros);
D = Miscr + Coldr + Wetr + Hwatr + Spacer;
PeakToMeanProportionate = max(D)/(sum(D)/48);PeakToMeanProportionate
%
%Plot the predicted and actual responsive demand
%figure;plot(D);hold on;plot(Dpred);
sum(D)/2
sum(Dpred)/2
sum(Dpredregn)/2
%Plot demand response to cost signal and predictions
figure;
plot(Miscr, 'c','LineWidth',2);hold on;
plot(Miscr + Coldr, 'g','LineWidth',2);hold on;
plot(Wetr + Miscr + Coldr, 'b','LineWidth',2);hold on;
plot(Hwatr + Wetr + Miscr + Coldr, 'm','LineWidth',2);hold on;
plot(Spacer + Hwatr + Wetr + Miscr + Coldr, 'r','LineWidth',2);hold on;
plot(Dpred,'k','LineWidth',2);hold on;
plot(Dpredregn,'g','LineWidth',2);hold on;
grid on;
axis([0 48 0 3000]);
%
%Now perform costing on the baseline and response
Bcost=sum(B.*Cost)/(1000*2);Bcost %Div by 1000 to convert to MW, by 2 for MWh
Dcost=sum(D.*Cost)/(1000*2);Dcost
Pcost=sum(Dpred.*Cost)/(1000*2);Pcost
Pcostregn=sum(Dpredregn.*Cost)/(1000*2);Pcostregn

%Call minimisation function. Set starting values = S
ub=ones(1,48); lb=ub*-1;
options=optimset('Algorithm','active-set');
%This version minimises cost
% [Smin,Pcostmin]=fmincon(@Costcalc,S,[],[],[],[],lb,ub,@Trainval,options);
% Pcostmin
%This version minimises peak-mean ratio
[Smin,PeakMeanRatio]=fmincon(@Peakmeanminimise,S,[],[],[],[],lb,ub,@Trainval,options);
PeakMeanRatio


%Now call the various prosumer functions with the minimised S
Miscr = Miscellaneous(Smin,NoPros);
Coldr = ColdAppliances(Smin,NoPros);
Wetr = WetAppliances(Smin,NoPros,Pros);
Hwatr = WaterHeating(Smin,NoPros,Pros);
Spacer = SpaceHeating(Smin,NoPros,Pros);
Dmin = Miscr + Coldr + Wetr + Hwatr + Spacer;
Dcostmin=sum(Dmin.*Cost)/(1000*2);Dcostmin
PeakToMeanOptimised = max(Dmin)/(sum(Dmin)/48);PeakToMeanOptimised
sum(Dmin)/2
%
%Plot demand response to minimised signal and prediction
figure;
plot(Miscr, 'c','LineWidth',2);hold on;
plot(Miscr + Coldr, 'g','LineWidth',2);hold on;
plot(Wetr + Miscr + Coldr, 'b','LineWidth',2);hold on;
plot(Hwatr + Wetr + Miscr + Coldr, 'm','LineWidth',2);hold on;
plot(Spacer + Hwatr + Wetr + Miscr + Coldr, 'r','LineWidth',2);hold on;
plot(Dpredmin,'k','LineWidth',2);hold on;
plot(Dmin,'g:','LineWidth',2);hold on;
grid on;
axis([0 48 0 3000]);
title('Title')
xlabel('Time')
ylabel('kW')
legend('M','M+C','W+M+C','H+W+M+C','S+H+W+M+C','Dpredmin','Dmin')

% %Now call the various prosumer functions with Price optimising response
% %purely for comparison
% Miscr = Miscellaneous(S,NoPros);
% Coldr = ColdAppliancesP(S,NoPros);
% Wetr = WetAppliancesP(S,NoPros,Pros);
% Hwatr = WaterHeatingP(P,NoPros,Pros);%requires a true price
% Spacer = SpaceHeatingP(P,NoPros,Pros);%requires a true price
% DP = Miscr + Coldr + Wetr + Hwatr + Spacer;
% PeakToMeanPriceOptimising = max(DP)/(sum(DP)/48);PeakToMeanPriceOptimising
% PriceOptcost=sum(DP.*Cost)/(1000*2);PriceOptcost 
% %
% %Plot the predicted and actual responsive demand
% %figure;plot(DP);hold on;plot(Dpred);
% sum(DP)/2
% %Plot price optimising demand response to cost signal 
% figure;
% plot(Miscr, 'c','LineWidth',2);hold on;
% plot(Miscr + Coldr, 'g','LineWidth',2);hold on;
% plot(Wetr + Miscr + Coldr, 'b','LineWidth',2);hold on;
% plot(Hwatr + Wetr + Miscr + Coldr, 'm','LineWidth',2);hold on;
% plot(Spacer + Hwatr + Wetr + Miscr + Coldr, 'r','LineWidth',2);hold on;
% grid on;
% axis([0 48 0 3000]);


