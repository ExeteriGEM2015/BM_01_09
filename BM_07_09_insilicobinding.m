%% BM_07_09
% Our final code for the simulation of our cell free kit. This is after the
% restructure implimented after meetings with both Jonathan Fieldsend and
% the lab team. 
% There are still improvements and optimisations to be made these are
% discussed below. 
% More information can be found at 
% <http://2015.igem.org/Team:Exeter/Modeling>. 
% The function take inputs of:
% * t - Number of toeholds
% * r - Number of RNA's
% * N - Number of time steps
% * T - temperature -> this is the parameter scanning variable 
% It outputs GFPcount, this depends on the parameter scanning variable
% choosen. 

function [GFPcount] = BM_07_09_insilicobinding(t,r,N,T)
%% Setting our deafault parameters and variables
% These are the parameters used for the basic setup of Brownian motion as
% well as the contianment to a tube.
% Containment changed to a cylinder to emulate the lab, they are using a
% well plate now. 
% All units are SI units unless otherwise stated. 
    
    rng('shuffle');

    eta = 1.0e-3; % viscosity of water in SI units (Pascal-seconds)
    kB = 1.38e-23; % Boltzmann constant
    %T = 293; % Temperature in degrees Kelvin
    tau = .1; % time interval in seconds
    d_t=5.1e-8; % diameter in meters of toehold
    d_r=1.7e-8; % of RNA
    d_c=5.1e-8; % of toehold-RNA complex
    D_t = kB * T / (3 * pi * eta * d_t); %diffusion coefficient
    D_r = kB * T / (3 * pi * eta * d_r);
    D_c = kB * T / (3 * pi * eta * d_c);
    p_t = sqrt(2*D_t*tau); 
    p_r = sqrt(2*D_r*tau);
    p_c = sqrt(2*D_c*tau);
    
    %CONFINEMENT - height can be changed depending on the volume of the solution (rather than the total possible volume of the eppendorf)
    A = (3.5e-10)*2; %binding distance, default at 1e-7, real world value .5e-10
    
    cylinder_radius=3.34e-6; %radius of F-Well plate well in metres (3.34e-3metres) %changed
    tube_height_max=7.13e-7; %height of F-Well plate well to fill i billionth of 50microlitres (1.426e-3metres)
    tube_height_min=-7.13e-7;
    %Changeable to suit the container of your system
    %Total height is split in half, with one half above the positive xy plane and one half below
    cone_height=18e-3; %unused
    

    %GIF stuff
    theta = 0; % changes the viewing angle
    
    %Figure Stuff
%     figure()
%     %axis([-0.00005 0.00005 -0.00005 0.00005 -0.00005 0.00005]);
%     axis([-5e-3 5e-3 -5e-3 5e-3  -8e-3 8e-3]) %changed
%     grid on
%     grid MINOR
%     set(gcf, 'Position', [100 10 600 600])
%     xlabel('X-axis')
%     ylabel('Y-axis')
%     zlabel('Z-axis')
%     hold on

    %Choosing the number of complexs based on the lower of t and r
    if t>=r
        c=r;
    else
        c=t;
    end
    
    %Checking variables and initalising to zeros 
    blank=[0,0,0];
    points={};
    joinstatus=zeros(N,t+r);
    
    %Initalising points to zeros 
    for j=1:N
        for k=1:t+r+(2*c)
            points{j,k}=blank;
        end
        for k=t+r+2:2:t+r+(2*c)
            points{j,k}=0;
        end
    end
    bouncepoints=points;
    %% The coordinate generation and the main loop
    % The coordinates are now generated on the fly at every time step, this
    % prevents the need to pass around large matrices.
    % This is also the main loop at which every required function is called
    % at each time step.
    
    
    %The main for loop -> loops over all the time steps
    
    for j=1:N
        %% Generation of the inital starting points, calls startpoint.

        if j==1
            [coords, startposition] = startpoint();
%             c_joined=zeros(1,c);
%             c_split=zeros(1,c);
            check=zeros(c,3);
        else
        %% Coordinate generation and confinement checking
        % The coordinates are checked against the height of the tube frist
        % then checkxy is called to check whether it has left the
        % cyclinder.
        
            %Toehold
            for i=1:t
                if any(any(check==i))~=1
                    for k=1:3
                        coords(k+3,i)=coords(k,i);
                        coords(k,i)=(p_t*randn(1))+coords(k+3,i);
                    end   
                    % checking against the height of the tube.
                    if coords(3,i)>=tube_height_max
                        coords(3,i)=tube_height_max;
                    elseif coords(3,i)<=tube_height_min
                        coords(3,i)=tube_height_min;
                    end
                    %calling checkxy to check x and y
                    [coords,bouncepoints]=checkxy(cylinder_radius, coords, i, bouncepoints);
