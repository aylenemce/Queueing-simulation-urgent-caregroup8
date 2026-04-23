%[text] # Run samples of the ServiceQueue simulation
%[text] Collect statistics and plot histograms along the way.
PictureFolder = "Pictures";
mkdir(PictureFolder); %[output:15a0b40e]
%%
%[text] ## Set up
%[text] We'll measure time in hours
%[text] Arrival rate: 2 per hour
lambda = 2;
%[text] Departure (service) rate: 1 per 20 minutes, so 3 per hour
mu = 3;
%[text] Number of serving stations
s = 1;
%[text] Run many samples of the queue.
NumSamples = 500;
%[text] Each sample is run up to a maximum time.
MaxTime = 50;
%[text] Make a log entry every so often
LogInterval = 1;
%%
%[text] ## Numbers from theory for M/M/1 queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
rho = lambda / mu;
P0 = 1 - rho;
nMax = 10;
P = zeros([1, nMax+1]);
P(1) = P0;
for n = 1:nMax
    P(1+n) = P0 * rho^n;
end 
%%
% calculating 2.1

fprintf('P(%d) = %.6f\n', n, P(n+1)); %[output:0fa02972]
L_theory  = rho / (1 - rho) %[output:15c7035f]
Lq_theory = rho^2 / (1 - rho) %[output:4293fdc1]
W_theory  = L_sim / lambda %[output:6ee5955f]
Wq_theory = Lq_sim / lambda %[output:4c8b7265]
theory = [L_theory, Lq_theory, W_theory, Wq_theory] %[output:32dc64d8]
%%
%[text] ## Run simulation samples
%[text] This is the most time consuming calculation in the script, so let's put it in its own section.  That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%[text] Reset the random number generator.  This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.  This is a good idea for testing purposes.  Under other circumstances, you probably want the random numbers to be truly unpredictable and you wouldn't do this.
rng("default");
%[text] We'll store our queue simulation objects in this list.
QSamples = cell([NumSamples, 1]);
%[text] The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.
for SampleNum = 1:NumSamples %[output:group:55a086bd]
    if mod(SampleNum, 10) == 0
        fprintf("%d ", SampleNum); %[output:13f627a9]
    end
    if mod(SampleNum, 100) == 0
        fprintf("\n");
    end
    q = ServiceQueue( ...
        ArrivalRate=lambda, ...
        DepartureRate=mu, ...
        NumServers=s, ...
        LogInterval=LogInterval);
    q.schedule_event(Arrival(random(q.InterArrivalDist), Customer(1)));
    run_until(q, MaxTime);
    QSamples{SampleNum} = q;
end %[output:group:55a086bd]
%%
%[text] ## Collect measurements of how many customers are in the system
%[text] Count how many customers are in the system at each log entry for each sample run.  There are two ways to do this.  You only have to do one of them.
%[text] ### Option one: Use a for loop: Solving for L
NumInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end

% Solving for L_q
NumInWaitingSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInWaitingSamples{SampleNum} = q.Log.NumWaiting;
end

% L Simulated
NumInSystem = vertcat(NumInSystemSamples{:});
meanNumInSystemSamples = mean(NumInSystem);
fprintf("Mean number in system: %f\n", meanNumInSystemSamples); %[output:06c4a262]

% L_q Simulated
NumInWaiting = vertcat(NumInWaitingSamples{:});
meanNumInWaitingSamples = mean(NumInWaiting);
fprintf("Mean number waiting in system: %f\n", meanNumInWaitingSamples); %[output:91b01706]
%[text] ### Option two: Map a function over the cell array of ServiceQueue objects.
%[text] The `@(q) ...` expression is shorthand for a function that takes a `ServiceQueue` as input, names it `q`, and computes the sum of two columns from its log.  The `cellfun` function applies that function to each item in `QSamples`. The option `UniformOutput=false` tells `cellfun` to produce a cell array rather than a numerical array.
%NumInSystemSamples = cellfun( ...
    %@(q) q.Log.NumWaiting + q.Log.NumInService, ...
    %QSamples, ...
    %UniformOutput=false);
%[text] ## Join numbers from all sample runs.
%[text] `vertcat` is short for "vertical concatenate", meaning it joins a bunch of arrays vertically, which in this case results in one tall column.
NumInSystem = vertcat(NumInSystemSamples{:});
%[text] MATLAB-ism: When you pull multiple items from a cell array, the result is a "comma-separated list" rather than some kind of array.  Thus, the above means
%[text] `NumInSystem = vertcat(NumInSystemSamples{1}, NumInSystemSamples{2}, ...)`
%[text] which concatenates all the columns of numbers in NumInSystemSamples into one long column.
%[text] This is roughly equivalent to "splatting" in Python, which looks like `f(*args)`.
%%
%[text] ## Pictures and stats for number of customers in system
%[text] Print out mean number of customers in the system.
meanNumInSystem = mean(NumInSystem);
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:17d65c90]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:895525a5]
t = tiledlayout(fig,1,1); %[output:895525a5]
ax = nexttile(t); %[output:895525a5]
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on"); %[output:895525a5]
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:895525a5]
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:895525a5]
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system"); %[output:895525a5]
xlabel(ax, "Count"); %[output:895525a5]
ylabel(ax, "Probability"); %[output:895525a5]
legend(ax, "simulation", "theory"); %[output:895525a5]
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.2$.
%ylim(ax, [0, 0.2]);
%[text] This sets the horizontal axis to go from $-1$ to $21$.  The histogram will use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
%xlim(ax, [-1, 21]);
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.pdf"); %[output:895525a5]
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.svg"); %[output:895525a5]
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:8f67ab5b]



% histogram for L_q

