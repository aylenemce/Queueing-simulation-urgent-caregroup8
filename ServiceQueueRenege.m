classdef ServiceQueueRenege < ServiceQueue

    properties
        RenegeRate = 4;
    end

    properties (SetAccess = private)
        RenegeDist
        Reneged = {}
    end

    methods
        function obj = ServiceQueueRenege(KWArgs)

            arguments
                KWArgs.ArrivalRate (1,1) double = 10
                KWArgs.DepartureRate (1,1) double = 12
                KWArgs.NumServers (1,1) double = 1
                KWArgs.LogInterval (1,1) double = 1/60
                KWArgs.RenegeRate (1,1) double = 4
            end

            % --- manually pass ONLY parent fields ---
            obj = obj@ServiceQueue( ...
                ArrivalRate = KWArgs.ArrivalRate, ...
                DepartureRate = KWArgs.DepartureRate, ...
                NumServers = KWArgs.NumServers, ...
                LogInterval = KWArgs.LogInterval );

            % --- subclass-specific setup ---
            obj.RenegeRate = KWArgs.RenegeRate;
            obj.RenegeDist = makedist("Exponential", ...
                'mu', 1/obj.RenegeRate);

            % NEW:
            % This creates the 5th column required by Section 3.3.2 [cite: 76]
            %obj.Log.NumReneged = zeros(0, 1, 'int64');

        end


        function handle_arrival(obj, arrival)
            % Let parent handle queue insertion + scheduling logic
            handle_arrival@ServiceQueue(obj, arrival);

            % NOW add reneging behavior only
            % This section would be deleted for the M/M/2 simulation
            c = arrival.Customer;

            patience_time = random(obj.RenegeDist);
            obj.schedule_event(Renege(obj.Time + patience_time, c.Id));

            % NEW:
            % In an M/M/2 system, they only wait if NumInSystem > 2 (since 2 are being served).
            %if obj.NumInSystem > obj.NumServers
            %c = arrival.Customer;
            %patience_time = random(obj.RenegeDist);
            %obj.schedule_event(Renege(obj.Time + patience_time, c.Id));
            %end

        end

        function handle_renege(obj, event)
            for i = 1:length(obj.Waiting)
                if obj.Waiting{i}.Id == event.CustomerId

                    % mark as reneged
                    obj.Reneged{end+1} = obj.Waiting{i};

                    % DO NOT touch Waiting directly
                    % just ignore them in future processing

                    % NEW:
                    % 2. REMOVE them from the Waiting queue
                    obj.Waiting(i) = [];

                    return
                end
            end
        end


        function record_log(obj)
            % Keep original log behavior (4 columns ONLY)
            record_log@ServiceQueue(obj);

            % NEW:
            % Add the total count of customers who have reneged to the last row
            %obj.Log.NumReneged(end) = length(obj.Reneged);
        end
    end
end