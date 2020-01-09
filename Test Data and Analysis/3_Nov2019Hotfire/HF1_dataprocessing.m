%% Documentation

% Data Processing from Hotfire 1 ("HF1") of BJ-01 Hybrid Engine
% Original Author: Dan Zanko (11/22/2019)

%% Initialization

clear, clc, close all

ft = load('HF1_fulltest.mat');
fb = load('HF1_fullburn.mat');
nb = load('HF1_nomburn.mat');


% NOTE::::: 
%      structure tag "ft" = full test data
%      structure tag "fb" = full burn data (includes long trailoff)
%      structure tag "nb" = portion of burn before blowdown (pulled from "ft")

% ** this was done for ease of coding/shorthand **

%% Creating important vars from data to use in calcs later on

% var for easy referencing of length
    ft.l = length(ft.LCR1);
    ft.dtime = diff(ft.time);

    fb.l = length(fb.LCR1);
    fb.dtime(1,1) = 0;
    fb.dtime(2:fb.l,1) = diff(fb.time);

    nb.l = length(nb.LCR1);
    nb.dtime(1,1) = 0;
    nb.dtime(2:nb.l,1) = diff(nb.time);


% N2O Mass Flow Rates
    fb.mdot_ox(1,1) = 0;
    fb.mdot_ox(2:fb.l,1) = -diff(fb.LCR1)./fb.dtime(2:fb.l,1);

    nb.mdot_ox(1,1) = 0;
    nb.mdot_ox(2:nb.l,1) = -diff(nb.LCR1)./nb.dtime(2:nb.l,1);
    
% Thrust (total thrust = sum of the two thrust load cells)
    fb.thrust = fb.LCC1 + fb.LCC2;
    
    nb.thrust = nb.LCC1 + nb.LCC2;

%% Ox Flow Calcs
eng.d_injhole = 5/64; % [in]
eng.n_injholes = 14;
eng.A_injhole = pi*(eng.d_injhole^2)/4; % [in^2]
eng.A_inj = eng.n_injholes * eng.A_injhole; % [in^2]

% WARNING THAT THIS IS EFFECTIVELY TAKING THE CdA of the ENTIRE LOWER
% PLUMBING LINES (NOT the injector)

fb.deltaP = fb.PTR1 - fb.PTC1; % diff in pressure from ox tank to CC (psi)

for i = 1:fb.l
    fb.rho_ox(i,1) = 0.000036127*N2O_NonSat_Lookup(FtoK(fb.TCR3(i)),psi2MPa(fb.PTR1(i)),"Density"); % density of n2o downstream of runtank converted to lbm/in^3
    if fb.deltaP(i,1) < 0
        fb.CdA(i,1) = 0;
    else
        fb.CdA(i,1) = fb.mdot_ox(i,1)./sqrt(2*32.2*12*fb.rho_ox(i,1).*fb.deltaP(i,1));
    end
end

%% Regression Calcs

% **DISCLAIMER**
% Because we actually ran out of HDPE to combust, these regression calcs
% are incredibly sketchy

% A total time to fuel depletion was estimated from the data, yielding a
% rough value for average mdot.

% This can then be used to get a rough value for average specific impulse



%% Engine Performance Calcs

fb.totimpulse = sum(fb.dtime.*fb.thrust);
fb.thrustavg = mean(fb.thrust(7:fb.l));

