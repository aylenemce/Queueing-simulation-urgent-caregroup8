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
NumSamples = 100;
%[text] Each sample is run up to a maximum time.
MaxTime = 8;
%[text] Make a log entry every so often
LogInterval = 1;
%%
%[text] ## Numbers from theory for M/M/1 queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
rho = lambda / (s*mu);
P0 = 1 - rho;
nMax = 10;
P = zeros([1, nMax+1]);
P(1) = P0;
for n = 1:nMax
    P(1+n) = P0 * rho^n;
end
  
%%
% calculating 2.1

a = lambda / mu;
Lq_sim = (P0 * a^s * rho) / (factorial(s) * (1 - rho)^2);
L_sim = Lq_sim + a;
W_sim = L_sim / lambda;
Wq_sim = Lq_sim / lambda;

theory = [L_sim, Lq_sim, W_sim, Wq_sim] %[output:3edb338a]

%%
%[text] ## Run simulation samples
%[text] This is the most time consuming calculation in the script, so let's put it in its own section.  That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%[text] Reset the random number generator.  This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.  This is a good idea for testing purposes.  Under other circumstances, you probably want the random numbers to be truly unpredictable and you wouldn't do this.
rng("default");
%[text] We'll store our queue simulation objects in this list.
QSamples = cell([NumSamples, 1]);
%[text] The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.
for SampleNum = 1:NumSamples %[output:group:9e44deab]
    if mod(SampleNum, 10) == 0
        fprintf("%d ", SampleNum); %[output:574bd9fa]
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
end %[output:group:9e44deab]
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
NumInSystemSamples = cellfun( ...
    @(q) q.Log.NumWaiting + q.Log.NumInService, ...
    QSamples, ...
    UniformOutput=false);
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
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:7f6f9946]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:2fc4ddf7]
t = tiledlayout(fig,1,1); %[output:2fc4ddf7]
ax = nexttile(t); %[output:2fc4ddf7]
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on"); %[output:2fc4ddf7]
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:2fc4ddf7]
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:2fc4ddf7]
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system"); %[output:2fc4ddf7]
xlabel(ax, "Count"); %[output:2fc4ddf7]
ylabel(ax, "Probability"); %[output:2fc4ddf7]
legend(ax, "simulation", "theory"); %[output:2fc4ddf7]
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.2$.
%ylim(ax, [0, 0.2]);
%[text] This sets the horizontal axis to go from $-1$ to $21$.  The histogram will use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [-1, 21]); %[output:2fc4ddf7]
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.pdf"); %[output:2fc4ddf7]
exportgraphics(fig, PictureFolder + filesep + "Number in system histogram.svg"); %[output:2fc4ddf7]
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:5e02bc12]
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
TimeInSystemSamples = cellfun( ...
    @(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);
%[text] ### Join them all into one big column.
TimeInSystem = vertcat(TimeInSystemSamples{:});
%%
%[text] ## Pictures and stats for time customers spend in the system
%[text] Print out mean time spent in the system.
meanTimeInSystem = mean(TimeInSystem);

fprintf("Mean time in system: %f\n", meanTimeInSystem); %[output:785bedcf]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:9af376cf]
t = tiledlayout(fig,1,1); %[output:9af376cf]
ax = nexttile(t); %[output:9af376cf]
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:9af376cf]
%[text] Add titles and labels and such.
title(ax, "Time in the system"); %[output:9af376cf]
xlabel(ax, "Time"); %[output:9af376cf]
ylabel(ax, "Probability"); %[output:9af376cf]
%[text] Set ranges on the axes.
ylim(ax, [0, 0.2]); %[output:9af376cf]
xlim(ax, [0, 2.0]); %[output:9af376cf]
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.pdf"); %[output:9af376cf]
exportgraphics(fig, PictureFolder + filesep + "Time in system histogram.svg"); %[output:9af376cf]
%%
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
    WaitingCountSamples{SampleNum} = ...
        cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served');

end

%%
%L_q (expected number of customers waiting)
fig = figure(); %[output:7c0fcf91]
t = tiledlayout(fig,1,1); %[output:7c0fcf91]
ax = nexttile(t); %[output:7c0fcf91]

