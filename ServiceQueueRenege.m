classdef ServiceQueueRenege < ServiceQueue

    properties
        RenegeRate = 4;
    end

    properties (SetAccess = public)
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
            %obj.Log.NumReneged = zeros(0, 1, 'int64');

        end


        function handle_arrival(obj, arrival)
            % Let parent handle queue insertion + scheduling logic
            handle_arrival@ServiceQueue(obj, arrival);

            % NOW add reneging behavior only
            % This section would be deleted for the M/M/2 simulation
            %c = arrival.Customer;

            %patience_time = random(obj.RenegeDist);
            %obj.schedule_event(Renege(obj.Time + patience_time, c.Id));

            % NEW:
            %if currentNumInSystem > obj.NumServers
               % c = arrival.Customer;
               % patience_time = random(obj.RenegeDist);
               % obj.schedule_event(Renege(obj.Time + patience_time, c.Id));
            %end

            isInQueue = false;
            for i = 1:length(obj.Waiting)
                if obj.Waiting{i}.Id == arrival.Customer.Id
                    isInQueue = true;
                    break;
                end
            end

            if isInQueue
                c = arrival.Customer;
                patience_time = random(obj.RenegeDist);
                obj.schedule_event(Renege(obj.Time + patience_time, c.Id));
            end
        end

        function handle_renege(obj, event)
            for i = 1:length(obj.Waiting)
                if obj.Waiting{i}.Id == event.CustomerId

                    % mark as reneged
                    obj.Reneged{end+1} = obj.Waiting{i};

                    % DO NOT touch Waiting directly
                    % just ignore them in future processing

                    % NEW
                    obj.Waiting(i) = [];

                    return
                end
            end
        end


        function record_log(obj)
            % Keep original log behavior (4 columns ONLY)
            record_log@ServiceQueue(obj);

            % NEW:
            %obj.Log.NumReneged(end) = length(obj.Reneged);
        end
    end
end