classdef Renege < Event
    properties
        CustomerId % Tracks which specific person is losing patience
    end
    
    methods
        function obj = Renege(time, id)
            obj.Time = time;
            obj.CustomerId = id;
        end
        
        function visit(obj, queue)
            % This tells the queue to execute the renege logic
            queue.handle_renege(obj);
        end
    end
end