%[text] 
%%
%[text] ## Collect measurements of how long customers spend in the system
%[text] This is a rather different calculation because instead of looking at log entries for each sample `ServiceQueue`, we'll look at the list of served  customers in each sample `ServiceQueue`.
%[text] ### Option one: Use a for loop: Solving for W
TimeInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % The next command has many parts.
    %
    % q.Served is a row vector of all customers served in this particular
    % sample.
    % The ' on q.Served' transposes it to a column.
    %
    % The @(c) ... expression below says given a customer c, compute its
    % departure time minus its arrival time, which is how long c spent in
    % the system.
    %
    % cellfun(@(c) ..., q.Served') means to compute the time each customer
    % in q.Served spent in the system, and build a column vector of the
    % results.
    %
    % The column vector is stored in TimeInSystemSamples{SampleNum}.
    TimeInSystemSamples{SampleNum} = ...
        cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served');
end

% Solving for W_q
WaitingInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % The next command has many parts.
    %
    % q.Served is a row vector of all customers served in this particular
    % sample.
    % The ' on q.Served' transposes it to a column.
    %
    % The @(c) ... expression below says given a customer c, compute its
    % departure time minus its arrival time, which is how long c spent in
    % the system.
    %
    % cellfun(@(c) ..., q.Served') means to compute the time each customer
    % in q.Served spent in the system, and build a column vector of the
    % results.
    %
    % The column vector is stored in TimeInSystemSamples{SampleNum}.
    WaitingInSystemSamples{SampleNum} = ...
        cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served');
    
end

% W Simulated
TimeInSystemSamples = vertcat(TimeInSystemSamples{:});
meanTimeInSystemSamples = mean(TimeInSystemSamples);
fprintf("Mean time in system: %f\n", meanTimeInSystemSamples); %[output:5f23dbc9]

% W_q Simulated
WaitingInSystemSamples = vertcat(WaitingInSystemSamples{:});
meanWaitingInSystemSamples = mean(WaitingInSystemSamples);
fprintf("Mean waiting time in system: %f\n", meanWaitingInSystemSamples); %[output:7fe5aa78]
%[text] ### Option two: Use `cellfun` twice.
%[text] The outer call to `cellfun` means do something to each `ServiceQueue` object in `QSamples`.  The "something" it does is to look at each customer in the `ServiceQueue` object's list q.Served and compute the time it spent in the system.
%TimeInSystemSamples = cellfun( ...
    %@(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    %QSamples, ...
    %UniformOutput=false);
%[text] ### Join them all into one big column.
%TimeInSystem = vertcat(TimeInSystemSamples{:});
%%
%[text] ## Pictures and stats for time customers spend in the system
%[text] `Print out mean time spent in the system.`
meanTimeInSystem = mean(TimeInSystem);

fprintf("Mean time in system: %f\n", meanTimeInSystem); %[output:66130328]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:309e85e1]
t = tiledlayout(fig,1,1); %[output:309e85e1]
ax = nexttile(t); %[output:309e85e1]
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:309e85e1]
%[text] Add titles and labels and such.
title(ax, "Time in the system"); %[output:309e85e1]
xlabel(ax, "Time"); %[output:309e85e1]
ylabel(ax, "Probability"); %[output:309e85e1]
%[text] Set ranges on the axes.
%ylim(ax, [0, 0.2]);
%xlim(ax, [0, 2.0]);
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.pdf"); %[output:309e85e1]
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.svg"); %[output:309e85e1]

% histogram for W_q

%%
TimeWaitingSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % The next command has many parts.
    %
    % q.Served is a row vector of all customers served in this particular
    % sample.
    % The ' on q.Served' transposes it to a column.
    %
    % The @(c) ... expression below says given a customer c, compute its
    % departure time minus its arrival time, which is how long c spent in
    % the system.
    %
    % cellfun(@(c) ..., q.Served') means to compute the time each customer
    % in q.Served spent in the system, and build a column vector of the
    % results.
    %
    % The column vector is stored in TimeInSystemSamples{SampleNum}.
    TimeWaitingSamples{SampleNum} = ...
        cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served');
end

%%
%L_q (expected number of customers waiting)
fig = figure(); %[output:556fd86c]
t = tiledlayout(fig,1,1); %[output:556fd86c]
ax = nexttile(t); %[output:556fd86c]

h = histogram(ax, Lq_sim, Normalization="probability", BinMethod="integers"); %[output:556fd86c]
title(ax, "expected count waiting"); %[output:556fd86c]
xlabel(ax, "Time"); %[output:556fd86c]
ylabel(ax, "Probability"); %[output:556fd86c]
%[text] Set ranges on the axes.
%ylim(ax, [0, 0.2]);
%xlim(ax, [0, 2.0]);
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Expected count waiting histogram.pdf"); %[output:556fd86c]
exportgraphics(fig, PictureFolder + filesep + "Expected count waiting histogram.svg"); %[output:556fd86c]

%compute waiting time
TimeWaitingSamples = cellfun(...
    @(q) cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served'), ...
    QSamples,...
    UniformOutput=false);
TimeWaiting = vertcat(TimeWaitingSamples{:});
meanTimeWaiting = mean(TimeWaiting);

%compute Lq
Lq_theory = lambda * meanTimeWaiting;

%final sim vector
theory = [L_sim, Lq_sim, W_sim, Wq_sim];

L_sim_emp  = meanNumInSystem;
W_sim_emp  = meanTimeInSystem;
Wq_sim_emp = meanTimeWaiting;
Lq_sim_emp = lambda * Wq_sim_emp;

sim = [L_sim_emp, Lq_sim_emp, W_sim_emp, Wq_sim_emp];

% Safe percent discrepancy calculation
pct = nan(size(theory));                % preallocate
nonzero = theory ~= 0;                  % indices where theory nonzero
pct(nonzero) = 100 * abs(sim(nonzero) - theory(nonzero)) ./ abs(theory(nonzero));
pct(~nonzero)  = abs(sim(~nonzero) - theory(~nonzero)); % absolute diff when theory == 0

% Display nicely
for k = 1:numel(theory) %[output:group:2ed6cdf5]
    if theory(k) ~= 0
        fprintf('Stat %d: theory = %.4g, sim = %.4g, discrepancy = %.3f%%n', ... %[output:767872c1]
                k, theory(k), sim(k), pct(k)); %[output:767872c1]
    else
        fprintf('Stat %d: theory = 0, sim = %.4g, abs discrepancy = %.4g\n', ...
                k, sim(k), pct(k));
    end
end %[output:group:2ed6cdf5]
%%
%[text] Average Value Estimates: 
%[text] $lambda$ = $2$
%[text] $mu$ = $3$ 
%[text] $s$ = $1$
%[text] $p$ = $\\frac{lambda}{s \* mu}$ = $\\frac{2}{(3)(1)}$ = $\\frac{2}{3}$
%[text] $P\_0$ = $(1-p)\*p^n$ 
%[text] for $n = 0:$ $(1-p)\*p^0=(1-\\frac{2}{3})\*\\frac{2}{3}^0=\\frac{1}{3}\*1=\\frac{1}{3}=0.3333$
%[text] for $n = 1$: $(1-p)\*p^1=\\frac{1}{3}\*\\frac{2}{3}^1=\\frac{2}{9}=0.2222$
%[text] for $n = 2$: $(1-p)\*p^2=\\frac{1}{3}\*\\frac{2}{3}^2=\\frac{4}{27}=0.148$
%[text] for $n=3$: $(1-p)\*p^3=\\frac{1}{3}\*\\frac{2}{3}^3=\\frac{8}{81}=0.0987$
%[text] for $n=4$: $(1-p)\*p^4=\\frac{1}{3}\*\\frac{2}{3}^4=\\frac{16}{243}=0.0658$
%[text] for $n=5$: $(1-p)\*p^5=\\frac{1}{3}\*\\frac{2}{3}^5=\\frac{32}{729}=0.0438$ 
%[text] for $s = 1$: $\\frac{(2/3)^1}{1!(1-(2/3))}$ = $2$
%[text] $P\_0$ = $(1-\\frac{2}{3})=\\frac{1}{3} = 0.33$
%[text] $L\_q$ = $\\frac{p}{1-p}=\\frac{\\frac{2}{3}}{1-(\\frac{2}{3})}=\\frac{\\frac{2}{3}}{\\frac{1}{3}}=2$
%[text] $L$ = $\\frac{p^2}{1-p}=\\frac{\\frac{2}{3}^2}{\\frac{1}{3}}=\\frac{\\frac{4}{9}}{\\frac{1}{3}}=\\frac{12}{9}=\\frac{4}{3} = 1.33$
%[text] $P\_q$ `=` $p=\\frac{2}{3} = 0.667$
%[text] $W\_q$ = $\\frac{L}{lambda}=\\frac{2}{2}=1$
%[text] $W$ = $\\frac{L\_q}{lambda}=\\frac{\\frac{4}{3}}{2}=\\frac{4}{6}=\\frac{2}{3} = 0.667$
%[text] How do these compare to the simulation numbers:

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":21.7}
%---
%[output:15a0b40e]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Directory already exists."}}
%---
%[output:0fa02972]
%   data: {"dataType":"text","outputData":{"text":"P(10) = 0.005781\n","truncated":false}}
%---
%[output:15c7035f]
%   data: {"dataType":"textualVariable","outputData":{"name":"L_theory","value":"2.0000"}}
%---
%[output:4293fdc1]
%   data: {"dataType":"textualVariable","outputData":{"name":"Lq_theory","value":"1.3333"}}
%---
%[output:6ee5955f]
%   data: {"dataType":"textualVariable","outputData":{"name":"W_theory","value":"1.0000"}}
%---
%[output:4c8b7265]
%   data: {"dataType":"textualVariable","outputData":{"name":"Wq_theory","value":"0.6667"}}
%---
%[output:32dc64d8]
%   data: {"dataType":"matrix","outputData":{"columns":4,"name":"theory","rows":1,"type":"double","value":[["2.0000","1.3333","1.0000","0.6667"]]}}
%---
%[output:13f627a9]
%   data: {"dataType":"text","outputData":{"text":"10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300 310 320 330 340 350 360 370 380 390 400 410 420 430 440 450 460 470 480 490 500 ","truncated":false}}
%---
%[output:06c4a262]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 1.881563\n","truncated":false}}
%---
%[output:91b01706]
%   data: {"dataType":"text","outputData":{"text":"Mean number waiting in system: 1.225046\n","truncated":false}}
%---
%[output:17d65c90]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 1.881563\n","truncated":false}}
%---
%[output:895525a5]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAWgAAADYCAYAAADGWHkUAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQfUVEXShhswYBZEFBOYAwqGFbOYBbNiWrOiYlbMAZU1AwZEMBLMoGLGNSuwRsyYBSOYMYC6vxF\/ntaa7envpkl37sxUnePZ5Zt7O7zd\/d7qqurqZn\/++eefRkURUAQUAUUgcwg0U4LO3JhogxQBRUARsAgoQetEUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAgoQescUAQUAUUgowgoQWd0YLRZioAioAjEEvTUqVPNb7\/9lkNqySWXNLPNNlsT5KZPn26+\/fZb+3d+57ksyqeffppr1nzzzWfmn3\/+LDazLG36\/fffzZdffmkYw\/\/+979mpZVWMu3atStL2VpIfSDAHHnllVdynVlsscXM4osvXrXOfffdd4Y2IS1btjSs0UaWWIJee+21zTfffJPD6NxzzzV77713E8yuu+46c+GFF+b+zqAvsMACmcN2mWWWybXpyCOPNCeccELm2liOBn344Yfm6KOPNm+99VauuOOPP94cddRR5Si+amX89NNPBmVAZJFFFjEtWrSoWntqveIffvjBdO7cOdeN3r1723lTSfniiy\/MzJkzbRWtWrUyc801V666bbbZxrzzzjv239tuu6254oorKtmUzJddMEHPM8885qmnnmpCvkrQ2Rrrvfbayzz33HN5jaoHgr7rrrvMiSeemOvX888\/bxZeeOFsgV9DrUmboNnNbbzxxjmErrzyStOtWzcl6JA5UzBBU87BBx9sTj\/99LwilaCzsyr\/+OMPs\/zyy+c1aPvtt7cayVZbbZWdhhbREiXoIkCLeMUn6FNPPdUceuih5a3EKe2jjz4ym222mRJ0QoSLImjKfvzxx83SSy+dqyZNgv7zzz9tvc2aNQvsJgQVtu0NM3FQJv81b948IXTGzJgxo2gb9v\/93\/\/lbe2SVvrVV1+ZOeecM9J8hC\/gH\/\/4R67IUjRnsQcG+R2Stjnpc5gvqC\/KNFYoQTMX2FK3bt26KLxpe9R8ivrN7zd9w5\/jbumTYoNJgHcZe19+\/fVXOxcxFxRj7nF9TIxz2Lpy6\/3ll18C2xLXn2IJGpzpZyHYlbI+\/X5gVgMbLAiVFH8NFE3QW2yxhbn22mtjCZoBOeuss3LPHXjggWbTTTfN\/XvKlCnmjDPOyP0b+xd2b4StLE4DZMcddzSLLrqouffee80jjzxifv75Z7P11lub3XbbzayzzjrmjTfeMMOHD7fbehZkp06dzDHHHJP3taYcn6B594477jBPPPGEAZx1113X7LDDDmbPPfcMHIcHH3zQjBw50jpWeH6hhRay9aOddu\/ePe+dG2+80Tz22GP2b6uuuqqh76NGjTL33XefYYKPHz8+0VhTBn17\/fXXbZ0I9a655poG8l1xxRVz5QwcONBgf77\/\/vtzf8PGyDMbbLCBQZOOEzDH9vfyyy+biRMn2sfBfv311zc9e\/Y0K6+8cq6IUsaXQj777DNDm5988sk8X8daa61l\/vnPf9qxYGFMmzbNXHzxxeb99983L730Uq5++sOiPe2003LEzmIeNmyY+fe\/\/51rPy+gUDC+zCvIzBXwffrpp+2fVlhhBbP77rsbPgYPPfSQrXPzzTe347vLLrvYOUmbn3nmGfsb5e6xxx52Z+l\/4CG\/oUOHmocffjjXlmWXXdbQv3322cfOC1fQYMEEYW4vt9xydn4ynux+zj\/\/fPsbH3jK5TfMBiK0hffALokPiHJ69eqVe3+nnXayfUTo\/wMPPGD\/P05\/nrvzzjstJvg2IKuuXbuaY489tsmOLWiOgdmbb75plTsRxmOppZay+K2xxhrGt0HjM8G3xZgz98EOkwhre\/bZZ29STSHrM24dsMZpM+tA1h193mijjcx+++1n55KMxWGHHWYVPKRt27Z2rrpCWZdddlnuT\/QXzkCi1kDRBE3BENCGG25oKwnToN9+++1cQ3iuf\/\/+Ztddd801lIb36NEj9++rr746tw13HZSQzGuvvdYEUwC76KKLDBNbQHQf6tevn52wIi5BM5khsyBhotJW0RxZaKeccoq55557QsfV11Rp0+23326fZzApQ8hliSWWiCVoNC7aD9lEiYspJMoHKkj4QJx55pmRZTEebHFdx7D\/wpAhQ3Ifo1LG1383qGEQDaTEhxwyCBP8IkQgQOSMA\/8OEz42V111VZ5zjHdkbPmdsQrC4IILLjA333xznvNV6oHY3IXJwgNL11Hrt+mGG26wC17EHT\/6zsdc5rVggWa48847h85dylpllVWsMjDvvPNGjneUDRrcZe6hEBDxFLZeUHA6dOgQWVfU3Lz88sut8uASNHWiiAWta7iBcRCSLmZ9RjX2tttusx\/9KIG8USAQxsPlp\/\/85z950TCs42uuuSZXHB85FIG4NVAQQTMB2WLL5OdrxhcLEqs0QUciFfEjg4ymIwPpEnRcmZdccokFHuFj1Ldv37hXTJ8+fcxBBx1kn3MJ2n8xCUEnmSRSLpoOmi0THDLzJzUfsgMOOCAyagWtnt1NGMG7fQBTiKwUgkYrdRc8pIJG55PArbfeajU4l8jcttC3cePGWTOGS7RRg8W8YAcjW+ak78VNgEcffdRqeQgaJ\/+Ok7vvvjv3sYgiMSHof\/3rXwZiF2EuEc3i7iz4LUlERlKCjusDCs2ll14a+Zg\/3u7D7AawTbsEHVfn4MGD7fPFrs+w8vmwiuIpz\/BB+OCDD5p8tNkRMIf4WLiWAj7k7i58yy23tLsthHBXdndI3BoomKAPOeSQvK28NCQNgoYg6RDbbkLkXOHvmEqwU7HVdLd98rXieZ+gGQi2J4B800035WnIEBCLmEmM51lIj7+z7erSpYvdFrMQ5DcWC2SBHS+IoBkctnIQDvWGCeVtsskmeROC3QX9pI+Yl9A6RGjf9ddfb\/+JvYw6RMCNLVmcsM0\/77zz8soEU9qCyQMzhIh8vIolaN8W6e4+IBp31+OGQ0bZoDFziUZDOxkLtBY+XGjWaETu9tp1iPkEjYkDgkVbPfzww\/M+Wow\/5bZp08Zq97LYqBP8JIKG\/xXh43LSSSfZ7TyEDMmKCPHy7yCCZo7i9MWkxbbY3VkyB9GUEYgFUpC5z66TuqKkEIIWPDG7MBfc+ctu1MU2rM5CbNCUQX\/BdO6557bznagPEfDlN0xOxazPsDb6cwx8wZkdLWuEHbuIWBG+\/vpra+oUcU3An3\/+uTUvijAP4dEka6BggmYLx4KnYQjaCySFthcUB13sAqZsdyK6Xx1+YyJOmDAh12l3S8G2TGx1PIDdTAjLJWi0KCaVHFZhmwQxiN2Vd9m6MeFdgvMJD0zciYNdEBujT9DYHHk3iSOSBYC9VyRIG\/IxgNiwrRZL0H5oHvhCQog\/AWVxFDu+PplCekcccYRZb731rE0XXwIaPcLBCbaDSBRB+9tIfAXuooFsV1999Rym7pzyCdqN4+fj5NoP0RTRGBG2tbLL4t9C+jzvxvDKDkcq5313nokm5hO0bP1dMvGVDGzAEFTHjh2tliY7IMwb4s8JI6NCCNrH09\/Wo2HGSaEE7QYj+HNQtHZ29MWsz7C2+ooKGLJ2+V\/s+m74Kj4ECfNkh+r6lWRM\/TnLM3zskqyBogiaKAHsgaI1ommwvawkQWOfcjVGn\/yYmOJ9xqHCpBVxJ5Y7uYO2Zf5i5EP08ccf59luWdgLLrhgrnwI3NXYRYvy24izL6mJxZ8k7i5AKr7lllvy2iUfomIJ2v0g4mSNsrdLG4ol6B9\/\/NE6coOEjz7bXcYck4sbmRBF0Nh7xSlLGThVfcHp5Gq87733njXRuQTtv+vXiV1YnHu+diQfUr8ecShJe1yHL3+T8XUJOqwPOJheeOGFQOzQttE6+S\/O\/kwBhRA0HxS3TJytYCNSboLmo40pzZXVVlstxzuYNzBz+Osg6foMI2jqhJCDhDbhLIY7aIsr\/jxBUWT+wkXitEdxQ4FDkqyBogiawn2bLFtCcYjxu2ggxS5gynAJw3fAYOvFNon4E9knaLR70SRcggQ4l8gpywcZRwB9cA38cVqCbGF8ghYyiHuf388++2xrchER7dh9l2gWd5sp2lYxBI226kZn+B\/EsDaXMr6jR482J598ciQcjBumHYm6iCJo157n77ikEk7CjhgxIlen7LxcgmZn5RKgP5\/cj6VP0GKq2W677SKdg36n5ePqEjRmEdfWLO+geeHwjXLkQiSYwfwoEb\/epAQd9LHw53e5CVoI2G2zywnyu79ziltfsj6jnsO0h2IXJWjtrFNRDH0s+R2eYvcuyqx\/EjtuDRRN0JgDCHcJ8+qGEbQfVcEX0HUuhEVxVIKggzRoTBWuJx7jP9vYAQMG5MYK8goK8ZEHwAUblDuB\/UUfN4l8TR67tp\/fxB9csYcVQ9DY18SMQNv48sdFj\/CcT9D++GIiwicg4o4vf2NRo1EQPhnmnHTHPoqgXRNNkPZFfb7WJ9vQchE05WOq2X\/\/\/Q3kLwoEIaFRwjsoDy5B+3PefR\/tCwUFbT4sSgQMxo4da+aYY47QqrNM0EFHvYMImoicYtZn3BpEKUI7x9EbFEnC+35UmrtzYs3zkXSj1IJOvkatgaIJmsZBGnzJg0QImsohKxFfayXuWWIteYatBfkxsPVUWoNGK4B8XZuwb9fFBvbuu+\/aRScSZG4IwqAUgmYb7ubNcEN6pC5fgxFtsBiCpkzsmGKq8QkO+y02cTm4glcaTOLGlwnqOlWEoHFoSeIq8McBhn0Suzc7A9chyTixvUZTiSJo1zdCf8TWJ3jRdkwnQX0sN0Gfc845Oaet2\/44UogjaIiZj6II8e3sfl588UWLGR9tV3zbt19\/PRA067GY9Rk2Fux0Jd8L\/imicviQMzdxukquEN5HGXP9T5jY3JOY7OrEeerviJKsgZIImgayaN3FJJ0WgvYN+3iW8YpyIortIR1kkogQ7M1CZPsC4chvpWjQ4rSjDt8G7H4BfYcPX8Bnn33WOl7cQyi0bdCgQTliR+N2t6KYJnBGlULQkJcbVoZTARMSxIn4kQ78jrYE2RVL0L7d1HWG+XY+CIiPadz4ElXhbsWFoDHHuD4FN9SM\/vkfSjEP+QRNn4mMQPyPGuNEtImcvvM\/Fpjl5ONRLoImUoOoDx8vtsJo1QhRODiUxEZO1jYJBY0jaN8+ylbcdSb7Oy\/fsZc1gnZDWWlbXLKkIA0aBaqY9RlG0K6Nn48rHz+ZQ4SB4owVwbcgplb+xseSU7xBGjc8IYeAeDbJGiiZoH0Nyido\/u17piEZtutBjg4haB88Qs7Ycou9pxAbdBRBUw8fDbaBfnvcReXHtEKIOGTYsrhmHndbWQpB0y7fXspkAQeC9\/2QJjcmtFiC9g8N0Qb6iFPY3UbTDrRTsQsXMr5C0H6UCh9DCIz0kmi4rnmFRYkfAWFLf9xxx+WmBx8xtEh2YoRiYX5yNRzGiRApHL1+nLAb+VNugmbHgfLhmm3kRCdarbuAXVNbHEETUoajyRV2sXykvv\/+exuP634Q+QhEHU9OW4P2FQ+0U3ZuHF6TOP6obHZBBA0WxazPMIL2bdo4s1E02IGxk3OdzEF+LPIUSeijW8err76alxoiyRoomaBpALHQBJq74oYp8YWBUJMIkSB8hZjELmFC3JA6ixiw+PokdRKGhdlFtYdDE5CCTG40RbbHYbYoyuJZ7MAS0lcqQbMY0fIkwD2svWgdaE7y8SqWoCnf9TiH1eeeJOSZQsZXCJrcEiyqJLGzkA7EhfgLXNooJwmZdzhnosaJd\/xQyXIRNE5PcdxGRQNIuwkpRIEgCspXZsJs0P6Zg7BxSpKDJW2Cpq2uKU3aHnSSMKkNmjKKWZ9huLHuOFYf5YTlXZQKeIqj3a4EjXuQwzPJGogl6LgvOg2DENC03EWBucBNts32EhJxn8E2zZl693CB60RCU5BcHL5mjcbwySefWFzivO7Y5SB3tpJu7lu2o5CfGypEeWg+mD78MCUOOxDfGuTdRUtju+YmOy+VoGkLWypiut1tlDsZIJp99903L8FNKQTNpGGs6L8v4vRwD8HIM8WML+SAGSUoUoFy+UiCoX+qC6cQdj93LglBC4lDTkE7NPrAPPTD3lznYdx8csMl\/SgOl6BpC\/ZidkJ+6ld+40NC+gA3AVCS9cYY8dHCMRb0IaL97CgwQcXF3PO+Gy7mtt896h0UxeHuYulPkigOngM\/FDF35ykE7Ua\/BBG0i4\/v5C90fYYRNH+nbRwmCsuXA0cwZ4LCZtG0ied3Cd5Pqyp1x62BWIKO6kShv0GybDUhXbaecXl8MaIzmL427dYbForEM9RHSBWkKhOZ8CscXExgybMBoJMmTbKmA05sxcWPMhHRbiBCJjQ2K9GACsUk6fMQNR8T6iaChIgLPlJR0SRJyw56zq2PDxtkyccnKtNZoeMr9YrjiyPqlM+84OYXJn9YfeyySDsgGd4wLfmZ3JhnkydPtnOOMjkBR76OJNnaSsEu6F3mMmOHuQitmb6VmhmNvmN\/hUzAgzkouAVlvSt3n0opj4RW3PbDmmMOcyCqkEx1UXWzLhl35hPjzbgXuz7RzAlrhGzBlHnGOqDcKHGDH3w7dtB7YWsgVYJOMqBsYSHlMWPGNLEZohlwegmywKkkYUxhX27flsT78lXDdMBXvNDFCgnhpZWtOZqjG6WSpI\/6jCKgCNQvAnwYMGmIUpgkSVkYGpkgaDpEaBUHAtzjr9JotFW2M2xL3bzEEDQ26SCCxusvNzWQy0HSE8o7lO3HMCaZMv4BHSXoJKjpM4pA\/SOA04\/AAvdUMb2OC3WMQqbqBO2HRkljOSgBKeOYC9sKYotj+xJE0OK4xAOLjdm1xclvfohM3BSSQxnSHr6QStBxqOnvikBjIEBmTz+JW9ITuZnVoN24VsgUbZmYxjj7NB3CTooh3z0IIR2VxCVBV\/i4yVX80JcwoKgLZyZ2YEiZgyOEnilBN8bi014qAtVAoOoaNHHEeLj50iRNJJQEKPH2ujHQ8p4bS5o0gZGcUpPUkOJtVoJOMhr6jCKgCBSDQNUJGm2WGGoIz71pJagzHMbgVA9kGXV7g3vaJ4iA3UtV3URKYQDK8U0iT9jGYOKII2j3Y1OoKaWYgdR3FAFFoP4QqDpBi4nDTcoeBDOhcJgYOGVE6FzU9UeYIQilQ4KSk\/B3IVBJCRg2tJwEoyzsze5x5CQEzaEPibd18xLX3zTSHikCikAlEKgKQRM7TGwqQqA\/Xk9C4KJMHER6yLFZ9y7EIFDc++vkaib3OeJH5aLVIBOIPIumTYgMWr7kWJDfkhB0XB6ESgyolqkIKAL1g0BVCLqQe8d8qDEzkP4vKhDfPR0VlHmOE0ec\/EOibNBuSB6B524kiOQ84LQTkSRoyO7pND42StD1s1C0J4pANRCoCkFjVuCEDkLcM05CIjj847cuIJAjR1J5RpL0RAEm2ribREied7PWRSWT8VMHRtXnJ01Rgq7GdNY6FYH6QqAqBO1CmNQGXSjskvQnKEmJnDB0L1oNKh+TCsl3goTUgRyxJZyPDFtk5XIT3itBFzpi+rwioAj4CFSdoDmDzrl54p7dREOlDpWbys91BHKunlA5zCBuvmOckITMYXcmk5XYqMPaweWypK8MC7MrhqCJ6SZCxRXSiyKcUJL\/Xyo2+r4ioAjUBgKpEzRJY8hnQe5eTBWExJFAJqmQOyMuUQllQbjkDZbcrdicuaUF+zXip3J07dZBNyn77SsnQQsxtzfGnGSM4XKkVrNSf35njHl4VhpTLtvCpQp5Q9QqioAi0BgIpE7QYhuW2yz8i0+TwO4mWo96npsrSDvpJtjmecwepGp0s2e5sdNJCFpu\/AgL00uqQQs538lHI6Iz3J3cQ0k6yfTQZxSBukGgrglaRomcqzgDyd1BjulypTWMmgVJCFrIeZIxZrkEU2qyMWZ5JekESOkjikB9IJA6QWMDxvwgNmeOXUtMdFJIuUrezWqX9L00n4sjaO7SIyFUnObst1k0acxEKoqAIlDfCKRO0PUN5\/96F0fQkPOHY8eaj4oApMMsm\/SBao8uAjl9RRGoLQSUoCs0XkkIetexY82RRdQ\/xBhz1N83xhTxur6iCCgCNYJA6gRN7DEOuVIEp1+SdKSl1FHqu3EETTRKUtuz3xaxRauZo9RR0vcVgWwjkDpBlyOlaNIojmpCH0XQYn+exoW3RTTyG2NMG2MMsd4aG10EgPqKIlAjCKRO0JwcJPytFNlxxx1TicQopY2qQZeCnr6rCCgCIJA6QTcK7EkIerAxRdugR2+yidWgVRQBRaB+EVCCrtDYxhE0MdAj+vYtOopjaSXoCo2cFqsIZAeB1Ama5Pe\/\/PKLIU3nKaecYrAnn3HGGQUhcuedd9a8k9BuX5o1KzoOWu3PBU0ZfVgRqEkEUifoNI96V3NE4jRo2qYnCas5Qlq3IpB9BFInaG5D+fnnn80qq6xiNtxwQ\/PBBx\/YpPmFyF577WXmnXfeQl5J\/dkkBO2SdNyJQjlB2K1bN3svoooioAjUPwKpE3T9Q\/pXD5MSNHcmdu\/e3XDkPS6bHdn\/yGZHrusgIckT5akoAo2CADcZha2HesAgkwTNQRaS5bdu3dqmCK1FKYSgyU\/dfsMeZvLL421Xp745Ia\/L6+52lOG\/p685xey9\/aahE5KdBbfTRN1MU4tYapsVgSAEZK7feuutdQtQZgj6008\/NVdccYV5\/PHHzTffcBTjL5lnnnnMGmusYQ455BBrEsGxVgtSKEFv0KufabNMp8iuJSFoCqjnCVsLY69tTAcBFJJ6n++ZIOgnnnjCHHzwwbGjCkFfc801mT+kQkeUoGOHUx9QBEpCQAm6JPiSvYwpg9A7bjRBdtppJ7PFFluYRRZZxObs+OSTT8zdd99tr5dCtt9+ezNw4MDMa9JK0MnGX59SBIpFQAm6WOQKeO\/mm282Z511ln3jtttusxewBgnRH3JfH1Ef5cjpUUAzC35UCbpgyPQFRaAgBJSgC4KruIdPP\/10M2rUKLPffvs1uTDVLxHteuLEiXmXvRZXa+XfUoKuPMZaQ2MjoASdwvj36dPHOrU4TdizZ8\/IGo866ih7vyDvHHTQQSm0rvgqskjQEuVRfK\/0zZEjRxpCu1Sqj4ASdApjcMstt5gzzzzTXuQ6eDDpg8IF8wcRHvfdd5\/h2qssS1YJevJX\/zVtlo2OFskyrtVs2zuP3myUoKs5Avl1K0GnMBaff\/652WqrrayTEIKGqH3hDkNC8PhvoYUWsocxmjdvnkLriq+i0gQtx8TdFrZr187mhw4Ls2NCQ9CE9KkUjsC9p3QvmaDZAbIT5HBF2gcsJFrqyCOPNCeccELBAPz444+mRYsWuSgq1u4GG2xg\/Ub4j9IWJegKIP7II4\/YZEmuPP300+b222+3fyKCo2vXrgay+f77783kyZPNM888Y23PCI7CPfbYw8w555wVaF35iqwUQS80+y\/moYceCjx12LNdO7O4EnT5BtErqRwEff\/991ti7tWrl00WlqYIQRPSiu+nEGHNrrzyymaJJZYw48f\/daBKCLpTp07mnnvuKaS4sjyrBF0WGP9XCJrwCiusUHKptX6jigsAuwFOEiY5qDKm36Fm8kvjQzPg7dWunTFK0CXPr7ACykHQaKEc6yeXDEf305RyEPSiiy5qFSaE9QxJzz777Ia\/py1K0GVGnAHlTsJSha9127ZtSy2mou+XW4N+7o7Bhv+i7jFUgq7okJokBD19+nTDjnDq1Kk2Je7yyy+f5y\/h9ylTplhCa9OmjSW51157zcw999xWQyV52IQJE+x7nTt3NrPNNpvhnZdfftl89tlnVsFZffXVLSkiaLbsLiF83neFsvDZoOGy44wiaNokpkNO7nbo0CF31oD6X3\/9dRtphYnxyiuvNIsvvrjt37vvvmvTMSy55JJ5db\/xxhvmzTffNF9\/\/bVZbrnlrGPV\/SBJv+eff377+zvvvGP7AQ6rrbaarT9OlKDjENLfQxEoJ0FPfWuCGd13v9jc0UrQlZ2QcQT96quvmn333Td36Epas88++9hYf8jWN3G4ZgLIz70lB3PCBRdcYHr37p2X\/gAz4JAhQyxJf\/jhh2bzzTcPtAPvueeeluxlxxlE0KRYYAfHB8UV2nL11VebtdZay3BN3Yknnpj3+6mnnmoPjWGDdk0cHC4777zzrK3eFVI2XHLJJdbfhEi\/Udjmm28+88ADD+Q9T+Ivyo8SJejKzveCS+eACicKGRj\/ix1VGLdfT5s2zbRs2dJOhlIEbeLLL7+09c8111ypEPTof+1nWrw5Ifb2FSXoUkY2\/t04gsY38sILL9iQUTRGtEcI9v333zcctCJVQRhBS+0HHHCA9b9ce+21OVJG2959990N2uZll11mPwA33HCD2WijjUomaAm9hOTFt8PJXXapK620kg1rhcTR8nFuCtGi9TL\/fYK+6KKLbNuXXXZZa2OH6LFZQ7iIHDITgpZ+Y5dHc8ZHhT+KetCoo3LvKEHHz9myPQGJss2SI99BBffr1y832HFfV96nzBEjRuQmNX9j0nG0\/Oijj7YaTRKZOXOmGTRokF1caCwiSy+9tDn33HPN+uuv36SaWJKVAAAgAElEQVSYcmrQEPSpb06Ivb9QCTrJaBb\/TBRBT5o0yWy99daWWFAi5phjDlsRhI1DDoIl4VcUQXOqVuaSq7Vi8xUbL2uAfDSnnXaaLa8UDfq3334zK664oi0bs4yQIXZytGKEjwt\/Fyeha4P2nYSYYPgIIZhLMIGIQNCiFfO\/LkEPHTrUbLbZZvZR1ixBAmj0cb4mJeji53JBbzKh0RyiyNktkC8027w4kcksz\/E1l0x5LJgLL7wwNqfHH3\/8YTUiiTJhAaKFk0NEhO0mOZ1dKSdBD9x9pUjbs9SrBB03I0r7PYqgf\/jhB2szRlAAMHVgy2W+uBJG0DyHnVeENbHbbrtZE8Mdd9yR+7u8z3rBbFIKQVMoJA0Bo6zgvGReP\/vss9ZMUShBE110xBFH5Jk8pOFo4DvvvLNBqSFjpRA0a5KPmCtyIC0u5lwJurT5nOht92ud5IVddtnFsI2K037fe+89w+0jCHGfxxxzjLXZ8VXef\/\/97d\/79+9vdt1118hqX3nlFdOjRw\/7DJMWux4TGnsjB2zeeustu4176qmn8kL\/ykXQYn+eZoxZKAYgJegkM6j4Z+JMHEG2WjRKiIkdX5wN2g1Vk3nnH+AqhKDF5BJlg\/7oo4\/s7vDRRx8NVJAK0aCvu+46q\/QEhRCifGHCENLnQ+CbR2RksHeDJfH8UbnNlaCLn8uJ35RJjQaBM6RLly7mwAMPtJoudjv5wg4YMMCWyQRN4uHF9sfWia0adbgHW+Q3Bj8ud\/Lw4cMtMUP2eK+DtCH+5p9uLBdBU7Zq0ImnU0UfjCNoKsfXMXbsWKsI4JSTXaHEHodp0P5hj3IQNOYSiDCMoHHosd5oI6Y\/TAvYjjt27GgjNliDhRA0B80uvfRSaz5kLbtCRAm7XlnPUYdclKD\/h1zV80ELWWJyQDNGxF7F1xgtAEFDZdIwkfD4xiXuZwuIcwJv86GHHpo3WaQs\/ogmjPMlTGS7FVQODkO2sYhrR+Pf5SZoDsEfqRp0RQk4rvAogoaACBXjrk1RIDAfcAM9NmgxYVSKoKl3zJgxuS5AvhAtEkbQnP7Dls2aol2cEkTcdwshaOlb0MEVdgfHH398zmSjBB032\/76veoEjfeWgXXJWLRqkidh\/xXZbrvtrEkBGxa2rCgR7QH7HXY8V7C1yd\/iUpfioEGTWHPNNW3spysu0fttKidBE\/\/8+R2DNYoj2Zyu2FNRBI3SgOboKho0BMc3mmmlCFqcd9SFnVeilEiLQMRHFEFffPHFdldIGOA555yTw012jfzBJ2jXZuw7CaWvbp38f5zshx12mI3g4E5NTIxK0MmmadUJGgLGGYAZQWxK3DXG\/8d+h5lDhPwThBcxsbBFh4mrAQQRMI4\/DgIgUTmooyBk4uIIYgsJ2VOOa0Zx81VHmVKSniTEzBF387faoJNN+mKfiiJoPvrE9GIugIDWW28989VXX5nRo0fbcDEhwXJr0PQFGzfkjBaNgxIlBpuySJgG7d5khJ+GqAuiOdx3IVT8NHxgROnhI8TOlogO344M0V9\/\/fXWlAEpc4CGeihTQu4Iz1OCTjYLq07QRGRg2mBbhLaLIw\/Sk3AjPNviCWfiM9mwb6GthAnkyURF\/HAfeUcIdNiwYWbTTTdNhpYx5tdff7UTUMwxtA37s6\/RUz67A3FyhKWoTErQepIw8RBV7ME4GzSKBYcx5PYfaQiOPuYLZCXJksSRJnMdWzB50UXibNDu7pJIDtaGHDaRuGn+zgchykkoJkapl\/l8\/vnnG6JScIIjkDax2awVfkMw+e2www52nbomDTR6MMDk5woRLmjrlIOE9ZvfxAatURwZMHEQBE\/APcLEwiaGx5sYT8wGTG4moxvsHnfKyN1quTGkMmEk\/pN\/B5lAwlb4uHHj7FZQYqEhdiZsUB6Ccpo4pD3lyMUBicRdTlsxhqvxgqd9MDFRNjuOOTNHFlxwQdO+fXuz1FJLpdJz1hIaPLvDOB+N2yDew4aOCQ9FQ97loA1RVvRBdofsFKiDK+nkuHlQ57799ltDJBVrjUMtQszlBEKjOMqJZkRZrs1LblaBDInm8IVtEsQd5dhzQ3qIzfQTNOFpR2NB4mzQPOMfX+UILjGoUbHYlSBobvWe\/PJ4G6\/a3hhzkjFm61lOVVLufDfL3hmXzQ5tHYJWKR4BdkSasL94\/Mr5phJ0OdGMKYstHeTBlxn7MnZitFPMCSIQI4dCJJ4yqkgxYQTlmJaged53TShB5ZHU5fDDD7cfBQRPNFEhclIsrA2VImiS7c+z2PI2cRIy9c0JuSbE5YNOcTi1KkWg4ggoQVcc4vgK2GZhUyZjFlulqG2VW5pEhwTd1CInDHHquB+AoNbg5Dn55JPtT+5R3LiWV5KgV9xi78Dq0bCXazt3bGx3XNv1d0WgFhBQgq7SKGFSwInQunVrS8zFCFnB5I5D1xGIfZDsXZhBCKrnIloETRmHJZo7GbfIUSAaMzGcvEMUSZj4JxuVoIsZNX1HEUiOgBJ0cqxKfhJHBbGbmBIkXwaF4lXmMAhOQ8Lukjo\/INzjjjvOes0RbM6QvYQQYUYhXE\/EtVu7Tki5BzGug76zUQk6DjH9XREoDQEl6NLwS\/y2G48Z9RIETSavqDSf7vuExGEzFpKW3zB7cHTcLceNnRaC9lMiRrXNzxugBJ14+PVBRaAoBJSgi4KtsJcwZRCzLDkLMDkQHYGzENL85JNPDPlpJbaUELyBAwcm1qRpDTGdOAM50cShkqQEX1hP8p9Wgk6GXtDlt1x8i3BIQv5\/stKy9xQmM3Zz+E6yftFx9tCLbpESdAojhuONkDUk6lQfJwq5MBZJEhqXQtMjq6gGQd927KaRt3pXGxO3fiHmoHDBh2eZtkiN9fGsFxhziLoWhEMaxP2iAEheC+Y2c7wQB3Mt9DULbVSCTmEUSCTDCSqJf46qEu2aY7Oucy+FJhZVRdoETVpSojjQOOMy9BXVoTK+JOQcd3T9rllhkCR6rRWSZmdH6k7Xh9GnTx87HkrQZZxAfxelBF1+TJuUKBOYnBwSdRFWrWSW452DDjoohdYVX0XaBG13IDWgQQs5R11+66I+2RhD1pRaIGkhaDdXjBJ08Wso7k0l6DiEyvD7LbfcYs\/8B8Ur+8VLRIWfe7kMzSh7EUrQTSElTzLH4+M0Z\/9N0aS5DimrwuEnEnkRkkniIXYy+Dtcgl511VXNiy++aHNmkOKTA1dB\/hBi\/\/GZ4J\/hpm6SIHErty+YU\/DNcLM2DnHK5KSje1aA6CiuoiJslDKIkiIpktjDydLoR0bRF8qjbvKHZFWUoFMYGSIliDvGSRh06o8m4GQhBI\/\/OOot18On0Lyiq6gGQWf9oArk\/OHYsbFpU4NA7zDLJn1ghu3RkunNbTv5LYSgiaP3b7pG4SBG3yVBUVjccgg1xQcjucf5DeIljNRPzARJo8lLegO5xJUdKn9nnXG7EPXy\/31lhwx8kuArLld60YujTC8qQZcJSLcYbu3FmeIK2bLkzj8iOMify7Hl77\/\/3kyePNmQ8AjbM8JWV24frkDzylakEnRTKCHoXceOjb14IGgQhsy6reSovy8VLdsglbEgMsbh5Cakk8siIGzmshA0VaEJQ9StWrWy6XXRkLl0eO+9\/zoZ6t4uxHskL2LuX3311fb3hx9+2CZCIhqJTHKkFWXnSSpTlBhi8cleR8Ij2oHGLATN+yg3PM9\/Dz74oCV9tP0TTjghh4R8IIiWkpu4ywhTWYtSgi4rnH9pwn7iomKqiLvtt5gyy\/2OEnRTRNlKJ7U9+2+LLTrLZo4oG7SfMxzNFQ0YwibnDCGlpB6Qq97kdmxwkBuGyAFDmk\/IFWJFW6YcOcVKSB85yslpQxpR7s8UgkYLJyMkHwdELqUlvw1\/F+GdCRMmWA27kDS85V4\/ScpTgk6CUgHPQNBMwlIFO1\/btm1LLaai7ytB58Mr9uckl98GDcw3xpg2xhiO8Gc1NjqKoN0LKegfKQfQguUyB\/k3Wi59lDA9niVtJ0n5uS+Qk7CSFJ+E+JInRjCTnM0QNQ5ZIWgyQ0p+Z55FC+cjgBbPbTDYm7F9k6kPMn\/55ZcT572p6EKKKFwJulrI10G9StCqQYOAmDh8jVQulZDLYiWRf9TUl2uz5L7NIC1Xbq2XRGBC0JhJ8PW4Ipo5Nmm0ecJdCXulfDmbkOWlqARdpdHh685Wj5zPQd7rKjWroGqVoIMJOsnlt0FAY4MevckmVrvMqhQSZucTtJg80KC5HSVI5p57bhteCjFhxsCG7JpCeEcuguXMAOcFhKBJBObnL5c2YLMmukPK5aJb1yGZVbyVoFMcGWxw5NnAicjtyCLcVkI4EvY3\/\/LXFJtXcFVK0E0hY8s9om\/foqM4lq5jgpYrrtCSiZ5wTRwzZsywt9q3adPGJv0SrfyII46w10O5go0ah7toxVEEzXtyETNkz2ExbNJclpE0KVnBC6OMLyhBlxHMqKL4kmMjkzvVwp4lZwcJ+\/3Unik1s6BqlKCD4WLhFxsHnWX7M70VDdq9oT7soIqvQXO1FBfNEvqGqUFu\/KFcyV9+8MEHWxOEaNvYpMeMGZPbZU6fPt1qyew+JXwujqAlhQIfBuomuRgHwmpBlKBTGCUch9waLGF03E\/IJZSEE0HYctOKJFOSSZpC00qqQgk6GL56PklIUi9C1jAZ4NSD6JISNGiJDRiy5BYfdo9ozjjF+RthdosttpjNWU4YHDtNdpWYM\/gbmjOhd926dbMXtCJxBC2OQRktIjrQomtBlKBTGCXXORJkJ6MJ2KTJccB\/COlJO3Tg6EJ2RQk6fGzqNRcHZAdpoB0jHFSRZEm+VsylsptvvnkuioPnCSEkb4cbbcHfCacjFM+1C1MX5g2cgq4QJkdyKfHdiPYdtrZ4V5yOSW4YytKKU4JOYTTkCy\/xoFFVckDlhRdesIH7vkc6haYWVIUSdDRc9ZjNjh6jyXLKb7755svFHBc0cYyxN2lPmjTJXg7MgS1C4IIEQucYN2F4nEbkjEExNxCJ3TqKxAvtQxrPK0GngHKvXr1sbCdf+t122y2yRoLvhw4danr37m2OPvroFFpXfBVK0PHYERst14jx\/12pheRI8T3M\/hN8BDCTED3CqcWkd35moWdK0CmMgtjokpCufOn946kpNLPgKpSgC4ZMX0gRgbfffttcd911NikTJhn3yHmKzSipKiXokuBL9rI4RnBMEH9Jpq0gYduI8wNnYS1sxZSgk42\/PlUdBOSoN7XjcOzfv3\/NnTlQgk5h7rhXXuH95kQToUKShpGUitygQugSUR14s0muxCGWLIsSdJZHR9tWDwgoQac0inI81a0Omxj2MAjclVrQnmmvEnRKk0eraVgElKBTHHrinYnoIEojSAg1wl5NGsdaECXoWhglbWMtI6AEXYXRI6vXxx9\/bG\/zJm\/0UkstZdq3b29WX331vOOvVWhaQVVWi6CnfTAxl3C9oAbrw4pAjSFAPhLJBlhjTU\/c3GZ\/VjnBLhm1OMLL6UHSKNaLVIOg333sFjPt\/b8uNoCo2yzTKRbOJM9xIW1HY0yw+\/avKgiSW2fWseS5Ymv869m48txiJAAv7p2vjTFv\/v1iS2PMksaY1saY2biVxxjzrTFmijHm57+fIW2pH97nNz+rqU0TwNwQj5Ae9dhjj63bvladoDn1dNNNN9ljrcRh1otUg6AFOyHqDXr1i4QTcuaaLJ6LIvPn7hhs+C8s2T4EuikfBW7tiBlAnvtw1um1jxIO9L9mPdfXmESJ\/uXZuFwfcschTWhvjDnJGLP1rMT4pLL\/jptLjDEDZl2x9TF1\/33NlhyscZst5M0cViJPOKD6WEEIVJ2gyTVAFi2EXAadO3cuqANZfbieCBqMx\/Q71Ex+aXxooqNmCUkUgt7VmETXXgnxxxEu7csKkWd1Pmq7ahOBqhM0sF111VVmwIAB9jQTJwrJCZDFjHVYg6ZNm2Zatmxpj\/JGSb0RNJr25JfH2+PHQVrn8rNuPEmS6zkpkYNtUm07K0Supx9rkwSz3OqqEzSJj7itm6veXYGsw4QES2EHWioBNsQ8YsQIc9lll9mDMghRJaQ\/5ch50MekHgm6zbKdzDyLLW\/NHcjUNyfkwQ1xR5kuCjGFCEEn0barTeS0Ve5MVJKuxAps3DKrTtByk3EhQ5D2pbGSEUzayMeDnLvI7rvvbg\/R+AnO65WgV9zirxuog2Tg7ivF5nouRINO+mxSs0kliNzFQWzbVfa7F7KU9NmMI1B1gv7oo4\/s9T2FyI477pg7aVjIe8U8S6Ywjpgj5ADhpgoO0LiHazgmS05rVxqRoOOcieAD6SYxhRSibVeLyIPmE0lwD\/zbsVjMfNN3FAEXgaoTdNaHQzLoEQaItt+8efNck+W3oFjMUgmaePBVV101Dx7swJgZorRYXih3FAdlJq1bSDrMsYczb0TCKI4kxFtNIg+au9ydyH0kqkVXZ2U\/\/\/zzVuGrl9C7qhM0h1GQrF4OK8nMyaTHvYiuuBEo3CPn5gcplaBHjhxpE7q3bds2V2VSkqwmQVM3JB3mTCSEDQJLEpmRVNuuFpEHUZDYopWgq0fQ5JbnsoR6kKoQNAmQuCCWsDpulkBIlMRtEITcZYmsOVpOPpA77rijyaW1kkuX9pPQCVIWaWSC5rBM+416hDoTl+jYxToYw+KqBcOk2na1iDyIAPBMtDHGXkNVamw0O7NqCodAak3QoJWgSxg1bpzgDH1Yzg2Sh6M9ZiHMjpvGO3bk\/FpTAuZv9IW7ExGuu1977bXzCLoQmH5btLOZOe+ika\/M\/sVr5o95F0n0HAVRZpQ0\/\/ELQ5nVqPvHd8aaGVPeidWkId84bbsaRB6Gq2jQKBwqtYtAVjTw1DVoiOy0006zI8fpwU033dTGFXOritzqffLJJ5vDDjus6qMrNy\/TEL7MQaF9ojUPGzbM9kWE51WiEXjooYfsSb2403yUEqdtV4PIg3qHDXr0JpvYxF8qtYtAVnYPqRO02HRJ0I\/TrU0bNoR\/3cPGTciQIlo0JoVqy5QpU0zXrl1tMziGzgfFFUw1K664ov1TkAmk2u2vhfqTXHuV5JLZpCcJy0nkQfgSxbH0JpvY\/DIqikCpCKRO0JgBiCE+\/vjj7bX0rlxyySVmyJAhNin\/xIkTm8QWl9rZQt\/nUMpqq61mX0Pb41JOVzhV2KVLF\/sn3wZdaF36fDQCSS+ZpZQok0g5idxvscRBQ86l2p91PigCIJA6QYtJIOhmbrTUffbZx44M8cdZsENLewcPHmy22WabvFnD6Ue0foS73fiwqFQOgUK07SRmk3IQufRWTxJWbtwbueSqETSOQN\/Og2Ge666yRNDEU95\/\/\/2WnCFpV+SEIblDrr\/++kaeR5nqe5pETsdFc9Zj3pmaBnXRGCXomGFku9qzZ0\/7lOsI5CAJ4TyYQS699FIbVqVSWwiUk8iVnGtr7GultUrQMSP1+++\/24tsSdCEYHNeYIEFbNQJsssuu5iLL764VsZb21kEAkmIvIhi9RVFIBYBJehYiIz59ddfrVNTSFpewexBmlS5gTxBUYke4aOAA7JVq1aZOrSTqPF19tD06dNtvHvr1tzNEi46ZukOPOPy5ZdfmiWXXDJ2\/dXy2FSNoAnk93MqYy4gzA4h90WQkDXuuuuuy4XnpTktfvjhB+sMnDlzpg0FLDcxz5gxwxDJwg0zIkS9YEpRE0qaI\/1XXRLFg\/OXcQ8SHbP0xoV1N2jQIOsTkhPI1A6XnHvuuU0ulK6HsakaQZcyrGmnGy2lrUnfJScJx9zlhCUpTX\/++edc\/mmIWyJGkpapz5WGwLXXXmsPnIQRtI5ZafgW8ja7mDPOOMPcfvvt9jXGBAWPNAwihOh2797d\/rNexiZ1gib2mUMppQhOubgtZynlV+PdW2+91fTp08dWDTGQKIlJSTgi\/UU01rryI8MH8u2337bpZB9\/\/PEcGQRp0DpmlR8PqeGVV14xPXr0sP8877zzbN4edtMkKTvzzDPNW2+9ZW9kIoEZuXzqZWxSJ+j0hrS2asKe\/c4775hevXqZU045Jdd4tnU77LCDnYC9e\/e2N7ioVA4BGQe3hjANWsescuPglzx8+HBLzORmv\/LKK\/N+xuQh6UXvu+8+m6a3XsZGCTq9ORZak5t0iePvq6++et6zAwcOtLa3VVZZxYwZMyYDLa7fJnBiVG7Leffdd83NN98caOLQMUt3DrDzxkkflPYXh+Eaa6xhGzR06FCbnkGSmNX6elKCTneeBdZGkigOuyCTJk0yLVq0yHsO0wa5qKOcVRnoRt01gfsyDz744EDcdczSHW5OGfPhXHPNNc3iiy+eV7mblx2zFDce1ct6UoJOd54F1iYTLIyAsYvuscce9t2sHIHPAGwVb0IUQeuYVRz+RBUQ9bXvvvtaZyGRVWTLhMxxuNfDelKCTjQNKvvQqFGjzOmnn27DhcQx5dbIqUXs0Aj5P\/zwxMq2rnFLjyJoHbPqzgvOJpBeQdK6QsbYn1lD9TQ2StDVnWe2drnZnBSs48ePb9KiCRMmWK81Mnny5Lx7ETPQ\/LptQhRB65hVb9jHjRtnzjnnnFwsNHnYzz\/\/\/Fw64HoaGyXo6s2zXM1yQ3jYluyRRx6xFxgQRhR2E00GulF3TYgiaB2z9IebG46I5CDRGoJCc9ZZZ+USrEmL6mlslKDTn2dNaiTudtttt7V\/D7oYgJOTF154ob1SCxubSjoIRBG0jlk6YyC1cFz78MMPz5kASb2A43yOOeao6\/WkBJ3uPAusjcm33nrrWS81R1b33nvvvOe22247GwfNVWGHHHJIBlrcGE2IImgds3TnwOjRow1X4SGEPnKZc5jU09goQac7z0Jrk9zSmDnIlCfXa3GVlhxcwYGol5GmN2BRBE0rdMzSGws05nvuucfmpeF2nTCRSz7qZWyUoNObY5E1ff3119YRKElgttxyS0Nypueee86+179\/f7PrrrtmpLWN0Yw4gtYxS28eyFV5cTXK3aD1MjZK0HEjnuLvn332mdl\/\/\/1zGf2oGo2awxJylDXF5jR8VULQUc5ZHbPKT5PPP\/\/cbLDBBokqIgfHuuuua5+th7FRgk407Ok+xITECUVCKPIKZOFuxnQRqL3adMyyO2a1PDZK0NmdV9oyRUARaHAElKAbfAJo9xUBRSC7CChBZ3dstGWKgCLQ4AgoQTf4BNDuKwKKQHYRUILO7thoyxQBRaDBEVCCbvAJoN1XBBSB7CKgBJ3dsdGWKQKKQIMjoATd4BNAu68IKALZRUAJOrtjoy0rAgHuCvz444\/tBbxcH8YpwPbt25tll13WLLbYYkWUqK8oAtVDQAm6ethrzWVGwM14FlQ0x+iPO+44s8ACC5S5Zi1OEagMAkrQlcFVS00RARK5k+Hs9ttvz9VKDpOOHTuaH3\/80aZqFUGj5nbohRdeOMUWFl8VqTVJSh92HVrxJeubtYCAEnQtjJK2MRKBU089NUfOENnll19uyblZs2b2venTp9u\/cYcdsuGGG5oRI0Y0uT09izDfcMMN9uND+lkuc1BpLASUoBtrvOuut9xy3q1bN9uvLl26WOKda665mvRz5syZZpdddjETJ060v3EzDSkssy5K0Fkfocq2Twm6svhq6RVGgGuPHnvsMVvLvffea1ZbbbXQGl955RXTo0cP+\/uRRx5pTjjhhLxnn3\/+ecP9j9yiTi7uZZZZxpI+ebr9q5W4huynn34yXFjauXPnvHIwqwwdOtT+bY899jDt2rWz\/\/\/GG2803377renevbt1XnILNW0id3GnTp3MxhtvbLV7hPqHDRtm84FzaTAmm549e5pWrVrZlLQqjYGAEnRjjHNd9vLPP\/+00RnI5ptvbiDNOCGNK1cizTfffKZDhw72cf49ePBgM2jQoMDXqWPIkCFmhRVWyP0uCeT79u1r9ttvv7z3INx11lnH\/u3uu+\/OETgEPHXqVPtxuPPOO80XX3zRpL5LLrnE7LzzziYsB7LaouNGuL5+V4Kur\/FsqN5AcHI3HVciHXXUUUX1H80WokW22GILawqZd955zUsvvWRt1wgkjXNx9tlnt\/8uhaClkdTTtWtXS9oDBgzItf21114zLVu2NPfff7958sknzQMPPGA1aJyFtAsNXKUxEFCCboxxrstevvDCC9aEgIjmWWhHMSVA8pgrttlmG0vILVq0yBWD+QQzCnL22WfnzAulEjT1bL\/99rl6IH\/5wLiXoqoNutARra\/nlaDrazwbqjdyJRWdRgsW+20hIKClynViDz30UJ4ZQ8rBfMJdkWjX1157bcka9EYbbWQgXle++uqr3FVNmFv4WCBK0IWMZv09qwRdf2PaMD1yIzhcUisEgCuuuMJcdtllZoklljDjx48PfPXEE080d911V14scikadJCDkopxSvq7ASXoQkaz\/p5Vgq6\/MW2YHnFAhXhn5OSTTzaHHXZYbN8xWXCZKNEQmBiEfIO0WilMSJx\/f\/DBB7EaNOWLNh\/kJOzTp4856KCDmrRVCPriiy+2dnDVoGOHs+4fUIKu+yGu7w5KZAT\/KwdRwnpM+BvhbAgECBEKQXMTNDdCBwkOyHvuuSdPy47SoF3beBBBB0V+qAZd3\/O02N4pQReLnL6XCQRwrOFgQ4gr5hb0MHFzdYhTEdPIpZdeauOSiTeW04duGTgRiRhxPwJC0EHasFuPEnQmpknNNkIJumaHThsOAu+\/\/77ZcsstLRgcGBk+fLg1X\/hCKNtee+1lQ9oIWRs3bpxp3bq1efDBB21cMoIGjSbtimuu6N27tzn66KPtzzjxyJjHIZYLLrgg750jjjjC4HBElKB1npaCgBJ0Kejpu5lA4Oqrrzb9+\/e3bSFnRb9+\/awpg6x1M2bMsPHM2Ki\/+eYb+4wb4vbLL79Ygoe4OQSCUw6HIcJvBx54oD3Nh1COkP8ZZ5xhRo4cacke8wdx0tjEeV\/aUg6CHqE22LIAAAJmSURBVDVqlDn99NNt\/Zx0rJUkT5mYGHXQCCXoOhjERu8CJwFxuj311FN5UECexDe7EnSgxY115lkcfM2bN7eELO+7MdA8g4aMpiwCuROKh2AukY9BqRo0Jx+33XbbXD1uqF+jj3sj9F8JuhFGuQH6SDIkNFmI1Cdlur\/SSiuZCy+8sEneDIEG+zOmDiFW+Tskj716q622aoKipAJ1f0Bzpx4hVZegJZ66ECch\/cKRSd8QPerdAJPZ6aISdGONd933Fm16ypQpVpslMRGEttxyyyVK0v\/rr79amzY3scw222z2Pd6X491B4P32229m8uTJ1pSC+YHngxyNpQJPbg6iUBZZZBEz\/\/zzl1qcvl8jCChB18hAaTMVAUWg8RBQgm68MdceKwKKQI0goARdIwOlzVQEFIHGQ0AJuvHGXHusCCgCNYKAEnSNDJQ2UxFQBBoPASXoxhtz7bEioAjUCAJK0DUyUNpMRUARaDwElKAbb8y1x4qAIlAjCChB18hAaTMVAUWg8RBQgm68MdceKwKKQI0goARdIwOlzVQEFIHGQ0AJuvHGXHusCCgCNYKAEnSNDJQ2UxFQBBoPASXoxhtz7bEioAjUCAJK0DUyUNpMRUARaDwElKAbb8y1x4qAIlAjCChB18hAaTMVAUWg8RBQgm68MdceKwKKQI0goARdIwOlzVQEFIHGQ0AJuvHGXHusCCgCNYKAEnSNDJQ2UxFQBBoPASXoxhtz7bEioAjUCAJK0DUyUNpMRUARaDwElKAbb8y1x4qAIlAjCChB18hAaTMVAUWg8RBQgm68MdceKwKKQI0g8P8+Xf0NNchoMgAAAABJRU5ErkJggg==","height":337,"width":560}}
%---
%[output:8f67ab5b]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 1.881563\n","truncated":false}}
%---
%[output:5f23dbc9]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.930638\n","truncated":false}}
%---
%[output:7fe5aa78]
%   data: {"dataType":"text","outputData":{"text":"Mean waiting time in system: 0.599511\n","truncated":false}}
%---
%[output:66130328]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.930638\n","truncated":false}}
%---
%[output:309e85e1]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAWgAAADYCAYAAADGWHkUAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQm0FMX59gsQlQRcEBdccQPcAEPUaETc4wLiguAWwBU3jCgCIiAaFdxBcWFRUUFxQYxbFKMEA4ZgjAoKqBDcyUFcMV8QBL7zq\/xrUtO3Z6bn3r53umee9xyP3Jnq6qqnap5++613qbdu3bp1RiIEhIAQEAKJQ6CeCDpxa6IBCQEhIAQsAiJobQQhIASEQEIREEEndGE0LCEgBISACFp7QAgIASGQUARE0AldGA1LCAgBISCC1h4QAkJACCQUARF0QhdGwxICQkAIiKC1B4SAEBACCUVABJ3QhdGwhIAQEAIiaO0BISAEhEBCERBBJ3RhNCwhIASEgAhae0AICAEhkFAERNAJXRgNSwgIASEggtYeEAJCQAgkFAERdEIXRsMSAkJACIigtQeEgBAQAglFQASd0IXRsISAEBACImjtASEgBIRAQhEQQSd0YTQsISAEhIAIWntACAgBIZBQBETQCV0YDUsICAEhIILWHhACQkAIJBQBEXRCF0bDEgJCQAiIoLUHhIAQEAIJRUAEndCF0bCEgBAQAiJo7QEhIASEQEIREEEndGE0LCEgBISACFp7QAgIASGQUARE0AldGA1LCAgBISCCTskeWL16tfnss8+KHu3GG29sNtpoI\/PWW29lrt16663NNttsU3Rfpbjgp59+StTYv\/nmG8OYkA033NA0adKkFLDonhWCgAg6JQv95ptvmpNPPrno0R5zzDFm+PDhpm3btplr+\/bta\/r06VN0X6W4YMWKFXU69n\/\/+9\/mu+++y0x1yy23NA0aNMj8DZ4LFy60fx977LHmzjvvLAUsib5nIQwTPfiEDU4EnbAFyTWcN954w3Tv3r3o0Yqgi4PsqaeeMv369ctc9Le\/\/c1svvnmIugiYCyEYRFdVXxTEXRKtkCcBD1w4EBz3nnnpWLmQQ26tsdeiFykQRfeNoUwLNyDWjgERNAp2QvYoL\/99tus0X744YfmjDPOyHzWuXNnM3jw4Kw2G2ywgbVBc72T9dZbz9SrV6\/gzNesWZP1eu9fkO+7sI6\/\/\/57O47qSHXG\/uOPPxrmXqwUIpdcBA0eq1atMo0aNYp8y5pgErwJZhnW9ec\/\/3nk+1enIeYLbPCcbeSSQhgGr\/vPf\/5j99n6669f9JDy7cO1a9fafR5lrxd94zq6QARdR0DXxm0g6N\/85jeZrrt162ZGjBhR5Vb8AHr37p35\/Pjjjzcnnnii\/fv+++83s2bNsv9u2bKloQ9+YC+++KJZvHixOeyww8zRRx9t23NANnLkSPP666\/b73bccUdrdjnnnHNM\/fr1q9z3j3\/8o3n00UftIR8\/7M0228zst99+1nZLn1Ek39gZ5\/PPP2+72W677ewcp0yZYsc+f\/58S1YdO3Y0v\/vd78yuu+6a93bLly83t9xyi50X9n4nPPQg3SuvvNKSUpCgL774Ymvj5xrmuPPOO5ujjjrKXHLJJaZhw4a1gonrFFxZj3\/84x\/23ghz7tChg+nRo4f51a9+ZT979913zU033ZQZy8EHH2zOOuusrLFNnjzZvPDCC5nPhg0bZnbaaSf79xdffGHvM336dPPVV19l2rRv396ceuqp5rjjjrMPh6gY0gFt6fOvf\/2rWbJkie2T\/vbee29z\/vnnm6ZNm2bu8+WXXxrenJxgglqwYIF59dVX7ZjZh8zpzDPPNNtuu63dE08\/\/bSZPXt2pt+hQ4dm5hNl3yWljQg6KStRjXFEJeh8B22XXXaZ3czIVlttZTVt\/0fohnXDDTeYiRMnWuILCuQNuTmhjwEDBmT6DZsa94XcCkm+sV9\/\/fXmvvvus11A\/mjo7sce7Jcfc4sWLXLe7tNPP7Vknktmzpxp8H7xCZp7rly5MkOO\/rX77LOPxcuRdJyYcJ\/HHnvMPjTyCQQIeaKpt2vXLtMUEnvttdeyLuWhPXfu3AyWECekCxHyQM0nkDRrERXDOXPmmIsuuih0n3Efxjdp0iT70EX++c9\/msMPPzwzBIjcf4i6L3bffXf7wBgyZEjocCHu3XbbrdCWS9T3IuhELUdxg4mboIu7e3brl19+2WqPyEMPPWTQwAoJ5pigJhe8JipBF7oXBHTbbbflbPb5559bzTNM0EpnzJhhtTqfoAvdc\/To0bZ93Jig0R544IFZt+eBAJEFH67vvfeefQPgYehryP56oc3uu+++mf7OPvtsc9VVV9m\/eYPyH3qQIG81wQfhI488Ygm1EIaYndB2w5QAf0I8\/P785z\/bN4IgQRfCPdf3vA2NGjWqupeX5DoRdElgj+emtUHQmDgwFaB1XXDBBeZf\/\/pXZrBo2GPGjDHNmjWzGpP\/g7\/uuuvMaaedZs0gBx10UEar5BpMABAAphRc\/NzrOJoSxJfPRlgMQdMf49tll13s6zivyk54DX7llVcKAl\/IfhokaLRL5v6zn\/3M\/vjvvvvuzD3Ag+\/ixiQ4RswT4IttGJOVb+biYQmZT5s2LQsP\/+H47LPPWjOQE8xEmBo++ugjc+ihh2Y+9996gm6faMSXX365bZsPQzDySRKzxLnnnmvHzgPt8ccfz9yPdpBqkKAhbXDGBEP7oKsj5qVTTjnFav88bJxw3bx58wrugSQ1EEEnaTWKHEttEDR2TXcAxMa\/\/fbbM6NCA0UTRd555x1zwgknZL5z3hWYArB\/OkGT9v\/GFOKT2BNPPGFtj7mkGILG3o2N2wnjY5xO+KEXkmIJGtKH\/BFspf79ndYeNyaQMMTvBO2Zw2L+z9o52yvf77nnntZNEK0XEncPR+zTaL0INl3mjfBA5UHKQxPbNSYSJ3x34YUXmv3339\/OmftwGIsQ+MQZBpIPQ3z5nXkCwuTf7nCQB5m\/F9DGH3zwwSoEzZnHoEGD7L24v2+2YIyckTiB\/P0HM2cMaTo0FEEX+sUm+Pu4CTqoYQR\/aM8884z9wSNLly41v\/71rzPouOAXbIe+DbB169Zmk002ybQjGtKPiHSadxwEjQ21cePGma584uHDuAk6SAbcY6+99sqQINo2WmHcmEBAvveOjx1j4gCWhwNj8YWHqK+h8jAmEpIgJkfcBDCxlsgPP\/xg2rRpE7o07BW0azTcQw45JMvbJx9B+\/jQsTvIdDfxHy5uPwY1aM5D0JCdHHDAAZk3PWzVY8eOzXzHm4J7EPHhBx98YG3raRERdFpWKmSccRM0dj\/8rZ0EX33xjnBaUpCg3evvjTfeaM0MUYWDLrScmhJ02OtrkJDiJmhHwP7Y0WKdfdV9Hzcm3A8bMW8M+YQ3l6uvvjqjMQY1ed6QdthhhywtGc+bVq1aZbp98sknTf\/+\/fPehznfe++9ZtNNN7XtchF08G0oyh5hzYIEjUdK165dM5djUnMP\/WB0Z5Cg+c34kaFRxlDKNiUnaDYNr1I8idOSH6KUC+bfO0kEjbbK6+8999xjbr755swwWdcwdzPXAJc0\/4Q+iG1UE0cpCDos1DuMoOPGxGGEeQDtnAM\/pwEH8fPJDDsv5gn3AMH7BjLmjADhkJe+ggJBYor6wx\/+kHUm4bfzPXlyETT3dw94rsVMgq07n2ASi5OgFy1aFOoSmpTfdHAcJSdofzGxkWE35EebzxE+qWDW9biSSNBo2RC1E1\/rrg4+5UDQcWPCa7rLF4JrIcSKtwbua1OnTs3kCgFvfku+zd93TeShhgnK2YTRlP2DVbxF8G5B8HP\/xS9+YQ8OuQ+HjhzEOqEvTEzYd\/OZOI444gjra46EvYGE7RERdHV+OTFdg29iWOIeFo8DCnxTqxMRFtPwEt1Nkgj6iiuusF4f77\/\/flYQCut4xx13ZLQWNCIOfpw8\/PDDWT66SdOgcfXafvvtM8MqFOodpkHHjQnBQc4UBTH+\/e9\/z\/xGOAzcY489MuP1DwP58O23384EKQWxxqPG+R7zXdDjAvL3k25hB4asnTj7bpCgfQyD7n60dT7aPAw4ROShjHBIyMMlToLWIWE1KI0n9Z\/+9CeDzTPogM4GPOmkk0yXLl3sQqbpBLYaUBR1SRIJmgngpue\/KuP+hqsXiYd8\/1kOtPjx5gvxrWsNmoPQSy+9NLMOkARmAJQIDtSqQ9BxYxK0aXOQhzKDCQEt1nd\/xH3Od6Fbt26dVXqCqWshXgjYFzRk302NM4qePXtaHLjeBQlxDQ8mgmeQfBh+\/PHHWTZv2uNrjRLmj5vPMb3wMIqToKOcQxT1I6zlxiU3cQTnx+ETP240a\/\/Ainb80NkgbEY\/w1gtY5TY7pNE0P7rMe5mnPDnsosCKA9efHQL2SDrmqBzBayERRJGtUEz3zgxwR3tyCOPjBTswe9oiy22yNrDQc2YL4PukHxGLgsetlH8x4maxJsCKYRh0H0z7Afmv3mJoBNKQQRJsDnQrP1XKYbL4RP+kEFXojimgpZBdFVcCdmxF5LUxc8vEMc40UbRPpzkysUBUfo4+WTqu6IV8uLgLcflZwh6cQTtl+CHD3WYpwFnDbfeemukQ+F8Yw\/aU4NBCMET\/KjaE4d6vFr7DxhH0J06dcqEu4cRtO\/yFYxejAsT1pu1v+aaa6qEbLu9gO2ZtXXr5e83TBF870swrar7jgck\/u++Wcq\/jshCvGWCkY35MOR69tK1114bWoQC10tCtt3bcnCf5\/PiCGJe3T0Qx+8zjj4Sp0H7k3KmjzBt2rVzzuxxgAExP\/DAA5ZY3I+TQxQONnjFrY7\/pCOYNEYxxYEpDydOzsnTQC4LovziflDFMc5gHwRALFu2zOYm4fUbc0xc7llxYoJmjhcUnhlunHhDgXU+8f2ReciPGzcub3t8oonMYx0hTt5gmzdvbh8AucyOhTDEJPPJJ59YEwY4szfIl5LP66c21jrJfSaOoHk94un63HPPVbFHo+Hh5cFTG3vZX\/7yF4ttVM2o0EIEbXvcz7kkoZ1iEyvWBo7TPKG3lUrQhTDX93WPQDDsGx9mTCaS5CGQCILmqcymwZThMmr5UOFjyasLJ9K+FgtBY5OOg6D91z7yCrh0ke4ejCf4apVrObGdo21wrbPfiaCTt\/krbUTYnjnI8\/OroIQQ2l2dXMyVhl8p5ltygubkNiztJOGjkDKHTbmSkHOIwWtRHARN+Oj48eNtaCuuP35+Y\/dd0GUp14KFZTwTQZdie+uePgJEFeLW6EswbFqIJQuBkhO07zMJOaItk0sgipcGPp8clIQlqS8W5l69etkDl7CSSn6ILH6khSqDEJjgTCP4wHLCLYIudkXUXggIgZITNKfHJEjBKyPsxLmulsidvodlV\/OzbPmeDFHGRqJ4vE1E0FHQUhshIAR8BEpO0GinmBZwX\/IToIQtE5nBiJrCZzNfdYxil9iPvgojYFzkXMkkbHg45UeVqARdyodT1LmonRCoFATiMJvGgVXJCdqZOPyE32ETwyWHAJWFCxdaV7h85YmKBYbwT1zpkFz+oI5AiZ7CPh5ViiFoIr6C6ReD93HJzv3osKhjSXo7zS3pKxQ+vnJaN97mmU9FEzRBDYR8IgQ8EDbKaXI+LRJPD3f67KpExLWd\/Vpq5NrF59UXfDRdCsZCCeaDYyqGoIMJ58PmR5UOxM9xGxcOpe6HuZHwvhwfPppbqXdXtPujoBEkU9EEXUxdtyCshHsTCh5nAiU\/Wi0s+5pfs622bNA8nKIQtLPZlyOJMTfEr0oS7WeV\/FaaW\/LXyL1BVzxBYyYgAgrB75nXCjw48r3e4\/ZG9BNtXGLwOJfcae9+oU\/Xv1\/eiXDiXG5\/YeOJW4OOc87qSwgIgWwEpEEHdkRUG3RtbyQ0UgJlwnLUughDKjdMmDChqKGIoIuCS42FQEkREEEH4CfGn1wN+D2XsqKKn1rRPwgkzwGvPJhB\/KKpHFoSxo2HB2Gyfpkgf4oi6JL+3nRzIVAUAhVP0CRAIikRZeoxVeDi9vXXX0cGkVwYhRLBRO7MawjhkgfY5aQl4xpVXVxeY7+kD5f5dmtXHl4mjuogr2uEQHIQqHiCdrZelxozmLglylKR46I2tO1Vq1YZip8GE4dj9qDOXqNGjTLD832noxB0MJVncJ5RDwmj4KM2QkAIVA8BEfROO1nkkkjQbknJgcthILk+2rdvn0XM1Vv2wleJoAtjpBZCoLYRqHiCxqaLOcHZnAmjdj7RUcHfc889q5WbOWr\/pWgngi4F6rqnEMhGoOIJWhsiHAERtHaGECg9AiLo0q9BIkcQlaBdWK2bRDkGrCRygTSoikCg4gkaX2IO2GoiHOJFSUdak3vU9bVRCZqQYQJ7mu3Uxiz\/59zEhKTWNV66nxCoDQQqnqDjyNpWW14ctbHgUfsshqAXLft\/ptnObczClyeKoKMCrHZCIAICFU\/QRA7izlYT6dKlS514VtRkjMVeK4IuFjG1FwLxI1DxBB0\/pOXRowi6PNZRs0g3AiLodK9frY1eBF1r0KpjIRAZgYonaBLj\/\/jjj+bYY481AwYMsJWvr7rqqsgA0nDKlCkVfUjo26BdBkC8OcoxTWdRG0ONhUANEah4gk5yqHcN17ZGl1dXg3beHFFySddogLpYCFQAAhVP0FRDWblypdl9993NgQceaL0QSIJfjOBq1rhx42IuSXzb6hJ0lxv\/aP4w4OhIyf4TD4IGKARKjEDFE3SJ8U\/s7UXQiV0aDayCEBBBR1hsAlmoP9i0aVOb8rMSRARdCausOSYdARF0jhX6\/PPPzZ133mleeeUV89VXX2VaUV5q7733Nueee641iZAPuhylpgTtMOGwUOHf5bhDNKe6QEAEHYKyqzpSaAEg6DFjxpRdkArzrilBtz7iDLN88VxzeudDRNCFNpK+FwI5EBBBB4DBlIHrHRVKkOOPP94cfvjhZsstt7Q5Oz755BMzdepU8+abb9rvO3fubEaOHFl2mnRNCfrXvW807788SQQt6hECNUBABB0Ab+LEiWbo0KH208cee8zss88+ofDi\/TFs2DD7HV4fceT0qME6xn6pCDp2SNWhECgaARF0ALJBgwaZyZMnmx49emQIOBeqaNdz587NKt5a9Aok9AIRdEIXRsOqKARE0IHlHjx4sHnkkUdsNOHZZ5+ddzNcfPHFtl4g15x11llltXFE0GW1nJpMShEQQQcWbtKkSWbIkCGGwqyjR4\/Ou6yYP\/DweOaZZwxlr8pJRNDltJqaS1oREEEHVm7p0qXmyCOPtIeEEDREHRRqGOKCx39UxwbE+vXrp3UPhI47LoImiT9Cjg7eTCRCQAhER6DiCXratGk2WZIvs2bNMo8\/\/rj9CA+Ojh07mubNm5tvv\/3WLFq0yLz++uvW9oxwUNi9e3ezwQYbREc9BS3jImimSjL\/TVYsEkGnYN01xGQhUNEEjSbcsmXLGq+IKqr8r6KKy8Xh3OwgZ4RqKy5gRYErNd5y6qBCEKh4gqYmYU3l6aefNltssUVNu0nU9XFp0D5BuwmSkEoiBIRAYQQqmqALw1O5LeImaKIKWx1xupk1ZoDqFlbuttLMi0RABF0kYH5zAlSIKCTd6HbbbVdUTytWrLBpTmtSDXzdunVm+fLlZsMNNzRNmjQp6v6FGougCyGk74VA7SMggs6BMeT36aefZkK+w5rdeOON5rXXXjOjRo2yId9RZMaMGea6664zixcvts232morc8ABB5iBAweaZs2aRenCMLYHHnjA3H777ZnxtW7d2oao9+nTx6y33npZ\/eBtQuRjLqGSTNeuXbO+FkFHWgo1EgK1ioAIOgRetOJevXrlJWf\/srFjx1pvj0ISTMK07bbbms8++8xeRsEA3NA22mijQt0YHgwkaXKCq5\/LuNetWzczfPjwrNwgvXv3Ni+\/\/HLOfnk4nHfeeSLogsirgRCoWwRE0AG8f\/jhB9OmzX89D6LIiSeeaEaMGFFFaw1eiysf2e8gUnyC7733XkvGpDUlZJzP6euWW27Je9sPPvjAHHXUUbbNRRddZC655BLTsGFDW0uxZ8+e9vObbropSyNGs0ZjJ6AmLJ81nwUfDNKgo6y+2giB2kVABB3A96mnnjL9+vUz5H3u27ev2Xfffc2ZZ55pCRQzAdrqG2+8YW6++WZ75bPPPmtatGhRcJWwVzstFQ190003zVzjfzdv3jx771xyww03mPHjx9uHCGP1A2Tcd35QyJo1a8yuu+5q+6TvqFKbBO3GoLqFUVdD7SoVARF0YOUdyWEqQDNGsDHzH6YDglKQmTNn2oRK2H6ff\/75gulGx40bZ68\/5JBDzH333Zd1V6IW99prL\/sZ39Eml2B6we4dZpZwY+Lat99+O6Ohd+jQwWblIztfVKlNgiZXNH7RIuioq6F2lYqACDqw8gRRoBX7ZOy0apInkUTJSadOncz8+fNt1ZUdd9wx7x6CUIlOvOKKK8wFF1xQpS0h5QsXLsy6b1iHHCiSs\/qJJ54w7du3z2ryzTffZD5zKVBnz55tvUzQqskXQgTkl19+aVq1amXwAT\/55JNNgwYNqtyqNglahWUrlW4072IREEEHEIOA0ezwtIDYEEdy2JB9b4hrrrnGPPjgg9ZujP04n0CEmDZ84vfbo42jAV922WWGLHlhQsGAPfbYw34VloPamTP43uWyhsjx0sglbdu2tXMKuun5+a3zla0Co0XLCkcS+n7QIuhif6ZqX2kIuLd2N++kBHfVW4cPWQkFjwxMG9h4ITcO4NBY0VwR30bMoRyHc9iqcW\/LJ5gwMGXcdddd5uijj67SFPs0pIvHRS5C5aCPAz+EJ2uYD7UjVmcq4eFx991322vIG+LqKD733HPWTQ\/hkPK2227LGhP9QMxo3vvtt1\/OqdWEoF2nSqRUwg2vWycSAX7fCMohZC2C\/r9lwqsCmy2Cj\/KVV15pfZwpEospA1MEpg7n\/0y7KH7QzjSRK0PeKaecYubMmZPTBMJ98MsmcRNCwibG58vq1aut6QJxJpC33nrLvP\/++1bzdnZud839999v3xSQ4MFlXZg4XN3CXbb4mRIpJZImNKhSIyATR8gK+MTlKqsQYII3R1Dw6oC4C\/kvn3DCCeadd97JMp34fTlXuFwmENr6h4kvvvhilURPRBXidYJEKcP13Xff2QrlCFVk3LX8XRcE7RIquZSk3DcpmkKpf5i6vxAAARF0jn2A5snrBcVisS9j373++uvNhAkTMlcQaILJIqiZhnV54YUXGkj1jDPOMNdee21Wk1WrVllvEISaiM6cEtaPM2GEaeI8AHgQIM4Ug90aadSoUZXuwjRu16guCZp7klQJzw4RtIhJCPwPARF0kbsBDwhswQR37LLLLtZGHUXQUKl3iFkCjdsnTD\/CcMGCBXlzSzsvk7CKLy7CEO8MHiS+Ro0r4G677ZY1VPy5ndtgKUwcToMWQUfZQWpTiQiIoCOsOlooB4VNmzYNjcSL0IXxXeDOP\/98079\/f3sZn59++unWxc73vSZXNQeWaO5UeHG25enTp2dqJfo+0++++6459dRTrRmEAz8O\/pDDDjvMLFmyxEYfcijoCgt8\/fXX1o8bN8Ew32xp0FFWVW2EQO0iIILOgS+HhSQZQtt1eS5oSkQedlsODZ1HRNQlwp0NTwpk5513tvk3OOyjf\/6eOnWqady4sf3etzf7h5AQ96WXXmqL1SLYjdHmXa6NYLi4H6WISYYDUEjfn9dLL71kow19EUFHXVW1EwK1h4AIOgTbYFKjXPBD0CQtCrPv5rqGHBzkyvAFlz60Wz\/Yxfd5DnqJYLPGX9qRtOsLswch6MHx0A5vDd4CfOEBcccdd9gDwaCUiqBxuUMw5eRz76u9n4R6FgLJQUAEHVgLSAyPCjRYBFMBmeo4LIQ0P\/nkE6vpYrNFcMEbOXJkwVBv\/zYQ7HvvvWfNGxwwVjcnNDmlOQxcu3atjSDM96DgntjOcdXbZJNN7MMg331LRdAKA08OOWgkpUdABB1YA7wohg4daj910Xhhy+SbK6K4tJV+qYsbQakI2kUZutHmi2IsbkZqLQTSh4AIOrBmeFrgceH8n\/MtKdo1uS38Q7n0bYHwEZeaoP0gFkaIuUPFZstld2keUREQQQeQGjx4sI1qIycHEYP5hJwZ2He55qyzzoqKeSralZqgfRc8AFO0YSq2jQYZMwIi6ACgkyZNMkOGDLEh3QSD5BNSeOKBQSJ8MsWVkySFoF1V8E1WLFI4eDltMM0lEgIi6ABMS5cutX7HHBLmypuBqxsuePxHqDcg+onzIyGf8EZJJGhn4pB3R8I3j4YXGwIVT9DTpk0zlKPyZdasWTZ3M4IHBwmKmjdvbr799luzaNEi67uM7RnBr5loPBcAEtvKlLijpBE0YeBOFA5e4s2h29cZAhVN0GjCLVu2rDHYpBzdZpttatxPkjpIGkH7+aRF0EnaKRpLbSJQ8QRN3oqaytNPP2222GKLmnaTqOtF0IlaDg2mQhGoaIKu0DWPNO0kE7SbgHykIy2lGqUYARF0hMUjUg9vDXI+l5utOdf0k0zQLtpQBB1h86pJqhEQQedYPsK6ybPBISKZ5pyQLpTwbEpUBYu2pnonBAafZIJ20YYub4eCWMpp52kuPgIi6JD9QM4Kqqd89tlneXcLOTtI2L\/eeuuV3a5KA0H7oDsXPEUblt1WrOgJiaADy49nR9euXTNudKTnJNsc6TghbFdpxSVTOuecc2wi\/nKTNBC0CwenZFazndoY\/i8Pj3LbiZU9HxF0YP0J3SaEGyFhPn7QQcEmTZpO\/kNIT9qiRYuy2klpImiAb3XE6WbWmAEi6LLahZqMCDqwB0aMGGGJmeok1CDMJwSoUDaKHM9EH5aTpJWgnV2atcA2zd+KPCynnVlZcxFBB9a7d+\/etjoJ9f1OPvnkvLvhhhtuMOPHjzd9+\/Y1ffr0Kaudk1aCdqYOtxiOoEXUZbU9K2YyIujAUrtsdlFId+DAgTYk\/KKLLjKXX355WW2atBK08\/Bw2fCwSzvRQWJZbdGKmIwIOrDMrvo29fumTJmSs+oINQspxMphYS5bdZp3ULkQtMuciL0JAAAQ50lEQVSG5+fyePTRR2X2SPPmrKCxi6ADi+2XvKIsFAVaOSh05aRWr15tqKAyfPhw69VBEVmSKxHEUk5SbgTt5\/KQ2aOcdmp5z0UEHbK+JD\/q2bNn1jekFW3YsGGVwqvlqD0z8XImaGenViRieZNbOcxOBJ1jFfF3xqMDL40wad26ta2kcsABB5TDPqgyh3ImaOzTuOT5B4nKNV2W2zj1kxJBF1jCd99913z88ce2mjd5o7fffnuzww47mHbt2pkGDRqkfgPkmkAlEDSaNOIfJCrQpWy3dConJoIOLNuoUaPM9OnTbfTgtddem8pFjWPQlUDQRCJagl48NxPo4uf38P8dB6bqQwgUi4AIOoDY1VdfbR5++GFDUiQqp1SqVCpBu0x5vvmDfyshU6X+Eko7bxF0AP+ZM2eaHj162E+nTp1q2rZtW9oVKtHdK5Wgg37UDn7MIE6jxl6t6MQSbcwKu60IOmTB77nnHnPzzTfbgrBEFFJ1pRwy1q1bt84sX77cbLjhhqZJkyZ5t7oI+kbz\/suTjPOjxgwStFfLXa\/C2LIE0xVBB0An8RHVut95552sbyDrXEKCpc0337wEyxftlhDzAw88YG6\/\/XYbWIPghUK6VELUwx4+IuiqBO0SMgXNIP4qSMuOtifVKhoCIugATk899ZTp169fNPT+r1XSi8byFkDxASc8bKgQg3Tr1s0G3dSrVy9rziLo3ATt3PT8Q0anXTvy1mFjUT8hNc6BgAg6AMxHH31kZs+eXdSG6dKlSybSsKgL66DxBx98YEPSEXKGXHLJJTbgxg\/Guemmm2wObF9E0MURtNOunQ27kJaNDZsfH+Ky7rl\/18G20C1SgoAIOiULVd1huox7uA3ydlC\/fv1MV+47tL1HHnlEBD1mgAkeEvo2aEfCYRp0kKBdsiY\/F4iLYPT\/7zTv4Pr6aVPdd3EG0\/gPh+ruraReV05zE0EHdhnBKEi5FIft1auXee211wyZ96ij6IvvsfL2229n5RORBl0zDTqMoB2xB7\/z\/bB98ncJnsJSqAbJ0XmVQOy53gB9s8tpp51Wtq6D5TQ3EbQxhgRI2Ghxq1uyZInd+yRKOuWUU6zLXZrJmlB0EkA98cQTVYrcfvPNN5nPSAAFKTsRQZeGoMPc\/NDCIeug+cSPhAySuE\/g+b6LornnehjkutZ\/QIS9CcSteQddHkXQcSP8v\/7qrcPloA5lzZo1hgXNlXODyt2kp0yjmx2VyffYYw+LZpCA+Yy5U2sReeyxx8w+++yTRdB1uAy6lRAQAnkQSEoKgjonaIjpyiuvtNAQPXjIIYdYP2Gqqriq3v379zfnn39+6jYQ1clxpUN4VQpzBXRa83333Wfn7sTZ8VI3aQ1YCJQhAkkJjKpzgnY2WhL0c4jWrFkzu7w\/\/PCDOeGEEwwkhxaNiSBt8umnn5qOHTvaYRO2zgPIF0w7rVq1sh+FmUDSNl+NVwgIgdpFoM4Jmtd6fIIvu+yyTDVvN8Vbb73V3HXXXTYp\/9y5c6v4CtcuFDXvnaCUvfbay3b04osvmpYtW2Z1SlThvvvuaz8LM4HUfATqQQgIgXJCoM4J2r3ih1XmRus844z\/ZjzDnziNdmg3v9GjR5tjjjkma68QLclbAjJv3jz7IJIIASEgBHIhUDKCDqtTh2GecldpJmh8Z5999llLzpC0Ly7CkFwjEyZM0K4UAkJACORFQAQd8wYht\/XZZ59te\/UPAilEcOqpp9rcHLfddps5\/vjjY76zuhMCQqDcEBBBx7yiP\/30ky18S0InBJvzxhtvbL1UkBNPPNHccsstMd9V3QkBIVCOCIiga2FVV61aZQ9BHUm7W2D2IK2qq1he7K0hfw4aN91001QH8+Sa99KlS83KlSvNdtttl8rzhyjrSWAWc8QfPo1nLME54ttPYNb3339vttxyS9O0adMoMKhNRARKRtBEDgZzJPP6j5sdQi6LMCEL3Lhx4zLueRHnWZJmK1assIeBa9euta6D1SVmNj8eLlSecYI3DCaTtJtKmNuwYcNsMimX8Y85dujQwfz+97+3NSnLRVwYMfOhSDJvVmmWiRMn2vztLqUucyGtLsnA9txzzzRPLTFjLxlB1wSBpKcbrcncgteSq4Twdxd5SepSNDD3o4C4nWdInPeti74Iff\/tb39r5s+fb28XnBufzZgxw2rUaZfvvvvOHoC7h1DaCZoc7uQ7R\/D332WXXexDx+3LsDiAtK9hKcZf5wR98cUX26CUmgiHbJXyKkXWu8GDB1u4xo4daw477DAbMo6bIjggafWpZg5oW7gbPvTQQ2bvvfc2mIdINuUSTYV5w9Rk75TqWva9b\/JKM0H73lZ+PAOmDvKdExHM+pEwTFIzBOqcoGs23Mq7GoJauHCh6d27txkwYEAGAMwmxx13nNU++\/btayu1pE3OPfdc88orr1gTh6tL6eZw1VVX2ZwsyKJFi7LStqZtni69wc4775wx4aWZoIcOHWowb4S5i\/KgZT3lShrPLhVBx4NjrfTiJ1ciLL5du3ZZ9xk5cqS54447zO67726ee+65WhlDbXXKA4YCwbwSh82NtwKnRQdTs9bWmGqjX6dt8pbw+OOPm2OPPdbeJs0E7TI28kbn4hZqAzv1aYwIOsG7gFdFNBHkww8\/NA0aNMgarSMxfvwcRqZJePi89NJL1lxz5JFHVvFKwb6JnRO7dK7Mh0mfL+cHJ510kn3LGTVqlM3T4h6yaSXoZcuWZaqtk+aUM4I333zTUBmJNwQSgIm049uZIuj4sIy9J5fgPxcBQ1zdu3e3901raHwYaL72TNmwyy+\/PHZs66JDV0EHTxvOC\/BYSTtBL1iwIPMWABGzVkHhnOSee+4pCzfCutgn+e4hgi71CuS5\/+TJk82gQYNsMQNstUEhOhE7NEKej6DbYoKnFjq0r7\/+2h4aYgpAMIGAQRoLOLgalHg4kDhro402KguCRmsmn7sTAq84GCStPHt0\/Pjx9qu0nosk7Tcjgk7ainjjcRXPSc2KZ0NQ5syZY6vQIGk+SCMAB28Vgnicm9Y555xjNec0kvOXX35pc7HgUucXZigHDdovfgwxjxgxImtb9uvXz54ppNk0lSRKEEEnaTUCY3E\/hlwmjmnTptnCBmn+MXz++ec2NB47JnLggQfagg677bZbglcm\/9AI5b\/77rvturjsjFyBTRrXQgSvHApVoIGmyc\/bN3FMmTLFukb64pun0mpnT9LGE0EnaTUCY\/F\/DGGO\/0RUDh8+3JbOQlNLm6BpdunSxYYK8xBCgz7qqKPSNo0q43W25ygT4c2hLuoIRhlLlDYE3DhSDvO\/981uuaoKRbmP2vwXARF0gncCr\/7777+\/fVUm7Pn000\/PGm2nTp2shwAaJz7FaRP3Ogw5v\/rqq6ElwtI2J8bLgxWvhqCwnqSjRXiwYpf+5S9\/mbp5U5QiV1ZGDgd50KbRsyiJe00EncRV8cbkckiz4cmI58poUTLLBa5wOMNBYtrEVdfBBe3oo48OHT65V4LuhWmbpxuvX1Q4za\/\/+D9je2Yvsg+32WYbO0VC97t27WpICNWzZ09z9dVXp3WpEjNuEXRiliJ8IJgBOAhk0yMUpSUJE6fpCF4P\/CjSJswHd6woUi4uhOVC0MyDtXOmKfbk+uuvb704eNtDmeBQm6yLkpohIIKuGX51cvUXX3xhNRKX6Y+b8iPA08G9MtfJQGK8CVVnoo6dUHcIIO3CIaE7\/Ey7WyRpbzGtBd0\/yX9OkFHz5s3TvlyJGL8IOhHLEG0Q5EvGvkmiKNI5lkM+4WgzV6ukIoAWzZ5kLxJJuPXWWyd1qKkclwg6lcumQQsBIVAJCIigK2GVNUchIARSiYAIOpXLpkELASFQCQiIoCthlTVHISAEUomACDqVy6ZBCwEhUAkIiKArYZU1RyEgBFKJgAg6lcumQQsBIVAJCIigK2GVNUchIARSiYAIOpXLpkEXiwDhydWpJr\/xxhvbNKErV640jRs3No0aNSr21movBKqNgAi62tDpwjQh4LKsFTtmcp1QmJf6kAMHDswUsi22H7UXAtVBQARdHdR0TeoQIIE+ifSLFdKC3nXXXSLoYoFT+1gQEEHHAqM6SToC1DskHWZQyBRIBrb27dtXKd9E280339y88MILhuv3228\/204iBOoKARF0XSGt+yQSAWoHki2vQ4cO5sEHH0zkGDWoykVABF25a6+ZG2OLuxYiaMqJUfCVeokuXej06dNtJXUyuB1++OGG+pFUhSG726GHHmr\/o9gvWvszzzxj3njjDauFt2vXzhYnoCpJmMybN8\/MmDHDzJ0716xZs8aWl0Jzp7iBpPIQEEFX3pprxh4CUQj6oIMOqmKDHjx4sK1EDmlD3hBqUNDIhw0blim24H9PJRLfXLJ27VozZswYWy4qTHr16mUGDRqkFLMVtntF0BW24JpuNgI1JWjXW+fOnc3BBx9sqP4C0fpC9RH+47sJEybYr0hsP3ny5Eyz+++\/31x33XX2bx4IJ510klm9erXVyrGBI926dQu1k2tNyxcBEXT5rq1mFgGBOAiayjB+dZg+ffqY559\/3t69R48eVot2wr8feughWxEHrZuai5g+OnbsaAuxcmh5\/fXX28+d+FXC58yZY5o1axZhZmpSDgiIoMthFTWHaiMQB0G\/9957WQEsvksftmlXVJVB8jfly5CZM2faCiQQtiPxsFJY1KXEDo2gZZ922mnVnq8uTBcCIuh0rZdGGzMCNSXo1q1bZ0wQbmiYLrAXI4sWLTL169fPjJrDwu7du9u\/MV+0aNHCkrPTqtGew+TSSy+1H5955plmyJAhMaOg7pKKgAg6qSujcdUJAjUlaGzL48aNyxqrI2jMGHhl+BJG0JhB0KajiOzQUVAqnzYi6PJZS82kGgjUlKCPOOKIKoeCxRI0Jg9MH0jfvn3zzqJNmzbWXi2pDARE0JWxzpplDgSSQNDXXHNNJkiGg0OSMgUFO\/RPP\/1kmjRpEvq9Frg8ERBBl+e6alYREUgCQU+aNCljVx47dqwNfPFlyZIl1k0PGT16tA2ukVQGAiLoylhnzTLBGjSBLhAwOUHatm1rbdrOlW7ZsmUGtz1s19i0Z8+ebf8vqQwERNCVsc6aZYIJmqHhNw0RIxAwId6rVq0yuPDhH42Eadda2PJGQARd3uur2RVAoFOnTmb+\/Pl5kyWh3WJm8PNBO9e4sEPCJ5980vTv399sttlmVvP1JcyLw33\/+uuv24AXNGlfdtxxR9OvXz+bw0NSWQiIoCtrvTXbhCOA1rx48WKzYMEC07BhQ5twCbOH70ud8CloeDEiIIKOEUx1JQSEgBCIEwERdJxoqi8hIASEQIwIiKBjBFNdCQEhIATiREAEHSea6ksICAEhECMCIugYwVRXQkAICIE4ERBBx4mm+hICQkAIxIiACDpGMNWVEBACQiBOBETQcaKpvoSAEBACMSIggo4RTHUlBISAEIgTARF0nGiqLyEgBIRAjAiIoGMEU10JASEgBOJEQAQdJ5rqSwgIASEQIwIi6BjBVFdCQAgIgTgREEHHiab6EgJCQAjEiIAIOkYw1ZUQEAJCIE4ERNBxoqm+hIAQEAIxIiCCjhFMdSUEhIAQiBMBEXScaKovISAEhECMCIigYwRTXQkBISAE4kRABB0nmupLCAgBIRAjAiLoGMFUV0JACAiBOBEQQceJpvoSAkJACMSIgAg6RjDVlRAQAkIgTgRE0HGiqb6EgBAQAjEiIIKOEUx1JQSEgBCIEwERdJxoqi8hIASEQIwI\/H8F\/b\/Cs2fqigAAAABJRU5ErkJggg==","height":337,"width":560}}
%---
%[output:556fd86c]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAWgAAADYCAYAAADGWHkUAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQm0FMX1xguUvxoXlE1xC26AGEDjATyK4gKJosYVUGIAV0wEFSWKBFCMCgIuKC7ghgZQQIWgJIq7EYMajwKKoAiu0SiI64mgwP\/8KqlJvX6z9Ez3zPS8+e45HH3T1VW3vqr++vatW7fqbdy4caORCAEhIASEQOIQqCeCTtyYSCEhIASEgEVABK2JIASEgBBIKAIi6IQOjNQSAkJACIigNQeEgBAQAglFQASd0IGRWkJACAgBEbTmgBAQAkIgoQiIoBM6MFJLCAgBISCC1hwQAkJACCQUARF0QgdGagkBISAERNCaA0JACAiBhCIggk7owEgtISAEhIAIWnNACAgBIZBQBETQCR0YqSUEhIAQEEFrDggBISAEEoqACDqhAyO1hIAQEAIiaM0BISAEhEBCERBBJ3RgpJYQEAJCQAStOSAEhIAQSCgCIuiEDozUEgJCQAiIoDUHhIAQEAIJRUAEndCBkVpCQAgIARG05oAQEAJCIKEIiKATOjBSSwgIASEggtYcEAJCQAgkFAERdEIHRmoJASEgBETQmgNCQAgIgYQiIIJO6MBILSEgBISACFpzQAgIASGQUARE0AkdGKklBISAEBBBaw5UHAKrVq0ya9eutXpvscUWplGjRhXXBylszNdff22WLVuWgqJ169Zm6623zgnNjz\/+aF577bVUuR133NHstNNOOe+rxAIi6EoctQTp\/N1335mvvvoqpdH2229vNtlkk6JqePzxx5tFixbZNg444AAzbdq0orZXCZWvWbPG\/Pvf\/7aqNmjQwDRt2jTxaj\/zzDPmzDPPTOl5\/\/33m06dOtm\/s82rb775xrRv3z5136BBg8zAgQMT399CFBRBF4Ka7kkh8PDDD5vBgwen\/n7ppZeKTg4+QXfs2NE88MADVT8ijAFjgeyxxx7miSeeSDwm2Qg627wSQSd+aKVgUhAQQSdjJOoCQTOX9t13XwtoPgQ9ZMgQc8455yRjIGLWQhZ0TIB+++23ZssttzT16tWLqcbs1axfvz4vVwJ+ux9++MH6bPMRfL2bbbZZxlvyJehC9OAe3CYO2zgs6I0bN5p169Zl7Vuw02D+6aefWp93vjjmg3m6suj6f\/\/3fxmrSSJBM3fQOdMzsWHDBgOmTnDNOMk1r5jLTjbddNNQz12uuRwENxfmUcc0zP0i6DAoZSjz1ltvmZtvvtm8\/vrr9sGFoPfff39z4IEHmjPOOMMwcZC3337bXHvttalaIJtx48aZbbbZxv42d+7c1Ocpf7ds2dJceuml5r333jMjRoxI3Tdy5Ejz97\/\/3dx1111m5cqVpnHjxubnP\/+5+d3vflfDJ+duYBLfeeed5vHHH0\/5bPn8RcfTTjvN\/OxnP0vbs3nz5pmZM2fafq1evdr2i\/t69OhhTjzxREtOLNTRh3fffde8+uqrqXqOPfZYe\/2yyy4zDRs2tL8XogekPGnSJPupvnDhQqtDly5dDP7Giy++ONWffFwc1Hn33Xebp59+2rz55pvWzwmG++yzj+nTp4859NBDTf369WtgAoGA91\/+8pdUmxTYbbfdrP8bYtxuu+1q3DN+\/PgUJozxhAkTalxnzrzyyiv2Nxa4Ro8ebf\/\/jTfeMDfccEOqLL8zdk8++aR5\/vnn7e8dOnSw4w0WCNgzVi+++KL56KOP7G9gdfTRR1u9mEeZ5KKLLrLjiDRp0sRcf\/31qaKXX365nWMI4zlx4sTUtTvuuMP87W9\/S\/3NNffCeuSRR8xDDz1k5zzPBLLzzjubX\/7yl6Znz55mr732St1Hf8eMGZP6mzmD7zzXvIL0+\/fvn7qPFzbzEoHYeZ6QXXbZxZZDn8cee8wsWbIkNY8uuOCCGrq4ylh8ZLxx1TH30f3UU081Bx98cA1dr776alt\/sUUEXSDC9957r4EwM0nXrl0NDyoTF2utb9++5oUXXkgV55OMTzMs78MOO8xOBiezZs2yhMsLgAfNSefOnWvU4bf9xz\/+0fz6179O\/fTPf\/7TfvYxKTMJfWDiOYHAeDBZrMkk7dq1s9d5sB1JpCtLXyGfQvRgdX\/AgAFp+wr5QKxOwhL0Z599Zs4777waL5Og3owR\/XdCHyExf9yC9+ywww7mtttuq\/GChEAhBIQXgCNjd2+\/fv1ShOv7iyFi\/1M923hD+t27d6\/lCvD1g1wcsacbIzDmxeOTEy9VXko+kXJ9\/vz5pnnz5rYo7S5dutT+f5s2bcyjjz5q\/x+sZs+enXHucGH69On2JYOk80EzZ3LNKyI9Mi0SQpwQrMOeF6R70QQV40XdokWL1M8Qe6bFRl7Ifj1\/\/etfTatWrbL2NY6LIugCUOTN\/6tf\/SrnnZA0ViCCdXPIIYfUuIcHcs6cOeamm25K\/Q6JYCEiQYLO1eBTTz1lLTsEyyHMQpF7GbiHBysml5x11ln2heOTu38PJPrcc89ZV0AhemBV3X777bnUsNfDEnQY8qA+xotxC0s4jgggQmdFxkXQ2QAA48WLFxssVqzBdAKJMb6ZBMvbt7Dvu+8+w0uBr6Ju3brVuM3hgkHBS9oJbfMv3VwNvky5B3KGpJF0BM1LJde8whUShqBzTSAsb\/fV8Pnnn6ciSHLdx3URdBiUylSmV69eNayiUaNGWUuXiX3FFVfYT3InfAq6GE3CwYYNG5a6hvXhW7hYU1gjzuebbtLzKX7cccdZ\/yntunAzKnUTbsGCBaZ3796pdpjwv\/\/9782uu+5qH1jf8ufzDasDq5RPfN+S5wuABwqXx9ixY1OWK1Yjn9RINl9hIXqke1CuueYaqwf13XjjjTV0DEPQEBmYOUF\/3AxYt4wJbiAnJ598sv2UDb6EIQ4+5ffee2\/79cCLjBeiE3+hKk6CRreDDjrIvP\/++\/YLyR8fP2KmEB\/0xx9\/XIMMqQPd05G+Mxxefvllc8opp6T6jftgv\/32s+PiGxp8ZTFm+H2ZY\/48xf2B+68YURy+BY2Sbtz23HNP2965556b0h1jxo1h0ChgXl144YXWyODFFQzlFEGXiXxzNUusKT5LJ0ceeaS59dZbaxAy1qUTiPG3v\/2t\/ZNFEXy\/EE06wZr2\/cJBgsYCv+eee1ILIny24wd14j5p8WNCQE74dINYnPiLbPyGP5YHiAfJCQ+qHz4XnPjOhZGNoAvRg4eIT28nWOC+lcdnKRa8kzAEDRa+bzfo2vE\/2R2GrBn4flc\/Rpe2ccO4iAP+ZpOFcxfERdDB+N7rrrvO3HLLLam++\/OlEIKmoiOOOCL16c7\/41\/mhei\/tCiHZQ1RYUk7nzkWMj5byHbq1Knmk08+sbrtvvvuKZ8wLzMMGt89wFzbaqutSkLQwXE74YQTahhQK1assDr7ONAv5iF+eSe8lHg5ORFBp6Ww8v\/I2x9SdoIV5vvr8N\/5PkcWzbBEnXz44YdpfWzpgu2DBA1psFDni08u\/M7OLOryfYs+iVMGi9L34+IvxWL0CZkXQTZfoNMhG0EHfZxh9ICA\/YWjdHq0bds2pX8YgvbJC70dQWSbTfiCcUEhzp0QLB\/sn7MM4yLoYN+DWPvuqUIJGrJ1bjj6CTaQEXOYLzwsSOeDf+edd6yP1vnXWZhjQc8JBghfj7jWmIeUdwuXPnalJOjgWAfnAgQd9LmzJuT82E5v3DK++08EXX4uTqtB8LMsl5q+H9qVvfLKK83kyZNr3JqONIIEzYYMCMmXoUOH1tiogXVOBEm2xcGgznym4jP2P1GJHgguFKXrazaCPuaYY\/LWA138z0miFIJREr4VFIageam5SJNMZBvsm29R+daxX46FWUjUiXNnxUXQECERPU5YgMOX7iQOgoZ8cZs5gVyd\/\/k3v\/mNxd7NC+YErjPnZsHwwABB+LI8\/fTTa1iZmZ6NUhF0urHGFTVjxoyUahB00K1GP4YPH15D\/eCXW9UQNBME642BroT99DzovhULQfBZnEnwffl+L0KPeAB8C5Z7zz\/\/fOvz8iVI0G4Rxy\/DA+O7TLBccAG4MCgmKSFO2QRC4eHDz+zE3zSQ7d5sBI2rJ189pkyZUuPlFXTPYKWxQOTwC0PQEJAfibF8+fJa4XTBPvq4+j53v1zQGsNVxEJhLoL2X1zZojhKQdBBlx1z1S3QYh1vu+22KZcSi4H+1+A\/\/vGPVB4ULGsX3gZGfFnyksM\/zdqM7zJJGkHjJ\/ddgEG3Jf0JzvOqIWi\/4zxsWEcA5GJoszJLGS4G37bB8LZsKhFuB3lihaeTXD7o4I6p4MPliMS30N1na64NNLhEfN8viz5+pAovBz8iAP9ss2bNsi4SFqIH7bDQ6oT\/9y284OJdGIImlhzid+Iv3PIbRAuJIPSJvtEuujghSsN\/EROSePjhh6c+4X0SD0aM8KJ1C7\/Bz+lyEzT9Ix9GujmJi4eQNpcfw5+zxNITBYLwssTt5IQvDuay2wcQ\/NJIGkGjN3sXXNw2LxfwwE\/uxH\/p8lvVEHSm2EN8qxAEftBsO9nKwNF2MjoLjof2z3\/+c+oznE8hP+wJfzAuB+TBBx80l1xySUpl7vV9dGGiOHyryl+woVIsc8iFBRv\/E43YXrdwSfQHcbj4oZHNN9\/cRmRgVfox1+jCQ4ZFSF+p201gn\/SDlsWzzz5ro0WQQvRg0cmPEsAPisuDeFZIkZeUyzlBG2EIOkj6bJhwC118cRx11FGpMWHeEWMcfGHxO4t0bi4GsffrDLqw\/NC94IJlMQg6Xex1tuckiA9lGWP8yWzc8cnL1eMvfgfXZfz1FMLywM6f54UQtD+vsuXi8Bezw7o46BPPLNErTpjvzDWwZB77X5dVRdB0ls0MvK0ByN+V5ibKSSedZMOkWDXPZQmWgrCDE5qJwIDSD3+lF10coQZDmrjGZzc+ZH8zAZ+KTHAkUxw0cagQrdss4Prs3BJEGPAV4giV67gFCKznhei7V\/xYUN8lwT1up2Iwntp3x0DivmuGkD7aoR98MeSrB\/dAdv48QA8+QdlZGVx0CkPQ4EGomt9vrDx2rfk74ugzljaEhKWL283HmBcq7RHyFpynvlUefGlRLyFnRDkE9Y+LoINrEYQLEk3hu9cyPRv4YV3styvjL5QFyYsy\/tdekDD5muAevjb56gpuFGGHKi\/cbGF22eaVm89OV\/+FUChBp8MgG5dUjQUdBIFJDCFAJMEdWDwgkAiWdTnTKeYKl3N9cp\/nkA5Wq08GfAbjUmClO+gjxiLHSs9no0pwRR2rmJC+bEIcKJ+pLp9ymA04EBT+RPf5l+7F414+7AorRI9g3HK2PoQhaO5ngRUSyya4n\/wyWPO4V4LrBcE6gm4YXgi46jLtYPPvj4ug08Uu59pJ6OsRtJLd\/KRMcNcsL0xisP1t8f7uyFxGkltXyEbQ2eZV2J2E+VjQ6EwagKuuuiqt+vTZj0GvWoL20cECJJCcyRe0TLFueKB831euiRHXdfIf4\/9lovHGDgoWhNvkwbWgRcV1+uV2ngV9dC5qIF2YHRZ50F\/I5ybxwsE8EtxP3eniriEe4ouDSX+wJHhxBK1z+kGcNO6SYNIetjoTC+4TmYuT5r5C9OCzmfENWpwsXEH6zs0RlqDRA9yw\/tMRLrG\/vmvFjSlEAVkFjQWu89DisgiGD3KNryn8lv4GDQgD9wcvIBfFkw9BB0nYj+LgpUAf\/AiFfAg66HP3Y8V5UfEV6wScaMsXYvL5kgrONeYM1rx\/v4tsChK02\/Ti6s00r1if8p973IbuSyGXBc1GMT9KyMVBuzbRn1hw+IZ5wt4D9P3JT35SIwyVL36+UIotid7q7Vwf6axpBwyf1EymUolbEHFvZ4iaT298uFiVhEVhOcbhiskUxYFfj4eGEChC4XL56MGRifjFF1\/YreBMLPTPJFj87p5\/\/etfNlESL41sGdxYCechJTES+vASCibuL0QPsOVlAaa4ObJldAszB\/Bjf\/DBB3a8vv\/+e+uOoX9uQStTHSTE5x7cG3y9EZ0TZpyZL3wlYfVBmLnGKkwfspWBqJ2lx3gxDqUU5qzDiE1XUfsbZl4Vq39+NjteFr4fOl34ZzH0SBxBY7HwdmLLc9DPh8XCpyMLR1gPzmUQfAsWAyhXp1scChtPG0WXMGF2UerXvUJACPwHASJ52AvgBDeey\/cBJxFam26RvNj4JYKg2V1Hvgc+4fxPQtd5\/KssZvEp6Vs6EDQ+6WITNJ+3kCXtub37IuhiT03VLwRKh0AwKoeW3U5KvlZ9t1hwraKYWpadoIPhTK6zrCJDysSaZvocZ7GOT81iE3RwOzU6iqCLOS1VtxAoLQK4DSHe4FpXUAvWvvBz+zHSxdS07ATtL6ARPoa1TFxqmCgN\/L9kZnMxrcUCioU559cjbpZQrFIQdLH6o3qFgBCoDATKTtCE67ByypupFKuiUYfF7ckXQUdFUvcLASGQC4GyEzThWDjkyU9AOE42YYcX+\/8JCfJPQsjVyTivhyXoSnjZxImL6hICdQmBYrtNw2JVdoJ2Lg7\/JJF0yhMexQYVQq7CpsIMC0I+5fIhaHZTpYuR9dvj64GY6dbdTjONd\/9fPoN8dFLZ0iKw7ImptsFW3f53xFhpNVBr+SCwesVis\/SJKXZ3Y9jnsaoJmsByYiURt\/2VELpsVieRHi7MJV1Wt3wGLErZfAg6mCw8Xbu4eAjmP6j\/tabJ7v87SiiKjrq3uAjMn\/ifg1gZM0nyEVi1YpFhzPJ5HquaoNNFRYQdZoL92QoeNQA+bHvBciLoQpGrO\/cte\/K\/FnRXWdCVMKoi6DxHidMKSKSCEPfMZz4RHNk+P9jGzPZOygQTuOfZfKTiIuhI8OlmIVByBETQESAP64OO0ESst4qgY4VTlQmBoiMggo4AMQHi5Dgg7rkSTlQRQUcYbN0qBMqAgAg6D9BJmEMyHrJD4apgswlJfMIKSYhIUlMuEUGXC3m1KwQKQ0AEnQduLlLDnUBBDo4wScX9JoJHFuXRfOSijqBznVpBP\/NZNVYUR+ShUQVCIC0CIug8JkalE3TYroqgwyKlckKguAiIoPPAl1M72HTifM7k2XUx0WGrIc9srvy9YesqVjkRdLGQVb1CID8ERND54VUVpUXQVTHM6mQFICCCroBBKrWKIuhSI672hEB6BETQecwMzvgiciOKkEM6TDrSKG1EvVcEHRVB3S8E4kFABJ0HjnFkeStnFEfYroqgwyKlckKguAiIoPPAl52DHMYYRY477risB5hGqTuue0XQcSGpeoRANARE0NHwq5N3i6Dr5LCqUxWIgAi6Aget2CqLoIuNsOoXAuEQEEGHw8mW6tatm1m7dq05+uijzaWXXmpPyv7DH\/6QRw3GPPTQQ1okzAsxFRYC1YuACDqPsddOwppgKWF\/HpNHRYVAAQiIoPMAjdNQvv\/+e9OmTRvTuXNnw8kFTz75ZB41GNO7d++SHXuel2JeYbk4CkVO9wmBeBEQQceLZ52oTQRdJ4ZRnagDCIigYx5ENrJw\/mCjRo1Mw4YNY669NNWJoEuDs1oRArkQEEHnQijE9Y8\/\/tjcfPPN5qmnnjKrV69O3bHlllua\/fbbz5x99tnWJUI+6EoQEXQljJJ0rAYERNARR9nlWM5VDQQ9ceLExG9SoR8i6FyjqetCoDQIiKAj4Iwrg9C77777ztZy\/PHHm65du5rtt9\/e5uz44IMPzKxZs8yrr75qrx977LHmxhtvTLwlLYKOMCl0qxCIEQERdAQwp0yZYkaMGGFrmD59uunQoUPa2oj+uOKKK+w1oj7iyOkRQe2ct4qgc0KkAkKgJAiIoCPAPHToUPPAAw+YPn36pAg4U3VY14sWLTLXX3+9tbSTLCLoJI+OdKsmBETQEUZ72LBhZtq0aXY34Zlnnpm1pgEDBhhSjXLPGWecEaHV4t8qgi4+xmpBCIRBQAQdBqUMZaZOnWqGDx9uunfvbiZMmJC1JtwfRHjMmTPHcOxVkkUEneTRkW7VhIAIOsJof\/LJJ+YXv\/iFXSSEoCHqoHCGISF4\/OM0bbZH169fP0Krxb9VBF18jNWCEAiDgAg6DEr\/LTNv3jybLMmX+fPnmxkzZtifiODo0qWLad68ufnyyy\/N8uXLzYsvvmh9zwgLhb169TKbbbZZHq2WvqgIuvSYq0UhkA4BEXTIeYEl3LJly5ClMxfTiSqRIVQFQqBqEBBBhxxqCJozCaPK7NmzTbNmzaJWU9T7ZUEXFV5VLgRCIyCCDg1V9RQUQVfPWKunyUZABF2i8WGDCjsKSTe6yy67hG5148aNZtWqVWbzzTc3W2+9dej7ohQUQUdBT\/cKgfgQEEHHgCUk+uGHH6a2fKer8tprrzXPP\/+8GT9+vN3ynUuo85577jE33HBDqt7WrVvbreUDBw40m266aa4q7HWiR9jJmEk4Gebkk0+ucVkEHQpaFRICRUdABB0RYqzifv36ZSVnv4lJkybZaI9cAqGTXMkJIXouU17Pnj3NqFGjQuX06N+\/v3niiScyNjdkyBBzzjnniKBzDYiuC4EyICCCjgD6t99+a9q1axe6hhNPPNGMHj06p\/X79ttvmyOPPNLWe95555nzzz\/fNGjQwJ6B2LdvX\/v7mDFjalm+6RTB4n733XftBpl0+an5bZttthFBhx5FFRQCpUNABB0B64cfftgMHjzYkPd50KBBpmPHjub000+3li5uBazeV155xYwdO9a28sgjj5gWLVrkbPGaa64xd955pyV\/2vA3trhrBxxwgN1mnk3Wr19v9tprL6vf4sWLc7brCsjFERoqFRQCRUVABB0BXkeWuBywjBF8zPzDBcGmFOSFF16wCZXwIc+dOzenawKXCf7qdO4HVxf1vv7667WsX787HCRw8MEH2yx7ZNsLKyLosEipnBAoLgIi6Aj4XnDBBdYq9snYWdUkTyKJkpNjjjnGLFmyxJ66sttuu2Vt9cADD7THZs2cOdPsv\/\/+NcquWbMm9Vuu1KULFiywUSNY2+T\/YEfj559\/blq1amVjunv06GE22WSTWrqIoCNMCt0qBGJEQAQdAUwI+P777zdXXXWVJULEkSInqPjREyNHjjT33nuvGTdunMEXnUlI9L\/PPvvYy+kI2LktuJ4tBzXXIXiiNDJJ+\/btrY7B8D0\/X3U2Vwp5RU499VRzUP9rTZPdw\/viI0CuW4VAVSEQhqDhHnjHyYoVKxKBUb2NxKKVUYjIwLWBrxgyZCEPyxcLGMHvi\/8XYXGPRT581YTJZRIW9FjYQyDApk2b1irqCPSuu+4yhx12WMa6eBnceuut9jp5QNy5iI8++qgN30PITU2Oal+on68DyBnp1KlT2jZE0GWcfGq6KhAIQ9A8hwgkjXtVBP3fqeF8vPy5ww47mMsuu8zGOHNILK4Mstvh6nDxz5TLFQdNPDUJlxASLVGvLz\/88IN1USDpXCB+2ddee80sW7bMWuRt27atUc\/dd99tLX+EUMHtttsudV0ujqp49tXJCkAgDEG7bjiDSQTtDaxPdO5kleeee85GcwSFqA6IOxjW5pcjdakj08cee6xWgiZ2FRItguTyQWebf1999ZU9cRzhVBhXJ3+LoCvgyZWKVYGACDqGYcZS5fOCw2LxL+Mnvvrqq83kyZNTte+8887mlltuqWXJpmveuTDS5ZheuHChOeGEE+xtvgslXT34s5Etttii1uVslrgIOoZJoSqEQAwIiKBjADFTFURM4FNmM8iee+5pfdRhxEWHpDupxe0wJArDfwEE6\/UtbUL79t577xpFiM92YYBycYQZFZURAqVHQAQdM+ZYrSwUNmrUKO3OvTDNPfPMM6kzDv2FwDfeeMNGTeAG8Q+fJRUqC5ZY7pzw4nzURxxxhFm5cqXdlciioDso4IsvvrBx2YT9schIG77Igg4zSiojBIqPgAg6BoxZLCQpEf5lly+DaongwM\/LoqGLoAjTHIR74YUX2kNmEfzDWOEupwZuFCI0nPh+a38REh+1y7OBi4VNK5C4r+fjjz9udxuKoMOMjMoIgdIiIIKOiPfTTz9tzjrrrJy1QNAkP0rnD05387p168xFF12UImlXBrcHW8f9evzY6WCUCCRPtAZWvS9t2rQxN910k10QDIos6JzDqQJCoCQIiKAjwAzpEbOMBYsQU0ymOhYLIc0PPvjAzJo1y4axIYTg3XjjjTm3evsqffPNN3YxcMOGDXYHYViC9+uA7PGFE8K37bbb2p2M6eKr3T0i6AiTQrcKgRgREEFHAHPKlClmxIgRtoZsu\/rYrcdGESRKaFwEVfO6VQSdF1wqLASKhoAIOgK0Q4cOtTHELv45W1VY1+TC8Bf3IjRd1FtF0EWFV5ULgdAIiKBDQ1W74LBhw2zKT3JysGMwmwwYMMD6k7nnjDPOiNBq8W8VQRcfY7UgBMIgIIIOg1KGMlOnTjXDhw+3W7rZVJJNSPlJhAeJ88ksl2QRQSd5dKRbNSEggo4w2p988omNO2aRMN2uP6omZI4QPP6x1Zv98n4C\/gjNF+1WEXTRoFXFQiAvBETQecA1b948s3bt2hp3zJ8\/38yYMcP+RgQHiY6aN29uvvzyS7N8+XKb8AjfM8JCIbv33IaRPJouaVERdEnhVmNCICMCIuiQkwNLuGXLliFLZy5GytGddtopcj3FrEAEXUx0VbcQCI+ACDokVhA0+S+iyuzZs02zZs2iVlPU+0XQRYVXlQuB0AiIoENDVT0FRdDVM9bqabIREEHHPD7s+CNag5zPSfc1Z+q6CDrmSaHqhECBCIigCwTOv41t3eTZYBFx6dKlqUuchkLyfRIWBQ9\/jaHZolUhgi4atKpYCOSFgAg6L7hqFybHBaenfPTRR1lrImcHCfs33XTTiC0W\/3YRdPExVgtCIAwCIugwKGUow8LhySefnAqjI50nB8iSvhPCdietuGRKZL1je3jSRQSd9BGSftWCgAg6wkizdZst3AgJ84mDDgo+adJ68g8hPWmLFi0itFr8W0XQxcdYLQiBMAiIoMOglKHM6NGjLTHqMatFAAAOvElEQVRzyglnEGYTNqhwzNTtt99udx8mWUTQSR4d6VZNCIigI4x2\/\/797SknnBPYo0ePrDVdc8015s477zSDBg0yAwcOjNBq8W8VQRcfY7UgBMIgIIIOg1KGMi6bXRjSHTJkiN0Sft5555mLL744QqvFv1UEXXyM1YIQCIOACDoMShnKkAuaRT\/O+3vooYcynlLCmYUc3MpiYSZfdQQ1Yr9VBB07pKpQCBSEgAi6INj+c5N\/5BXHSHHQKwuF7liqH374wZ6gMmrUKBvVwSGyJFdiE0uSRQSd5NGRbtWEgAg64miT\/Khv3741aiGtaIMGDWod1FoJ1jMdEUFHnBS6XQjEhIAIOgYgiXcmooMojXTSunVre5LKgQceGENrxa9CBF18jNWCEAiDgAg6DEohy7zxxhvm\/ffft6d5kzd61113NT\/96U\/NvvvuazbZZJOQtZS\/mAi6\/GMgDYQACIigI8yD8ePHm2eeecbuHrzyyisj1JSsW0XQyRoPaVO9CIigI4z95Zdfbv70pz8ZkiJxckpdERF0XRlJ9aPSERBBRxjBF154wfTp08fWMGvWLNO+ffsItSXnVhF0csZCmlQ3AiLoiON\/2223mbFjx9oDYdlRyKkrScxYt3HjRrNq1Sqz+eabm6233jprr0XQESeFbhcCMSEggo4AJImPOK174cKFNWqBrDMJCZaaNm0aodX8boWY77nnHnPDDTfYjTIIUSWkP2XLebqXiQg6P4xVWggUCwERdARkH374YTN48OC8aij1obFY9Rwm4ISXBye+ID179rSbaOrVq1ejDyLovIZUhYVA0RAQQUeA9r333jMLFizIq4bjjjsutdMwrxsLKPz222\/bLeYIOUDOP\/98u4HG31wzZswYm9PaFxF0AWDrFiFQBARE0EUANSlVugx6hAFi7devXz+lmrt2wAEHmGnTpomgkzJoRdZj2ZNTTePd25omu7crckuqPg4ERNARUGQzCpLUw2H79etnnn\/+eUMmPc5F9MWPQHn99ddr5AeRBR1hUiT81vkTL7UaHtT\/2oRrKvVAQASd5zwgARI+XcLqVq5cae8mUdIpp5xiQ+6SRNZsLSeh08yZM2sdWrtmzZrUbyR0gpSdiKDznBQVVFwEXUGDJYLOb7DWr19vevfunTHnBid333\/\/\/YkIs+Ok8X322cd2MEjA\/EZfODsRmT59uunQoUMNgs4PGZUWAkIgKQisWLEiEarU20gMWQkFIrvssstsi+wePOyww2xcMaequFO9L7nkEnPuueeWUKv0TXHaOKF0yEsvvZQ2tM9ZzXfddZftixPKS4SAEKhMBDp16pQIxUtO0M6nS4J+Ft2aNGligfj222\/NCSecYCBFrGhcCuWWDz\/80HTp0sWqwTZ0Xii+4Kpp1aqV\/SmdC6Tc+qt9ISAEKhuBkhM0bgBiiC+66KLUad4Owuuuu87ccsstNin\/okWLasUWlxpqNqW0bdvWNvvYY4+Zli1b1lCBXYUdO3a0v6VzgZRaX7UnBIRA3UKg5ATtXALpTubGSj3ttNMswsQfJ2G7t9N3woQJpnv37jVGn92PWP3I4sWL7YtFIgSEgBCIC4GyETQLgUE\/D455jrtKEkFfcMEF5pFHHrHkDEn74nYYkjtk8uTJcY2J6hECQkAIWARE0DkmArmqzzzzTFvKXwjkYIFTTz3V5ua4\/vrrzfHHH68pJQSEgBCIFQERdA44f\/zxR3uQLQmaEHzODRs2tFEnyIknnmjGjRsX66CoMiEgBISALOiQc2DdunV2UdORtLsNtwdpUt0J5MHq8klPGlIVFUsAAhrXBAyCp8JXX31l9yQ0atQoWYrFoE3ZLGh2DgZzKuMuIMwOIfdFOiFr3B133JEKz4sBg9BVfPPNN3YxcMOGDTYUMBsx55ueNJ0SnHS+ZMmSjPpNnTq1VmRJ6M6oYMEIcLBxr169rFsL95akfAi4SCsW6Hk285FKeL7KRtD5ABksW+p0o\/nqWkh60nRt+FvH010njpzDdCWlQwBLjU1UTz31lAi6dLBnbGnSpElm9OjRNoIqX4KuhOer5AQ9YMAAuyklimC1JPVzptD0pEE8Pv\/8cxvlwpdGpgiRZs2aJSpvSZQxTfK9rEM8++yz5p133jFz585NfdXIgi7PqPEF89Zbb9mUv7wokXwJulKer5ITdHmGtHStFpqeNKjha6+9Zk466SRz9NFH2xNnJOVDwE+K5Wshgi7PmLD2s3Tp0hqN50vQlfJ8iaBjnmOFpicNqjFnzhwbPUIcNv8k5UMAC3rGjBnGpa15\/PHHDalmRdDlGRN29boTjZYtW2amTJmStwVdKc+XCDrmOVZoetKgGljNnIFIrDV+TywGoknatGljiaFz584xa67qwiLg1hhE0GERK145zjQ966yz8iboSnm+RNAxzp0o6UmDahDWN3v27IzasSX+yiuvjFF7VRUWARF0WKSKX65Qgq6U50sEHeMcipKeNKgG1hkJo8igN2LECJu06euvvzbkMGHrOQJR9OjRI8YeqKowCIigw6BUmjKFEnSlPF8i6BjnUZzpSZ2fjXzURGv4wtFbZM9r3bp1rc0zMXZHVWVAQASdnKlRKEFXyvMlgo5xrpUqPamblKhOuFGSjgiLEc7EViWCTs7QFErQ2XqQpOdLBB3zXIsjPSlRAxwGwAni6ciX01pYPESSkpY1ZhgTXZ0IOjnDUwhBV9LzJYKOea7FkZ503rx5drcasZ3EawbzYpP2lM06cnHEPHghqxNBhwSqBMUKIehKer5E0DFPonzTk3IOI6ebI+QG2GabbYzb5cRvQ4YMMficneDS6Nmzp01zytmOZ599dsw9UHW5EBBB50KodNdzEXSlP18i6JjnUr7pSdmuCjEj8+fPN82bN7f\/73Yk8v\/t27c3++23n\/nss89Si4JsASe7nvzPMQ9giOpE0CFAKlGRXARd6c+XCLoIEymf9KTsSOvTp08tgoboOZ9x\/PjxtTQkRGjkyJG1sgEWoSuqMg0CjqCVC7z808MRdOPGjQ05OoJS6c+XCLqIcyxsetJsKlDH8uXLzaeffmp23HFHwyJkME1rEbugqoVAnUYg6c+XCLpOTz91TggIgUpGQARdyaMn3YWAEKjTCIig6\/TwqnNCQAhUMgIi6EoePekuBIRAnUZABF2nh1edEwJCoJIREEFX8uhJdyEgBOo0AiLoOj286pwQEAKVjIAIupJHT7oLASFQpxEQQdfp4a2+znGqTSGnxjds2NCsXbvWfP\/992arrbYyW2yxRfWBpx4nDgERdOKGRApFQeC2224zY8eOzbuKMWPGmJtuusmQXCeYoCrvynSDEIgJARF0TECqmmQgcOutt5px48blrcyoUaNs7hMRdN7Q6YYiIiCCLiK4qrr0CHzxxRdmzZo1tRo+5ZRTzOrVq83+++9vRo8eXet606ZNbXZA7u\/UqZMtJxEC5UZABF3uEVD7JUGge\/fuZunSpebggw829957b0naVCNCICoCIuioCOr+ikAgDEFPnz7dnpzeuXNns\/fee9t+cQDDwoULzR577GG6du1qyC9MikuyCx5++OH2384772yt9jlz5tiUl1jh++67rznqqKPsaezpZPHixea5556zJ7evX7\/e5vvGcu\/QoUNF4CklS4OACLo0OKuVMiMQhqAPOeSQWj7oYcOGmWnTplnShrwh1KBgkV9xxRVm5cqVta7NnDmzhrtkw4YNZuLEiRkXMvv162eGDh1a65izMsOn5suEgAi6TMCr2dIiEJWgnbbHHnusOfTQQ+1hvRCtL0cccYThH9cmT55sL3Xs2NE88MADqWJ33323ueqqq+zfvBBOOukke0AwVjk+cIQjzdL5yUuLmFpLAgIi6CSMgnQoOgJxEDQHAvPPycCBA83cuXPtn5yKgxXthP+\/77777MG\/WN316tWzro8uXbrY8yRZtLz66qvt7078Y85efvll06RJk6LjogaSjYAIOtnjI+1iQiAOgn7zzTdrbGDxQ\/rwTe+0004pbf2z8Dh2idNwIGxH4vi1gyfj+IcFY2X37t07pt6rmkpFQARdqSMnvfNCICpBt27dOuWCcA3jusBfjHAsWf369VM6sVjYq1cv+zfuixYtWlhydlY11nM6ufDCC+3Pp59+uhk+fHhefVThuoeACLrujal6lAaBqASNb\/mOO+6oUbMjaNwYRGX4ko6gcYNgTYcR+aHDoFT3y4ig6\/4Yq4fGmKgE3a1bt1qLgvkSdN++fW2YHjJo0KCs49KuXTvrr5ZUNwIi6Ooe\/6rpfRIIeuTIkalNMiwckpQpKPihf\/zxR+ufTne9agZMHbUIiKA1EaoCgSQQ9NSpU1N+5UmTJtmNL74QR40rBZkwYYK1+iXVjYAIurrHv2p6nwSCZqMLBExOkPbt21uftgul++yzzwxhe\/iu8WkvWLDA\/ldS3QiIoKt7\/Kum90kgaMAmbhoiRiBgtnivW7fOEMJHfDSSzrqumoFSR2sgIILWhKgKBI455hizZMmSrMmSsG5xM\/j5oF1oXLpFwgcffNBccsklpnHjxtby9SVdFIe7\/uKLL9oNL1jSvuy2225m8ODBNoeHRAiAgAha80AIlAEBrOZ3333XvPXWW6ZBgwY24RJuDz+WugxqqcmEISCCTtiASB0hIASEgENABK25IASEgBBIKAIi6IQOjNQSAkJACIigNQeEgBAQAglFQASd0IGRWkJACAgBEbTmgBAQAkIgoQiIoBM6MFJLCAgBISCC1hwQAkJACCQUARF0QgdGagkBISAERNCaA0JACAiBhCIggk7owEgtISAEhIAIWnNACAgBIZBQBETQCR0YqSUEhIAQEEFrDggBISAEEoqACDqhAyO1hIAQEAIiaM0BISAEhEBCERBBJ3RgpJYQEAJCQAStOSAEhIAQSCgCIuiEDozUEgJCQAiIoDUHhIAQEAIJRUAEndCBkVpCQAgIARG05oAQEAJCIKEIiKATOjBSSwgIASEggtYcEAJCQAgkFAERdEIHRmoJASEgBETQmgNCQAgIgYQi8P+lcgR3QQYwdQAAAABJRU5ErkJggg==","height":337,"width":560}}
%---
%[output:767872c1]
%   data: {"dataType":"text","outputData":{"text":"Stat 1: theory = 2, sim = 1.882, discrepancy = 5.922%nStat 2: theory = 1.333, sim = 1.199, discrepancy = 10.073%nStat 3: theory = 1, sim = 0.9306, discrepancy = 6.936%nStat 4: theory = 0.6667, sim = 0.5995, discrepancy = 10.073%n","truncated":false}}
%---