%% Plots

    %% Thrust vs. time
    figure('Name', 'Thrust'), hold on

        plot(fb.time,fb.thrust, fb.time,smooth(fb.thrust));

        xlabel('Time (s)')
        ylabel('Thrust (lbf)')
        title('Thrust vs. Time - HF1')
        grid on, grid minor
        legend('Raw','Smoothed')

    hold off
    
    %% Thrust and tank pressure vs. time
    figure, hold on
        subplot(2,1,1)
            plot(fb.time,fb.LCR1)
            grid on, grid minor
            xlabel('Time (s)')
            ylabel('N_2O Mass (lbm)')
            title('N_2O Mass vs. Time - HF1')
        subplot(2,1,2)
            plot(fb.time,fb.PTR1)
            grid on, grid minor
            xlabel('Time (s)')
            ylabel('Tank Pressure (psia)')
            title('Lower Tank Pressure vs. Time - HF1')
    hold off

    %% Plotting thrust and chamber pressure vs. time
    figure('Name', 'Thrust & Chamber P'), hold on
        
        xlabel('Time (s)')
        title('Thrust and Chamber Pressure vs. Time - HF1')
        grid on, grid minor
        
        yyaxis left
            plot(fb.time,fb.thrust);
            ylabel('Thrust (lbf)')
        yyaxis right
            plot(fb.time,fb.PTC1); 
            ylabel('Chamber Pressure (psia)')
            ylim([0 inf])

    hold off

    %% Plotting ox tank and chamber pressures
    figure('Name', 'Tank & Chamber P'), hold on

        plot(fb.time, fb.PTR1, fb.time, fb.PTC1);

        xlabel('Time (s)')
        ylabel('Pressure (psia)')
        title('Pressure vs. Time - HF1')
        legend('Tank Pressure','Chamber Pressure')
        grid on, grid minor

    hold off
    
    %% Plotting smoothed Chamber Pressures vs. not smoothed
    figure('Name', 'Chamber P'), hold on

        plot(fb.time, fb.PTC1, fb.time, smooth(fb.PTC1(1:201)));

        xlabel('Time (s)')
        ylabel('Pressure (psia)')
        title('Chamber Pressure vs. Time - HF1')
        legend('Raw','Smoothed')
        grid on, grid minor

    hold off
    
    %% Plotting smoothed mdot_ox vs. not smoothed
    figure('Name', 'Chamber P'), hold on
        plot(fb.time, fb.mdot_ox, fb.time, smooth(fb.mdot_ox));
        xlabel('Time (s)')
        ylabel('N_2O Mass Flow Rate (lbm/s)')
        title('Oxidizer Mass Flow Rate vs. Time - HF1')
        legend('Raw','Smoothed')
        grid on, grid minor
    hold off
    
    %% Plotting mdot and deltaP b/w OxTank and CC vs. time 
    figure('Name', 'mdot & dP'), hold on
        subplot(2,1,1)
            plot(fb.time,fb.mdot_ox,fb.time,smooth(fb.mdot_ox))
            xlabel('Time (s)')
            ylabel('Oxidizer Mass Flow Rate (lbm/s)')
            grid on, grid minor
            title('Oxidizer Flow Rate vs. Time - HF1')
            legend('Raw','Smoothed')
            ylim([0 inf])
        subplot(2,1,2)
            plot(fb.time, fb.deltaP,fb.time,smooth(fb.deltaP));
            xlabel('Time (s)')
            ylabel('\DeltaP (psig)')
            grid on, grid minor
            title('Lower Tank-to-Chamber \Delta P vs. Time - HF1')
            legend('Raw','Smoothed')
    hold off

    %% Plotting mdot and Pch & thrust vs. time 
    figure('Name', 'mdot & dP'), hold on
        subplot(3,1,1)
            plot(fb.time,smooth(fb.mdot_ox))
            xlabel('Time (s)')
            ylabel('Oxidizer Mass Flow Rate (lbm/s)')
            grid on, grid minor
            title('(Smoothed) Oxidizer Flow Rate vs. Time - HF1')
            ylim([0 inf])
        subplot(3,1,2)
            plot(fb.time, smooth(fb.PTC1));
            xlabel('Time (s)')
            ylabel('Chamber Pressure (psia)')
            grid on, grid minor
            title('(Smoothed) Chamber Pressure vs. Time - HF1')
            legend('Raw')
        subplot(3,1,3)
            plot(fb.time, smooth(fb.thrust));
            xlabel('Time (s)')
            ylabel('Thrust (lbf)')
            grid on, grid minor
            title('(Smoothed) Thrust vs. Time - HF1')
            legend('Raw')
    hold off
    
    %% (CURRENTLY COMMENTED OUT) plotting effective discharge area vs. time
    % 
    % 
    % figure('Name', 'CdA'), hold on
    % 
    %     plot(fb.time,nb.CdA)
    %     
    %     fb.Cd = fb.CdA/eng.A_inj;
    %     xlabel('Time (s)')
    %     ylabel('Effective Discharge Area (in^2)')
    %     title('Effective Discharge Area vs. Time - HF1 - TAKEN USING P_{TANK} b/c INJECT PT FAILED - USE WITH CAUTION')
    %     grid on, grid minor
    %     
    % hold off