%                   
                end
            end
            %RNA
            for i=t+1:t+r
                if any(any(check==i))~=1
                    for k=1:3
                        coords(k+3,i)=coords(k,i);
                        coords(k,i)=(p_r*randn(1))+coords(k+3,i);
                    end   
                    % checking against the height of the tube.

                    if coords(3,i)>=tube_height_max
                        coords(3,i)=tube_height_max;
                    end
                    if coords(3,i)<=tube_height_min
                        coords(3,i)=tube_height_min;
                    end
%                   %calling checkxy to check x and y
                    [coords,bouncepoints]=checkxy(cylinder_radius, coords, i, bouncepoints);
                end
            end
            %Complex
            for i=t+r+1:t+r+c
                if check(i-(t+r),1)~=0 && check(i-(t+r),2)~=0
                    for k=1:3
                        coords(k+3,i)=coords(k,i);
                        coords(k,i)=(p_c*randn(1))+coords(k+3,i);
                    end
                    % checking against the height of the tube.
                    if coords(3,i)>=tube_height_max
                        coords(3,i)=tube_height_max;
                    end
                    if coords(3,i)<=tube_height_min
                        coords(3,i)=tube_height_min;
                    end
%                   %calling checkxy to check x and y 
                    [coords,bouncepoints]=checkxy(cylinder_radius, coords, i, bouncepoints);
                end
            end
        end
        for q=1:c
            if check(q,3)==0 && check(q,1)==0 && check(q,2)==0 && j~=1
                jointime=j; %variable to make sure joiner and splitter dont happen in same time step 
                [coords,check, startposition, points] = joiner(coords,check, startposition, points);
            elseif check(q,3)~=0
                check(q,3)=check(q,3)+1;
            end
            if check(q,1)~=0 && check(q,2)~=0 && j~=jointime
                [coords, check, startposition, points] = splitter(q, coords, check, startposition, points);
            end
        end
        %% Bouncing
        % 
        for f=1:t+r+c
            if f<t+r+1
                if bouncepoints{j,f}==0 %not a bouncer
                    matcoords=[coords(1,f),coords(2,f),coords(3,f)];
                    points{j,f}=matcoords;
                %couldn't have these statements on the same line for some reason

                elseif bouncepoints{j,f}~=0
                    if size(bouncepoints{j,f},2)==3 %couldn't have these statements on the same line for some reason
                        matcoords=[coords(1,f),coords(2,f),coords(3,f) bouncepoints{j,f}(1,1),bouncepoints{j,f}(1,2),bouncepoints{j,f}(1,3)];
                        points{j,f}=matcoords;
                    end
                end
            end
            if f>=(t+r+1)
                if f==(t+r+1)
                    g=f;
                    h=f+1;
                end
                if bouncepoints{j,g}==0 %not a bouncer
                    matcoords=[coords(1,f),coords(2,f),coords(3,f)];
                    points{j,g}=matcoords;
                elseif bouncepoints{j,g}~=0 
                    if size(bouncepoints{j,f},2)==3
                        matcoords=[coords(1,f),coords(2,f),coords(3,f) bouncepoints{j,g}(1,1),bouncepoints{j,g}(1,2),bouncepoints{j,g}(1,3)];
                        points{j,g}=matcoords;
                    end
                end
                g=g+2;
                if j>1
                    if points{j-1,h}(1,1)~=0
                        if points{j,h}==0 
                            points{j,h}=1;
                        end
                    end
                end
                h=g+1;    
            end
        end

        
        if j==N
            plotter(points);
            counter(points);
            finish=1;
        end
    end
    
%% Startpoint
% Creates a start point definitely inside the dimensions of container,
% this is randomly generated. 
% A vector called startpositon is made so the particles are located around
% this. 
    function [coords, startposition] = startpoint()
        coords=zeros(6,(t+r+c)); %each column is a toehold, with six rows, for current xyz and previous xyz
