with Remote_Control_Car_Tasks;

with Ada.Real_Time;     use Ada.Real_Time;
with STM32.Board;       use STM32.Board;

procedure Remote_Control_Car is
begin
   Remote_Control_Car_Tasks.Start;
   delay until Clock + To_Time_Span (Duration'Last);
end Remote_Control_Car;
