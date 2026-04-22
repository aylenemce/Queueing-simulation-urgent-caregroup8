%[text] # Run samples of the ServiceQueue simulation
%[text] Collect statistics and plot histograms along the way.
PictureFolder = "Pictures";
mkdir(PictureFolder);
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
rho = lambda / (s*mu);
% PROBABILITIES Pn (0 to 10)
nMax = 10;
P = zeros(1, nMax+1);
P(1) = 1 - rho;
for n = 1:nMax
    P(n+1) = (1 - rho) * rho^n;
end
  
%%
% calculating 2.1

a = lambda / mu;
L_sim  = rho / (1 - rho);
Lq_sim = rho^2 / (1 - rho);
W_sim  = L_sim / lambda;
Wq_sim = Lq_sim / lambda;

% Convert to minutes (optional but usually required)

%%
%[text] ## Run simulation samples
%[text] This is the most time consuming calculation in the script, so let's put it in its own section.  That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%[text] Reset the random number generator.  This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.  This is a good idea for testing purposes.  Under other circumstances, you probably want the random numbers to be truly unpredictable and you wouldn't do this.
rng("default");
%[text] We'll store our queue simulation objects in this list.
QSamples = cell([NumSamples, 1]);
%[text] The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.
for SampleNum = 1:NumSamples
    if mod(SampleNum, 10) == 0
        fprintf("%d ", SampleNum);
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
end
%%
%[text] ## Collect measurements of how many customers are in the system
%[text] Count how many customers are in the system at each log entry for each sample run.  There are two ways to do this.  You only have to do one of them.
%[text] ### Option one: Use a for loop.
NumInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end
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
fprintf("Mean number in system: %f\n", meanNumInSystem);
%[text] Make a figure with one set of axes.
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on");
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers");
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r');
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system");
xlabel(ax, "Count");
ylabel(ax, "Probability");
legend(ax, "simulation", "theory");
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.2$.
%ylim(ax, [0, 0.2]);
%[text] This sets the horizontal axis to go from $-1$ to $21$.  The histogram will use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [-1, 21]);
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.pdf");
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.svg");
fprintf("Mean number in system: %f\n", meanNumInSystem);
%[text] 
%%
%[text] ## Collect measurements of how long customers spend in the system
%[text] This is a rather different calculation because instead of looking at log entries for each sample `ServiceQueue`, we'll look at the list of served  customers in each sample `ServiceQueue`.
%[text] ### Option one: Use a for loop.
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


%[text] ### Option two: Use `cellfun` twice.
%[text] The outer call to `cellfun` means do something to each `ServiceQueue` object in `QSamples`.  The "something" it does is to look at each customer in the `ServiceQueue` object's list `q.Served` and compute the time it spent in the system.
%TimeInSystemSamples = cellfun( ...
    %@(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    %QSamples, ...
    %UniformOutput=false);
%[text] ### Join them all into one big column.
TimeInSystem = vertcat(TimeInSystemSamples{:});
%%
%[text] ## Pictures and stats for time customers spend in the system
%[text] Print out mean time spent in the system.
meanTimeInSystem = mean(TimeInSystem);

fprintf("Mean time in system: %f\n", meanTimeInSystem);
%[text] Make a figure with one set of axes.
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60);
%[text] Add titles and labels and such.
title(ax, "Time in the system");
xlabel(ax, "Time");
ylabel(ax, "Probability");
%[text] Set ranges on the axes.
ylim(ax, [0, 0.2]);
xlim(ax, [0, 2.0]);
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.pdf");
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.svg");
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
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);

h = histogram(ax, Lq_sim, Normalization="probability", BinMethod="integers");
title(ax, "expected count waiting");
xlabel(ax, "Time");
ylabel(ax, "Probability");
%[text] Set ranges on the axes.
%ylim(ax, [0, 0.2]);
xlim(ax, [0, 2.0]);
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Expected count waiting histogram.pdf");
exportgraphics(fig, PictureFolder + filesep + "Expected count waiting histogram.svg");
%%
>>>>>>> 2f236e94cb224adf6503589c81ef3ded102353de
%[text] Average Value Estimates: 
%[text] $lambda$ = $2$
%[text] $mu$ = $3$ 
%[text] $s$ = $1$
%[text] $p$ = $\\frac{lambda}{s \* mu}$ = $\\frac{2}{(3)(1)}$ = $\\frac{2}{3}$
%[text] $P\_0$ = $\[$$\\sum\_{n=0}^{s-1}$$\\frac{(lambda/mu)^n}{n!}$ + $\\frac{(lambda/mu)^s}{s!(1-p)}$$\]$$^{-1}$
%[text] for $n = 0:$ $\\frac{(2/3)^0}{0!}$ = $0$
%[text] for $n = 1$: $\\frac{(2/3)^1}{1!}$ = $\\frac{2}{3}$
%[text] for $n = 2$: $\\frac{(2/3)^2}{2!}$ = $0$
%[text] for $n = 3:$
%[text] for $n = 4:$
%[text] for $n = 5:$
%[text] for $n = 6:$
%[text] for $n = 7:$
%[text] for $s = 1$: $\\frac{(3/2)^1}{1!(1-(3/2))}$ = $-3$
%[text] $P\_0$ = $\[$$\\sum\_{n=0}^{s-1}$ $0$ + $-3$$\]$$^{-1}$ = $\\frac{-1}{3}$
%[text] $L\_q$ = $ \\frac{(lambda/mu)^s \* p}{s!(1 - p)^2} \* P\_0$ = $ \\frac{(3/2)^1 \* (3/2)}{1!(1 - (3/2))^2} \* \\frac{-1}{3}$ = $-3$
%[text] $L$ = $\\frac{lambda}{mu} + L\_q$ = $\\frac{3}{2} + -3$ = $\\frac{-9}{2}$ = $4.5$
%[text] $P\_q$ = $Busy \* P\_0$ = 
%[text] $W\_q$ = $\\frac{L\_q}{lambda}$ = $\\frac{L\_q}{3}$ = 
%[text] $W$ = $\\frac{L}{lambda}$ = $\\frac{L}{3}$ = 
%[text] How do these compare to the simulation numbers:
%[text] L = 2
%[text] L q =1.33
%[text] W theory = 1.000
%[text] W q = 0.667
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":21.7}
%---
