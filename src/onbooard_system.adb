with Onboard_System_Package;

with Ada.Real_Time;     use Ada.Real_Time;
with STM32.Board;       use STM32.Board;

procedure Onbooard_System is
begin
   Onboard_System_Package.Start;
   delay until Clock + To_Time_Span (Duration'Last);
end Onbooard_System;