h = histogram(ax, Lq_sim, Normalization="probability", BinMethod="integers"); %[output:7c0fcf91]
title(ax, "expected count waiting"); %[output:7c0fcf91]
xlabel(ax, "Time"); %[output:7c0fcf91]
ylabel(ax, "Probability"); %[output:7c0fcf91]
%[text] Set ranges on the axes.
%ylim(ax, [0, 0.2]);
xlim(ax, [0, 2.0]); %[output:7c0fcf91]
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture.
exportgraphics(fig, PictureFolder + filesep + "Expected count waiting histogram.pdf"); %[output:7c0fcf91]
exportgraphics(fig, PictureFolder + filesep + "Expected count waiting histogram.svg"); %[output:7c0fcf91]
%%
% hello
%[text] Average Value Estimates: 
%[text] $lambda$ = $\\frac{1}{1.25}$ = 
%[text] $mu$ = $\\frac{1}{6.5}$ =  
%[text] $s$ = $1$
%[text] $p$ = $\\frac{lambda}{s \* mu}$ = 
%[text] $P\_0$ = $\[$$\\sum\_{n=0}^{s-1}$$\\frac{(lambda/mu)^n}{n!}$ + $\\frac{(lambda/mu)^s}{s!(1-p)}$$\]$$^{-1}$
%[text] for $n = 0:$ 
%[text] for $n = 1:$
%[text] for $n = 2:$
%[text] for $n = 3:$
%[text] for $n = 4:$
%[text] for $n = 5:$
%[text] for $n = 6:$
%[text] for $n = 7:$
%[text] $total$ =
%[text] $P\_0$ = 
%[text] $L\_q$ = $ \\frac{(lambda/mu)^s \* p}{s!(1 - p)^2} \* P\_0$ = 
%[text] $L$ = $\\frac{lambda}{mu} + L\_q$ = 
%[text] $P\_q$ = $Busy \* P\_0$ = 
%[text] $W\_q$ = $\\frac{L\_q}{lambda}$ = 
%[text] $W$ = $\\frac{L}{lambda}$ = 
%[text] How do these compare to the simulation numbers:
%[text] L theory = 2
%[text] L q =1.33
%[text] W theory = 1.000
%[text] W q = 0.667


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":21.7}
%---
%[output:3edb338a]
%   data: {"dataType":"matrix","outputData":{"columns":4,"name":"theory","rows":1,"type":"double","value":[["2.0000","1.3333","1.0000","0.6667"]]}}
%---
%[output:574bd9fa]
%   data: {"dataType":"text","outputData":{"text":"10 20 30 40 50 60 70 80 90 100 ","truncated":false}}
%---
%[output:7f6f9946]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 1.266996\n","truncated":false}}
%---
%[output:2fc4ddf7]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAARoAAACqCAYAAAByDoB7AAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQvcn2MZx+9NSWJO04piyyhGoaOkTGk0IZtSUTnkTGYYCUMqhikblsMUlWojUrPWYSsqh+QQli02pGi2qNbayvK9df273nvP+fD\/P\/\/3va7PZx\/e932e+3nu677v33Odr34rV65c6YyMA8YB40CNHOhnQFMjd21o44BxwHPAgMY2gnHAOFA7BwxoamexPcA4YBwwoLE9YBwwDtTOAQOa2llsDzAOGAcMaGwPGAeMA7VzwICmdhbbA4wDxgEDGtsDxgHjQO0cMKCpncX2AOOAccCAxvaAccA4UDsHDGhqZ7E9wDhgHDCgsT1gHDAO1M4BA5raWWwPMA4YBwxobA8YB4wDtXPAgKZ2FtsDjAPGAQMa2wPGAeNA7RwwoKmdxfYA44BxwIDG9oBxwDhQOwc6DjS33nqr+93vfuc++MEPuo033rj2CdsDjAPGgfZzoONAc\/3117sTTjjBz\/xtb3ub+9CHPuR22203t84667SfG\/ZE44BxoBYOdBxofvCDH7hjjjlmlcl94AMfcHvuuad7z3ve4172spfVMnkb1DhgHGgPBzoONEzzySefdD\/+8Y\/d97\/\/ffeb3\/ymx8xf8YpXuFGjRrm99trLbbvttq5fv37t4Yw9xThgHKiMA40AGj2bP\/3pT27WrFkOSefOO+\/sMdHXvOY17pOf\/KSXdDbccMPKmGADGQeMA\/VyoHFAo6f75z\/\/2f3kJz\/xks4dd9zRgxMYjw855BC3zTbb1MshG904YBwozYFGA42oVFHSjcx8p512cl\/72tdKM8IGMA4YB+rjQOOA5o9\/\/KO319x8882r2Gs22GAD75Xaaqut3A033OB+8YtfeM488sgj9XHIRjYOGAdKc6ARQPP444+7H\/3oR15Fuu+++1aZ1D777OP23ntv9453vMO95CUvaf0doMFmY0BTeh\/YAMaBWjnQcaD54Q9\/6I4++uhVJjl8+HAPLrvssovD8xRFzz\/\/vBs6dKgBTa1bxAY3DpTnQMeBRgfsvfGNb3RIL7vvvnsmr9I\/\/\/lPd+aZZ7ovfelL5TlhIxgHjAO1caAtQIPdRWjttdd2AwYMaP18++23u1\/\/+tc+BeF1r3tdbRNt18D\/\/ve\/3VNPPeWeeOIJt3TpUveGN7zBvfrVr27X4+05XcAB9shvf\/vb1ptutNFGHU2\/WbJkieOdoDXWWMNxRqumtgCNBpCjjjrKjR07tjUPcp2uuOIKt8cee7jRo0cnzm\/SpEnurrvucuPHj3eDBw+umhelx3v00Ud9lPODDz7YGuv444+PVA1LP6yNA\/zjH\/9wzz77bOuJgwYNcquttlob36B3Pepvf\/ube9Ob3tSa1JgxYyKj46ucNaEimBqg9dZbz7385S9vDU8U\/ty5c\/3PI0eOdBdffHGVj\/ZjdRxoRHUKASicKYhLoB4MmTp1qk9NaBp97GMf89KZpt4ANFq9ZW5IoRYwWXz3tRtokK7f\/e53t174kksu8fmEQr0WaFAtFi5c6OdJJDCMwHWdpDrhmQKVoa9\/\/evuXe96V\/GVruHO\/\/znP27zzTfvMTLqIF+I97\/\/\/TU8sX1DGtBUy+sQaE4++WR36KGHVvsQNdqCBQu8U0Wo0UCzcuXKF0WgmFwjDlqcOB2qTkT7iqiWl7vYO376058WSrTEeKxFxqzPfvrpp\/3zkjLKFy9e7N7ylre0hiwjyYi+rF35Wd8173WoRTwvaW55gYa9wEdh\/fXXL8Rv5pC0n5L+FiUJr1ixotB7oGpwb1RS7\/Lly91zzz3n1ZAiaiTjCrHOWXL4\/vWvfxXa90WBBj4zzzxnBp5oG6zMsd8BBxywErvCW9\/6Vv87SjZgHIJIZHzVq17lbrzxRh\/nsmzZMjdixAi37777ure\/\/e2+jsxVV13l1QU2Fl6jY489tgd6Mk4INBxKUgoee+wxv5CA2Gtf+1qHCBdFxMkATH\/5y18czEb64flIC3ioNCHtEPAHbb311u7AAw901113nbvpppv8vT\/\/+c8znUXGYG7333+\/4zBCPHf77bd3gMjrX\/\/61jgXXXSRwz5DHJAQOjjX7Ljjjt7QnUbwHN347rvvbsUSwft3vvOd7uCDD3Zbbrllawg2zumnn976mTkSDiCE9Hfqqae2ftbryy+JuOadf\/azn7lnnnmmdd2b3\/xm99GPftSrqGz+RYsWufPPP9\/94Q9\/6BE8yXzYfKecckoLoNiUV155pSNcQcdCDRkyxMc\/sa84lJrg72233eZ\/tcUWW7gPf\/jDDlC75ZZb\/DPf+973+vXFEwl\/eOdf\/vKX\/m+M+5GPfMSnofTv37\/HuOwp7H4zZ85svctmm23mmN\/+++\/v94UmJAp4ArG3CZn47ne\/69cTafScc87xf+NDxbj8DSlciHfhPniXpbwJ4xx22GGt+wnjYI4Q8ycSHuJMcN306dM9T7D9EeqB2eAzn\/nMKhJ01B6DZw888IBP5RFiPTbZZBPPv+22286fO22jIdzki1\/8ol9z9j68Q9XibL\/0pS9d5TEzZsxw3\/rWt7yBm+ujzme\/IUOGrLzsssta4j2AI5uPw3LvvfeuMjCTxaXMAskh1Bede+65nvFCGmhYFA5lFMHw8847rxWUx4YZN26c+973vhd5Pb8MJQfe6Tvf+Y6\/HoYyhmSEk5SZBjR83Xl\/Dk0S8Z5ivAYMRK0L7wEETjvttMSxWCBEZ33owxsmT57cAtWHHnrIg6yQfhd+x3hkvAvp9Q3vjXoxDgyHC8BKsoVhyMdjAiCxDvwcR4DmpZde2sMIyj2ytvydtYriwRe+8AV37bXX9jCyy3M4oIChEIABL7VBPnwnUlZIXRHS68fc+SjJvhZe8KUmKj1u7zIWEet81NZaa63E9U6y0cB32XscWKSDuGci2ac5RZL25pe\/\/GX\/EdRAwzMRKKLONdjAOgjY5DmfiUCTyK2EP\/KyfHnkhfK4rS+44AK\/oBDSCR6mNPrc5z7nDjroIH+ZBprwvixA8+1vf9t\/qbMQXx4kDRaKQxkuDoD8qU99qoeXLRwXKQtpJA6o9PXwlANZBmiQEvTG5XDwhQ038ze\/+U3\/RdUHUr8Lc5szZ45XjzRgJPGNfQHQiyie9b60tSDbn68uhATAz2lECot4fpIOowAN8Vo6p469hPctLGuSxYOUFWjS5sCH+cILL0y8LFxvfTHSGbYbDTRpz8TzK5pHnvOZCjQcdF4WcRjPkCZ+j4iOHocIq8VJRD3EYSgEGpARYHjlK1\/prr766h4qB94MJBIOLaI0sSgQv0e6oSYNqhQLKgebRWfTo+dGAQ2xLIiIHJzDDz88lpeMt\/POO\/f4qiINME\/m+NWvftXxFRDCks\/7Q7h\/eYYQfPvEJz6Rtm5ePfv85z\/fY0x4yrugSqHeCAkIFwWaUFfX0iAHRkuh2guYZKNBfUbVEmItpkyZ4gEYSQfQ1mK7NnyGQMN6AxRID0cccUQP8AVgGXfgwIFe2kJFE4J\/4vHjv0KA5IknnujVBIAFsBASAOHnKKDB2YBxH1UZ6VFL+lSCRHKBkKD222+\/1t4HvHhWEuUBGuEn6hx7Qe9ftAPN27hn5rHRMAbzhadrrrmm3+8Yj4XgL39DlWX\/yxlkfVC34A3qcHg+E4GGA6oXFIbqcg3kGkmdX8Q90WV5KfRKOXhREg2bCvUrKgUBIxygoQ1k2HHkZ56LTqgZgN6MDh4CDTo5hz7U46MWhYXEHiIU9XUKecABxfZQFGhClzj85TBB2KSwRYWLXBRoQlBgcxx55JFuhx128DYPbG1IWBDrKh+KJKBBzQQAhFgX\/c6ABh8HIb2nQqBB5RMbByA7ceLE1n18ufmCQ6jzIvXys4AX1+sYEJE4ZRDu1\/YjbBdIVyHQiEqh90i4h7GRcNCGDRvmbUYikaI2ib0z7uDnAZqQn8xbmzOy5PnlBRrAi\/0QtQdFikJN1h\/S8MOKOqvPZyLQoL\/pL3h4iGGwHH4MZzA\/asPpRRLAEKDByIxOrYEgCmgYVzxffGU4hFqCkq9a+I4YdbOqbqF0oaUymdc3vvGNHjYXAdSiQKO\/lBjTk+xR8g5Fgebvf\/+7N9hHEaoQYjRrjiqnPSlJQMPaifGdMTCeh4RxUX+wHn74YW+H00AT3hs+E7uJGHEJicDIHn4Qwudgo9OkDfv8XtZXA03cHDCchoXYZGykH6QA\/qXZZ7gnD9AAjHpMjOrwRqhqoOHjg4quiZpPIrmgNqE+heeAD8i6667buo2zqc9nItCEhjZsIejuULggIdBg6xBk1wcdkRURHVWIryYiGOqH\/hIhSYDCaSKoZgYi+qc\/\/elVJBrZ1HFfF\/37M844w11zzTWtX4m0oq8BGLX4Kl+\/IkCD9KC9SSGwx71zUaBhvGnTprmTTjopkR2sGyqjeImSgEbbAEIJWB5y9tln+yBLIZGENdBgv9EHOdxPGvRDoBEVkOjyJCNwOGn5SGigiatvhDSIYT\/JYM8hRb0OvVrhc7MCTRTohR\/SqoFGgES\/s\/4Yyt9DSTbtfLUdaKIMWIhY2nOAZRvxcMKECa335xBGudbkAtxv73vf+3oATbh505gRiuvYfbDraAoPqgQPFgEaPFyinvAMJIk0bxfXhUATevnwRmAzE9JeJ37H5kTVJGwhzgitPzJJQKNVv6ivIc8Lv8KislQFNIyPCkjJEKlRxCElFCOJuIePoAaa8OOq70ci5EOLdBUHaPBg9uzZbvXVV499dJOBJioFIQpo8CDmOZ9tBxo2ACCiVaXQ7oGO+Pvf\/95vHqEoNSZqJTXi5wWa0F5EDII2dPK88IsiX+ciQMN46PkiYoYHFfsGNiMJ4Nt11109TwAKQFUIlVWrrXxVdUa7AA2GS0lwhf+ooEiO2IWQ1LThmXVCbEc1TgIadHPAVgivEgZMId4dlSxqjlUDzVlnndUyzuv3T\/vApAENAAO4CxEfhTRK3h084+OjKbQNhc\/vDUDDecxzPmsDGjHOwuTQRsImIEsUwpsD44XY2IjsBIDpRD6+EJJVCiDgatTuRlQejI5lgIZDqN25HBg8YAAAFHpm+DtfLw5tUaAJ7Qra6BnqwRwkjNuhkRhPB14QIlhRKwBHLeIL0KDmaZubdvEyvxDwRe0MgYY548mBQnBGtMY7JtG0IeiJbY57qwIaPEt4qUJ+oQoj5cg+I9RAbEjsPwnBSAMaroPvQngFtdMglIRDA27TgEaHkPBuablOURINgoAOlmWMr3zlKy0BAg1Fn8+OAA2Tw+Cb5gkKrxEjMZucuBUhLa6WARrGC+0JgCIub4KYQleijikoCjRhcB3vgHGR6GktnvMeSAtiNwk9JfAANS\/KYClAE3rVkPg4iAA4EodW29hc2NkgVIXjjjuuxW\/AmK86Ece4QFFrdUoJAIybk3y2MM5EeyqrBhokQFRorQ5KhDZSho5z0ip8GtBgR8SjqQl7Dfvwr3\/9qw9i08AOmMUVa2OMdks04QeUmCMkaQJOJQ4sKXs7CmiYRxizxLqzd0m61XFZ7M3agCbNvR2iPD+Tx4QXQ76GLAhfeHG5Rt3DgiK6iys9CmjwVhHTkaXWBpuKry4etSQCwfmSidetKNDwDNQenb4Q9VwdGczfsRVgnM9CAjQANZsjS+wFh4cDCIUbVZ4pkcGAJa7OqGhS\/X6hC7QqoMG4LQb6UPqI4g+uWyRugg2hNKDhmssvv9zHiaRRlhy3dgMN76xVdJlDVGRwVhsNYyBZoxYnrbucz8JAk+YliAMaxFwOsXbR8dJ8iQilD92DAATxEYijIfHVRAzUPbtDoEGk5n5hBp4RbB18jeOSFomUJSZIPGzhc\/mK60QzAgkZs0jAHmMDAKgYzD8k+Mzf9NhyDb8H7PRCY7shJ0XblrQxWMA7rnMEkcLwMMyOx\/iH0V4\/S4BGwIhDFiVRMQfeM3Q3ayNx2n7SYQqh10kDDe+CPQXJNCzZwd8ARNZLr18WoGGNAF8MoFEHi\/dnT6FipUnq3K\/bBOn31ykIUV4n7fllPlm8TlwH\/wBKLWkI0GhvXRTQaP6Ezpys57Mt9WiivgIYCefNm+dVEiIw0+IPkBjmz5\/vVSbya4iUlC9S3FcmdMGxGUTERWqB8UlZswAOoPjZz37WG0bZQDpwUJ5bVZq\/PI\/Ng\/TFoQdEk96R90FFQRJDdM1aJ0YMnPCT8bkPiRJ7WtzzkCzJZJeMZkTiMHOZ92CdeCfGZJ1YryzZyWnSQt6\/Y\/yGl6ihSDHMLUmlyTI+c8c+wYGFH+xB4VvTWzdj96REC2cODy6BoXkys5P4k3Y+2w40fPlZIJCTLws6u840zrLYSEtpBwpDphT3IZxeMk+lcwLPCZMR457NOwM42CqisnP5XVRqfJa52DXGgb7AgbYDjXigdGRwUv5R1CJog2LcIpHxS9IYkbCoaVqclb8hysepRzKuFLSKixjtC5vE5mgcKMuBtgMNhltEN9QC7ACIthLCnnUyBImlqVq4MvHSRKk1Ok\/jnnvuSZRGxBCqvTBZ39OuMw4YB17kQNuBpl2MFwOWjueRZ2t3ZVouFAZFgA3ph9BybDVY23HvYsknnaJIhbV28cGeYxxoAgcaCTQYRaUUZJaKZSEjuZ+sWigKSHR9X52TFbUgABW2pDgiTgMpLWxRQSyBkM5mbsKi2zsYB9rNgcYADSoKLlBiPHTwE7YRXLskTKJqZfFeYLjFgAvFVewXWxFBaroMZrgAOt2dOBB5B3qDSxmD0OXHM0kehbLYgdq96PY840C7OdAIoAmTAOOYwCGn9kmaS06XoJSqdHpMXJRS8zdKtdLXEoyGOxMJScc+cI0uK6EzvQVo0kLR273Y9jzjQKc40HGgQUVC+pAgKKQDgs4ok4gKRAFzcnIklJ1wd5IdkyQbHRAVlYxJkBHBfnGqVdbF0NHA5BrJmAY0WTlo1\/UVDnQcaIi2lIr+SfYSXZ80zYDL4olqpPORZFF1hba0vBTADoqSouIkIwOavnJ8bJ5ZOdBxoCHqFmmA0PC0QuRSilFnOMdNVPKHogr5SMSwrvkbNY6WfKJS\/wm3p\/IaZKpT1i1n1\/VFDnQcaCR3I0y9j1oMKamgux7ELZrOVNYGXyqlYahFvdKARUoEuUN4pOjlIzYcqSBHlDHGXwkzJ6wdcCTDOixYFSXR8DvUuBBMyQyHKGkg\/98XN6LNuXdzoONAIzVEoiSPkPWSrq7rx8YtD8BBaQOpVYv9BFe5tOIIK6lpu44uTo2aJu1KySWiRAJgpL1jNCrT7XBDoKH6PgCzqXPuROccdd9opUabvpkvlEWljiANgrkGwDEyDvQ2DnQcaMjERYLgoEfZU2A4oIHrm38kRnKQ0zJkuY+iWmQU68LY\/B5QIwtX21107E1YBZ\/7KX4elr0kupliP2FhLw00IsVMd8692Iswmig3Tcs3A5vedsRsPnCg7UBDyciwvgx9YKS7JB4nuiOSEUtRITKBcVFLmwwOInaRPJmylEbA6EuqPwWM0tzjUVsD0CI+B9c51d7JBo5L7BSgQf0CaOY554Zm2G\/znXObG9hk4JRd0m0caCvQhMW4izIrS1Jl0bGruA+gof8O0lqaJBM+TyQbaS1TxfvYGMaBTnOg7UCDp6cs0fuILpdNJYAGw+6gZcvcggIvOfgFm82BZq8pwDm7pakcaCvQNJUJVb+XAM35y5a5nk2Esz1psnPuaNUwL9tddpVxoLkc6CqgwQNEvArZ1GG\/pSaxGKAhxymrbSZ8d7HVmPrUpFW1dynDgcYADYcKQ2tSoWMC7agxE9UbuQwTqr6XdiTE1ixyzm2QcXDaz48PrrUYm4zMs8saz4FGAA1SCoWq0qroCzcJrNMN1JrG5TwSjQCMxdg0bRXtfarkQMeBJqnxfNRECbSjC2NcB4MqmVN0LAGaSS+0pEiy0QjIpHmmLMam6ErYfU3hQMeBRrogUndmzJgxPgNamqmTSCltOKTPL\/2PBg\/GL9NcAmjo4jdgyZJYr5OATFY7jsXYNHe97c3SOdBxoJFC4bpVqrRupR2KJC1KnV\/6MpHgmKUAVvr067lCAvZoyRElrcx2zg13zmJs6mG\/jdpADnQcaCTLWoOKSDn0N9atWKTRFXlGROY2ldIigwGZR52zGJumLqC9V+Uc6DjQACRUoiOXCLc1JAXBqaiH+iREciIdFimvia2mqZSW6wTQjE6x34RzM69UU1fb3isLBzoONHiQMO7Sf4mymnTQI3lR+j7rwlQ0pCf9AFsO7UebSmnZ2wTjZbXNmFeqqats75WHAx0HGt1Anharp5xyiqNcJ8XIUZHItEaFkviZPJOza40DvYUD3V7kvuNAw0bQRb6l0t6cOXO89ymkNddc0y1dutSrW0bGgb7AAUwJSMlpXVWbzItGAA0MotsADKUoOfYXikudc8457uqrr27xTwpPATJ0uDQyDvQFDuCFNaCpeaXpCkkdGKrjDR061F1yySU+BcGApmbG2\/CN4YABTU1LkdSpUmJsDGhqYr4N2zgOGNBUuCRZO1VSOtMkmgoZb0M1ngMGNBUtUZ5OlfS6njx5cqLqpPteV\/SKfW4Y6xfenCU3oKlgLfJ2qqQOLy1q41QnUa0qeLU+PYSpps1ZfgOaCtaiSKdKHpsGNHudO6OCt+t7Qyx65D5325RxpYztdI2gBxfpJfxrJ4l0fNRRR7mxY8fmfjTVBFZbbbVWAXvqPu+4446OVj90Uu0EGdBUwPUinSoNaCpgfMwQVQANGfYAzGGHHebGjRtX38tGjCxAc8ghhzj2Vh6iO8eWW27pCKMgQBQSoCFynVrVnSADmgq4XqRTpQFNBYyvEWiQCpYsWeLWWmstt956tMprH1UBNESo0+IHonMHYENqDL\/vBBnQVMD1Ip0qDWgqYHwJoHn22WcdvbieeOIJ39uKLp1bb711a0T+TllWDubAgQP9Yb333nsdUd1IDKi9d9xxh78P4z5FzLjn7rvvdk8++aTbYost3LbbbusPN4SkQV8vgIv7NTHWM88843Pl6PWVBDS8kzQf3G677XxdIyk3wvPJqyMynRpIxGttvPHGfn7YBInjCutU0175gQcecMR6EeOFAV0Dq8x7wIAB\/u9z587184AP22yzTea6SgY0Fez3vJ0qJQXBbDQVMD9iiDTV6Z577nEHHHDAKmVX999\/f3f66ad70AhVJ61+cIjpiy6EmkJNIhJlAQwhSrXiXQRsqOtDD\/QoO8l+++3nQUt6fUUBDaET9FsHGDXxLpdddplvKiilSfTfTz75ZJ93h41Gq07EeVFtIEyDoXjbBRdc4DuvQjJvWgytvfbavo6Spqy1rw1oCuz1sp0qKdhN8W8DmgLMz3BLGtBQiOzOO+\/0dYL4gvM1ByiI3qakB6U94oBGHk99aDqRkrkv4IL0Q\/Ezvv4TJ070QEZJEHqdlwUayo+Q3gJYSZfTG264wdtcKKSG8RowQurCiC2AgRRCV9MQaKg2wLtvttlm3gYFYOmkX7p10CZZgEbmjd0KSYYzQGdWnoOEk1bEzYAmw8bVl1TVqdJUp5yMz3F5EtDMmzfPjRgxwh8QCsqvvvrqfmSAB8MrQEHWfRLQ4GWUEiBaisAmIjYQul1MmTLFZ\/IzXhmgWbFihSMkgrFR9+RQ61rVgCS\/F2OwttGExmBUO8AUQg3TbZEltAIpiP\/XQHPFFVe4XXbZxd9Hxw\/aPiNhZem6akCTYwNzKUBTtlMlG4R\/JtHkZH7Gy5OAhh7m2FSgXXfd1atQ2DoAHk1xQMN12EGEAKt9993Xqy7UIhKS+5F8UMfKAA1jAjYACWodRmpit371q1959QfKAzT0Uj\/yyCN7qFLy3khEtEKm+iMlTgRopO615hGSE5IU6ldacGRRoOE+ykukjZ9xa5S6rDHZ21lnkZbrJH+3OJqsHO15XZrqFGXL4AvPAeNLnmaj0S5iMvZHjRrlaw5NmkTPiBcpD9CIKpdko1mwYIEjdWXWrFmRLX3yAM3ll1\/uKDsb5bpH3UM1EvAC0EK1S+Z4wgkneLsQpR8AgyQqCjSob52IZYqaSyOB5vnnn\/e6O\/o6ngRNBjTFACTrXWlAwziLFi3ydjION8ZX6cclsStxEk1ozK0CaFDDONBxQIPhls4avCP2GFQWbCvDhg3zHib2WR6gARAvvPBCX+ERA7YmpGyM2CLBJAX75QUakU6yriPXYZdKA7F21bhpDNCwIdDLMZThBhRCX+Yrceihh3oR24Amz1bLf20S0HCQWJutttqq5ZpFLZk+fbq30YhqVBfQ8Nybb765NSn2DIABxQEN0bzYegAZ3ouoX0jfmwdoZG5RAXxIa8cff3xLFew00GRZ\/T4FNCw01fRC92PIKOwCbJiLL77YbDRZdlGBa5KABvcsX3LdGodHEJ+CpFAX0IiRlmdhB8FVDLEP8FAlAQ2F7ImJwf1+1llntTiiqzqGQKNtKqExWOaqn8n\/I4UffvjhDo\/TGWec4ahvXSXQWOGrAptZ34KBePTo0d7NB+HO5GtBMBfAI5X3RDzffvvtfWCXGYNLMj7m9iSgwZCKMZ+14CDtsMMO7umnn3bTpk3z6yeHuWqJhlfFBgTIINXwwXnwwQe9zUUoTqLRlQHIf8JLhPdJ3wswsAcBSlHFAFPsP0jUoZ0FwKLyI4AEuBBIyHMYU1zduMUNaP6\/yTquOkkCHq8U11ObrwXGPP4JGdC0H2h4Ino\/QWl4jDRh0CW+hEMnayoGU+lqga3kuuuua92WZqPRfb3wPAFuIvVK3A2\/B9iSjMHSpFAeDKBQJhYv2mmnneZ\/DfgQ23PllVf6v0EE7O25554efLSqhIQFD3BZa8Ijh\/TEOFDcvPmb2Gjq9DrVs0OKjdpxoJHgJyI3ZYHjpiIeBv6eBjQ7HnZuMY708bueeeR+N3fWtanZ24Tfc8jXXXddt+mmm7pNNtmkLZwjsA6JCok3LdBNvxD3sWdIK8D9LPcScEi4BHPo37+\/vwXJjWdQv1rSIKIHdlnnAAAPlklEQVQmt3jxYvfwww979znBfQIwVTOiqNep6vcoM17HgYavHiInQVrEVCSR\/jKlAU0Zpti98UBuvGk\/BwxoKuC5ZG9naQqHKEvodpJEU8Er2RDGgUZxwICmguVAZ8c1SnIdblId0h2KvrvttlsrZsMqwFXAfBuiKziQBjRknj\/11FM+uxwjdBLhfCEOiizzMEatTmZ0XHXSpTzRnY877jgf9CQMQ\/\/FZUg0JoZA8muWL1+eakOok2k2tnGgnRyIAhpxkGAIx1YmxBk6++yzW\/lk8vvnnnvOG7Cvueaa1rUEUGIb3XvvvWufTseBhhniMcCjoAk3ofTh1r8nzB3mmkRT+96wBzSEAyHQ0FyR7HkxI+BFI7aIj7YQJTZ23313\/yNeMqKgSX6FOFvLli1raQcAEOEDdVIjgIYJ4urEAyXMCCdNoB72HP5u7Vbq3BI2dtM4EAKNhAXwniSGUpMHLxq1gnDXE2MEmNx6661ePSL6l7MDEUJCuQzAilo8pFNAUtqirrk3BmhkgrhNFy5c6B577DGPxLhNcT1ScY3w8bQUhLoYVXbcM888040fP77HMNTWgQgYk\/8v+xy7v\/dxIAQaiWrGZkncjiYJluR3N910k698SIwTqSNhIijqF3FCAFMWZ0wZznYcaGAiFdcIiNIh4nGT6jagEYDZ1Dl3onNuhHOOKrpLnHMznXMTnHMLX5gsIATgdCPxdcTIiKorsSjdOI+mvnMINFJiAi8sOYCaMAxTugMioJDUEGKOILLF+WBruuiii3wgbJhHVjUvOg40HC4MVLrYUNIkuwloBGSmO+f2SZjU9c65UV0CNkiZGOgx1kuCIjVjKGili1pVvVH78ngh0FAkjKxz0nEIQNSEuoQ9BqImDuAvNaAoXCZrJvegMgFWYa2gqvndcaDRjKG8ohRW6naJRkBmnnNuaIZVm++c47vTdMlGvoC63q3EQhnQZFjoApekubdlSJJDKUaGUZhKB2SuA0oATxyQYPMk4h4iypl6QnVQx4GGSV166aVuwoQJ3oBFhDAIHDfhbpBoqNUyfPhwlybJhAsqkg2lHptKAjRkRe+zz4tymgFNvauVBjSEe5DkiTMFAlSwz+Dqljg1qfoXvik2Uew0kM6Mr3pGHQcasl5J92eSmgCdKKKOyNKlSxvt3gZkHp092y0osFqDX7DZHNhQew1rRMFw6q6QCY0Bmy+nBhqMj3fddZePecJTSC2hqCAycowo68nXlxYq2AiiAshQ00jgpOUJB4oxKeakc5DIY6KWL7WBGQOVgcBPsRehYoR5UcyF8Xg2iaBNpiSgmTNnjrdtSiwNe4+cQam\/LBURdVM8PVc6SOC1gubPn1+bja3jQBNVGjLLojc5jobFHj17tjsqy0SCaya\/UMHu6P8VsC5we623SAkF\/RDWQYCG4K+wBQlBYWRE68Msvbz0OHyF6aIghkz+BoAQwBlmigM2SFb0f4IkMZfYEn5PQuSxxx7rn8v\/i\/dFnkdpC6k8h0uYSo5NpiigCVu+ACTYygh21SQxanGqE4XmKHURVde4Sp50HGio50rpgazE14p\/TQYavp5ZbTPhvMVW00T1iU2L3k8ZCAqHAzxsbAEa5oJkAuAQ4k6MBxILkaof\/\/jH\/VTlw8LG5z6MmdgRiOmAZs6c6b0k2vWKe5ZaN3i2KGKOCxdVgPdAghGg4X4ODNfzb8aMGR68wj7cAnTSrSDr3uvUdSHQwIcjjjjCnwOIqn4YdKUrhX7Phx56yI0cOdL\/SneakGukBnLdvcU7DjR5F6\/pNhqxzyxi0+ednHOOFmoDnfMu\/ybG1iTZaMQAKSoLkgQSiZQA4SuM\/Q2PifSAEhbJunJgcNsCEgAE0gvjiM0OVzoGTz5OZPMj9gvQAF70V5JukdJlIVQbpOkcEg\/SZ9MpBBoKjZ100kn+tdMM8IASBcrguQZ8mfMee+zh42iktU1dvOg40OAuhbImeDUdaJhLb5VomFsS0CDB0KxNSAyNqClEp8rP0q1Su1rxeBAGT+FwyoZIFTvEejlUMq4UpwJw8O4J0FAOVgpZcS1SER0akKooQ4o9BtsQ7UcAJSo1JtWbqevQ5R03BBokGOxkADjzjyMBZ+mTxZzhrdhvkA5pgAchHSEl1kUdARoMfBQix50tRiwmyZcGV1wS6HQL0NA8pKiNZtrOO\/doG1vX4hcZNwloQgkBdytlN0Us19UU454ttgRUM6STKKlD7A5IR+JtIbQe9Uva0YaSEjYbpCvxwkjPqCI8aPc9IdDAT90+OO59ABKkTMCVsyVnjTWhuqCYLM477zxfyrROajvQIPry1YvLaYIxGBS72b3NV2bq+PGFvU5DuhRoQjE+BBpRpZBowiRa2eT0Vj\/ooIP8HuEghCoW10lnA7KOydURiSaqFKy8g7h3ZVxKkmjDc52HrOzYGmjCNrtJY+ueUXjl4Dn8EALUaZFD76e6qe1AI5uEiSHCoSOvscYaXqSTerCIyojMUdQNEg3vjfpUNI6mqfYZ5pUnjiYEGkkGZIPj7dGqE2UMCN4cOHCg78MkBma6QlJfV5MUQBMpJQlouE\/sEIAWEjM2G9zCeUqB1n0Qk8ZPi6PJ824AFQbi9ddf3+dB1RWgF75T24FGRGIWGw8EGwuibis6OpszbJGqX7pbgKa3RwZTH0giSuMC9kKgYY0xTOJyRoUBUITEjiBN6ET6wWZDLydRp8nlwdOF6iBu6zSgAWCIuAbgeDY2DvKFuoWqBJpOzbntQCP6ZdRiUxeDOhpsCNp3RH1xugVoWNDemOuEXW3s2LHecMiHgQObFWjgidhIWGNctEi1SDIYN\/kd7u2NNtrIlzHA\/UzWMR8e1CR+Rw0WvCQ6czkNaMQALIcM2w8fum4hA5oCK0U\/YCjKcIefn3gJKC7vopuARoNNb8ne5tBi5xBdn3gmSaoMpRSMj9Q+Ea8T\/CA+CNuB9g7xe9zYRLRquwnPQm3C+KsJwybJuCLliDQU166He0WSFgNyga3bsVsMaAqwXoAmqp+N9C7uTUDDXIitETck\/6+p6UmUUUuMZEHULlXdJGYl71ZAjSKbmNYmtCnB9RxFABOGTD48RBcTDbzOOuvkfZyPzUEaSgKj3IO26QYDmgKM7otAU4BNdkuFHADMUL\/wdiE1d0PsjJ6+AU2BzWBAU4BpdkshDuBdIcSe5E1UvajI2EIDt\/kmA5oCDDegKcA0u6UQByQFgZsxLBOYljUCvdADa7rJgKYAYwVo8Fqg42vC9ShGRkp7RhGZt4SUNzmpsgBb7BbjQCwHDGgKbA4BmgK39rjFgKYsB+3+buGAAU2BlSLuAo9DUaJDAv\/CuidFx7P7jANN5wBAAxEW0K3U9oC9soySOJqy49j9xoFu4oCOReqm95Z37Tqguf3227uRz73unYlHIScLIg7mmGOOcYMHD25FcyO1krh4yy23+Gso6UlJgrAKfxMZwztTspR8ICLVm0KUt+hW6jqg6VZG96b3JniOFACIfKWpU6dG1gWmHgwFzEkngUioJQWl6QTIEGCZtQVQ0+fThPczoGnCKnTZO1AFj35A0I033uillTjS7VvDkprcg4RK3VqKYlEjBWcB4EWaQViakpgYPJNk\/IdteZCgaJgGkeyJlAWRULl48WLfh5qAPRIxeSfSG\/BskpJAcSyI51P\/hvIUFO0m9+rggw\/20c9xZS26bOk69roGNB1jfXc+mJQAMqoh8pg4\/GlE4BwlJQlnQL2C+HnSpEm+S2IU8QzUFilAzjWSkEvahjRJk3t14qTuDwaQUH4EkEOVIzQiJGlyH1frJa5VSdq87e\/\/54ABje2GXBzgoFKUHCpTbkFKNzAOZR9QschlIshOvCyADVX5JGWgDNDIJHkObWIBH3qJCdF+hbpIFD7H9kTpTyQaEkZ5LyQio+IcMKApzrs+eafubCiSQF5GoKIAVqhBdCsAWLSRWNq0Mi5Z2qK2lAUankOEsJAuLaqrA5qNJu+Kpl9vQJPOI7tCcYCGfxSngqLKbGZhFlKDlI\/Ew6PVI7kftYwyE0g7eLigMkCz0047eU+SJt3fCTUO0IMMaLKsYr5rDGjy8avPX609Tvpw5mEMnUknTpzoi09RhCqKqENDBUZtHykDNFGGaJ4rkepaOjOgybOa2a41oMnGJ7vqfxygN9OwYcP8T0m1nTXDUIWoKYP3BtVFQCRKypD7BIz4WdJNkoCG8cV7FGUMpgogRc9DEqDRvcQNaKrf7gY01fO0148onpws1epwO0uCLIZYDrQATVK0q\/Qu0lJPEtBo21EU0ER5qkyiad9WNaBpH697zZPIV8OQCoV9rcNJ6q6Kop6gctEmhbgW4lWiakNLn28NZgI0UdKJfo4BTfO2mgFN89ak8W8k3Q14UQLnrrrqqsiSnriQqS\/Mf3EV0+KEsH5pd8v9uveQTFyrQWPGjPHpDRDGWoqVE8xHO1xNtGWRdAcDmuZtIQOa5q1JV7wRxeUpJAURqk+BcFQk6vnSo4l4GGw40lFRu5Zpg0y3RAAIYy82EelKwN9obStdFBlH6hKfeuqpPmsf0KJrAnE22Iy4X96F9ykLNNKpgbGIXN5www27Yk2a\/JIGNE1enQa\/G5G9GFdplaJJeifp30UF9ulYGa7FkNu\/f38PUMTXQDqGhp+RWJBchAApafOKGiagVhZoiGQeOXJk6znaxd7gJWn0qxnQNHp5mv1yJE0iWQAIAg76jWmhQqO5MC9JrsE+g9s57CMNWGHPCftocx+BdUTrakKS4jkCDhpoJB4njzGYeWGwZm6QpSCU34cGNOV52OdHQLp5\/PHHvXRBAiMHc+jQoZnaoixfvtyXb6X1Cu1ZuY\/7kzoVrFixws2fP9+raKg1XF9He1tyn\/CaDRo0yA0YMKDPr3MZBhjQlOGe3WscMA5k4oABTSY22UXGAeNAGQ4Y0JThnt1rHDAOZOKAAU0mNtlFxgHjQBkOGNCU4Z7daxwwDmTigAFNJjbZRcYB40AZDhjQlOGe3WscMA5k4oABTSY22UXGAeNAGQ4Y0JThnt1rHDAOZOKAAU0mNtlFxgHjQBkOGNCU4Z7daxwwDmTigAFNJjbZRcYB40AZDhjQlOGe3WscMA5k4oABTSY22UXGAeNAGQ4Y0JThnt1rHDAOZOKAAU0mNtlFxgHjQBkOGNCU4Z7daxwwDmTigAFNJjbZRcYB40AZDhjQlOGe3WscMA5k4oABTSY22UXGAeNAGQ4Y0JThnt1rHDAOZOKAAU0mNtlFxgHjQBkOGNCU4Z7daxwwDmTigAFNJjbZRcYB40AZDhjQlOGe3WscMA5k4oABTSY22UXGAeNAGQ78F9F1nNSolZjDAAAAAElFTkSuQmCC","height":85,"width":141}}
%---
%[output:5e02bc12]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 1.266996\n","truncated":false}}
%---
%[output:785bedcf]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 0.609400\n","truncated":false}}
%---
%[output:9af376cf]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAARoAAACqCAYAAAByDoB7AAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQcUHEUZxyeh95IAClIDEpAQkEcTkBpqIPQahEgJSiiBSAgdpPcSSgARAlE6CgTQRIoSRBSFBEJooaOSAIr4qBLfb\/S7NzfZ23K3c7t3+33v8Uhyu7Mz\/5n97zdfmx6zZs2aZVQUAUVAEQiIQA8lmoDoatOKgCJgEVCi0YWgCCgCwRFQogkOsT5AEVAElGh0DSgCikBwBJRogkOsD1AEFAElGl0DioAiEBwBJZrgEOsDFAFFQIlG14AioAgER0CJJjjE+gBFQBFQotE1oAgoAsERUKIJDrE+QBFQBJRodA0oAopAcASUaIJDrA9QBBQBJRpdA4qAIhAcASWa4BDrAxQBRUCJRteAIqAIBEdAiSY4xPoARUARUKLRNaAIKALBESicaB5\/\/HHz3HPPmR133NEss8wywQesD1AEFIH2I1A40dx9991mxIgRduTrrbee2WWXXcy2225rFllkkfajoU9UBBSBIAgUTjTjx483RxxxxGyD23777c1OO+1kNt10UzPPPPMEGbw2qggoAu1BoHCiYZjvvvuumThxornvvvvM008\/XTfyBRZYwOy2225m0KBBZq211jI9evRoDzL6FEVAEcgNgVIQjTuav\/71r2bChAkGTeePf\/xj3UC\/8Y1vmAMOOMBqOksssURuIGhDioAiEBaB0hGNO9y\/\/e1v5je\/+Y3VdJ566qk6JDAeH3zwwaZfv35hEdLWFQFFoGUESk00sqWK0m5k5Jtssom56aabWgZCG1AEFIFwCJSOaN555x1rr7n\/\/vtns9f06tXLeqVWX311c88995jf\/e53Fpnp06eHQ0hbVgQUgZYRKAXRvPXWW+bXv\/613SJNnjx5tkHtuuuuZueddzYbbLCBmXPOOWu\/QzTYbJRoWl4H2oAiEBSBwonmgQceMMOGDZttkJtvvrklly222MLgeYqSr776yqy88spKNEGXiDauCLSOQOFE4wbsrbnmmgbtZbvttkvlVfrkk0\/M6aefbs4999zWkdAWFAFFIBgChRPNH\/7wB\/Pkk0\/aFISVVlop2EAbNfzFF1+Yt99+O\/NziVxeeOGFzV\/+8pfavUsvvXTHpFF8+eWXper7hx9+aOgTMu+885qFFloo85zoDeVFoHCiIdfp+uuvNwMHDjS77757LFKjR482f\/rTn8xpp51mVlhhhVxQJUBwjz32yNwWkcvnnHOO6d+\/f+3e4cOHR0Y5Z268DTf861\/\/amvf\/\/3vf5t\/\/vOftZEttdRSZo455qj9HTynTZtm\/77DDjuYK664og0odNYjkjAs82gKJxrZOh1++OHm2GOPbYgVXzsC9ViMP\/3pT21qQh5CUOBee+2VuSklmmyQuVtk7kSTdYMulWiS8UzCMLmF4q4ohGiOO+4488Ybb9hREwnM1gXXddzWCc8UAXzI2LFjzcYbb5wLankSzfHHH28OPfTQXPoVuhFfownd96SXRIkmecaTMExuobgrCiEad1FlHTppCKQo5JVoiY3mH\/\/4R103Xn75ZTN48ODav2E\/Oumkk+qu4fnYaLhfBNd7mlys\/\/znP3XbBrfhuN+isProo49sP5qRZvr+2WefNYV90kvSiGjA4\/PPPzfzzTdf6iG2gon\/ELZ7zGsjz2fqTiVcyLYIrT2uakEShv4jcJawPZ177rkzdzNuHeLtZZ2nWevy4EKI5ic\/+YmZMWOG7QNxMxiD8TgRJ9NIevbsadMNuGaxxRbLDFyWGyCabbbZpnbLnnvuGenZYiKHDh1auw53PF4z5IYbbjCTJk2yf\/7mN79paIOF8tBDD5lXX33VbLnllta7xvUYQi+99FLzxBNP2N9WXHFFu50jxYJx+\/Lggw+an\/\/859aYywJFG1x\/\/fWtbYM200hc3+kn0djIsssua8d411132b5PnTrVvnRsXY866iizyiqrxD5u5syZ5sILL7TjchNmIW\/IY9SoUfbl8omGkAdsYNzDGPv06WPLhxx55JFmrrnmCoKJNAquzMef\/\/xn+2yEMROF\/r3vfa+2TqmjdP7559f6stlmm5nvf\/\/7dX279dZbDSEcItgXRXMn8p3nPPLII+b999+vXbPOOuuYffbZx5oKILm0GNIA19Lm73\/\/e\/Paa6\/ZNmlv7bXXNocddphZfPHFa8\/hHUSTFaFcywsvvGAefvhh22fWIWMaMmSI4QPPmvjFL35h31dp95RTTknlxCmEaNyZSGujSfPy5HVNWqKJM6gec8wxdlKQr33ta1bzcReT9PXss882t9xyi32BfYGEeElFaGPkyJG1dqPGy3Oj4pL8a+P6ftZZZxk+BggkhsYki9Zvh0UZZ5hnyxtnT8MZgLfOJRqe+emnn9ZecveZ6667rsVLyCZPTHjObbfdZskvTniRIQE0JyoKiPAy\/va3v627lY+PBKEyLggA8uCF5sMQJ5ANc5EWQ\/IBsXVGrTOeQ\/\/GjRtnPx4Iga5bbbVVrQsQkl89gR+JxKcvJ598cmR3IaDVVlstdiyFE83HH39sXnnlFWsYLEuFvbyJphUCZJvI1xzBNsUXMUnY5vlf1maJJulZvEgXX3xxw8tIKUETiBK0hMcee8x+ZbNsp\/E+cn3emKBh+LY\/iI0X0n95n3\/+eauRQequxuLOF9oFxdxEDjroIHPiiSfav6LRuuTNy4yW6RP6z372M0sMSRiylUf7aEQy0gfI7tFHH7Uamk80SXPd6He008suu6xcRMNkzpo1y8w\/\/\/x2CwS4H3zwQeoxsi\/kCxhSQhANWye2IHwFf\/CDH9QM24wDjWfMmDGmd+\/e9gvmLtwzzzzT7LvvvnZ79d3vfrf2lecethYsZLZouNZFzefLxQsct4dOq9HIl5D+EYWNmo8KLoJ6TYZ9kiTZF3yi4WvP2FknLOKrrrqq9gjw4Le8MfH7yLYHfLGdsBV2A0PFIUHqjIuHS\/Kk1LC9FGH7yRbm9ddftxHvIq4W6odbuN7YOAzByH3Z2e4ccsghtu8Q8+233157HtdBDj7RQD7gzNaO6\/0QA7ate++9t9XGIE0R7psyZUq5iEb2p2L38CcqacHyOzlOIbWfEETDvl8MfUzgJZdcUhsqGgGaAfLss8\/axFER8QaxxcA+IIJm4\/6dLZb7Mt5xxx12b95IshAN9iBsQCL0j36KpMk1y0o0kBckhmBLcJ8vWlTemEAmEJgI2gxOAf7P3Iltgt\/XWGMNq4XzoYSMhOSxIaKFINg8GDfCh4EPAuSPbYetlwi\/\/fCHPzQbbrihHTPPweiOsM6x8SFxGBILJtseXnz+LEZgCNldC1LxwCcabIInnHCCfRbPd7dD9BEboggk5n5gsMHFfdjavnWqItH4jO8vmHvvvdcuXAR3\/0YbbVSbUAkCZG\/t7pH79u1rFl100dp1hAi4Ec6iCeVBNNgYFlxwwVpT7gvEP+ZNNP6i5hk4AuRlRvvhK503JrxIrrfRxY4+YWiH5PwaSHwMXI2BjwqRzQRzSp8pV8tcIpgLcH5ECWsFbQeNg3w\/N6gxjmhcfGjXd6y4JCnr0Sca7IVoLCLf+c53apo3tpxrr7229huamxAq\/\/jSSy\/VJTz7Y2s70cDmqHNik4FtJaam0Uvh\/zsvpZvFnfa+tNflrdGwL3arBfoqNd4c+Wr5RCNq9XnnnWe3V2kFgyZfnVaJJkot9l+svIlGiMTtO1qF2B\/k97wx4XnYUNDg4gRN8tRTT619wX3NCo11+eWXr9Na8BSuuuqqtWbvvPNOQzxZnDDma665puZlbUQ0vnaaZo0wZz7R4EFzo\/PZqsvHy4\/W9omGd8YlxcKJJg0IRV9TJqJBe0Ctvvrqq80FF1xQg4YvXpSbVy7AFex6FHxM026diiCaqBSEKKLJGxPBiG0H2hKGXdFIfPzcl5IPJ9seIUK8hZAKNjQEYz5t+cKLzhb3l7\/8ZZ3Nzr3O9Tw2IhqeLx8q7mX7hS0oTthq50k0OHSiQjGkD23XaIomkTTPLyPRoPVAOCKuFpRmTN1INHljgvov+Vi49CEIvEu4jSm0JrlYYAmRuzYxNyQAcmZrKzYTNBfXYIxDBG8cwsv57W9\/2xqIeQ42SwzuIrTF1hX7R9zWacCAATZWCYnSCKPWSFcTDeoYBrRWBK9MyOLkZSKaH\/3oR9ZL9eKLL9YF47GYLr\/88tpXhC+UW9L05ptvrovxKBvR4GJdbrnlat1KSkGI0mjyxoQgSdni8oKTwCsR6KzZb33rW7X+ukZf\/vGZZ56pBWv6WOMBlNgVfvM9RJCYm5yLncStkS32D59oXAx9NzvXSowPpIaxGC0WwRgMSeZJNKU1BrdCNJ3mdWrFRiNEA164x10VHDc2cR8kKLrxFxguWYRxoeft3jph8D766KNr085iZ3uBkRTDaTNEkzcmvs0Hgy3eIbYmaBVu2AFua9d1TcgGgYl+yREIBCJxBY3FdQ+zPqgUCQ7cL8GS3APBEkSIxGGIndP1ZHE9sToQpdtv\/p0tHaSaJ9Ek2enavnWCacldaUU44ylL7guLgOCptHVO4jQaVOu\/\/\/3v9gvFAmxUJsKNDG6FaFy1GzcvHolGdgMw5UtMjEfSHr3dRNMocC8qMjitjYbx5okJjomtt946VdAb0bBLLrlk3TL2NRV+9MMQ+DdyhfhopIk\/Igoa7w+ShKEfNhH1jrmacFcTTSsEk\/VeCIaSEsSsyMvJ3pn9LF\/SRp4rtAO+BiKonV\/\/+tdtTWNXc8CzwN5a4gdcUnBdwElEQzF2cfv7Xid\/fw9hMp4ozwjxHBdddFGqGCPwcN207nN8e4MfjOV7HJK+ZoIjxltUdpcohWioRyRpGFFE47pa\/WjkvDChn8wvVRv9VAIZA7YZ5jaq0gBbHH53xS+HIb9B9MRPNTrBg0hhvHt+pHIchrTNWjrjjDMii7kR8kAqgaxXf53HeZ18zLOugbZrNFnJopXrfVWYF148AwQMokImZaCSxYrLU+Ik0BhQcaVkBf278sorUycztjIe9140Kyz95MEQKU3Urpswl9dz8m6HQLD33nvP5n6h1rPNi3OLZnl+npigKRGKwXqRfhI8lxSV7saz8LG67rrrYodATA2RtswjaxHbIx81iKzR2kzCEE37zTfftFsjcGZtkI8W56XMgnMz17adaNAmAIqvFgmC2Fsk\/yPtAAjlTjIGu18Xwrgl61dOTuBZPoNHPZ\/gK47kRfgiYKhjAWD8I4COrzAExpc5r9IVaXHQ68qFgB\/lTgwMWzEVY9pONO2KDCbKkRKhGPSwC7k+fvnN9xxELQgJS\/fdmVzrBt650b26sKqFALYZDLaulsvHh5SDZmrBdCN6bScaDJWUAGAPyv4T9Y59ZRYhqc4NiY+698ADD7T77KjKcW4kJ5pJXOEocRtGtYOqLkZXSM1NlMsyHr22sxEgSphwAlf8cP7OHmHrvW870bTe5XQtiPEwKrnQTTJzDbFRLZP\/wj6doCo\/kdMlLDcJMF0P9SpFoDoIlJJoCI5CDcW4GVfasNE0ucFVUUSCgVcqw6HyEquQVQhQ2n\/\/\/W0\/yYylHXd7hrdBRREoMwJuRnzofpaGaIgRIA4AzcAt3oOXh+0JCYJstZK8RAAGCWB0Rhq5F8VWRHAUWbJphRigG2+8sVabhP5hn5GSBvJM3IgqikBZEUhjn8yz76UgGspBUgsjSSAaMpiTgvXc0odsfXChuoLLTzJpk+q2uPcRSk6MgsTSQFDEnPjtQ24QjV\/HJWl8+ns0AhIIlzZeR3GMRwA8WaNumYfQmBVONGw90D4kiIvAILKOOWCMLRDxAIRwS4IaWcvUbI3TbNxgtKjkQ7fEYpKNhgmgH7i2JUiO0H+KMjfKjlaiyXfZFvFi5DuCcrVWBJ6FEw0h1ry0SJy9xK2Xm4YcZGvk1peV6Xar2BH1GneUBsFPJDVKuDipBZzdFOe2VKIp14ulvalHoJJEQ+lAarNSTCip8LZUlHdLXzZaRCS8EecSlTIvEcNkkmNviRO3QJGbdxJ3jxKNvtplRqCSRCM5E0QHuxmtURMlMS1pqvy7GbKuwZewcuwnbK9cwkJzoVQhHimiOcWGI8mR3EMOTCNx86aUaMr8mmnfKkk0Uvc1TbEeqUmSJgoX4qAsgaTIk3CIq1zKLPhnJrl2HakSz5J066DELVHXqKxEoy9zmRGoJNGQrYwGwYseZU9hwiANXN\/8R2g3L3Jc2UCZZFzRaCR+PQ5IjbKYrvfKjb0RovEzqeMWDxZ8KQitRFPm10z7VgmiIfFMjpKQKScnRLKj8eRQQIgMVs7EJkMZF7Wc9ocdh6I9WRIYScnH6EsdEILrktzjrS5FJZpWEdT7QyLQ9UTjF1FuFszQFfaa7Zfcp0TTKoJ6f0gEKkE0eHpaFc609qubtdpmnvcr0eSJpraVNwJdTzR5A1bW9pRoyjoz2i8QUKJJWAcE6hEhTJkIt6p80vLJWjM4qT3KQ+AGb1TRTokmCUH9vUgEKk00kAE5SnGFtwm0o8aM636Om7BmawbHtSlu8LiDzZVoinyN9NlJCFSWaNBSKFQVRzIueATWxZ3CKNfmUTPYnzSefe6559q0Bb9otxqDk5a4\/l4GBCpJNHEHnkdNCoF2vOhJZ2\/nVTOYPnCoGAWk8XZJzpMSTRleGe1DMwhUkmjk9D1e3OHDhxsieIcMGWJr0pBIKUeVyLnT5C9R0T1J8qoZzHPcw83kuUo0STOgv5cVgUoSjRACx5+gqYhVHDDkRD3+Tcpmci4Th3clFcDKq2Ywz6bUhBTj4hhWkiubJRqx38QtQq27UtZXtDv6VUmikSxrl1REyyHJ0j2KRQ4ZS1OfN6+awf7SkiJdrRLNRkPPm23Vvj99ipk24RZbsF1FEQiFQCWJBiKhoBSFpXBbI08++aT9MxX12D6JkD3NyX4caI+tppGErBmchWjiFsqg8x6c7eeZ0yebSWNGKtGEesMq3q6rTVeulKd4cTh\/iQxoTtOj6p6cN+wWpuIgdAyy2HI40raRhKwZnIVo+g4YbLvYa6V+ta6K1hJHNO7h8f4Y436r+Hukw0+BgGgzXFqpUp7uweXU3h01apShXCfFyNkiYYhlCyXxM2LD4ZpGEqpmMM\/LQjRsj3qvtGZdN0VriSMa\/x5pgHuVhFK8TXpJLAKV3DqBiJwGyZ+l0h6FwPE++YIXCgKKO\/Qt75rBbh\/aQTRxJBS3gtS2owyTBoHKEg3gcMY1thmKkmN\/IcSfEwbcUpsUBb\/yyisNB6knSV41g\/3nFE00attJmnn9PQmBShNNI3BmzJhhz2miOt7KK69sbThpJK+awZ1ONOpOT7NaqnWNEs3\/57vVkyppJq+awZ1ENHGvixim3WtmvjrZYPfRLZcSTWgECj9uRQaY50mVtJlXzeBOIpq42BzdcoV+lTqn\/cpqNHmfVClT3mrN4KilI32V1Iioa2S70qzXKY4UQvwmB+O5Y8FeliTqak9CqJy\/V5JoQpxU6U9vUTWDO4Vo4l6HOFe7brnKSSRJvaok0YQ6qTIJ7JC\/d5pG06yWpEQTchWFa7uSRBPqpMpw05TcclWIJg6JKBICFxZ5nLQzWjV5JrvzikoSTaiTKkMskbQlQatCNHHGZznjyp8HbD9ZPWC8GEkEpdpV+hVfSaIJdVJletiTr8xaErQqRBO35Yojk6j7Xpw4rmHmuhCNZrwnr9U0V1SSaEKeVJkG9DTXZC0JqkQz0mS1+6QhmjiCamYbF+dZQyNbf\/310yyPjrumEkRTxEmVrayEZkqCKtE0TzRxcxVHNHHaTjPzH1dGgfmNk7ITVNcTTSeeVNlMSVAlmuaJJmvQoWhCzZJQ3H1RcULMbZIm1MigXRaCqgTRdNpJlc2UBFWiaZ5o4l78dv\/WKIYIbWbVAfvNptRIraEoQ3hSAGQ7C1F1PdE0o8IWfU8zJUGVaDqfaMgDi9Ku0KCSfuvdp74GEWuYe0IQFG028vCxhYvSypRo\/s8qX331lS0GTs2ZeeaZpzCuabYkqBBNXFSt\/lY\/rSR3IlG4VOW3EAu9kXbVTg2KcZUmqZKXesyYMQZj8bRp02qYU3WP+jOHHnqoWWeddULMRcM2my0JmiYwra0D0YcpAh4CjbSdUECVgmh4oamm9\/bbb8eOc8CAAbbwVdLhcXmBFbIkaF591HYUgU5AoHCiwRO1++67m8mT\/6c6b7LJJoZC5aussoolHqm8J8flHnzwwYa0hXZIyJKg7ei\/PkMRKAsChRPNAw88YIYNG2bxaHSmNjabyy+\/3P6HUKohzWmVeYAcqiRoHn3TNhSBTkGgcKLhdEoIZp999rE1guNkr732sudgX3PNNWbrrbduC8ahSoK2pfP6EEWgJAgUTjRDhw41EyZMMIT577HHHrGwSPBc0rlOeWKbtSRons\/WthSBbkGgcKKR7O005HH88ceb22+\/3Rx++OHm2GOPbcscZC0J2pZO6UMUgQ5DoHCiufXWW61xl6NU7rrrLrPEEktEQkhN4W233dZgoG1kywmFfZaSoBDTzJkzzWKLLVZoDFAoLIpoN215jiL61onPJJH5008\/Ncsuu2zbPLiFE41bynPFFVc0Rx99tNlqq63MfPPNZ+fwiy++MBMnTjTnnHOO9UItsMACZtKkSbEHyIWa\/LiSoB999JG56KKLzM0331x7\/LrrrmttTzvvvHOoLlWiXexy2OfA8eKLL67EmPMeJOvztNNOs0dKEwwrgpf3xz\/+sVluueXyfmRde4UTDb1h8Jyr7QrFv+Ucbvff263NpEH\/s88+syds8kIg9J0vhrjkIaBddtklTVN6jYcABwkedthh9nRSJZrmlseHH35o9t9\/fzN16tTI9ck\/cjIsGk4oKQXRMDjiZfBAycvqD7hv374Gew65R2UTsnXpGwIRbrnllvakTbxj8gVGKxNXedn6X7b+sP189NFHzcsvv2zGjx9fe0GUaJqbKdbh+eefb3cDY8eONWuvvbbBHMB59kTcI5xxP3r06OYekOKu0hCN9PW5554zb7zxhnnzzTcNmgIq3fLLL2\/WWmstM8ccc6QYUvsvYZJIm8CDNnLkyFoHiP\/Zaaed7IuSxtjd\/p6X84l8gaPSTZRompuvQw45xGqEbJ3QvF058cQTjRy388orr5iePXs295CEuwonGjJJcSETDXzGGWcEGWTIRtFciGJG7r77bkuIrlx66aU20HD11Vc3999\/f8iudE3baDR4FzECI7\/61a\/M448\/rlunJmaYj13\/\/v3tNj5qfaJpi1bzzDPPBLN9Fk40p556qjWgkjz5xBNPNAFlsbdgoJYaO6j6vtYlE4naOmXKlGI726FPl1KqqtFkn0A+hBA1\/yfI1a+GcMkll5grrrjC2hUbmS2yP3X2OwonGr5Uos7dc889ln07SaT\/jYhEPCaMibKg7UoI7SQMk\/qqRJOEUHO\/u9pM6Ni0wokGiK6++mpzwQUXWFZlUaEhdMoLKXFAuObZB\/uCzQk7DfLss8+ahRZaqLlVUeG7lGjynfwPPvjAGofZniJ83FnHIWs\/FU40JEiiuvESugLpNBISMRsF9uU7Jcmtse8dMWKEDTjEiu\/LU089Zfbee2\/7zyGNbck97dwrlGjymTtsX3hI+ai71RCIsg9JMvS+cKKRFzULlMTdLLPMMlluCXatxAA12jpRyIs4kNB74GADLEHDSjStTwKR9QTDPv3007axjTfe2IwaNcqsttpqrTeeooXCieb111+PrSofNYZBgwbVIodTjDHoJS+88ILZYYcd7DMwZmPUduW6666zUc1ECd92221B+9KtjSvRtDazM2bMMLwzROHzQUSjIZ2nnVI40bRzsCGehTq64YYb2rBuQrn326++Ov7AgQNtHA1fD+IZVLIjoESTHTP3Drb27BwgGUwVRZgdCicagvKQ0HvE1qYq\/m55EZhISl6IVnPHHXfUAvgwFGMwVsmOgBJNdszcO9Cm+RASs7bddttFNtajR4+gAbGFEA2JkhQix5392muv2YHzEmI0xdXdaaSDakrfZSzUNiYBU87ywcJPuVKV5hBQomkON+5iTZISk0ZChl+0nWgIHNp3330bBgcRek5IdKe4t2UC3333XZsYSqF1ETQcahxHna2TZuL1mv8hIESz6667mgsvvFBhyYDAfffdl3r9kUYz99xzZ2g9\/aVtJxoMotgrELYYm2++uZl33nntlkNOQTjuuOOsp6YThVofGIgXX3xxs8Yaa3QcYXYi5trn8iPQdqKRI2aJO8FA1bt3b4vSxx9\/bEspoBGg1WDfUFEEFIHuQKDtRCOGqWOOOaZ2+oFASd0Wzm1iy8HxKxioVBQBRaDzEWg70UhNlqiTDIhDGTx4sEU1pGGq86dNR6AIdBYChRENBl+O5XRl+vTptoynEk1nLSLtrSKQhIASTRJC+rsioAi0jIASTcsQagOKgCKQhIASTRJC+rsioAi0jEBhREMksF+bhdR1CXijtGeU4IkiUVHc4i0joA0oAopAcAQKI5pWRlamMhGtjKMb7v3kk09sDFRWWWSRRWzxeY6lWXDBBUuTjZ91HHp9OgTaTjTDhg1ramG6w+EIEyJvVYpHQKojZu0J+V8UbScanKOOpUB21nb0+s5AoO1E0xmwaC\/TInDVVVc1lX9EjR6CM5Vo0iLd2dcp0XT2\/BXee+rPcg6TL2SzU5qAdBIOBvSFmiiUZOV+4qmiznEqfHDagdwQUKLJDUptyEVADtXjbOebbrpJwak4Ako0FV8AoYafhmjI5OfweerXSu1aDhOkUH2fPn1slDiGf6rCUYZyiy22sP+RkIsWde+999pyI2hFHNxHUad+\/fpFDokztThfmhw6SpVwLCyaFLl3KuERUKIJj3Eln5CGaDhWx7fRcIY5lfohH0gIYvAFDYnjXaXQmPs7Wf\/uNoyTGimyRp3cKKGawAknnKDlPAKvUiWawABXtflWiUZw23HHHc1mm21mk2whDFeoHMd\/\/HbjjTfan9Zbbz1vdjJwAAADWElEQVR7RpHIDTfcYM4880z7V4htt912M1R4REvCRoTsueeekXakqs5diHEr0YRAVds0eRANlQnd6oRHHHGEGT9+vEWXkq9oNSL8eezYsXUlRthSbbrppvYMI4zTZ511Vl3pkbPPPttcf\/31tgnO39Ig0HALV4kmHLaVbjkPonn++efrAvlcV7oftCnnawE6xxQvvfTSlniEjKJOCaXWs1QQQOuhxKxKGASUaMLgWvlWWyWavn371rY2AqYcP8zf\/VM\/3TPO2RatsMIKlmREy0GbiRIOVUOGDBliTj755MrPWygAlGhCIVvxdlslGmwv5LS5IkQTdSpoFNGwvUK7SSNqp0mDUvPXKNE0j53eGYNAq0TDkTW+8Tcr0XAqBVsqZPjw4bHzRRIv9hyVMAgo0YTBtfKtloFoTj\/99FqwIG5ykjd9wU7DaaNUEoj6vfITmRMASjQ5AanN1CNQBqIZN25cze5y7bXX1srESk\/dw9VGjx5tPWUqYRBQogmDa+VbLQPREPCHrYecq\/79+9fVMXrvvfcM7nJsO9h8OFWU\/6uEQUCJJgyulW+1DETDJBB3A6EgEAmpB59\/\/rnBdU58DRKl7VR+AnMGQIkmZ0C1uf8hMHDgQDN16lQTl1SJtsH2xa1HIy7pKGPwnXfeaTjFtFevXrMdqRzldZK54BgfAv\/QbFyhyuOIESMaHnyvc5kfAko0+WGpLZUYAbQYysRyXPFcc81lEzPZTvXs2bPEve6erinRdM9c6kgUgdIioERT2qnRjikC3YOAEk33zKWORBEoLQJKNKWdGu2YItA9CCjRdM9c6kgUgdIioERT2qnRjikC3YOAEk33zKWORBEoLQJKNKWdGu2YItA9CCjRdM9c6kgUgdIioERT2qnRjikC3YOAEk33zKWORBEoLQJKNKWdGu2YItA9CCjRdM9c6kgUgdIioERT2qnRjikC3YOAEk33zKWORBEoLQJKNKWdGu2YItA9CCjRdM9c6kgUgdIioERT2qnRjikC3YOAEk33zKWORBEoLQJKNKWdGu2YItA9CCjRdM9c6kgUgdIioERT2qnRjikC3YOAEk33zKWORBEoLQJKNKWdGu2YItA9CCjRdM9c6kgUgdIioERT2qnRjikC3YPAfwHZlF+2pgcQOQAAAABJRU5ErkJggg==","height":85,"width":141}}
%---
%[output:7c0fcf91]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAARoAAACqCAYAAAByDoB7AAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQn0HEURxjvBICpIhHiBwQgoCYdBfYAKyBWVIxABQeRQUSBogkKIYECEQEI4lfs2hkDkBoWAIiiggAryJBwhSEgAEZUjCMEHRCW+X\/tq7e3Mzs7OTs\/0zla955P8d6an++ueb6qqq6sGLF26dKlRUQQUAUUgIAIDlGgCoqtNKwKKgEVAiUYXgiKgCARHQIkmOMT6AEVAEVCi0TWgCCgCwRFQogkOsT5AEVAElGh0DSgCikBwBJRogkOsD1AEFAElGl0DioAiEBwBJZrgEOsDFAFFQIlG14AioAgER0CJJjjE+gBFQBFQotE1oAgoAsERUKIJDrE+QBFQBJRodA0oAopAcASUaIJDrA9QBBQBJRpdA4qAIhAcASWa4BDrAxQBRUCJRteAIqAIBEegcqK58847zUMPPWR23HFHs\/rqqwcfsD5AEVAEykegcqK59tprzcSJE+3IN954Y7Pzzjubbbfd1qy88srlo6FPVAQUgSAIVE40N954oznooIOWGdz2229vdtppJ7PFFluYN7\/5zUEGr40qAopAOQhUTjQM85lnnjG33nqrueGGG8x9993XNPK3ve1tZtdddzVjxowxG264oRkwYEA5yOhTFAFFoDAEoiAadzR\/\/etfzS233GLQdO69996mgb7vfe8zX\/7yl62m8853vrMwELQhRUARCItAdETjDvdvf\/ub+eUvf2k1nXvuuacJCZzH++23n9lggw3CIqStKwKKQNcIRE00YlIlaTcy8s0339xcfPHFXQOhDSgCikA4BKIjmr\/85S\/WXzN79uxl\/DWrrrqq3ZVad911zXXXXWd+85vfWGQWLFgQDiFtWRFQBLpGIAqi+fOf\/2x+8YtfWBPpgQceWGZQu+yyi\/nc5z5nPv7xj5s3velNjd8hGnw2SjRdrwNtQBEIikDlRHPTTTeZ8ePHLzPIrbbaypLL1ltvbdh5SpI33njDrL322ko0QZeINq4IdI9A5UTjBux9+MMfNmgv2223XaZdpVdffdVMnjzZnHDCCd0joS0oAopAMAQqJ5rf\/\/735ne\/+509grDmmmsGG6g2nB+B559\/3rz++uu2gbe85S1mlVVWyd+Y3lkZAi+\/\/LJ59NFHG88fPny4WWmlldr259\/\/\/rf54x\/\/2LhutdVW6\/i4UOVEw1mniy66yIwePdp8\/vOfTx30WWedZf7whz+YY445xgwbNqwtQHW84J\/\/\/Kd56aWXGkN797vfbZZbbrmgQ8WEFd8ZfrIf\/\/jHQZ\/XC42\/+OKLBo0aGTRoUCYNvOpx3XbbbeZrX\/taoxuXXXaZ2WSTTey\/09bV4sWLzciRIxv3HXLIIYnR\/Gnjq5xoxHQaN26cOfTQQ1v2FVYlUG\/evHnmRz\/6kT2a0I\/impqMH40wdPCiSzScR7v88sv7EfqmMXM+j7lA1lprLRtkGrukEU3auupZojnssMPMk08+aeeFSOCnn37asHWdZjqxM0UAHzJz5kyz2WabxT6vQfqnRBME1o4brQPRsJY41oN0QjTf+c53zAEHHNARZpVoNByYRDPJIxxD4Ovxr3\/9y+5GlXX26T\/\/+U9HJgoaGH3Ep9GJ4AtJO0TaKdHk6Qf3YI4JtkVoNEuXLjVLlizp6IAsmPNxwSfUKY6dYJ50LX1dfvnlWzYTI9Gwduhzq3eCXVowFcHkE2m3rljLIoSYZHnv3LVcCdH88Ic\/NM8995ztN7Y\/zmB2nLD\/W8nAgQPNO97xDmsqzJ071y5AiOZjH\/uY+eQnP2m++tWvNmJs\/vSnP5kTTzyx0RQvzSmnnGLe\/va3278RaSxqL\/\/+0Ic+ZA4\/\/HDzxBNPmO9973uN+9jR+u1vf2vo78KFC63W9dGPftR84xvfaLJZ5QYmA3\/TzTff3PBpoFbTx7333tusv\/76icMjhuiqq64y999\/v3nhhRfsuLhvt912s7twvGQ4ZBnD448\/3hTIiBOd3ydNmtRIrZGnH5DLBRdcYEl8zpw5tg+Yp9jjmLTio+nEdKLN6dOnm1\/96lfm4Ycftn4AMFxvvfXMl770JbPlllsa5tUVXgTwJuzBjan6wAc+YNcHLzjrwJXTTz+9gQlzjC\/PlTPPPLNxbg5HpuxSkgfpBz\/4QeNS\/s7cETD661\/\/2v59o402svMtpjqHfpmru+++22riCFjtsMMOtl+so1YyYcIEO4\/IkCFDzPe\/\/\/3GpUcffbRdYwjzef755zd+u\/DCCxvBqfyR34R4iT275pprDGteNH4+xp\/97GfN7rvvbj74wQ822mG8J510UuPfrBnM7nbrCvIaO3Zs4z4+PKxLhPeI9wkZOnSovY7+\/PznP7fvqayjSojGnYisPhqOGfDit5JRo0YZFhwTwNeTQD4czSKoeqh8r7zyiiFGhxdahChjnF2PPPKIXTAimGduG+6zjzvuOLPXXns1\/sRxCZ4BuK2EMXBkQoQXkQWGU66VQMD8zgJN80vRT16iPP1gN4JYpqSxslAgCJGsRPPss88a\/G7+aXx3nMwR4xdhjLyMrTDnuve85z3m3HPPbSJ6iICFjUBk\/mHcr3zlKw3icP0pEIprAqTNN+SFJu5\/+d3x8IILQSXNJxhDoCLs5JB3CXJ1CYHf77rrLvPe977XXupaAETFEzWPgNVPfvKTlmuHH6644gpLlkiSj4Y1025dsTPVyhk8depU+2EQ7CF6IUy3Y5UTDS\/+\/PnzLbO2yrAHE+MIbieQDV9lhK\/Npz71qaZbWFjXX3+9OeOMMxp\/d53QPtG0ex4HPvnSIjB5FoegkJosAr4q7YTDo7yULkm590AGd9xxhzUx8vSDr9x5553Xrhv296xEk+UloD3mi3nL+uLIguaFlq96UUSTBgAYP\/jggzZ6\/Vvf+lbipbyMzG8rQRNyNR7xNaKlfvrTn266TXDh\/eBjI8Kz+V\/SWvU\/CtwDyUA2SBLRQI7t1hUmVhaiScOvdKLhi4vG8da3vtWqmmwRLlq0KHWRs5BQ50Uwi9A8mCC2ut3fOJYghMU27He\/+93GfXwNXI2DrxtfB\/GJJE0eKj65cLDZp02b1qTOo0Ki\/mL67bnnno3nMHHf\/va3zRprrGEXnquJffGLXzR8BdASMB1czQqNjIWBKXXyySc3NAm+4qjqSJotnacfmLCyxSkDOP74420\/aO+0005r6mMWouGFBDMR+o\/5grbBnGBeihDSANH5HxNeAEyEESNGWG0OQobYRVyHZJFEQ9823XRTu1mBxurOj7vDl8dHwzk+96WmDfqeRF7yASRrwR577NEYN2bJRz7yETsv7gcTrZc5wy\/CGnPNTswq\/Cohdp1cjYZOyrwRsc\/zDjzwQNv30olGdpawH7GJeamkM6ls4\/zokomcd5KfecG\/\/vWv23\/i\/MI3wguTJGg3rt\/EJxo0IrbSxfGFOeD6kURVxs7nRRLBZuUFEXGdqfwNfwULgQUhwoKTlKb8zZ9AMY3SiCZPP1gM7hEQNCL3q4t\/BY1KJAvRgIXr+\/BNRtcUEAz5eLh+CTfGg2dj3skOCf8m2EzMkKKIxo8POfXUU83ZZ5\/dGLu7XvIQDQ1ts802DdOC\/8b\/ArG75Mt1mHFoPGg24lNCY8HcgjRmzZpld2wR3inxmUDKX\/jCF5rMF9baiiuuWArR+PPGIWgUgZ4kGhhdtBDsW9cmxzmKZiDCtniSDZoUdOQTDYsfh6wr\/o4ZkZa05drevlObL7zr58CfwBfcJZassUFpROP7ALL0AyJxHYRJ\/SDnj\/Q\/C9G4LyHYyUJP+5DgK8G0RcRM8a\/3xydf6qKIxh+7j7Vr9uYlGkhDzHvGCTZoLKxhNG7MX\/FRPfbYYzYwTvxPkAmOWxE+pLzEmOysQ64XB7WLXZlE48+14FQ60fCC4QQVnwwRlhJTk7QQcSZOmTJlmZ9aba+5fhq56dhjjzUzZsxoaiNp8ftEQ2AaL5YrRxxxRFPAGtoSO15pTmC\/86i\/+FRc1ZfdDt8hmIRHGtEQXd1pP+iLG+kL3v6ujnyV6E8WooGcxQncijT8sblfeldbca\/DAQ8ZiIhmWxTR8EKzAymCoxVfk0gRRAOJYI6LQBLin9lnn30s9rIuWBOY5GK+8QHlQ4rgcth3332XSQiXtGbKIpqkucbEvfLKK8vXaNK+aq2IxtUqWOio260E29A1xdjyYyJdjYJ7v\/nNb5qDDz64qRmfaJICA5l41xTjS4JpIblxAJutxTThxWAR4YcRcYOn0u5NIxocxp3249JLL20iYd\/s46uJI7ATjYYXyd05wtnvb2P7Y3RxdX1S7nW+poQJikO4HdG4BJy261QG0UAQbO+LsFbFEY+2Mnjw4IapitPX1c45fiPnzNB0ZFuZtvB\/QdZo+\/guXVNMiSYD6\/jOSn9bOa0JnM6QAH6IJGnno\/EjIP1FIi+EqzGJOtwuoMlPj4Fzz91Zg+TcHQz8F+9617tSncF5+sFzcKiL8N\/uF9d30mbRaIhFgsBEXJ8af4MweBkQxsTYeC59EWFXyf2goAWTMkRMA5eM\/B0uPhiuae1qilUTDePjvFHSmsR0ZCvZd85zD7FY7FohkL6bwhYNkLUsuZp8za8viQYHqxxGy8Az9hJ2pSANhC8jXx40FwQfg7vdiL8EUwa5+uqrDccdRFi4rg2bZdfJ\/cq5jjnaRFPiJcExd9RRRzWeQ2wI2gXCbhVxHPhpkBVWWMHuIPGVd2N26AuLhS80C4m2JQDLJS9fo7n99tvt7haSpx84F91dDfwEmFLEQ\/ByQ7ZucGMWovHJSxz\/9BENkDQgIvi8iFHxiZe\/44wVwvCxd9v0TWN3y9x3TIcgmqTYnbS17ePDtcwx\/hbWNwGoMvfSjrvJgW+K2mcirr+R7XCwc9d5HqJx11XaWSd30yIq06mIVBC8jJgnbJX7ScuFGPytRCYFdR4fixtUhQrKRCGt4miIY4Aw\/GMTYu6wI8LEu4sDc2Odddax6q1rtsmWOM9zTR3+LZHHfjyOa+ZBRq7Jx3Ypz2EckHGn\/eAeXlo3sI5+sGtGpLTvXMxCNODBFrE7br66+OXEtJOXBM2HFwunPv4HF2M+DDwPH54f+OdqSUlBdGz1yjk696Uvimh8Xx3b9KztLDuoZISU2CHpG0GkEvjGh5Mtb1dc7dt\/8dHuuAftHy3YD5gj4pwPR9r2dtq6oh9Z4miiIhoWBS9tJ8LLwCS0S9kpaj\/Xo0W4ixr1ml0LPPO+D+WnP\/2pVUU7CdhDG3G3tNFS2EpPE4L7UH\/Fzs4SiMiLhr3N9iSSRKBCokR55umHH\/eSNoYsRMP9ONJ5GdMEs9a9Bu0Ks833p\/lt+OYdxIbDOiki1b+3KKJJin1pFxns9sXXWmR9co0fBQ\/xE8Pj+rncaOd275L43dKIJm1dZY0Mjopo2oHS6nfI6ZJLLrHxJb7A6BLsxm\/+F47fCfaSSFLfhpVdjqTtbTQk156GxPC\/JIHK\/bSdFLfDC0R8in84EPKEAJMOmRJngxnmH+4jBP+cc85peiElzkY0s077gTrOi+9rMDgoIS8xn7ISDf0AN7SxJOIgdsQ12WROWfC8dP4xAtH4IPekM3FotziF3UA15gizCiKVXcdOiMYnE3fXCXJjDOyoiHRCNL5Pyo01gnApmigCTjzLFWK60Gz9tcaaQbty75edWJ9oJPhP2m21rjgm4fqEcEeI5tbOdCJgFlO89O3tvEQj9+HfQaXHx8FXnu1IvuTtnK9Znttq1wm7l8ln6xGzi5cvbduWRQ+B4FtCi0GlbpX3mH5BXnLP3\/\/+d3ugEvJLO7FMBCiLjQOU+DEgUz8BVp5+gC2kB6aYT2knmLNgip\/nqaeesvP12muvWTOP8blJ5pPaIeyBezCbMLnwyWWZZ0gNrZWvMC9+6HLKEI5sPzNfzEOZwpoVjAg+7Xa8WdZVnvGVTjQ4ORkMpgdfeMybI488sqO+w8Qhkj21Ihq+rvxGXyUMPmt8SEcD04sVgZoiUDrRFH0Eoch5aUU0SflzlGiKRF7bqjsCpRMNW3uo0Gyjcp4DE0NCz7OCTXCXOEez3pPlulZEg59G1GO2Z9kpUaLJgqheowj8D4HSiabXgZdDhko0vT6T2v8yEYiSaHD4SgpHPN4xSVaiYTtSRRGIGYGkCORQ\/Y2GaNjWZOsSZ6ubAwTNgfMb+++\/vzW1ithd6gbMLEQDybgpILp5nt6rCIRAoOyyOVEQjZ\/zpBWwEI2bLzXEBLRrsxOi8XNztGu77N+FEMec+LOyH93R8x69dZaZd8ulphf6OXjx\/OjrXhFzxtyXWZ+rcqLxT1cTok+AEYXRMKGIwSBQSkLQCVPnAGJVmo0STUccUcjFEM3zjz9gNh37\/4TzhTRccCP0U4kmGdTKiYYdHKk84CZS9rvrHkRjl6qIM1N51pkSTR7U+uMeJZrW81w50cjhNEL03XQFSV2WlJjk6eW\/qxAlmipQ741nKtFETDRyFoLoYLcucFKXJZUj90gqiLKXoBJN2Yj3zvOUaCImGsmhInlJ0pYVR\/\/ZkfITVpW5FJVoykS7t56lRBMx0ZAz5DOf+Yw94StFuvzucjCPrW8p2eEfmS9zOQrRpCU7kt0c3XUqc2aqf5YSTUREQ3kVDlW6QlU+OW7PjhNVC6jS949\/\/MOe4CVNgRz\/x49DOYluT6mGXJZKNCHRjbdtJZpIiAbNxM0yn3fJ+Dlo87YT6j4lmlDIxt2uEk1EROOXqc2zdCiDQVLrWEWJJtaZCdsvJZpIiCbsNMfTuhJNPHNRZk+UaGpCNATqESFMmoihQ4dmXkNksKNUKBUIyLwWWpRoQiMcZ\/tKND1ANJAB5WvTElNTopZUmm7FvrQlR5tUNqQOtLRLikyy\/FE1oF06SWmb3S635pD\/TDIFkqdVRIkmTiII3SslmsiJBi2FrO7tst\/LMNy6PWmLxy8cz5a0nAynxMi0adMynZmi8L1fAsV9rl9oTokm9CsdZ\/tKNBETDYm\/qZuUVSh0TqH0dtqIW2Rr3LhxNhv\/oEGDbN5fKe5GcXtXE2nVBzQgKisSKJiUH4e\/UTdHNZqss1jP65RoIiYaKY1C3hkKuVHOg+LlaB6YKxIYJ3WqKYExbNiwtiuV8hTUQ4LEeIZbE0d+y5KTg8JmlFTtJKOeajRtp6eWFyjRREw08tK7JU7xwfA\/TBuC8xDqFnHwEh8LBbHapYmQAlu+WeO2xX9LFb9WEElhLY4\/cLo8iyjRZEGpftco0URMNFL+0yUV0XI4ZOmWYhk9erSZO3euzcJHvaQ0kUqAVIakQLor1AySv7VLOUGBLna50H6om0OEMqVHqU9ETNBuu+22TD0lJZr6kUiWESnRREw0EAlngqZMmWJfaERebjLqubs9kydPtuVCKeCGr6aVkDBrvfXWsz8nEYmYQ\/yelgOH3yEqdpVaCTWJ6aO7be6m8sxinmVZxCGu6ZUMeyHGHqLN2ImmynVZeT4adpBw7uJL4aXGYUvWPTQShHKmUuURJy7OXHw5bE+3Ehy3OHARwE0qNieJs6jpTYH1VgKpUX4W4ZyV5C2ePXu23TZHyI1DjhwRmVC0NUT+P8Ti7qZNJZpu0Fv23tiJhh5LGk\/+u69SebrFxSknOmnSJEO6TpKRYyKRPgITSuJnBCyuaSXE43AwE+FApl+mlDKymD5IkmnltkspXGo5oSG59Ye5Zvr06VYTQ9iip2SukBvJyfX0drEvcuyt9QLRuGTTV0Tjv7CSae+OO+6wu0++sAsFAbnbyf41xOMIKVD8zT\/ISZQwu1tIOx9N2uJ+6aWXbIUG5PLLL2+0qT6a2CkhTP+UaFrjWrnpJF1Dc8A3Q1Jy\/C\/4UaZOnWpmzJjR6D1F288+++xlNIuk4YlplJTjZs6cOWbnnXe2t7mmWVI7+HsQCrj70kozUqIJ8yLH3qoSTQ8QTasussODz4WguLXXXtv6cLKI7GYlZe6TiGF2jVwi89t1NR+21EeMGNF0yb333tvYflfTKcus1PsaJZoeI5oiKlXedtttjRzErsP3oYcessXdMK\/cJOfkysExjSZFxj\/x4WyzzTZm4cKFZtttt7XOX0m4tWjRIhvXw3Y7zmSeIaIaTb0JpdXolGh6gGiKrlQJcRx88MHmpptusqPHJ4NWJGeWMM\/YURJx\/TruoU18OAcccIC9DNNt8803t2TkVtS8+eabbfSwEk1\/EoyMWokmcqIJValyyZIlZsKECQ2yERgwpzjS4Ppd3Ngb\/3Q4ZMXuEtvurqy77rrmjDPOWKbGlGo0\/Uk4SjQRE00ZlSoXL15snb5vvPGGjQhOcuy2ezUgLXxFbJ0PHjzYRiYnxefQjhJNOzTr+bsSTcRE02uVKrO8Iko0WVCq3zVKNBETTa9VqszyeijRZEGpftco0URMNL1UqTJrSlAlmvqRSJYRKdFETDS9UKmy05SgSjRZXsv6XaNEEzHR9EKlyk5TgirR1I9EsoxIiSYioum1SpV5UoIq0WR5Let3jRJNJETTi5Uq86QEVaKpH4lkGZESTURE02uVKvOkBFWiyfJaZr\/m+QUPmBcWPGjWGbVX9psquFKJJhKiqWDuu35knpSgSjRdw97UAC\/wvFsuNWNO\/FmxDRfcmhJNjxENEbxUQSDnjBxiLHhNZGoub0pQIRrSeMYupOYYsmb2cjdVjAeNBumVfsY+78x52Slmo8lHw0t9\/vnnG5zF8+bNa6xnsuORxIqDjX6S8dCLPm9KUIiG81IqikCsCGyyySalppiNgmh4ocmm9\/TTT6fOC3mASXzVrnhcUZNbZErQovqk7SgCvYhA5UTDThTVIiljgpCGgUTlpF2AeCTznpTL3W+\/\/QzHFsqQslKCljEWfYYiUCUClRMNKRjGjx9vMWhVUxufDekY+B9CWoks1SqLALaolKBF9EXbUAR6FYHKiYZSKxAMWe\/IEZwmVK0kfeZ5551ns+CVIUWkBC2jn\/oMRSBmBConmrFjx9qsd4T5U\/UxTSR4rl1dpyIB7zQlaJHP1rYUgbogUDnRyOntLORBHe0rr7zSjBs3zhx66KGlzEGnKUFL6ZQ+RBHoMQQqJxrqIeHcJR\/vNddc0zJrHTmFSRCOg7aVLycU9p2kBIWYqJ5AMbkqY4BCYVFFu1nTc1TRt158JgeZX3vtNTN06NDSdnArJxo3lSfpMUkoPmrUqEa6TWonkSB82rRpdheK8rh33XVXagG5UJOflhL05ZdfNqeeeqq55JJLGo\/faKONrO+Jkrkq+RGQsjZ+6eH8LfbfnaxPSjpTUppgWBF2eY877jizxhprBAWlcqJhdAyeutquUJFS6nC7fy9bm8mC\/uuvv25Lr\/BCIPSdL4ZsyUNAUrAuS3t6zf8RoOLEgQceaKtOKNHkWxkvvvii2WeffWxpoKT1yd+oDIuGE0qiIBoGR7wMO1DysvoDHj58uMGfw9mj2IQaxvQNgQipBcULwu4YtaOQbkrvxjbe0P3B\/Lz99tvNY489ZijcJy+IEk0+5FmHJ510krUGZs6cacs44w6gnr2UEkoqtJjvacl3RUM00j0KvD355JPmqaeeMmgKqHTvf\/\/7zYYbbmiWW265IsdeWFtMEscm2EE7\/PDDG+0S\/7PTTjvZFyWLs7uwDvV4Q3yBk46bKNHkm9j999\/faoSYTmjerhx55JHmsssus3+aP3++GThwYL6HtLmrcqLhTBBbyEQDH3vssUEGGbJRNBcpHnfttddaQnTltNNOs4GG1ICaPXt2yK7Upm00GnYXcQIjFOi788471XTKMcN87EaOHGnN+KT16RZIvP\/++4P5PisnmqOPPto6UDk8effdd+eAstpbcFBLjh1UfV\/rkolEbaW2lErnCEgqVdVoOseODyFELaWe\/Z1QyjyfeeaZ1q\/Yym3R+VOXvaNyouFLJercddddZ9m3l0T634pIZMeEMZEWtKwDob2EYbu+KtG0Qyjf7642Ezo2rXKiAaJzzz3XlqiFVVlUaAi98kJKHBBb89jBvuBzwk+DzJkzx6y00kr5VkUf36VEU+zkL1q0yDqHMU8RPu6s45BxX5UTDQckUd14CV2BdFoJBzFblaMtdkrat4bdO3HiRBtwiBffl3vuucfsscce9s8hnW3te9q7VyjRFDN3+L7YIeWj7mZDIMo+JMnQ+8qJRl7UTqAk7mb11Vfv5JZg10oMUCvTiURexIGEtoGDDTCChpVoup8EIusJhr3vvvtsY5tttpmZNGmSGTFiRPeNZ2ihcqJ54oknDKkFO5ExY8Y0Ioc7uS\/EtY888ojZYYcdbNM4s3Fqu3LhhRfaqGaihK+44ooQXah9m0o03U3xc889Z3hniMLng4hGw3GeMqVyoilzsCGehTr6iU98woZ1E8q9117NmfpHjx5t42j4ehDPoNI5Ako0nWPm3oFpj+UAyeCqqMLtUDnREJSHhLYRu5uq9LvlRWAiSXkhWs1VV13VCODDUYzDWKVzBJRoOsfMvQNtmg8hMWvbbbddYmMDBgwIGhBbCdFwUJJE5GxnL1y40A6clxCnKVvdvUY6qKb0XcZCbmMOYIpJiIefdKUq+RBQosmHG3exJjkSk0VChl+UTjQEDu25554tg4MIPSckule2t2UCn3nmGXswlETrImg45DgmS59KfgSEaHbZZRdzyimn5G+oD++84YYbMq8\/jtEsv\/zyQVAqnWhwiOKvQDAxttpqK7PCCitYk0OqIBx22GF2p6YXhVwfOIhXWWUVs\/766\/ccYfYi5trn+BEonWikxCxxJziohgwZYlF65ZVXbCoFNAK0GvwbKoqAIlAPBEonGnFMTZgwoVH9QKAkbwt1mzA5KL+Cg0pFEVAEeh+B0olGypckVTIgDmXvvfe2qIZ0TPX+tOkIFIHeQqAyosHhS1lOVxYsWGDTeCrR9NYi0t4qAu0QUKJph5D+rggoAl0joETTNYTagCKgCLRDQImmHUL6uyKgCHSNQGVEQySwn5uFo+sS8EZqzyRhJ4qDirIt3jWom5IYAAAEyElEQVQC2oAioAgER6AyoulmZDGliehmHHW499VXX7UxUJ3KyiuvbJPPU5ZmxRVXjOY0fqfj0OuzIVA60YwfPz7XwnSHQwkTIm9VqkdAsiN22hPOf5G0nWhwSh1L2Y9O29HrewOB0ommN2DRXmZF4Jxzzsl1\/ogcPQRnKtFkRbq3r1Oi6e35q7z35J+lDpMvnGYnNQHHSSgM6As5UUjJyv3EUyXVcap8cNqBwhBQoikMSm3IRUCK6lHb+eKLL1Zw+hwBJZo+XwChhp+FaDjJT\/F58tdK7lqKCZKofq211rJR4jj+yQpHGsqtt97a\/o8DuWhR119\/vU03glZE4T6SOm2wwQaJQ6KmFvWlOUNHqhLKwqJJcfZOJTwCSjThMe7LJ2QhGsrq+D4aapiTqR\/ygYQgBl\/QkCjvKonG3N859e+aYVRqJMkaeXKThGwCRxxxhKbzCLxKlWgCA9yvzXdLNILbjjvuaLbcckt7yBbCcIXMcfyP32bMmGF\/2njjjW2NIpHp06ebKVOm2H9CbLvuuqshwyNaEj4iZPfdd0\/0I\/Xr3IUYtxJNCFS1TVME0ZCZ0M1OeNBBB5kbb7zRokvKV7QaEf575syZTSlGMKm22GILW8MI5\/TUqVObUo8cf\/zx5qKLLrJNUH9Lg0DDLVwlmnDY9nXLRRDNww8\/3BTI526l+0GbUl8L0ClTvNpqq1niETJKqhJKrmfJIIDWQ4pZlTAIKNGEwbXvW+2WaIYPH94wbQRMKT\/Mv\/2qn26Nc8yiYcOGWZIRLQdtJkkoqobsu+++5qijjur7eQsFgBJNKGT7vN1uiQbfC2faXBGiSaoKmkQ0mFdoN1lE\/TRZUMp\/jRJNfuz0zhQEuiUaStb4zt9OiYaqFJhUyCGHHJI6XxzixZ+jEgYBJZowuPZ9qzEQzeTJkxvBgmyTc3jTF\/w0VBslk0DS730\/kQUBoERTEJDaTDMCMRDNrFmzGn6XCy64oJEmVnrqFlc766yz7E6ZShgElGjC4Nr3rcZANAT84evhzNXIkSOb8hg9++yzhu1yfDv4fKgqyv+rhEFAiSYMrn3fagxEwyQQdwOhIBAJRw+WLFli2DonvgZJ0nb6fgILBkCJpmBAtbn\/ITB69Ggzd+5ck3aoEm0D88XNRyNb0knO4KuvvtpQxXTVVVddpqRy0q6TzAVlfAj8Q7NxhSyPEydObFn4XueyOASUaIrDUluKGAG0GNLEUq540KBB9mAm5tTAgQMj7nV9uqZEU5+51JEoAtEioEQT7dRoxxSB+iCgRFOfudSRKALRIqBEE+3UaMcUgfogoERTn7nUkSgC0SKgRBPt1GjHFIH6IKBEU5+51JEoAtEioEQT7dRoxxSB+iCgRFOfudSRKALRIqBEE+3UaMcUgfogoERTn7nUkSgC0SKgRBPt1GjHFIH6IKBEU5+51JEoAtEioEQT7dRoxxSB+iCgRFOfudSRKALRIqBEE+3UaMcUgfogoERTn7nUkSgC0SKgRBPt1GjHFIH6IKBEU5+51JEoAtEioEQT7dRoxxSB+iCgRFOfudSRKALRIqBEE+3UaMcUgfogoERTn7nUkSgC0SKgRBPt1GjHFIH6IKBEU5+51JEoAtEioEQT7dRoxxSB+iDwXzKM4aRUwu8IAAAAAElFTkSuQmCC","height":85,"width":141}}
%---