%         startposition=zeros(6,(t+r+c));
%         coords=mat2dataset(coords);
        for m=1:t+r
            coords(3,m)=(tube_height_min)+((tube_height_max-tube_height_min)*rand(1));
            coords(1,m)=(-cylinder_radius)+((cylinder_radius-(-cylinder_radius))*rand(1));
            coords(2,m)=(-cylinder_radius)+((cylinder_radius-(-cylinder_radius))*rand(1));

        end
        startposition=coords;
    end
       
%% Checking function
% Checks the coordinates are within the boundaries of the eppendorf 
%Function that checks whether the particle is inside of the tube
%for its calculated z-coordinate at the point of contact in the
%tube (in cone: via line equation intersects of path and boundary 
%// in cylinder: line equation of tube boundary). 
%From this point of contact, the new X and Y coordinates are
%calculated for the "exit point" and then subsequently, the new
%resultant xyz can be calculated

    function [coords,bouncepoints]=checkxy(radius,coords,i,bouncepoints)
        %Function that checks whether the particle is inside of the tube
        %for its calculated z-coordinate at the point of contact in the
        %tube (in cone: via line equation intersects of path and boundary 
        %// in cylinder: line equation of tube boundary). 
        %From this point of contact, the new X and Y coordinates are
        %calculated for the "exit point" and then subsequently, the new
        %resultant xyz can be calculated
        

            if (coords(1,i)^2)+(coords(2,i)^2)>=(radius^2)
                %red box in (Maths for exitx.png explains derivation)
                %setting exitX/Y at boundary of cylinder
                grad=abs((sqrt((coords(1,i)^2)+(coords(2,i)^2))-sqrt((coords(4,i)^2)+(coords(5,i)^2)))/(coords(3,i)-coords(6,i)));
                
            
                %confirmed to be correct
                if coords(1,i)<0
                   exitX=-sqrt((radius^2)/((grad^2)+1)); 
                else
                   exitX=sqrt((radius^2)/((grad^2)+1));
                end
                if coords(2,i)<0
                   exitY=-(grad*sqrt(((radius^2)/((grad^2)+1))));
                else
                   exitY=grad*sqrt(((radius^2)/((grad^2)+1)));
                end
                
                Px=coords(1,i);
                Py=coords(2,i);
                lastx=coords(4,i);
                lasty=coords(5,i);
                
                
                
                
                trajectory_gradient=(Py-lasty)/(Px-lastx); %m1
                tangent_gradient=(-exitX/exitY);  %m2
                theta_bounce=atan(trajectory_gradient);
                phi_2=atan(tangent_gradient);
                phi_1=theta_bounce-phi_2;
                exitPDist=sqrt(((Px-lastx)^2)+((Py-lasty)^2));
                G_length=exitPDist*cos(phi_1);
                Gx=exitX+(G_length*cos(phi_1));
                Gy=exitY+(G_length*cos(phi_1));
                Cx=Px-Gx;
                Cy=Py-Gy;
                newX=Px-(2*Cx);
                newY=Py-(2*Cy);
               
                perpendicular_gradient=(exitY/exitX);
%                 shifted_perpendicular_line=(perpendicular_gradient*EX)-((exitY+Px)/exitX)+Py;
               
                %z-intercept with boundary: (see book)
                prad=sqrt((coords(1,i)^2)+(coords(2,i)^2));
                lastrad=sqrt((coords(4,i)^2)+(coords(5,i)^2));
                Dr=prad-lastrad;
                pZ=coords(3,i);
                lastZ=coords(6,i);
                Dz=pZ-lastZ;
                Gr=radius-lastrad;
                Gz=Gr*tan(acos(Dr/sqrt((Dr^2)+(Dz^2))));

                if pZ<lastZ
                    exitZ=lastZ-Gz;
                else
                    exitZ=lastZ+Gz;
                end
                %write new points directly into points in a way that joiner and
                %splitter can still work
                if i<=t+r
                    bouncepoints{j,i}=[exitX exitY exitZ];
                elseif i>t+r
                    bouncepoints{j,(2*i)-1}=[exitX exitY exitZ];
                end
                %update for next point
                coords(1,i)=newX;
                coords(2,i)=newY;
                coords(3,i)=coords(3,i);
            end
    end

%% Joining function
% This function has a threshold for joining, a joining probability. If this
% is met the toehold and RNA's are joined. The check vector changes to
% indicate this, the toeholds and RNA's are spotted being made and a
% complex line is made instead. 
% startingposition is also updated to indicate the new starting point of the
% complex line.
    function [coords, check, startposition, points] = joiner(coords, check, startposition, points)
        colshift=0;
        %Joining probability calculated from in silico data of free energy of complex from NUPACK and
        %equation of polynomial fit to normalised curve gives probability
        %of binding (or rather gives the threshold to enable a successful
        %binding event which a randomly generated number is tested against)
        joinevent = (randi([1 10000000],1))/10000000;
        Tempcorrection = T-273;
        jointhreshold = ((4e-07)*(Tempcorrection^4)) - ((6e-05)*(Tempcorrection^3)) + (0.0023*(Tempcorrection^2)) - (0.0072*Tempcorrection) + 0.3745;
        if joinevent >= jointhreshold
            for n=1:t
                for m=t+1:r+t
                    if any(any(check==n))==1 || any(any(check==m))==1
                        continue
                    else
       %                 if ((((tx(j,k)-rx(j,m))^2)+((ty(j,k)-ry(j,m))^2)+((tz(j,k)-rz(j,m))^2))<=(A^2) || (check_r(1,m)~=0 && check_t(1,k)~=0)) && (j~=1) && delay(1,n)==0    
                        if (((coords(1,n)-coords(1,m))^2)+((coords(2,n)-coords(2,m))^2)+((coords(3,n)-coords(3,m))^2))<=(A^2)
                            for p=1:c    
                                if check(p,1)~=0 && check(p,2)~=0
                                    continue
                                else
                                    if check(p,1)==0 && check(p,2)==0
                                        coords(1,t+r+p)=(coords(1,n)+coords(1,m))/2;
                                        coords(2,t+r+p)=(coords(2,n)+coords(2,m))/2;
                                        coords(3,t+r+p)=(coords(3,n)+coords(3,m))/2;
                                        startposition(1,t+r+p)=coords(1,t+r+p);
                                        startposition(2,t+r+p)=coords(2,t+r+p);
                                        startposition(3,t+r+p)=coords(3,t+r+p);
                                        check(p,1)=n;
                                        check(p,2)=m;
                                        if colshift==0;
                                            colshift=1;
                                        end
                                        points{j,t+r+p+colshift}=[1,n,m];
                                        colshift=colshift+1;
                                        joinstatus(j,n)=1;
                                        joinstatus(j,m)=1;
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

%% Splitter function
% Splitter is similar to joiner but the opposite happnens. 
% If a threshold is reached the complex will split back into a toehold and 
% RNA. These lines are now produced again, check is updated to reflect this
% and finally startposition is changed.

    function [coords, check, startposition, points] = splitter(q, coords, check, startposition, points)
        splitevent = (randi([1 10000000],1))/10000000;
        Tempcorrection = T-273;
        splitthreshold = (-(4e-07)*(Tempcorrection^4)) + ((6e-05)*(Tempcorrection^3)) - (0.0023*(Tempcorrection^2)) + (0.0072*Tempcorrection) + 0.6255;
        %y=-4E-07x4 + 6E-05x3 - 0.0023x2 + 0.0072x + 0.6255


        if splitevent<=splitthreshold
            if check(q,1)~=0 && check(q,2)~=0
                toehold=check(q,1);
                rna=check(q,2);
                startposition(1,toehold)=coords(1,t+r+q);
                startposition(2,toehold)=coords(2,t+r+q);
                startposition(3,toehold)=coords(3,t+r+q);
                startposition(1,rna)=coords(1,t+r+q);
                startposition(2,rna)=coords(2,t+r+q);
                startposition(3,rna)=coords(3,t+r+q);
                coords(1,rna)=coords(1,t+r+q);
                coords(2,rna)=coords(2,t+r+q);
                coords(3,rna)=coords(3,t+r+q);
                coords(1,toehold)=coords(1,t+r+q);
                coords(2,toehold)=coords(2,t+r+q);
                coords(3,toehold)=coords(3,t+r+q);
                
                
                points{j,t+r+(2*q)}=[0,toehold,rna];
                check(q,1)=0;
                check(q,2)=0;
                check(q,3)=-5;
            end
        end
    end

%% Plotting function
% 
    function [] = plotter(points)
        %Conditions from plotting drawn from points array
        for row=1:N
            if row==1
                %startpoints
                for col=1:t+r
                   plot3(points{row,col}(1,1), points{row,col}(1,2), points{row,col}(1,3),'kx') 
                end
            else
                for altcol=t+r+2:2:t+r+(2*c)
                    if points{row,altcol}(1,1)==1 && size(points{row,altcol},2)==3 && row>1
                        if points{row-1,altcol}(1,1)==0 %definitely joinpoint
                            %plot blue using row-1 to row to joinpoint column, column selected from points{row,col}(1,2)) 
                            plot3([points{row-1,(points{row,altcol}(1,2))}(1,1), points{row,altcol-1}(1,1)], [points{row-1,(points{row,altcol}(1,2))}(1,2), points{row,altcol-1}(1,2)], [points{row-1,(points{row,altcol}(1,2))}(1,3), points{row,altcol-1}(1,3)], 'b')
                            %plot red using row-1 to row to joinpoint column, column selected from points{row,col}(1,2)
                            plot3([points{row-1,(points{row,altcol}(1,3))}(1,1), points{row,altcol-1}(1,1)], [points{row-1,(points{row,altcol}(1,3))}(1,2), points{row,altcol-1}(1,2)], [points{row-1,(points{row,altcol}(1,3))}(1,3), points{row,altcol-1}(1,3)], 'r')
                            %plot circle at joinpoint
                            plot3(points{row,altcol-1}(1,1), points{row,altcol-1}(1,2), points{row,altcol-1}(1,3), 'ko')
                        end
                        if points{row-1,altcol}(1,1)==1 %defintely splitpoint
                            %do nothing
                        end
                    elseif (points{row,altcol}(1,1)==1 && size(points{row,altcol},2)==1) || (points{row,altcol}(1,1)==0 && size(points{row,altcol},2)==3)
                        %plot green from row-1 to row
                        if size(points{row-1,altcol-1},2)==3
                            plot3([points{row-1,altcol-1}(1,1), points{row, altcol-1}(1,1)], [points{row-1,altcol-1}(1,2), points{row, altcol-1}(1,2)], [points{row-1,altcol-1}(1,3), points{row, altcol-1}(1,3)],'g')
                        elseif size(points{row,altcol-1},2)==6 %Bouncing of the side points index for this is 6 numbers, the xyzpoint before hitting and the xyzpoint on the boundary
                            bounceplot(points, row, altcol-1, 'g')
                        end
                    end
                    if points{row,altcol}(1,1)==0 %currently split
                        if size(points{row-1,altcol},2)==3 && points{row-1,altcol}(1,1)==0 %prevents incorrect plotting in the case of join/split in consecutive timesteps
                            %plot from split column to blue column
                            plot3([points{row-1,altcol-1}(1,1), points{row,(points{row-1,altcol}(1,2))}(1,1)],[points{row-1,altcol-1}(1,2), points{row,(points{row-1,altcol}(1,2))}(1,2)],[points{row-1,altcol-1}(1,3), points{row,(points{row-1,altcol}(1,2))}(1,3)],'b')
                            %plot from split column to red column
                            plot3([points{row-1,altcol-1}(1,1), points{row,(points{row-1,altcol}(1,3))}(1,1)],[points{row-1,altcol-1}(1,2), points{row,(points{row-1,altcol}(1,3))}(1,2)],[points{row-1,altcol-1}(1,3), points{row,(points{row-1,altcol}(1,3))}(1,3)],'r')
                            %plot star at splitpoint
                            plot3(points{row-1,altcol-1}(1,1), points{row-1,altcol-1}(1,2), points{row-1,altcol-1}(1,3), 'k*')
                            %plot 
                            continue %might not be necessary
                        end
                    end
                    for col=1:t+r
                        if points{row,col}(1,1)~=points{row-1,col}(1,1) && points{row,col}(1,2)~=points{row-1,col}(1,2) && points{row,col}(1,3)~=points{row-1,col}(1,3)
%                         have to be specific due to 1x6 object when bouncing occurs
                           if size(points{row,altcol},2)~=3
                               %determine column in t or r for colour of line
                               if col<=t %plot blue for toeholds
                                   if ((size(points{row-1,altcol},2)==3 && points{row-1,altcol}(1,1)==0) && points{row-1,altcol}(1,2)==col)
                                   %if just split, don't plot from row-1 to row in t column since plotting from split point has just occurred
                                       continue
                                   elseif points{row,altcol}==0 && size(points{row-1,altcol},2)~=3
                                       if size(points{row-1,col},2)==3
                                           plot3([points{row-1,col}(1,1), points{row,col}(1,1)], [points{row-1,col}(1,2), points{row,col}(1,2)], [points{row-1,col}(1,3), points{row,col}(1,3)],'b')
                                       elseif size(points{row,col},2)==6 %Bouncing of the side points index for this is 6 numbers, the xyzpoint before hitting and the xyzpoint on the boundary
                                           bounceplot(points, row, col, 'b')
                                       end
                                   end
                               end
                               if col>t %plot red for rna(trigger)
                                   if ((size(points{row-1,altcol},2)==3 && points{row-1,altcol}(1,1)==0) && points{row-1,altcol}(1,3)==col)
                                   %if just split, don't plot from row-1 to row in r column since plotting from split point has just occurred
                                       continue
                                   elseif points{row,altcol}==0 && size(points{row-1,altcol},2)~=3
                                       if size(points{row-1,col},2)==3
                                           plot3([points{row-1,col}(1,1), points{row,col}(1,1)], [points{row-1,col}(1,2), points{row,col}(1,2)], [points{row-1,col}(1,3), points{row,col}(1,3)],'r')
                                       elseif size(points{row,col},2)==6 %Bouncing of the side points index for this is 6 numbers, the xyzpoint before hitting and the xyzpoint on the boundary
                                           bounceplot(points, row, col, 'r')
                                       end
                                   end
                               end
                           end
                        end
                    end
                end
            end
        end
    end  
%% Bouncing function
% 

    function [points] = bounceplot(points, row, col, style)

    %   coordinate structure is now: row-1 = [lastX lastY lastZ]
    %                                row   = [newY exitZ newZ exitX newX exitY ]
    
        plot3([points{row-1,col}(1,1) points{row,col}(1,4)], [points{row-1,col}(1,2) points{row,col}(1,5)], [points{row-1,col}(1,3) points{row,col}(1,6)],style)
        plot3([points{row,col}(1,4) points{row,col}(1,1)], [points{row,col}(1,5) points{row,col}(1,2)], [points{row,col}(1,6) points{row,col}(1,3)],style)
    end

%% Counting function
% This function is related to the generation of a GFP output of our system,
% it is used in combination with the parameter scanning aspect of our
% simulation.

    function counter(points)
        %simplfied status of each toehold and trigger drawn from points array
        
        for jstatcol=1:t+r
            for jstatrow=2:N
                if points{jstatrow,jstatcol}(1)==points{jstatrow-1,jstatcol}(1) && points{jstatrow,jstatcol}(2)==points{jstatrow-1,jstatcol}(2) && points{jstatrow,jstatcol}(3)==points{jstatrow-1,jstatcol}(3)
                    joinstatus(jstatrow,jstatcol)=1;
%                     if joinstatus{jstatrow-1,jstatcol}==0
%                         joinstatus{jstatrow-1,jstatcol}=1;
%                     end
                else
                    if joinstatus(jstatrow,jstatcol)~=1
                        joinstatus(jstatrow,jstatcol)=0;
                    end
                    if points{jstatrow-1,jstatcol}==1
                        joinstatus(jstatrow,jstatcol)='split';
                    end
                end
            end
        end
        totalgreen=0;
        for col=1:t
            totalgreen=totalgreen+sum(joinstatus(:,col));
        end
        totalgreentime=totalgreen*tau;
        GFPrate=1.2;
        GFPcount=totalgreentime*GFPrate;
        %GFPconc=GFPcount/eppendorfvolume;
        %GFPrate is calculated using E0040 Biobrick for GFP (720 base
        %pairs/240 AA) Ribosome speed @ 200AA/min -> 240/200 = 1.2 GFP/min
               
    end

%% Code needed to produce a .gif file of the simulation output

    function jiff(row) 
       change = 360/N; % the size of the angle change 
       % gif utilities
       set(gcf,'color','w'); % set figure background to white
       drawnow;
       frame = getframe(gcf);
       im = frame2im(frame);
       [imind,cm] = rgb2ind(im,256);
       outfile = '17_07_v1.gif';
       
       % adjusting the viewing the angle
       view(theta,45);
       theta = theta + change;

       % On the first loop, create the file. In subsequent loops, append.
       if row==2
          imwrite(imind,cm,outfile,'gif','DelayTime',0,'loopcount',inf);
       else
          imwrite(imind,cm,outfile,'gif','DelayTime',0,'writemode','append');
       end
    end 
end
%% End Of The Code
    % This is the final simulation developed by the Univeristy Of Exeter
    % iGEM team 2015.
    % Developed mainly by Amy, Dan and Todd. 